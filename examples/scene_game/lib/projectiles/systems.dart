part of 'projectiles.dart';

@System()
final class ShootProjectilesSystem extends GameSystem {
  const ShootProjectilesSystem();

  void run(
    Commands commands,
    // Reads the player position only (no node mutation), so no `writes:` here.
    @Query(requires: [Player]) Single<SceneNodeRef> player,
    @Resource() InputState input,
    @Resource() GameState game,
    @Resource() Blaster blaster,
    @Resource() LockOnReticle reticle,
    @Resource() FixedTime time,
  ) {
    if (game.status != GameStatus.playing) {
      blaster.reset();
      input.clearFireTransitions();
      return;
    }

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

    final charged = shots.charged;
    if (charged != null) {
      // A charged release is one larger projectile, not a burst.
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
      final position = binding.node.globalTransform.getTranslation();

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

  /// Applies the native bounce/spin to the first rock overlapping [position],
  /// scaled by [charge], and inserts an ECS hit reaction on the resolved rock
  /// entity. Returns whether a rock was hit.
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
      final collider = hit.collider;
      if (collider is! RapierCollider ||
          collider.collisionLayer & PhysicsLayers.rock == 0) {
        continue;
      }

      final entity = index.entityOf(hit.node);
      if (projectile.charged) {
        if (entity == null || projectile.hitRocks.contains(entity.index)) {
          continue;
        }
      }

      final rockPosition = hit.node.globalTransform.getTranslation();
      final xAway = rockPosition.x - position.x;
      final knock = projectileKnockbackForCharge(projectile.charge);
      final lift = projectileLiftForCharge(projectile.charge);
      final spin = projectileSpinForCharge(projectile.charge);
      final body = hit.node.getComponent<RapierRigidBody>();
      if (body != null) {
        body.linearVelocity = Vector3(
          xAway.clamp(-1, 1).toDouble() * knock * 0.35,
          lift,
          -knock,
        );
        body.angularVelocity = Vector3(-spin, 0, xAway.sign * spin * 0.55);
      }

      // Resolve the hit node back to its rock entity (the index walks ancestors,
      // so a hit on a child mesh still resolves) and attach a scaled hit
      // reaction — no rebuilt node/entity maps, no scan of all rocks.
      if (entity != null) {
        if (projectile.charged) projectile.hitRocks.add(entity.index);
        commands.insert<RockHitReaction>(
          entity,
          RockHitReaction(
            strength: projectile.charge.clamp(0.0, 1.0).toDouble(),
          ),
        );
      }
      vfx.emit(rockPosition, strength: projectile.charge);
      hitCount++;
      if (!projectile.charged || hitCount >= chargedProjectileMaxHits) break;
    }
    return hitCount;
  }
}

/// Update: drives the player's charge orb and beam from the [Blaster] (the sole
/// source of charge truth). The orb grows with charge, pulses, flashes faster
/// near full, and shifts colour from cyan toward a hot charged violet; a beam
/// tethers the player to the orb. All animation mutates player-owned nodes and
/// the player's unique materials in place — no shared-material leaks, no
/// per-frame allocation.
@System()
void updateChargeVisuals(
  @Query(requires: [Player], writes: [PlayerVisuals])
  Single<PlayerVisuals> visuals,
  @Resource() Blaster blaster,
  @Resource() FrameTime time,
) {
  final v = visuals.value;
  final dt = time.delta;
  final charging = blaster.isCharging;
  final c = blaster.charge01;

  // Ease the show factor so release/cancel shrinks the orb and beam cleanly.
  final target = charging ? 1.0 : 0.0;
  v.chargePhase += dt * (6 + 10 * c);
  final show = _approach(v.chargeShow, target, dt * 12);
  v.chargeShow = show;

  final pulse = 1 + 0.08 * math.sin(v.chargePhase);
  final flash = (charging && c > 0.82)
      ? 0.75 + 0.25 * math.sin(v.chargePhase * 3)
      : 1.0;

  // A restrained vertical charge beam above the player. It grows like a simple
  // cylinder, then the small decor-like motes carry the magical feel.
  final beamBaseY = playerBodyVisualRadius * 1.05;
  final beamHeight = (0.25 + 1.45 * c) * show;
  final beamCenterY = beamBaseY + beamHeight * 0.5;
  final beamThick = (0.06 + 0.08 * c) * show * pulse;
  _place(
    v.chargeBeam,
    0,
    beamCenterY,
    0,
    beamThick,
    beamHeight * 0.5,
    beamThick,
  );
  _placeUniform(v.chargeOrb, 0, 0, 0, 0);

  // Colour from cyan toward charged violet; brighten near full with the flash.
  final mix = c * c;
  v.chargeOrbMaterial.emissiveFactor = Vector4(
    (0.3 + 0.85 * mix) * flash,
    (0.9 - 0.35 * mix) * flash,
    (1.2 + 0.2 * mix) * flash,
    1,
  );
  v.chargeOrbMaterial.baseColorFactor = Vector4(
    0.4 + 0.45 * mix,
    0.9 - 0.2 * mix,
    1.0,
    (0.6 + 0.4 * c) * show,
  );

  v.chargeBeamMaterial.emissiveFactor = Vector4(
    (0.4 + 0.7 * mix) * flash,
    (1.0 - 0.3 * mix) * flash,
    (1.4 + 0.1 * mix) * flash,
    1,
  );
  v.chargeBeamMaterial.baseColorFactor = Vector4(
    0.45 + 0.4 * mix,
    0.88,
    1.0,
    (0.5 + 0.4 * c) * show,
  );

  final moteAlpha = (0.35 + 0.45 * c) * show;
  v.chargeMoteMaterial.baseColorFactor = Vector4(
    0.62 + 0.2 * mix,
    0.9 - 0.12 * mix,
    1.0,
    moteAlpha,
  );
  v.chargeMoteMaterial.emissiveFactor = Vector4(
    (0.45 + 0.55 * mix) * flash,
    (0.8 - 0.18 * mix) * flash,
    (1.0 + 0.22 * mix) * flash,
    1,
  );

  final moteCount = v.chargeMotes.length;
  final moteRadius = 0.34 + 0.12 * c;
  for (var i = 0; i < moteCount; i++) {
    final offset = i / moteCount;
    final rise = (offset + v.chargePhase * 0.035) % 1.0;
    final angle = v.chargePhase * (0.45 + 0.05 * i) + offset * math.pi * 2;
    final wobble = 1 + 0.18 * math.sin(v.chargePhase * 1.3 + i);
    final x = math.cos(angle) * moteRadius * wobble;
    final z = math.sin(angle) * moteRadius * wobble;
    final y = beamBaseY + math.max(beamHeight, 0.1) * rise;
    final size = (0.65 + 0.35 * math.sin(v.chargePhase + i)) * show;
    _placeUniform(v.chargeMotes[i], x, y, z, size);
  }
}

