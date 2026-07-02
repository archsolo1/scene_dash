part of '../projectiles.dart';

// Reused scratch so the update loop allocates nothing per projectile.
final Vector3 _projectilePosition = Vector3.zero();
final Vector3 _rockHitPosition = Vector3.zero();

/// Gated to `inState(GameStatus.playing)` at registration; the run-end
/// cleanup lives in [stopBlasterOnRunEnd] on `OnExit`.
@System()
final class ShootProjectilesSystem extends GameSystem {
  const ShootProjectilesSystem();

  void run(
    Commands commands,
    @Query(requires: [Player]) Single<SceneNodeRef> player,
    @Resource() InputState input,
    @Resource() Blaster blaster,
    @Resource() LockOnReticle reticle,
    @Resource() FixedTime time,
  ) {
    final shots = blaster.update(
      pressed: input.firePressed,
      released: input.fireReleased,
      canceled: input.fireCanceled,
      held: input.fireHeld,
      dt: time.delta,
    );
    input.clearFireTransitions();
    if (shots.isEmpty) return;

    final base = player.value.node.globalTransform.getTranslation()
      ..y += playerBodyVisualRadius * 0.45
      ..z -= playerBodyVisualRadius + projectileRadius + 0.08;

    // The bundle itself scopes each shot to the run (DespawnOnExit field).
    final charged = shots.charged;
    if (charged != null) {
      final strength = math.max(charged, minChargedCharge);
      commands.spawn(ProjectileBundle(position: base, charge: strength));
      reticle.flashFired();
    } else {
      for (var i = 0; i < shots.burst; i++) {
        commands.spawn(ProjectileBundle(position: base));
      }
    }
  }
}

/// Projectiles reset their own state when a run (re)starts.
@System()
void resetProjectilesOnRunStart(
  @Resource() Blaster blaster,
  @Resource() ImpactVfx impactVfx,
  @Resource() LockOnReticle reticle,
) {
  blaster.reset();
  impactVfx.reset();
  reticle.reset();
}

/// Leaving the run aborts any in-flight charge and clears the one-frame fire
/// transitions, so a held button cannot fire into the lose screen.
@System()
void stopBlasterOnRunEnd(
  @Resource() Blaster blaster,
  @Resource() InputState input,
) {
  blaster.reset();
  input.clearFireTransitions();
}

@System()
final class UpdateProjectilesSystem extends GameSystem {
  const UpdateProjectilesSystem();

  void run(
    @Query(writes: [Projectile]) Query2<Projectile, SceneNodeRef> projectiles,
    @Resource() PhysicsWorld physics,
    @Resource() SceneNodeIndex index,
    @Resource() ImpactVfx vfx,
    @Resource() LockOnReticle reticle,
    @Resource() FrameTime time,
    Commands commands,
  ) {
    final dt = time.delta;
    projectiles.each((entity, projectile, binding) {
      projectile.age += dt;
      binding.node.globalTranslationInto(_projectilePosition);
      final position = _projectilePosition;

      if (projectile.age >= projectileLifetime ||
          position.z < -rampLength * 0.5 - 2 ||
          position.y < -2) {
        commands.despawn(entity);
        return;
      }

      final hitCount = _knockRocks(
        physics,
        index,
        commands,
        vfx,
        position,
        projectile,
      );
      if (hitCount > 0) {
        reticle.flashImpact();
        if (!projectile.charged ||
            projectile.hitRocks.length >= chargedProjectileMaxHits) {
          commands.despawn(entity);
        }
      }
    });
  }

  /// Applies the native bounce/spin to rocks overlapping [position] and inserts
  /// an ECS hit reaction on each resolved rock entity. Returns the hit count.
  int _knockRocks(
    PhysicsWorld physics,
    SceneNodeIndex index,
    Commands commands,
    ImpactVfx vfx,
    Vector3 position,
    Projectile projectile,
  ) {
    final hits = physics.overlapSphere(
      position,
      projectileHitRadiusForCharge(projectile.charge),
      layerMask: PhysicsLayers.rock,
      includeFixed: false,
      includeKinematic: false,
      includeDynamic: true,
      includeTriggers: false,
    );
    var hitCount = 0;
    for (final hit in hits) {
      if (!colliderOnLayer(hit.collider, PhysicsLayers.rock)) continue;

      final entity = index.entityOf(hit.node);
      if (projectile.charged) {
        if (entity == null || projectile.hitRocks.contains(entity.index)) {
          continue;
        }
      }

      hit.node.globalTranslationInto(_rockHitPosition);
      final xAway = _rockHitPosition.x - position.x;
      final knock = projectileKnockbackForCharge(projectile.charge);
      final lift = projectileLiftForCharge(projectile.charge);
      final spin = projectileSpinForCharge(projectile.charge);
      hit.node.getComponent<RapierRigidBody>()
        ?..linearVelocity = Vector3(
          xAway.clamp(-1, 1).toDouble() * knock * 0.35,
          lift,
          -knock,
        )
        ..angularVelocity = Vector3(-spin, 0, xAway.sign * spin * 0.55);

      // The index walks ancestors, so a hit on a child mesh still resolves to
      // its rock entity.
      if (entity != null) {
        if (projectile.charged) projectile.hitRocks.add(entity.index);
        commands.insert<RockHitReaction>(
          entity,
          RockHitReaction(
            strength: projectile.charge.clamp(0.0, 1.0).toDouble(),
          ),
        );
      }
      vfx.emit(_rockHitPosition, strength: projectile.charge);
      hitCount++;
      if (!projectile.charged || hitCount >= chargedProjectileMaxHits) break;
    }
    return hitCount;
  }
}

