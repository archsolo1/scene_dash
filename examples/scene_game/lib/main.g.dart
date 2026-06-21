// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'main.dart';

// **************************************************************************
// EcsGenerator
// **************************************************************************

mixin _$CubeBundle implements SceneDashBundle {
  @override
  void insertInto(World world, Entity entity) {
    final self = this as CubeBundle;
    world
        .ensureObjectStore<SceneTransform>()
        .insert(entity.index, self.transform);
    world.ensureObjectStore<Orbit>().insert(entity.index, self.orbit);
    world.ensureObjectStore<SceneNodeRef>().insert(entity.index, self.node);
  }
}

class _$SpawnCubesSystemAdapter implements SystemAdapter, SystemAccessProvider {
  _$SpawnCubesSystemAdapter(this._system);

  final SpawnCubesSystem _system;
  late final Commands _p0;

  @override
  void initialize(World world) {
    _p0 = world.commands;
  }

  @override
  SystemAccess get access => const SystemAccess(
        reads: <Type>{},
        writes: <Type>{},
      );

  @override
  void run() {
    _system.run(_p0);
  }
}

base mixin _$SpawnCubesSystem on GameSystem {
  @override
  SystemAdapter createAdapter() =>
      _$SpawnCubesSystemAdapter(this as SpawnCubesSystem);
}

class _$OrbitSystemAdapter implements SystemAdapter, SystemAccessProvider {
  _$OrbitSystemAdapter(this._system);

  final OrbitSystem _system;
  late final Query2<SceneTransform, Orbit> _p0;
  late final FrameTime _p1;

  @override
  void initialize(World world) {
    world.ensureObjectStore<SceneTransform>();
    world.ensureObjectStore<Orbit>();
    _p0 = world.query2<SceneTransform, Orbit>(
        withTypes: const <Type>[], withoutTypes: const <Type>[]);
    _p1 = world.resources.get<FrameTime>();
  }

  @override
  SystemAccess get access => const SystemAccess(
        reads: <Type>{},
        writes: <Type>{SceneTransform, Orbit},
      );

  @override
  void run() {
    _system.run(_p0, _p1);
  }
}

base mixin _$OrbitSystem on GameSystem {
  @override
  SystemAdapter createAdapter() => _$OrbitSystemAdapter(this as OrbitSystem);
}

class _$SetupWorldSystemAdapter implements SystemAdapter, SystemAccessProvider {
  _$SetupWorldSystemAdapter(this._system);

  final SetupWorldSystem _system;
  late final Scene _p0;

  @override
  void initialize(World world) {
    _p0 = world.resources.get<Scene>();
  }

  @override
  SystemAccess get access => const SystemAccess(
        reads: <Type>{},
        writes: <Type>{},
      );

  @override
  void run() {
    _system.run(_p0);
  }
}

base mixin _$SetupWorldSystem on GameSystem {
  @override
  SystemAdapter createAdapter() =>
      _$SetupWorldSystemAdapter(this as SetupWorldSystem);
}
