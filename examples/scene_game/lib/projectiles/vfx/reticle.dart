part of '../projectiles.dart';

// Reused scratch so the per-frame targeting pass allocates nothing.
final Vector3 _reticlePlayerPos = Vector3.zero();

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

/// Drives the reticle onto the most relevant rock in the firing lane, facing
/// the camera. Visual feedback only — no homing.
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

  player.value.node.globalTranslationInto(_reticlePlayerPos);
  final pos = _reticlePlayerPos;

  // Nearest rock ahead of the player within the firing lane.
  var bestZ = -1e9;
  var hasRock = false;
  var bx = 0.0, by = 0.0, bz = 0.0;
  rocks.each((entity, binding) {
    final m = binding.node.globalTransform.storage;
    final rx = m[12], ry = m[13], rz = m[14];
    if (rz > pos.z + 1.0) return;
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
  reticle.opacity = approach(reticle.opacity, showing ? 1.0 : 0.0, dt * 10);
  reticle.charge01 = approach(
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

@System()
void disposeLockOnReticle(@Resource() LockOnReticle reticle) =>
    reticle.disposeModel();
