// Hide Flutter's 64-bit Matrix4 so it does not clash with flutter_scene's
// 32-bit vector_math Matrix4 used by InstancedMesh / Node transforms.
import 'package:flutter/material.dart' hide Matrix4;
import 'package:flutter/scheduler.dart';
import 'package:flutter_scene/scene.dart';
import 'package:scene_dash/scene_dash.dart';
import 'package:scene_dash_flutter_scene/scene_dash_flutter_scene.dart';
import 'package:vector_math/vector_math.dart' show Matrix4, Quaternion, Vector3;

part 'main.g.dart';

// Workload: a [gridSize] x [gridSize] grid of entity-bound cubes. Only
// `spinFraction` of them animate, but the integration syncs *every* bound node each
// frame (writes its transform + marks it dirty). If full-frame sync were a
// bottleneck, build time would scale with the cube count and changed-only sync
// would matter. The reporter below shows whether it does.
const gridSize = 40; // 40 x 40 = 1600 cubes
const spinFraction = 0.1; // 10% animate; 90% are static

/// Control switch (`--dart-define=useEcs=false`): when false the same grid is
/// added as **static scene nodes with no ECS binding or per-frame sync**, to
/// isolate flutter_scene's own per-node cost from the integration's sync.
const useEcs = bool.fromEnvironment('useEcs', defaultValue: true);

/// Rendering switch (`--dart-define=instanced=true`): render the whole grid as a
/// single `InstancedMesh` instead of one node per cube. This is a pure
/// flutter_scene + ECS pattern — the integration is not involved and needs no
/// changes. (0.18.x note: the instanced backend is still "naive", so it does not
/// yet cut draw calls; this exists to demonstrate the pattern and to re-measure
/// once flutter_scene optimizes it.)
const instanced = bool.fromEnvironment('instanced', defaultValue: false);

/// One shared cube mesh for every node (created after static resources init).
final Mesh _cubeMesh = Mesh(CuboidGeometry(Vector3.all(0.5)), UnlitMaterial());

@ObjectComponent()
final class Spin {
  final double speed;
  double angle;
  Spin(this.speed) : angle = 0;
}

@Bundle()
final class CubeBundle with _$CubeBundle {
  final SceneTransform transform;
  final SceneNodeRef node;

  CubeBundle({required Vector3 position})
      : transform = SceneTransform.fromVector(position),
        node = SceneNodeRef(Node(mesh: _cubeMesh));
}

/// Static control: add the same grid directly to the scene, no ECS, no sync.
void _spawnStaticNodes(Scene scene) {
  const spacing = 1.2;
  const half = gridSize * spacing / 2;
  for (var gx = 0; gx < gridSize; gx++) {
    for (var gz = 0; gz < gridSize; gz++) {
      final node = Node(mesh: _cubeMesh)
        ..localTransform
            .setTranslationRaw(gx * spacing - half, 0, gz * spacing - half);
      scene.add(node);
    }
  }
}

// --- Instanced rendering: one InstancedMesh for the whole grid ---
//
// Pure flutter_scene + ECS, with no integration involvement: the mesh is a resource,
// each entity owns one instance slot, and a system writes the instances it
// animates directly via the flutter_scene API. No `SceneNodeRef`, no sync.

final class CubeInstances {
  final InstancedMesh mesh;
  const CubeInstances(this.mesh);
}

@ObjectComponent()
final class Instance {
  final int index;
  final Vector3 base;
  Instance(this.index, this.base);
}

@System()
final class SpawnInstancesSystem extends GameSystem
    with _$SpawnInstancesSystem {
  const SpawnInstancesSystem();

  void run(Commands commands, @Resource() CubeInstances cubes) {
    const spacing = 1.2;
    const half = gridSize * spacing / 2;
    final placement = Matrix4.identity();
    var i = 0;
    for (var gx = 0; gx < gridSize; gx++) {
      for (var gz = 0; gz < gridSize; gz++) {
        final base = Vector3(gx * spacing - half, 0, gz * spacing - half);
        placement.setTranslationRaw(base.x, base.y, base.z);
        final index = cubes.mesh.addInstance(placement);
        final entity = commands.spawn();
        commands.insert<Instance>(entity, Instance(index, base));
        if (i % (1 ~/ spinFraction) == 0) {
          commands.insert<Spin>(entity, Spin(0.5 + (i % 5) * 0.3));
        }
        i++;
      }
    }
  }
}

// Reused scratch (single-threaded) so the per-instance update never allocates.
final _instanceMatrix = Matrix4.identity();
final _instanceRotation = Quaternion.identity();
final _yAxis = Vector3(0, 1, 0);

@System()
final class MoveInstancesSystem extends GameSystem with _$MoveInstancesSystem {
  const MoveInstancesSystem();

