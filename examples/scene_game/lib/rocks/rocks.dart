import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';
import 'package:flutter_scene_rapier/flutter_scene_rapier.dart';
import 'package:scene_dash/scene_dash.dart';
import 'package:scene_dash_flutter_scene/scene_dash_flutter_scene.dart';
import 'package:vector_math/vector_math.dart' show Matrix4, Vector3, Vector4;

import '../game/config.dart';
import '../game/game_state.dart';

part 'rocks.g.dart';

/// Tags a rolling rock entity.
@Tag()
final class Rock {
  const Rock();
}

/// Spawn cadence plus RNG, injected as a resource.
final class RockSpawner {
  final math.Random random;
  double _accumulator = 0;

  RockSpawner({int? seed}) : random = math.Random(seed);

  /// Advances the timer; returns the number of rocks due this step.
  int tick(double dt) {
    _accumulator += dt;
    var due = 0;
    while (_accumulator >= rockSpawnInterval) {
      _accumulator -= rockSpawnInterval;
      due++;
    }
    return due;
  }

  /// A random X within the ramp's spawn band.
  double nextLane() => (random.nextDouble() * 2 - 1) * rockSpawnHalfWidth;

  void reset() => _accumulator = 0;
}

/// A dynamic rock. Rapier owns its node transform, hence [PhysicsDriven].
@Bundle()
final class RockBundle with _$RockBundle {
  final Rock rock;
  final SceneNodeRef node;
  final PhysicsDriven physics;

  RockBundle({required double x})
    : rock = const Rock(),
      node = SceneNodeRef(_makeNode(x)),
      physics = const PhysicsDriven();

  static final Material _material = PhysicallyBasedMaterial()
    ..baseColorFactor = Vector4(0.46, 0.25, 0.18, 1)
    ..metallicFactor = 0
    ..roughnessFactor = 0.92;

  static Node _makeNode(double x) {
    return Node(
        mesh: Mesh(SphereGeometry(radius: rockRadius), _material),
        localTransform: Matrix4.translation(Vector3(x, rockSpawnY, rockSpawnZ)),
      )
      ..addComponent(RapierRigidBody(type: BodyType.dynamic_, ccdEnabled: true))
      ..addComponent(RapierCollider(shape: SphereShape(radius: rockRadius)));
  }
}

/// Fixed step: drop new rocks at the top while the game is running.
@System()
final class SpawnRocksSystem extends GameSystem with _$SpawnRocksSystem {
  const SpawnRocksSystem();

  void run(
    Commands commands,
    @Resource() RockSpawner spawner,
    @Resource() GameState game,
    @Resource() FixedTime time,
  ) {
    if (game.status != GameStatus.playing) return;
    final due = spawner.tick(time.delta);
    for (var i = 0; i < due; i++) {
      commands.spawn(RockBundle(x: spawner.nextLane()));
    }
  }
}

/// Despawns rocks that have rolled off the bottom into the void.
@System()
final class CleanupRocksSystem extends GameSystem with _$CleanupRocksSystem {
  const CleanupRocksSystem();

  void run(
    @Query(requires: [Rock]) Query1<SceneNodeRef> rocks,
    Commands commands,
  ) {
    rocks.each((entity, binding) {
      final node = binding.node;
      if (node.parent == null) return;
      if (node.globalTransform.getTranslation().y < rockKillY) {
        commands.despawn(entity);
      }
    });
  }
}

/// Installs the rocks feature and its spawner resource.
@GamePlugin()
final class RocksPlugin extends Plugin {
  const RocksPlugin();

  @override
  void build(AppBuilder app) {
    app
      ..insertResource<RockSpawner>(RockSpawner())
      ..addSystem(
        const SpawnRocksSystem(),
        schedule: Schedules.fixedPrePhysics,
        label: const SystemLabel('rocks.spawn'),
      )
      ..addSystem(
        const CleanupRocksSystem(),
        schedule: Schedules.update,
        label: const SystemLabel('rocks.cleanup'),
      );
  }
}
