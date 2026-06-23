import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_scene/scene.dart';
import 'package:scene_dash/scene_dash.dart';
import 'package:scene_dash_flutter_scene/scene_dash_flutter_scene.dart';
import 'package:vector_math/vector_math.dart' as vm;

// Benchmark output is intentionally printed for `flutter run`/adb capture.
// ignore_for_file: avoid_print

const String _mode = String.fromEnvironment(
  'benchmarkMode',
  defaultValue: 'ecs',
);
const int _gridSide = int.fromEnvironment('gridSide', defaultValue: 40);
const int _warmupFrames = int.fromEnvironment('warmupFrames', defaultValue: 90);
const int _sampleFrames = int.fromEnvironment(
  'sampleFrames',
  defaultValue: 240,
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Scene.initializeStaticResources();

  final benchmark = await SceneBenchmark.create(
    mode: BenchmarkMode.parse(_mode),
    gridSide: _gridSide,
  );
  runApp(SceneBenchmarkApp(benchmark: benchmark));
}

enum BenchmarkMode {
  staticNodes('static'),
  ecs('ecs'),
  instanced('instanced');

  const BenchmarkMode(this.id);
  final String id;

  static BenchmarkMode parse(String value) {
    for (final mode in values) {
      if (mode.id == value) return mode;
    }
    throw ArgumentError.value(
      value,
      'benchmarkMode',
      'Expected static, ecs, or instanced.',
    );
  }
}

final class SceneBenchmark {
  SceneBenchmark._({
    required this.mode,
    required this.gridSide,
    required this.scene,
    required this.camera,
    this.game,
    this.instancedMesh,
  });

  final BenchmarkMode mode;
  final int gridSide;
  final Scene scene;
  final PerspectiveCamera camera;
  final Game? game;
  final InstancedMesh? instancedMesh;
  double _elapsed = 0;

  int get visibleCount => gridSide * gridSide;

  static Future<SceneBenchmark> create({
    required BenchmarkMode mode,
    required int gridSide,
  }) async {
    final scene = Scene()..directionalLight = DirectionalLight(intensity: 2.0);
    final camera = PerspectiveCamera(
      position: vm.Vector3(0, gridSide * 0.72, gridSide * 1.35),
      target: vm.Vector3.zero(),
      fovRadiansY: 42 * vm.degrees2Radians,
      fovFar: 1000,
    );
    final mesh = _cubeMesh();

    switch (mode) {
      case BenchmarkMode.staticNodes:
        _addStaticNodes(scene, mesh, gridSide);
        return SceneBenchmark._(
          mode: mode,
          gridSide: gridSide,
          scene: scene,
          camera: camera,
        );
      case BenchmarkMode.ecs:
        final game =
            Game(
                scene: scene,
                diagnostics: const AppDiagnostics(profileSystems: true),
              )
              ..app.addSystemAdapter(
                _SpawnGridAdapter(mesh, gridSide),
                schedule: Schedules.startup,
                label: const SystemLabel('benchmark.spawnGrid'),
              );
        await game.start();
        return SceneBenchmark._(
          mode: mode,
          gridSide: gridSide,
          scene: scene,
          camera: camera,
          game: game,
        );
      case BenchmarkMode.instanced:
        final instanced = InstancedMesh(
          geometry: mesh.primitives.single.geometry,
          material: mesh.primitives.single.material,
        );
        for (var i = 0; i < gridSide * gridSide; i++) {
          instanced.addInstance(_gridMatrix(i, gridSide, 0));
        }
        scene.root.add(Node()..addComponent(InstancedMeshComponent(instanced)));
        return SceneBenchmark._(
          mode: mode,
          gridSide: gridSide,
          scene: scene,
          camera: camera,
          instancedMesh: instanced,
        );
    }
  }

  void tick(Duration elapsed, double deltaSeconds) {
    _elapsed = elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    game?.onTick(elapsed, deltaSeconds);

    final instanced = instancedMesh;
    if (instanced != null) {
      final animated = math.max(1, visibleCount ~/ 10);
      for (var i = 0; i < animated; i++) {
        instanced.setInstanceTransform(i, _gridMatrix(i, gridSide, _elapsed));
      }
    }
  }

  Future<void> dispose() async {
    await game?.shutdown();
  }
}

class SceneBenchmarkApp extends StatefulWidget {
  const SceneBenchmarkApp({super.key, required this.benchmark});

  final SceneBenchmark benchmark;

  @override
  State<SceneBenchmarkApp> createState() => _SceneBenchmarkAppState();
}