  void run(
    @Query(writes: [Spin]) Query2<Instance, Spin> spinners,
    @Resource() CubeInstances cubes,
    @Resource() FrameTime time,
  ) {
    spinners.each((entity, instance, spin) {
      spin.angle += spin.speed * time.delta;
      _instanceRotation.setAxisAngle(_yAxis, spin.angle);
      _instanceMatrix.setFromTranslationRotation(
          instance.base, _instanceRotation);
      cubes.mesh.setInstanceTransform(instance.index, _instanceMatrix);
    });
  }
}

@GamePlugin()
final class InstancedPlugin extends Plugin {
  const InstancedPlugin();

  @override
  void build(AppBuilder app) {
    app
      ..addSystem(
        const SpawnInstancesSystem(),
        schedule: Schedules.startup,
        label: const SystemLabel('inst.spawn'),
      )
      ..addSystem(
        const MoveInstancesSystem(),
        schedule: Schedules.update,
        label: const SystemLabel('inst.move'),
      );
  }
}

@System()
final class SpawnGridSystem extends GameSystem with _$SpawnGridSystem {
  const SpawnGridSystem();

  void run(Commands commands) {
    const spacing = 1.2;
    const half = gridSize * spacing / 2;
    var i = 0;
    for (var gx = 0; gx < gridSize; gx++) {
      for (var gz = 0; gz < gridSize; gz++) {
        final position = Vector3(gx * spacing - half, 0, gz * spacing - half);
        final entity = commands.spawn(CubeBundle(position: position));
        // Deterministically animate every Nth cube.
        if (i % (1 ~/ spinFraction) == 0) {
          commands.insert<Spin>(entity, Spin(0.5 + (i % 5) * 0.3));
        }
        i++;
      }
    }
  }
}

@System()
final class SpinSystem extends GameSystem with _$SpinSystem {
  const SpinSystem();

  void run(
    @Query(writes: [SceneTransform, Spin])
    Query2<SceneTransform, Spin> spinners,
    @Resource() FrameTime time,
  ) {
    spinners.each((entity, transform, spin) {
      spin.angle += spin.speed * time.delta;
      transform.rotation.setAxisAngle(Vector3(0, 1, 0), spin.angle);
    });
  }
}

@GamePlugin()
final class BenchmarkPlugin extends Plugin {
  const BenchmarkPlugin();

  @override
  void build(AppBuilder app) {
    app
      ..addSystem(
        const SpawnGridSystem(),
        schedule: Schedules.startup,
        label: const SystemLabel('bench.spawn'),
      )
      ..addSystem(
        const SpinSystem(),
        schedule: Schedules.update,
        label: const SystemLabel('bench.spin'),
      );
  }
}

// --- Frame-timing reporter ---

final _build = <int>[];
final _raster = <int>[];

void _onTimings(List<FrameTiming> timings) {
  for (final t in timings) {
    _build.add(t.buildDuration.inMicroseconds);
    _raster.add(t.rasterDuration.inMicroseconds);
  }
  if (_build.length < 120) return;
  String stats(List<int> us) {
    final sorted = [...us]..sort();
    final avg = sorted.reduce((a, b) => a + b) / sorted.length / 1000;
    final p90 = sorted[(sorted.length * 0.9).floor()] / 1000;
    return 'avg=${avg.toStringAsFixed(2)}ms p90=${p90.toStringAsFixed(2)}ms';
  }

  debugPrint(
    'SCENEBENCH mode=${instanced ? "instanced" : useEcs ? "ECS+sync" : "static"} '
    'cubes=${gridSize * gridSize} '
    'build(UI) ${stats(_build)} | raster(GPU) ${stats(_raster)}',
  );
  _build.clear();
  _raster.clear();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Scene.initializeStaticResources();

  final scene = Scene();
  final game = Game(scene: scene);
  if (instanced) {
    final mesh = InstancedMesh(
      geometry: CuboidGeometry(Vector3.all(0.5)),
      material: UnlitMaterial(),
    );
    scene.add(Node()..addComponent(InstancedMeshComponent(mesh)));
    game.world.resources.insert<CubeInstances>(CubeInstances(mesh));
    game.addPlugin(const InstancedPlugin());
  } else if (useEcs) {
    game.addPlugin(const BenchmarkPlugin());
  } else {
    _spawnStaticNodes(scene);
  }
  await game.start();

  SchedulerBinding.instance.addTimingsCallback(_onTimings);

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SceneView(
          scene,
          cameraBuilder: _camera,
          onTick: game.onTick,
        ),
      ),
    ),
  );
}

Camera _camera(Duration elapsed) {
  return PerspectiveCamera(
    position: Vector3(0, 35, -45),
    target: Vector3(0, 0, 0),
  );
}
