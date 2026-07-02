part of '../collectables.dart';

// Reused scratch so per-frame position reads allocate nothing.
final Vector3 _playerScratch = Vector3.zero();
final Vector3 _pickupScratch = Vector3.zero();

/// Spawns a shield pickup when none is active and the cadence is due; the
/// [OptionalSingle] gate is the single source of "is a pickup active".
@System()
void spawnShieldPickups(
  @Query(requires: [ShieldPickup]) OptionalSingle<SceneNodeRef> activePickup,
  @Resource() CollectableSpawner spawner,
  @Resource() FixedTime time,
  Commands commands,
) {
  if (activePickup.isPresent) return;
  if (!spawner.tick(time.delta)) return;
  // The bundle itself scopes the pickup to the run (DespawnOnExit field).
  commands.spawn(ShieldPickupBundle(x: spawner.nextLane()));
}

/// Collectables reset their own state when a run (re)starts.
@System()
void resetCollectablesOnRunStart(
  @Resource() ShieldState shield,
  @Resource() CollectableSpawner spawner,
  @Resource() ShieldDeflectVfx deflectVfx,
) {
  shield.reset();
  spawner.reset();
  deflectVfx.reset();
}

@System()
void updateShieldState(
  @Resource() ShieldState shield,
  @Resource() FrameTime time,
) {
  shield.tick(time.delta);
}

/// Pulses and bobs each pickup's glow child; the physics-driven root transform
/// is left to Rapier.
@System()
void animateShieldPickups(
  @Query(
    requires: [ShieldPickup],
    writes: [ShieldPickupState, ShieldPickupVisuals],
  )
  Query2<ShieldPickupState, ShieldPickupVisuals> pickups,
  @Resource() FrameTime time,
) {
  final dt = time.delta;
  pickups.each((entity, state, visuals) {
    state.age += dt;
    final pulse = 1 + 0.18 * math.sin(state.age * 6);
    final bob = 0.12 * math.sin(state.age * 3);
    visuals.glow.setLocalUniform(0, bob, 0, pulse);
  });
}

/// Collects a pickup when the player is close enough (a direct squared distance
/// — only zero or one pickup exists).
@System()
void collectShieldPickups(
  @Query(requires: [Player]) Single<SceneNodeRef> player,
  @Query(requires: [ShieldPickup]) Query1<SceneNodeRef> pickups,
  @Resource() ShieldState shield,
  Commands commands,
) {
  player.value.node.globalTranslationInto(_playerScratch);
  pickups.each((entity, binding) {
    binding.node.globalTranslationInto(_pickupScratch);
    final dx = _pickupScratch.x - _playerScratch.x;
    final dy = _pickupScratch.y - _playerScratch.y;
    final dz = _pickupScratch.z - _playerScratch.z;
    if (dx * dx + dy * dy + dz * dz <= shieldCollectDistanceSq) {
      shield.activate();
      commands.despawn(entity);
    }
  });
}

/// Drives the player's shield bubble and activation badge from [ShieldState],
/// which owns the timing. Mutates player-owned nodes/materials in place.
@System()
void updateShieldVisuals(
  @Query(requires: [Player], writes: [PlayerVisuals])
  Single<PlayerVisuals> visuals,
  @Resource() ShieldState shield,
  @Resource() FrameTime time,
) {
  final v = visuals.value;
  final dt = time.delta;

  // Activation pop on the inactive -> active edge.
  if (shield.active && !v.shieldWasActive) v.badgePop = 1;
  v.shieldWasActive = shield.active;

  final warning = shield.expiringSoon;
  v.shieldPhase += dt * (warning ? 16 : 4);
  final breathe = 1 + 0.05 * math.sin(v.shieldPhase);
  final warnFlash = warning ? 0.5 + 0.5 * math.sin(v.shieldPhase * 1.5) : 1.0;

  // Bubble: eased show factor so expiry shrinks it cleanly.
  v.shieldShow = approach(v.shieldShow, shield.active ? 1.0 : 0.0, dt * 8);
  final bubbleScale = v.shieldShow * breathe;
  v.shieldBubble.setLocalUniform(0, 0, 0, bubbleScale);
  v.shieldBubbleMaterial.baseColorFactor = Vector4(
    0.4,
    0.8,
    1.0,
    (0.12 + 0.12 * warnFlash) * v.shieldShow,
  );
  v.shieldBubbleMaterial.emissiveFactor = Vector4(
    0.25 * warnFlash,
    0.6 * warnFlash,
    1.1 * warnFlash,
    1,
  );

  // Activation badge: a short overshoot in front of the player.
  v.badgePop = math.max(0, v.badgePop - dt / 0.45);
  final prog = 1 - v.badgePop;
  final badgeScale = v.badgePop > 0.001 ? math.sin(prog * math.pi) * 1.3 : 0.0;
  v.shieldBadge.setLocalUniform(
    0,
    playerBodyVisualRadius * 0.6,
    -(playerBodyVisualRadius + 0.4),
    badgeScale,
  );
}

/// Despawns pickups that fell below the world or rolled past the ramp.
@System()
void cleanupPickups(
  @Query(requires: [Collectable]) Query1<SceneNodeRef> pickups,
  Commands commands,
) {
  pickups.each((entity, binding) {
    binding.node.globalTranslationInto(_pickupScratch);
    if (_pickupScratch.y < collectableKillY ||
        _pickupScratch.z > collectablePassZ) {
      commands.despawn(entity);
    }
  });
}

@System()
void spawnShieldDeflectVfx(
  @Resource() Scene scene,
  @Resource() ShieldDeflectVfx vfx,
) {
  vfx.pool = buildDeflectPool()..addTo(scene);
}

@System()
void updateShieldDeflectVfx(
  @Resource() ShieldDeflectVfx vfx,
  @Resource() FrameTime time,
) {
  final pool = vfx.pool;
  if (pool == null) return;
  final dt = time.delta;
  final scratch = pool.scratch;
  for (var i = 0; i < vfx.age.length; i++) {
    final a = vfx.age[i];
    if (a >= _deflectDuration) continue;
    final next = a + dt;
    vfx.age[i] = next;
    final t = (next / _deflectDuration).clamp(0.0, 1.0);
    final ease = 1 - math.pow(1 - t, 2).toDouble();
    final fade = 1 - t;
    final s = (0.5 + 1.4 * ease) * fade;
    scratch
      ..setIdentity()
      ..setTranslationRaw(
        vfx.origin[i * 3],
        vfx.origin[i * 3 + 1] + 0.6 * ease,
        vfx.origin[i * 3 + 2],
      )
      ..scaleByDouble(s, s, s, 1);
    pool.mesh.setInstanceTransform(i, scratch);
  }
}

