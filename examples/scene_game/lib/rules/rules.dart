import 'package:flutter_scene/scene.dart';
import 'package:flutter_scene_rapier/flutter_scene_rapier.dart';
import 'package:scene_dash/scene_dash.dart';
import 'package:scene_dash_flutter_scene/scene_dash_flutter_scene.dart';
import 'package:vector_math/vector_math.dart' show Matrix4, Ray, Vector3;

import '../game/config.dart';
import '../game/game_state.dart';
import '../game/view_state.dart';
import '../player/player.dart';
import '../rocks/rocks.dart';

part 'rules.g.dart';

/// Evaluates the two lose conditions each frame.
///
/// Fell off: a downward raycast finds no fixed platform within
/// [groundProbeDistance]. Hit by a rock: any rock is within the combined radii
/// of the player.
@System()
final class GameRulesSystem extends GameSystem with _$GameRulesSystem {
  const GameRulesSystem();

  void run(
    @Query(requires: [Player]) Query1<SceneNodeRef> players,
    @Query(requires: [Rock]) Query1<SceneNodeRef> rocks,
    @Resource() PhysicsWorld world,
    @Resource() GameState game,
    @Resource() FrameTime time,
    @Resource() ImpactMotion impact,
  ) {
    if (game.status != GameStatus.playing) return;
    game.addSurvival(time.delta);

    Node? playerNode;
    Vector3? playerPos;
    players.each((entity, binding) {
      if (binding.node.parent == null) return;
      playerNode = binding.node;
      playerPos = binding.node.globalTransform.getTranslation();
    });
    final node = playerNode;
    final pos = playerPos;
    if (node == null || pos == null) return;

    if (game.survived > startupGrace) {
      final ground = world.raycast(
        Ray.originDirection(pos, Vector3(0, -1, 0)),
        maxDistance: groundProbeDistance,
        includeFixed: true,
        includeKinematic: false,
        includeDynamic: false,
      );
      if (ground == null) {
        game.lose('You fell off the platform');
        return;
      }
    }

    final rockNodes = <Node>{};
    rocks.each((entity, binding) {
      if (binding.node.parent == null) return;
      rockNodes.add(binding.node);
    });

    final hits = world.overlapSphere(
      pos,
      playerRadius + hitPadding,
      includeFixed: false,
      includeKinematic: false,
      includeDynamic: true,
      includeTriggers: false,
    );
    for (final hit in hits) {
      if (rockNodes.contains(hit.node)) {
        _startImpact(
          node,
          pos,
          hit.node.globalTransform.getTranslation(),
          impact,
        );
        game.lose('A rock got you');
        return;
      }
    }
  }

  void _startImpact(
    Node player,
    Vector3 playerPos,
    Vector3 rockPos,
    ImpactMotion impact,
  ) {
    final body = player.getComponent<RapierRigidBody>();
    if (body != null) {
      body
        ..type = BodyType.kinematic
        ..linearVelocity = Vector3.zero()
        ..angularVelocity = Vector3.zero();
    }
    impact.start(playerPosition: playerPos, rockPosition: rockPos);
  }
}

/// Keeps camera state current and runs the visible post-hit tumble.
@System()
final class PlayerViewSystem extends GameSystem with _$PlayerViewSystem {
  const PlayerViewSystem();

  void run(
    @Query(requires: [Player]) Query1<SceneNodeRef> players,
    @Resource() CameraRig camera,
    @Resource() ImpactMotion impact,
    @Resource() FrameTime time,
  ) {
    Node? player;
    Vector3? position;
    players.each((entity, binding) {
      if (binding.node.parent == null) return;
      player = binding.node;
      position = binding.node.globalTransform.getTranslation();
    });
    final node = player;
    final pos = position;
    if (node == null || pos == null) return;

    if (impact.active) {
      impact.advance(time.delta);
      node.localTransform = impact.transform();
      camera.follow(impact.position, time.delta);
      return;
    }

    camera.follow(pos, time.delta);
  }
}

/// Restarts after a loss by clearing rocks and restoring the player body.
@System()
final class RestartSystem extends GameSystem with _$RestartSystem {
  const RestartSystem();

  void run(
    @Query(requires: [Player]) Query1<SceneNodeRef> players,
    @Query(requires: [Rock]) Query1<SceneNodeRef> rocks,
    @Resource() InputState input,
    @Resource() GameState game,
    @Resource() RockSpawner spawner,
    @Resource() CameraRig camera,
    @Resource() ImpactMotion impact,
    Commands commands,
  ) {
    if (!input.restartRequested) return;
    input.restartRequested = false;
    if (game.status != GameStatus.lost) return;

    rocks.each((entity, binding) => commands.despawn(entity));
    players.each((entity, binding) {
      final body = binding.node.getComponent<RapierRigidBody>();
      if (body != null) {
        body
          ..type = BodyType.kinematic
          ..linearVelocity = Vector3.zero()
          ..angularVelocity = Vector3.zero();
      }
      binding.node.localTransform = Matrix4.translation(
        Vector3(0, playerStartY, playerStartZ),
      );
    });
    camera.reset();
    impact.reset();
    spawner.reset();
    game.reset();
  }
}

/// Installs the rules and restart systems. [GameState] is shared with the HUD.
@GamePlugin()
final class RulesPlugin extends Plugin {
  const RulesPlugin();

  @override
  void build(AppBuilder app) {
    app
      ..addSystem(
        const RestartSystem(),
        schedule: Schedules.frameStart,
        label: const SystemLabel('rules.restart'),
      )
      ..addSystem(
        const GameRulesSystem(),
        schedule: Schedules.update,
        label: const SystemLabel('rules.evaluate'),
      )
      ..addSystem(
        const PlayerViewSystem(),
        schedule: Schedules.update,
        label: const SystemLabel('rules.playerView'),
      );
  }
}