/// Startup: build the spark, charged-spark and ring instanced pools.
@System()
void spawnImpactVfx(@Resource() Scene scene, @Resource() ImpactVfx vfx) {
  vfx.sparkPool = InstancedPool(
    geometry: SphereGeometry(radius: 0.22, segments: 12, rings: 6),
    material: glowMaterial(Vector4(0.56, 0.92, 1.0, 0.4), alpha: 0.4),
    capacity: _sparkCapacity,
  )..addTo(scene);
  vfx.chargedSparkPool = InstancedPool(
    geometry: SphereGeometry(radius: 0.26, segments: 12, rings: 6),
    material: glowMaterial(Vector4(0.78, 0.5, 1.0, 0.5), alpha: 0.5),
    capacity: _chargedCapacity,
  )..addTo(scene);
  vfx.ringPool = InstancedPool(
    geometry: ringGeometry(thickness: 0.16),
    material: glowMaterial(Vector4(0.44, 0.82, 1.0, 0.28), alpha: 0.28),
    capacity: _ringCapacity,
  )..addTo(scene);
}

/// Update: advance all three pools. Allocation-free — one scratch matrix per
/// pool, reused for every instance. Strength (charge) scales the charged sparks
/// and the ring within bounded limits.
@System()
void updateImpactVfx(@Resource() ImpactVfx vfx, @Resource() FrameTime time) {
  final dt = time.delta;
  _advanceBurst(
    vfx.sparkPool,
    vfx.sparkAge,
    vfx.sparkOrigin,
    dt,
    duration: _sparkDuration,
    startScale: 0.45,
    endScale: 1.15,
    floatUp: 0.3,
    spin: 0.8,
  );
  _advanceBurst(
    vfx.chargedSparkPool,
    vfx.chargedAge,
    vfx.chargedOrigin,
    dt,
    duration: _chargedDuration,
    startScale: 0.55,
    endScale: 1.5,
    floatUp: 0.5,
    spin: 1.3,
    strength: vfx.chargedStrength,
    strengthSize: 1.1,
  );
  _advanceBurst(
    vfx.ringPool,
    vfx.ringAge,
    vfx.ringOrigin,
    dt,
    duration: _ringDuration,
    startScale: 0.4,
    endScale: 1.8,
    spin: 0.7,
    strength: vfx.ringStrength,
    strengthSize: 1.4,
  );
}

