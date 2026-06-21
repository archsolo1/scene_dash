// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rules.dart';

// **************************************************************************
// EcsGenerator
// **************************************************************************

class _$GameRulesSystemAdapter implements SystemAdapter, SystemAccessProvider {
  _$GameRulesSystemAdapter(this._system);

  final GameRulesSystem _system;
  late final Query1<SceneNodeRef> _p0;
  late final Query1<SceneNodeRef> _p1;
  late final PhysicsWorld _p2;
  late final GameState _p3;
  late final FrameTime _p4;
  late final ImpactMotion _p5;

  @override
  void initialize(World world) {
    world.ensureObjectStore<SceneNodeRef>();
    world.ensureTagStore<Player>();
    world.ensureTagStore<Rock>();
    _p0 = world.query1<SceneNodeRef>(
      withTypes: const <Type>[Player],
      withoutTypes: const <Type>[],
    );
    _p1 = world.query1<SceneNodeRef>(
      withTypes: const <Type>[Rock],
      withoutTypes: const <Type>[],
    );
    _p2 = world.resources.get<PhysicsWorld>();
    _p3 = world.resources.get<GameState>();
    _p4 = world.resources.get<FrameTime>();
    _p5 = world.resources.get<ImpactMotion>();
  }

  @override
  SystemAccess get access =>
      const SystemAccess(reads: <Type>{SceneNodeRef}, writes: <Type>{});

  @override
  void run() {
    _system.run(_p0, _p1, _p2, _p3, _p4, _p5);
  }
}

base mixin _$GameRulesSystem on GameSystem {
  @override
  SystemAdapter createAdapter() =>
      _$GameRulesSystemAdapter(this as GameRulesSystem);
}

class _$PlayerViewSystemAdapter implements SystemAdapter, SystemAccessProvider {
  _$PlayerViewSystemAdapter(this._system);

  final PlayerViewSystem _system;
  late final Query1<SceneNodeRef> _p0;
  late final CameraRig _p1;
  late final ImpactMotion _p2;
  late final FrameTime _p3;

  @override
  void initialize(World world) {
    world.ensureObjectStore<SceneNodeRef>();
    world.ensureTagStore<Player>();
    _p0 = world.query1<SceneNodeRef>(
      withTypes: const <Type>[Player],
      withoutTypes: const <Type>[],
    );
    _p1 = world.resources.get<CameraRig>();
    _p2 = world.resources.get<ImpactMotion>();
    _p3 = world.resources.get<FrameTime>();
  }

  @override
  SystemAccess get access =>
      const SystemAccess(reads: <Type>{SceneNodeRef}, writes: <Type>{});

  @override
  void run() {
    _system.run(_p0, _p1, _p2, _p3);
  }
}

base mixin _$PlayerViewSystem on GameSystem {
  @override
  SystemAdapter createAdapter() =>
      _$PlayerViewSystemAdapter(this as PlayerViewSystem);
}

class _$RestartSystemAdapter implements SystemAdapter, SystemAccessProvider {
  _$RestartSystemAdapter(this._system);

  final RestartSystem _system;
  late final Query1<SceneNodeRef> _p0;
  late final Query1<SceneNodeRef> _p1;
  late final InputState _p2;
  late final GameState _p3;
  late final RockSpawner _p4;
  late final CameraRig _p5;
  late final ImpactMotion _p6;
  late final Commands _p7;

  @override
  void initialize(World world) {
    world.ensureObjectStore<SceneNodeRef>();
    world.ensureTagStore<Player>();
    world.ensureTagStore<Rock>();
    _p0 = world.query1<SceneNodeRef>(
      withTypes: const <Type>[Player],
      withoutTypes: const <Type>[],
    );
    _p1 = world.query1<SceneNodeRef>(
      withTypes: const <Type>[Rock],
      withoutTypes: const <Type>[],
    );
    _p2 = world.resources.get<InputState>();
    _p3 = world.resources.get<GameState>();
    _p4 = world.resources.get<RockSpawner>();
    _p5 = world.resources.get<CameraRig>();
    _p6 = world.resources.get<ImpactMotion>();
    _p7 = world.commands;
  }

  @override
  SystemAccess get access =>
      const SystemAccess(reads: <Type>{SceneNodeRef}, writes: <Type>{});

  @override
  void run() {
    _system.run(_p0, _p1, _p2, _p3, _p4, _p5, _p6, _p7);
  }
}

base mixin _$RestartSystem on GameSystem {
  @override
  SystemAdapter createAdapter() =>
      _$RestartSystemAdapter(this as RestartSystem);
}
