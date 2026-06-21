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
    world.ensureObjectStore<SceneNodeRef>().insert(entity.index, self.node);
  }
}

class _$SpawnInstancesSystemAdapter
    implements SystemAdapter, SystemAccessProvider {
  _$SpawnInstancesSystemAdapter(this._system);

  final SpawnInstancesSystem _system;
  late final Commands _p0;
  late final CubeInstances _p1;

  @override
  void initialize(World world) {
    _p0 = world.commands;
    _p1 = world.resources.get<CubeInstances>();
  }

  @override
  SystemAccess get access => const SystemAccess(
        reads: <Type>{},
        writes: <Type>{},
      );

  @override
  void run() {
    _system.run(_p0, _p1);
  }
}

base mixin _$SpawnInstancesSystem on GameSystem {
  @override
  SystemAdapter createAdapter() =>
      _$SpawnInstancesSystemAdapter(this as SpawnInstancesSystem);
}

class _$MoveInstancesSystemAdapter
    implements SystemAdapter, SystemAccessProvider {
  _$MoveInstancesSystemAdapter(this._system);

  final MoveInstancesSystem _system;
  late final Query2<Instance, Spin> _p0;
  late final CubeInstances _p1;
  late final FrameTime _p2;

  @override
  void initialize(World world) {
    world.ensureObjectStore<Instance>();
    world.ensureObjectStore<Spin>();
    _p0 = world.query2<Instance, Spin>(
        withTypes: const <Type>[], withoutTypes: const <Type>[]);
    _p1 = world.resources.get<CubeInstances>();
    _p2 = world.resources.get<FrameTime>();
  }

  @override
  SystemAccess get access => const SystemAccess(
        reads: <Type>{Instance},
        writes: <Type>{Spin},
      );

  @override
  void run() {
    _system.run(_p0, _p1, _p2);
  }
}

base mixin _$MoveInstancesSystem on GameSystem {
  @override
  SystemAdapter createAdapter() =>
      _$MoveInstancesSystemAdapter(this as MoveInstancesSystem);
}

class _$SpawnGridSystemAdapter implements SystemAdapter, SystemAccessProvider {
  _$SpawnGridSystemAdapter(this._system);

  final SpawnGridSystem _system;
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

base mixin _$SpawnGridSystem on GameSystem {
  @override
  SystemAdapter createAdapter() =>
      _$SpawnGridSystemAdapter(this as SpawnGridSystem);
}

class _$SpinSystemAdapter implements SystemAdapter, SystemAccessProvider {
  _$SpinSystemAdapter(this._system);

  final SpinSystem _system;
  late final Query2<SceneTransform, Spin> _p0;
  late final FrameTime _p1;

  @override
  void initialize(World world) {
    world.ensureObjectStore<SceneTransform>();
    world.ensureObjectStore<Spin>();
    _p0 = world.query2<SceneTransform, Spin>(
        withTypes: const <Type>[], withoutTypes: const <Type>[]);
    _p1 = world.resources.get<FrameTime>();
  }

  @override
  SystemAccess get access => const SystemAccess(
        reads: <Type>{},
        writes: <Type>{SceneTransform, Spin},
      );

  @override
  void run() {
    _system.run(_p0, _p1);
  }
}

base mixin _$SpinSystem on GameSystem {
  @override
  SystemAdapter createAdapter() => _$SpinSystemAdapter(this as SpinSystem);
}
