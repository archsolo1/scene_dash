import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_scene/scene.dart';
import 'package:scene_dash/scene_dash.dart';
import 'package:scene_dash_flutter_scene/scene_dash_flutter_scene.dart';
import 'package:vector_math/vector_math.dart' show Vector3;

part 'main.g.dart';

// --- Components ---
//
// Position, rotation and scale use the bridge's standard `SceneTransform`,
// which `Game` writes onto each bound node automatically.

@ObjectComponent()
final class Orbit {
  final double radius;
  final double speed;
  double phase;
  Orbit({required this.radius, required this.speed, required this.phase});
}

// --- Bundle: the complete definition of one cube ---

const _ringSize = 8;

@Bundle()
final class CubeBundle with _$CubeBundle {
  // Procedural, immutable cube geometry — created once and shared by every
  // cube. Sharing is an optimization the bundle owns, not caller ceremony.
  static final Mesh _mesh =
      Mesh(CuboidGeometry(Vector3.all(0.8)), UnlitMaterial());

  final SceneTransform transform;
  final Orbit orbit;
  final SceneNodeRef node;

  /// One self-contained world object: gameplay state + transform + visual node.
  /// The bridge mounts the node into the scene automatically.
  CubeBundle({required double phase})
      : transform = SceneTransform.zero(),
        orbit = Orbit(radius: 3, speed: 1, phase: phase),
        node = SceneNodeRef(Node(mesh: _mesh));
}

// --- Systems ---

/// Startup system: spawns a ring of cubes. Each [CubeBundle] fully defines its
/// own entity (state + node + mesh), so this is just `commands.spawn(...)`.
@System()
final class SpawnCubesSystem extends GameSystem with _$SpawnCubesSystem {
  const SpawnCubesSystem();

  void run(Commands commands) {
    for (var i = 0; i < _ringSize; i++) {
      commands.spawn(CubeBundle(phase: i / _ringSize * 2 * pi));
    }
  }
}

/// Per-frame system: advances each orbit and writes the position into
/// [SceneTransform]. Runs in [Schedules.update] (works without a physics world).
@System()
final class OrbitSystem extends GameSystem with _$OrbitSystem {
  const OrbitSystem();

  void run(
    @Query(writes: [SceneTransform, Orbit])
    Query2<SceneTransform, Orbit> movers,
    @Resource() FrameTime time,
  ) {
    movers.each((entity, transform, orbit) {
      orbit.phase += orbit.speed * time.delta;
      transform
        ..x = orbit.radius * cos(orbit.phase)
        ..z = orbit.radius * sin(orbit.phase);
    });
  }
}

// --- World plugin: scene-wide settings ---
//
// Scene-wide configuration (skybox, environment, lighting, ...) belongs to a
// world/level plugin, not a bundle — there is one per scene, not one per
// entity. The bridge exposes the real flutter_scene `Scene` as a resource, so
// this uses the full flutter_scene API directly with no bridge wrapper.

@System()
final class SetupWorldSystem extends GameSystem with _$SetupWorldSystem {
  const SetupWorldSystem();

  void run(@Resource() Scene scene) {
    scene.skybox = Skybox(GradientSkySource());
  }
}

@GamePlugin()
final class WorldPlugin extends Plugin {
  const WorldPlugin();

  @override
  void build(AppBuilder app) {
    app.addSystem(
      const SetupWorldSystem(),
      schedule: Schedules.startup,
      label: const SystemLabel('world.setup'),
    );
  }
}

// --- Demo plugin ---

@GamePlugin()
final class DemoPlugin extends Plugin {
  const DemoPlugin();

  @override
  void build(AppBuilder app) {
    app
      ..addSystem(
        const SpawnCubesSystem(),
        schedule: Schedules.startup,
        label: const SystemLabel('demo.spawn'),
      )
      ..addSystem(
        const OrbitSystem(),
        schedule: Schedules.update,
        label: const SystemLabel('demo.orbit'),
      );
  }
}

// --- App entry point ---

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Scene.initializeStaticResources();

  final scene = Scene();
  final game = Game(scene: scene)
    ..addPlugin(const WorldPlugin())
    ..addPlugin(const DemoPlugin());
  await game.start();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SceneView(
          scene,
          cameraBuilder: _buildCamera,
          onTick: game.onTick,
        ),
      ),
    ),
  );
}

Camera _buildCamera(Duration elapsed) {
  return PerspectiveCamera(
    position: Vector3(0, 4, -8),
    target: Vector3(0, 0, 0),
  );
}
