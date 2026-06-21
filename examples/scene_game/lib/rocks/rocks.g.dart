// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rocks.dart';

// **************************************************************************
// EcsGenerator
// **************************************************************************

mixin _$RockBundle implements SceneDashBundle {
  @override
  void insertInto(World world, Entity entity) {
    final self = this as RockBundle;
    world.ensureTagStore<Rock>().add(entity.index);
    world.ensureObjectStore<SceneNodeRef>().insert(entity.index, self.node);
    world.ensureTagStore<PhysicsDriven>().add(entity.index);
  }
}

class _$SpawnRocksSystemAdapter implements SystemAdapter, SystemAccessProvider {
  _$SpawnRocksSystemAdapter(this._system);

  final SpawnRocksSystem _system;
  late final Commands _p0;
  late final RockSpawner _p1;
  late final GameState _p2;
  late final FixedTime _p3;

  @override
  void initialize(World world) {
    _p0 = world.commands;
    _p1 = world.resources.get<RockSpawner>();
    _p2 = world.resources.get<GameState>();
    _p3 = world.resources.get<FixedTime>();
  }

  @override
  SystemAccess get access =>
      const SystemAccess(reads: <Type>{}, writes: <Type>{});

  @override
  void run() {
    _system.run(_p0, _p1, _p2, _p3);
  }
}

base mixin _$SpawnRocksSystem on GameSystem {
  @override
  SystemAdapter createAdapter() =>
      _$SpawnRocksSystemAdapter(this as SpawnRocksSystem);
}

class _$CleanupRocksSystemAdapter
    implements SystemAdapter, SystemAccessProvider {
  _$CleanupRocksSystemAdapter(this._system);

  final CleanupRocksSystem _system;
  late final Query1<SceneNodeRef> _p0;
  late final Commands _p1;

  @override
  void initialize(World world) {
    world.ensureObjectStore<SceneNodeRef>();
    world.ensureTagStore<Rock>();
    _p0 = world.query1<SceneNodeRef>(
      withTypes: const <Type>[Rock],
      withoutTypes: const <Type>[],
    );
    _p1 = world.commands;
  }

  @override
  SystemAccess get access =>
      const SystemAccess(reads: <Type>{SceneNodeRef}, writes: <Type>{});

  @override
  void run() {
    _system.run(_p0, _p1);
  }
}

base mixin _$CleanupRocksSystem on GameSystem {
  @override
  SystemAdapter createAdapter() =>
      _$CleanupRocksSystemAdapter(this as CleanupRocksSystem);
}
