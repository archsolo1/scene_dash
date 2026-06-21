import 'package:flutter_scene/scene.dart';
import 'package:flutter_scene_rapier/flutter_scene_rapier.dart';
import 'package:scene_dash/scene_dash.dart';
import 'package:scene_dash_flutter_scene/scene_dash_flutter_scene.dart';
import 'package:vector_math/vector_math.dart' show Matrix4, Vector3, Vector4;

import '../game/config.dart';
import '../game/game_state.dart';

part 'player.g.dart';

/// Tags the single player entity.
@Tag()
final class Player {
  const Player();
}

/// The player: a kinematic sphere driven by Rapier's character controller.
///
/// The node carries everything physics needs, and [PhysicsDriven] tells the
/// integration's generic transform sync to leave it alone. The controller owns
/// the transform while playing; after a hit, rules temporarily switch the body
/// to dynamic so the player can tumble.
@Bundle()
final class PlayerBundle with _$PlayerBundle {
  final Player player;
  final SceneNodeRef node;
  final PhysicsDriven physics;

  PlayerBundle()
    : player = const Player(),
      node = SceneNodeRef(_makeNode()),
      physics = const PhysicsDriven();

  static Node _makeNode() {
    final playerMaterial = PhysicallyBasedMaterial()
      ..baseColorFactor = Vector4(0.08, 0.58, 0.95, 1)
      ..metallicFactor = 0.05
      ..roughnessFactor = 0.32
      ..emissiveFactor = Vector4(0.0, 0.08, 0.16, 1);
    final markerMaterial = PhysicallyBasedMaterial()
      ..baseColorFactor = Vector4(1, 1, 1, 1)
      ..metallicFactor = 0
      ..roughnessFactor = 0.45
      ..emissiveFactor = Vector4(0.18, 0.18, 0.18, 1);

    return Node(
        mesh: Mesh(SphereGeometry(radius: playerRadius), playerMaterial),
        localTransform: Matrix4.translation(
          Vector3(0, playerStartY, playerStartZ),
        ),
      )
      ..add(
        Node(
          mesh: Mesh(
            CuboidGeometry(Vector3(0.18, 0.18, playerRadius * 1.6)),
            markerMaterial,
          ),
          localTransform: Matrix4.translation(Vector3(0, playerRadius, 0)),
        ),
      )
      ..addComponent(RapierRigidBody(type: BodyType.kinematic))
      ..addComponent(RapierCollider(shape: SphereShape(radius: playerRadius)))
      ..addComponent(
        RapierKinematicCharacterController(
          up: Vector3(0, 1, 0),
          slide: true,
          snapToGround: 0.5,
          autostep: true,
        ),
      );
  }
}

/// Startup: spawn the one player.
@System()
final class SpawnPlayerSystem extends GameSystem with _$SpawnPlayerSystem {
  const SpawnPlayerSystem();

  void run(Commands commands) {
    commands.spawn(PlayerBundle());
  }
}

/// Fixed step: translate input into a move-and-slide request.
///
/// The controller has no gravity of its own, so a constant downward bias keeps
/// the player on the slope and makes it fall once it walks off an edge.
@System()
final class MovePlayerSystem extends GameSystem with _$MovePlayerSystem {
  const MovePlayerSystem();

  void run(
    @Query(requires: [Player]) Query1<SceneNodeRef> players,
    @Resource() InputState input,
    @Resource() GameState game,
    @Resource() FixedTime time,
  ) {
    if (game.status != GameStatus.playing) return;
    players.each((entity, binding) {
      final node = binding.node;
      // Skip until the node is mounted under the RapierWorld.
      if (node.parent == null) return;
      final controller = node
          .getComponent<RapierKinematicCharacterController>();
      if (controller == null) return;

      final dt = time.delta;
      controller.move(
        Vector3(
          input.horizontal * playerStrafeSpeed * dt,
          -playerStickSpeed * dt,
          0,
        ),
      );
    });
  }
}

/// Installs the player feature.
@GamePlugin()
final class PlayerPlugin extends Plugin {
  const PlayerPlugin();

  @override
  void build(AppBuilder app) {
    app
      ..addSystem(
        const SpawnPlayerSystem(),
        schedule: Schedules.startup,
        label: const SystemLabel('player.spawn'),
      )
      ..addSystem(
        const MovePlayerSystem(),
        schedule: Schedules.fixedPrePhysics,
        label: const SystemLabel('player.move'),
      );
  }
}