class _SceneBenchmarkAppState extends State<SceneBenchmarkApp> {
  final List<FrameTiming> _samples = <FrameTiming>[];
  late final TimingsCallback _timingsCallback;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _timingsCallback = _onTimings;
    SchedulerBinding.instance.addTimingsCallback(_timingsCallback);
    _printConfig();
  }

  @override
  void dispose() {
    SchedulerBinding.instance.removeTimingsCallback(_timingsCallback);
    unawaited(widget.benchmark.dispose());
    super.dispose();
  }

  void _onTimings(List<FrameTiming> timings) {
    if (_finished) return;
    for (final timing in timings) {
      if (_samples.length < _warmupFrames) {
        _samples.add(timing);
        continue;
      }
      _samples.add(timing);
      if (_samples.length >= _warmupFrames + _sampleFrames) {
        _finished = true;
        _printSummary();
        unawaited(widget.benchmark.dispose().then((_) => exit(0)));
        return;
      }
    }
  }

  void _printConfig() {
    final benchmark = widget.benchmark;
    print(
      'SCENE_BENCHMARK config '
      'mode=${benchmark.mode.id} '
      'gridSide=${benchmark.gridSide} '
      'visible=${benchmark.visibleCount} '
      'warmupFrames=$_warmupFrames '
      'sampleFrames=$_sampleFrames',
    );
  }

  void _printSummary() {
    final measured = _samples.skip(_warmupFrames).toList(growable: false);
    final builds =
        measured
            .map((t) => t.buildDuration.inMicroseconds / 1000)
            .toList(growable: false)
          ..sort();
    final rasters =
        measured
            .map((t) => t.rasterDuration.inMicroseconds / 1000)
            .toList(growable: false)
          ..sort();

    print(
      'SCENE_BENCHMARK result '
      'mode=${widget.benchmark.mode.id} '
      'frames=${measured.length} '
      'build_median_ms=${_percentile(builds, 0.50).toStringAsFixed(3)} '
      'build_p95_ms=${_percentile(builds, 0.95).toStringAsFixed(3)} '
      'raster_median_ms=${_percentile(rasters, 0.50).toStringAsFixed(3)} '
      'raster_p95_ms=${_percentile(rasters, 0.95).toStringAsFixed(3)}',
    );

    final profiler = widget.benchmark.game?.profiler;
    if (profiler != null) {
      for (final timing in profiler.timings) {
        print(
          'SCENE_BENCHMARK system '
          'mode=${widget.benchmark.mode.id} '
          'schedule=${timing.schedule.id} '
          'system=${timing.label.id} '
          'runs=${timing.runs} '
          'latest_us=${timing.latestMicros} '
          'avg_us=${(timing.totalMicros / timing.runs).toStringAsFixed(3)} '
          'max_us=${timing.maxMicros}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final benchmark = widget.benchmark;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ColoredBox(
        color: Colors.black,
        child: SceneView(
          benchmark.scene,
          camera: benchmark.camera,
          onTick: benchmark.tick,
        ),
      ),
    );
  }
}

final class _SpawnGridAdapter implements SystemAdapter {
  _SpawnGridAdapter(this.mesh, this.gridSide);

  final Mesh mesh;
  final int gridSide;
  late World _world;

  @override
  void initialize(World world) {
    _world = world;
  }

  @override
  void run() {
    for (var i = 0; i < gridSide * gridSide; i++) {
      _world.commands.spawn(_CubeBundle(mesh, i, gridSide));
    }
  }
}

final class _CubeBundle implements SceneDashBundle {
  const _CubeBundle(this.mesh, this.index, this.gridSide);

  final Mesh mesh;
  final int index;
  final int gridSide;

  @override
  void insertInto(World world, Entity entity) {
    final matrix = _gridMatrix(index, gridSide, 0);
    world
      ..ensureObjectStore<SceneTransform>()
      ..ensureObjectStore<SceneNodeRef>()
      ..insertNow<SceneTransform>(
        entity,
        SceneTransform.trs(
          translation: matrix.getTranslation(),
          scale: vm.Vector3.all(1),
        ),
      )
      ..insertNow<SceneNodeRef>(entity, SceneNodeRef(Node(mesh: mesh)));
  }
}

Mesh _cubeMesh() {
  final material = UnlitMaterial()
    ..baseColorFactor = vm.Vector4(0.25, 0.85, 1.0, 1.0);
  return Mesh(CuboidGeometry(vm.Vector3.all(0.48)), material);
}

void _addStaticNodes(Scene scene, Mesh mesh, int gridSide) {
  for (var i = 0; i < gridSide * gridSide; i++) {
    scene.root.add(
      Node(mesh: mesh, localTransform: _gridMatrix(i, gridSide, 0)),
    );
  }
}

vm.Matrix4 _gridMatrix(int index, int gridSide, double elapsed) {
  final x = (index % gridSide) - (gridSide - 1) * 0.5;
  final z = (index ~/ gridSide) - (gridSide - 1) * 0.5;
  final animated = index < math.max(1, (gridSide * gridSide) ~/ 10);
  final y = animated ? math.sin(elapsed * 2.2 + index * 0.17) * 0.25 : 0.0;
  return vm.Matrix4.translationValues(x * 0.72, y, z * 0.72);
}

double _percentile(List<double> sorted, double p) {
  if (sorted.isEmpty) return 0;
  final raw = (sorted.length - 1) * p;
  final low = raw.floor();
  final high = raw.ceil();
  if (low == high) return sorted[low];
  final t = raw - low;
  return sorted[low] * (1 - t) + sorted[high] * t;
}
