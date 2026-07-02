part of '../player.dart';

@System()
void spawnPlayer(Commands commands) {
  commands.spawn(PlayerBundle());
}

/// Translates input into a move-and-slide request each fixed step. The query
/// declares `writes: [SceneNodeRef]` because mutating an object reached through
/// a component reference counts as writing that component.
@System()
void movePlayer(
  @Query(requires: [Player], writes: [SceneNodeRef])
  Single<SceneNodeRef> player,
  @Resource() InputState input,
  @Resource() FixedTime time,
  @Resource() PlayerKnockback knockback,
) {
  // Resolve the Single once — `.value` re-runs the query each access.
  final ref = player.value;
  final controller = ref.component<RapierKinematicCharacterController>();
  if (controller == null) return;

  final node = ref.node;
  final dt = time.delta;
  _snapToRamp(node, knockback);

  // Read translation from the matrix storage — getTranslation() allocates.
  final m = node.localTransform.storage;
  final positionY = m[13];
  final motion = knockback.step(dt)
    ..x += input.horizontal * playerStrafeSpeed * dt;
  final nextX = m[12] + motion.x;
  final nextZ = m[14] + motion.z;
  if (isOverRampFootprint(nextX, nextZ)) {
    motion.y = playerGroundYAtZ(nextZ) - positionY;
    knockback.ground();
  } else {
    motion.y += knockback.fallStep(dt);
  }
  controller.move(motion);
}

void _snapToRamp(Node node, PlayerKnockback knockback) {
  final transform = node.localTransform;
  final m = transform.storage;
  if (!isOverRampFootprint(m[12], m[14])) return;
  m[13] = playerGroundYAtZ(m[14]);
  // Reassign to trip the transform dirty flag after the in-place edit.
  node.localTransform = transform;
  knockback.ground();
}

/// Unfolds the six visual crab legs, then layers a procedural two-group gait on
/// top while the player strafes. Only player-owned child nodes move.
@System()
void animateCrabLegs(
  @Query(requires: [Player], writes: [PlayerVisuals])
  Single<PlayerVisuals> visuals,
  @Resource() InputState input,
  @Resource() FrameTime time,
) {
  final v = visuals.value;
  final dt = time.delta;

  v.legExtension01 = approach(
    v.legExtension01,
    1.0,
    dt / crabLegExtensionDuration,
  );

  final movement01 = input.horizontal.abs().clamp(0.0, 1.0).toDouble();
  v.gaitPhase = advanceCrabGaitPhase(v.gaitPhase, movement01, dt);
  final direction = input.horizontal == 0
      ? 1.0
      : input.horizontal.sign.toDouble();

  for (final leg in v.allLegs) {
    final sample = sampleCrabLegGait(
      globalExtension: v.legExtension01,
      extensionDelay: leg.extensionDelay,
      movement01: movement01,
      direction: direction,
      gaitPhase: v.gaitPhase,
      phaseOffset: leg.phaseOffset,
    );
    final basePose = mixCrabLegPose(
      leg.collapsedPose,
      leg.extendedPose,
      sample.extension,
    );
    _applyLegPose(leg, basePose, sample.lift, sample.stride, sample.bend);
  }
}

/// Restores the player's body, pose and knockback for a fresh run. Each
/// feature resets its own state in `OnEnter(GameStatus.playing)`; the rules
/// feature only resets what it owns (run clock, camera).
@System()
void resetPlayerOnRunStart(
  @Query(requires: [Player], writes: [SceneNodeRef])
  Single<SceneNodeRef> player,
  @Query(requires: [Player], writes: [PlayerVisuals])
  Single<PlayerVisuals> visuals,
  @Resource() PlayerKnockback knockback,
) {
  final ref = player.value;
  final body = ref.component<RapierRigidBody>();
  if (body != null) {
    body
      ..type = BodyType.kinematic
      ..linearVelocity = Vector3.zero()
      ..angularVelocity = Vector3.zero();
  }
  ref.node.localTransform = Matrix4.translation(
    Vector3(0, playerStartY, playerStartZ),
  );
  knockback.reset();
  visuals.value.resetLegs();
}
