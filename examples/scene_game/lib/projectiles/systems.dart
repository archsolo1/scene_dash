part of 'projectiles.dart';

@System()
final class ShootProjectilesSystem extends GameSystem {
  const ShootProjectilesSystem();

  void run(
    Commands commands,
    @Query(requires: [Player]) Query1<SceneNodeRef> players,
    @Resource() InputState input,
    @Resource() GameState game,
    @Resource() Blaster blaster,
    @Resource() FixedTime time,
  ) {
    if (game.status != GameStatus.playing) {
      input.shootRequested = false;
      blaster.reset();
      return;
    }

    if (input.shootRequested && blaster.canStartBurst) {
      blaster.startBurst();
    }
    input.shootRequested = false;

    if (!blaster.consumeShot(time.delta)) return;
    final player = players.singleOrNull();
    if (player == null) return;

    final position = player.$2.node.globalTransform.getTranslation()
      ..y += playerRadius * 0.45
      ..z -= playerRadius + projectileRadius + 0.08;
    commands.spawn(ProjectileBundle(position: position));
  }
}

@System()
final class UpdateProjectilesSystem extends GameSystem {
  const UpdateProjectilesSystem();

  void run(
    @Query(writes: [Projectile]) Query2<Projectile, SceneNodeRef> projectiles,
    @Resource() PhysicsWorld physics,
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

      if (_knockFirstRock(physics, position)) {
        commands
          ..spawn(impactSparkBundle(position))
          ..spawn(impactRingBundle(position));
        commands.despawn(entity);
      }
    });
  }

  bool _knockFirstRock(PhysicsWorld physics, Vector3 position) {
    final hits = physics.overlapSphere(
      position,
      projectileHitRadius,
      layerMask: PhysicsLayers.rock,
      includeFixed: false,
      includeKinematic: false,
      includeDynamic: true,
      includeTriggers: false,
    );
    for (final hit in hits) {
      final collider = hit.collider;
      if (collider is! RapierCollider ||
          collider.collisionLayer & PhysicsLayers.rock == 0) {
        continue;
      }

      final rockPosition = hit.node.globalTransform.getTranslation();
      final xAway = rockPosition.x - position.x;
      final body = hit.node.getComponent<RapierRigidBody>();
      if (body != null) {
        body.linearVelocity = Vector3(
          xAway.clamp(-1, 1).toDouble() * projectileKnockback * 0.35,
          projectileLift,
          -projectileKnockback,
        );
        body.angularVelocity = Vector3(-9, 0, xAway.sign * 5);
      }
      return true;
    }
    return false;
  }
}

@System()
final class UpdateProjectileVfxSystem extends GameSystem {
  const UpdateProjectileVfxSystem();

  void run(
    @Query(writes: [VfxEffect]) Query2<VfxEffect, SceneNodeRef> effects,
    @Resource() FrameTime time,
    Commands commands,
  ) {
    final dt = time.delta;
    effects.each((entity, effect, binding) {
      if (!effect.initialized) {
        effect.origin.setFrom(binding.node.localTransform.getTranslation());
        effect.initialized = true;
      }

      effect.age += dt;
      final t = (effect.age / effect.duration).clamp(0, 1).toDouble();
      final ease = 1 - math.pow(1 - t, 3).toDouble();
      final fade = (1 - t) * (1 - t);
      final scale =
          effect.startScale + (effect.endScale - effect.startScale) * ease;
      final pos = Vector3(
        effect.origin.x,
        effect.origin.y + effect.floatUp * ease,
        effect.origin.z,
      );

      effect.material
        ..baseColorFactor = Vector4(
          effect.color.x,
          effect.color.y,
          effect.color.z,
          effect.color.w * fade,
        )
        ..emissiveFactor = Vector4(
          effect.color.x * 1.8 * fade,
          effect.color.y * 1.8 * fade,
          effect.color.z * 1.8 * fade,
          1,
        );
      binding.node.localTransform = Matrix4.translation(pos)
        ..rotateY(effect.spin * t)
        ..scaleByDouble(scale, scale, scale, 1);

      if (effect.age >= effect.duration) {
        commands.despawn(entity);
      }
    });
  }
}
