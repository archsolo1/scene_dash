part of '../rocks.dart';

/// Drops new rocks at the top of the ramp each fixed step.
@System()
final class SpawnRocksSystem extends GameSystem {
  const SpawnRocksSystem();

  void run(
    Commands commands,
    @Resource() RockSpawner spawner,
    @Resource() GameState game,
    @Resource() FixedTime time,
  ) {
    final due = spawner.tick(time.delta, survived: game.survived);
    for (var i = 0; i < due; i++) {
      final x = spawner.nextLane();
      final flaming = spawner.nextIsFlaming(game.survived);
      final entity = commands.spawn(RockBundle(x: x, flaming: flaming));
      // Scoped to the run: losing (exiting `playing`) despawns every rock.
      commands.insert<DespawnOnExit>(
        entity,
        const DespawnOnExit(GameStatus.playing),
      );
      if (flaming) commands.insert<Flaming>(entity, const Flaming());
    }
  }
}

/// Despawns rocks that have rolled off the bottom into the void.
@System()
final class CleanupRocksSystem extends GameSystem {
  const CleanupRocksSystem();

  void run(
    @Query(requires: [Rock]) Query1<SceneNodeRef> rocks,
    Commands commands,
  ) {
    rocks.each((entity, binding) {
      if (binding.node.globalTransform.getTranslation().y < rockKillY) {
        commands.despawn(entity);
      }
    });
  }
}

/// Animates the per-rock flash shell while a hit reaction is active, then drops
/// the component. Only the child shell is scaled — never the physics-driven
/// root node.
@System()
void updateRockHitReactions(
  @Query(requires: [Rock], writes: [RockHitReaction, RockVisuals])
  Query2<RockHitReaction, RockVisuals> reactions,
  @Resource() FrameTime time,
  Commands commands,
) {
  final dt = time.delta;
  reactions.each((entity, reaction, visuals) {
    reaction.remaining -= dt;
    final shell = visuals.shell;
    if (reaction.remaining <= 0) {
      _setShellScale(shell, 0);
      commands.remove<RockHitReaction>(entity);
      return;
    }
    final t = (1 - reaction.remaining / rockHitReactionDuration).clamp(0.0, 1.0);
    final env = math.sin(t * math.pi);
    final pulse = 1 + 0.1 * math.sin(t * math.pi * 4);
    final peak = 1.15 + 0.55 * reaction.strength;
    _setShellScale(shell, peak * env * pulse);
  });
}

// Mutates in place and re-assigns to trip the node's dirty flag — no allocation.
void _setShellScale(Node shell, double scale) {
  final m = shell.localTransform
    ..setIdentity()
    ..scaleByDouble(scale, scale, scale, 1);
  shell.localTransform = m;
}

@System()
void spawnRockTrails(@Resource() Scene scene, @Resource() RockTrails trails) {
  trails.pool = buildFlamePool()..addTo(scene);
}

/// Lays each flaming rock's trail puffs into the shared instanced pool by
/// enumeration order, then hides the slots freed by despawned rocks. Rocks roll
/// down +Z, so the puffs trail a fixed distance behind in -Z (no per-rock state).
@System()
void updateRockTrails(
  @Query(requires: [Rock, Flaming]) Query1<SceneNodeRef> rocks,
  @Resource() RockTrails trails,
) {
  final pool = trails.pool;
  if (pool == null) return;
  final scratch = pool.scratch;
  var slot = 0;

  rocks.each((entity, binding) {
    if (slot + _puffsPerRock > pool.capacity) return; // pool full
    final m = binding.node.globalTransform;
    for (var i = 0; i < _puffsPerRock; i++) {
      final size = rockRadius * (0.34 - i * 0.07);
      scratch
        ..setIdentity()
        ..setTranslationRaw(
          m[12],
          m[13] + rockRadius * (0.12 + 0.08 * i),
          m[14] - rockRadius * 0.55 * (i + 1),
        )
        ..scaleByDouble(size, size, size, 1);
      pool.mesh.setInstanceTransform(slot, scratch);
      slot++;
    }
  });

  // Hide instances that belonged to rocks which despawned since last frame.
  for (var i = slot; i < trails.activeCount; i++) {
    pool.hide(i);
  }
  trails.activeCount = slot;
}
