part of 'rocks.dart';

/// Fixed step: drop new rocks at the top while the game is running.
@System()
final class SpawnRocksSystem extends GameSystem {
  const SpawnRocksSystem();

  void run(
    Commands commands,
    @Resource() RockSpawner spawner,
    @Resource() GameState game,
    @Resource() FixedTime time,
  ) {
    if (game.status != GameStatus.playing) return;
    final due = spawner.tick(time.delta, survived: game.survived);
    for (var i = 0; i < due; i++) {
      commands.spawn(
        RockBundle(
          x: spawner.nextLane(),
          flaming: spawner.nextIsFlaming(game.survived),
        ),
      );
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
      // The integration mounts bound nodes before the update phase, so a queried
      // rock is already in the scene - no parent guard needed.
      if (binding.node.globalTransform.getTranslation().y < rockKillY) {
        commands.despawn(entity);
      }
    });
  }
}