/// Advances one burst pool: ages each live instance and writes its grow-then-pop
/// transform; free slots (age past [duration]) are skipped (already hidden).
/// When [strength] is given, each instance's end size is boosted by up to
/// [strengthSize] times its stored 0..1 strength.
void _advanceBurst(
  InstancedPool? pool,
  Float32List age,
  Float32List origin,
  double dt, {
  required double duration,
  required double startScale,
  required double endScale,
  double floatUp = 0,
  double spin = 0,
  Float32List? strength,
  double strengthSize = 0,
}) {
  if (pool == null) return;
  final scratch = pool.scratch;
  for (var i = 0; i < age.length; i++) {
    final a = age[i];
    if (a >= duration) continue;
    final next = a + dt;
    age[i] = next;
    final t = (next / duration).clamp(0.0, 1.0);
    final ease = 1 - math.pow(1 - t, 3).toDouble();
    final fade = (1 - t) * (1 - t);
    final boost = strength == null ? 1.0 : 1 + strengthSize * strength[i];
    final s = (startScale + (endScale - startScale) * ease) * fade * boost;
    scratch
      ..setIdentity()
      ..setTranslationRaw(
        origin[i * 3],
        origin[i * 3 + 1] + floatUp * ease,
        origin[i * 3 + 2],
      )
      ..rotateY(spin * t)
      ..scaleByDouble(s, s, s, 1);
    pool.mesh.setInstanceTransform(i, scratch);
  }
}

/// Startup: build the single reused lock-on reticle (one WidgetComponent on one
/// node) and add it to the scene, hidden.
@System()
void spawnLockOnReticle(
  @Resource() Scene scene,
  @Resource() LockOnReticle reticle,
) {
  final component = WidgetComponent(
    child: ReticleWidget(reticle.model),
    size: const Size.square(reticleCanvas),
    worldHeight: rockRadius * 4.4,
    pixelRatio: 1.5,
    input: WidgetInput.manual,
    update: WidgetUpdatePolicy.everyFrame,
  );
  final node = Node()
    ..frustumCulled = false
    ..addComponent(component);
  reticle
    ..node = node
    ..component = component
    ..hideNode();
  scene.root.add(node);
}

/// Update: pick the most relevant rock in the firing lane and drive the reticle
/// onto it facing the camera, easing its charge/lock/visibility from the
/// [Blaster] and publishing to the model. Visual feedback only — it does not
/// steer the projectile or add homing.
@System()
void updateLockOnReticle(
  @Query(requires: [Player]) Single<SceneNodeRef> player,
  @Query(requires: [Rock]) Query1<SceneNodeRef> rocks,
  @Resource() Blaster blaster,
  @Resource() CameraRig camera,
  @Resource() LockOnReticle reticle,
  @Resource() FrameTime time,
) {
  final dt = time.delta;
  reticle.firedFlash = math.max(0, reticle.firedFlash - dt / 0.25);
  reticle.impactFlash = math.max(0, reticle.impactFlash - dt / 0.3);

  final pos = player.value.node.globalTransform.getTranslation();

  // Nearest rock ahead of the player (largest Z below the player) within the
  // firing lane. Reads the transform's translation columns directly — no
  // allocation, no rebuilt set.
  var bestZ = -1e9;
  var hasRock = false;
  var bx = 0.0, by = 0.0, bz = 0.0;
  rocks.each((entity, binding) {
    final m = binding.node.globalTransform.storage;
    final rx = m[12], ry = m[13], rz = m[14];
    if (rz > pos.z + 1.0) return; // not ahead of the player
    if ((rx - pos.x).abs() > reticleLaneHalfWidth) return;
    if (rz > bestZ) {
      bestZ = rz;
      hasRock = true;
      bx = rx;
      by = ry;
      bz = rz;
    }
  });

  final charging = blaster.isCharging;
  final showing =
      hasRock &&
      (charging || reticle.firedFlash > 0.01 || reticle.impactFlash > 0.01);
  reticle.opacity = _approach(reticle.opacity, showing ? 1.0 : 0.0, dt * 10);
  reticle.charge01 = _approach(
    reticle.charge01,
    charging ? blaster.charge01 : 0.0,
    dt * 12,
  );
  reticle.locked = charging && blaster.charge01 >= 0.98;
  reticle.pushToModel();

  if (reticle.opacity > 0.01 && hasRock) {
    reticle.billboardAt(bx, by, bz, camera.position);
  } else {
    reticle.hideNode();
  }
}

/// Shutdown: dispose the reticle model (owned by the resource, not the widget).
@System()
void disposeLockOnReticle(@Resource() LockOnReticle reticle) =>
    reticle.disposeModel();

double _approach(double value, double target, double rate) {
  final a = rate.clamp(0.0, 1.0);
  return value + (target - value) * a;
}

/// Writes a uniform-scaled local transform at (x,y,z) onto [node] in place.
void _placeUniform(Node node, double x, double y, double z, double s) =>
    _place(node, x, y, z, s, s, s);

/// Writes a local transform at (x,y,z) with per-axis scale onto [node] in place.
void _place(
  Node node,
  double x,
  double y,
  double z,
  double sx,
  double sy,
  double sz,
) {
  final m = node.localTransform
    ..setIdentity()
    ..setTranslationRaw(x, y, z)
    ..scaleByDouble(sx, sy, sz, 1);
  node.localTransform = m;
}
