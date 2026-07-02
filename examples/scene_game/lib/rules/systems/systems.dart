part of '../rules.dart';

// Reused scratch state — systems run sequentially, so sharing is safe.
final Vector3 _playerPos = Vector3.zero();
final Vector3 _rockPos = Vector3.zero();
final Ray _groundRay = Ray.originDirection(Vector3.zero(), Vector3(0, -1, 0));

/// Evaluates the lose condition (no ground below) and rock contacts each frame.
@System()
void evaluateGameRules(
  @Query(requires: [Player]) Single<SceneNodeRef> player,
  @Resource() PhysicsWorld world,
  @Resource() GameState game,
  @Resource() NextState<GameStatus> nextStatus,
  @Resource() FrameTime time,
  @Resource() PlayerKnockback knockback,
  @Resource() ShieldState shield,
  @Resource() ShieldDeflectVfx deflectVfx,
) {
  final node = player.value.node;
  // globalTransform returns the node's cached matrix — no allocation.
  final m = node.globalTransform.storage;
  final pos = _playerPos..setValues(m[12], m[13], m[14]);

  game.addSurvival(time.delta);

  if (game.survived > startupGrace) {
    _groundRay.origin.setFrom(pos);
    final ground = world.raycast(
      _groundRay,
      maxDistance: groundProbeDistance,
      includeFixed: true,
      includeKinematic: false,
      includeDynamic: false,
    );
    if (ground == null && pos.y <= playerFallLoseY) {
      game.recordLoss('You fell off the platform');
      nextStatus.set(GameStatus.lost);
      return;
    }
  }

  final hits = world.overlapSphere(
    pos,
    playerCollisionRadius + hitPadding,
    layerMask: PhysicsLayers.rock,
    includeFixed: false,
    includeKinematic: false,
    includeDynamic: true,
    includeTriggers: false,
  );
  // Captured once so the shield protects against every rock this frame, even
  // if deflecting one drains the timer to zero.
  final shielded = shield.active;
  for (final hit in hits) {
    // overlapSphere's layerMask is not yet honored by flutter_scene_rapier, so
    // classify rocks on the result side by collider layer.
    final collider = hit.collider;
    if (collider is! RapierCollider ||
        collider.collisionLayer & PhysicsLayers.rock == 0) {
      continue;
    }
    final rm = hit.node.globalTransform.storage;
    final rockPos = _rockPos..setValues(rm[12], rm[13], rm[14]);
    if (shielded) {
      _deflectRock(hit.node, pos, rockPos, deflectVfx);
      shield.absorbHit();
      continue;
    }
    knockback.pushFromRock(playerPosition: pos, rockPosition: rockPos);
    return;
  }
}

/// Throws a rock up and away from the player.
void _deflectRock(
  Node rockNode,
  Vector3 playerPos,
  Vector3 rockPos,
  ShieldDeflectVfx vfx,
) {
  var dx = rockPos.x - playerPos.x;
  var dz = rockPos.z - playerPos.z;
  var len = math.sqrt(dx * dx + dz * dz);
  if (len < 1e-4) {
    // Centres overlap: push uphill (-Z) rather than dividing by zero.
    dx = 0;
    dz = -1;
    len = 1;
  }
  final nx = dx / len;
  final nz = dz / len;
  final body = rockNode.getComponent<RapierRigidBody>();
  if (body != null) {
    body
      ..linearVelocity = Vector3(
        nx * shieldDeflectOutward,
        shieldDeflectUp,
        nz * shieldDeflectOutward,
      )
      ..angularVelocity = Vector3(
        shieldDeflectSpin,
        0,
        nx.sign * shieldDeflectSpin,
      );
  }
  vfx.emit(rockPos);
}

@System()
final class PlayerViewSystem extends GameSystem {
  const PlayerViewSystem();

  void run(
    @Query(requires: [Player]) Single<SceneNodeRef> player,
    @Resource() CameraRig camera,
    @Resource() FrameTime time,
  ) {
    final m = player.value.node.globalTransform.storage;
    camera.follow(_playerPos..setValues(m[12], m[13], m[14]), time.delta);
  }
}

/// Consumes the restart input: while lost, a restart request transitions back
/// to [GameStatus.playing]; [StartRunSystem] then does the actual reset in
/// `OnEnter(GameStatus.playing)`.
@System()
void requestRestart(
  @Resource() InputState input,
  @Resource() CurrentState<GameStatus> status,
  @Resource() NextState<GameStatus> nextStatus,
) {
  if (!input.restartRequested) return;
  input.restartRequested = false;
  if (status.value != GameStatus.lost) return;
  nextStatus.set(GameStatus.playing);
}

/// Starts a run clean: restores the player body and resets all feature state.
/// Registered in `OnEnter(GameStatus.playing)`, so it runs once at startup and
/// again on every restart. Rocks, projectiles and pickups need no cleanup here
/// — they carry `DespawnOnExit(GameStatus.playing)` and are swept by the
/// transition itself.
@System()
final class StartRunSystem extends GameSystem {
  const StartRunSystem();

  void run(
    @Query(requires: [Player], writes: [SceneNodeRef])
    Single<SceneNodeRef> player,
    @Query(requires: [Player], writes: [PlayerVisuals])
    Single<PlayerVisuals> playerVisuals,
    @Resource() InputState input,
    @Resource() GameState game,
    @Resource() RockSpawner spawner,
    @Resource() CameraRig camera,
    @Resource() PlayerKnockback knockback,
    @Resource() Blaster blaster,
    @Resource() ImpactVfx impactVfx,
    @Resource() LockOnReticle reticle,
    @Resource() ShieldState shield,
    @Resource() CollectableSpawner pickupSpawner,
    @Resource() ShieldDeflectVfx deflectVfx,
  ) {
    // Resets the native body and transform through SceneNodeRef, hence
    // `writes: [SceneNodeRef]` above.
    final ref = player.value;
    final node = ref.node;
    final body = ref.component<RapierRigidBody>();
    if (body != null) {
      body
        ..type = BodyType.kinematic
        ..linearVelocity = Vector3.zero()
        ..angularVelocity = Vector3.zero();
    }
    node.localTransform = Matrix4.translation(
      Vector3(0, playerStartY, playerStartZ),
    );
    camera.reset();
    knockback.reset();
    spawner.reset();
    blaster.reset();
    impactVfx.reset();
    reticle.reset();
    shield.reset();
    pickupSpawner.reset();
    deflectVfx.reset();
    input.clearFireTransitions();
    playerVisuals.value.resetLegs();
    game.reset();
    // Charge/shield visuals self-clear once the blaster and shield are reset.
  }
}
