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
  node.globalTranslationInto(_playerPos);
  final pos = _playerPos;

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
    if (!colliderOnLayer(hit.collider, PhysicsLayers.rock)) continue;
    hit.node.globalTranslationInto(_rockPos);
    final rockPos = _rockPos;
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
    player.value.node.globalTranslationInto(_playerPos);
    camera.follow(_playerPos, time.delta);
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

/// Starts a run clean. Registered in `OnEnter(GameStatus.playing)`, so it
/// runs once at startup and again on every restart.
///
/// Rules only resets what it owns — the run clock and the camera. Every
/// feature resets its own state in its own `OnEnter(GameStatus.playing)`
/// system, and run-scoped entities (rocks, projectiles, pickups) carry
/// `DespawnOnExit(GameStatus.playing)` in their bundles, so the transition
/// itself sweeps them.
@System()
void startRun(@Resource() GameState game, @Resource() CameraRig camera) {
  game.reset();
  camera.reset();
}
