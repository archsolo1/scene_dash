// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rules.dart';

// **************************************************************************
// EcsGenerator
// **************************************************************************

class $PlayerViewSystemAdapter implements SystemAdapter, SystemAccessProvider {
  $PlayerViewSystemAdapter(this._system);

  final PlayerViewSystem _system;
  late final Single<SceneNodeRef> _p0;
  late final CameraRig _p1;
  late final FrameTime _p2;

  @override
  void initialize(World world) {
    world.ensureObjectStore<SceneNodeRef>();
    world.ensureTagStore<Player>();
    _p0 = Single<SceneNodeRef>(
      world.query1<SceneNodeRef>(
        withTypes: const <Type>[Player],
        withoutTypes: const <Type>[],
      ),
    );
    _p1 = world.resources.get<CameraRig>();
    _p2 = world.resources.get<FrameTime>();
  }

  @override
  SystemAccess get access =>
      const SystemAccess(reads: <Type>{SceneNodeRef}, writes: <Type>{});

  @override
  void run() {
    _system.run(_p0, _p1, _p2);
  }
}

/// Schedulable descriptor for [PlayerViewSystem]. Pass to `app.addSystem` and reference in
/// `after`/`before`.
final playerViewSystem = SystemDescriptor(
  const SystemRef('package:scene_game/rules/rules.dart', 'PlayerViewSystem'),
  () => $PlayerViewSystemAdapter(const PlayerViewSystem()),
);

class $EvaluateGameRulesAdapter implements SystemAdapter, SystemAccessProvider {
  late final Single<SceneNodeRef> _p0;
  late final PhysicsWorld _p1;
  late final GameState _p2;
  late final NextState<GameStatus> _p3;
  late final FrameTime _p4;
  late final PlayerKnockback _p5;
  late final ShieldState _p6;
  late final ShieldDeflectVfx _p7;

  @override
  void initialize(World world) {
    world.ensureObjectStore<SceneNodeRef>();
    world.ensureTagStore<Player>();
    _p0 = Single<SceneNodeRef>(
      world.query1<SceneNodeRef>(
        withTypes: const <Type>[Player],
        withoutTypes: const <Type>[],
      ),
    );
    _p1 = world.resources.get<PhysicsWorld>();
    _p2 = world.resources.get<GameState>();
    _p3 = world.resources.get<NextState<GameStatus>>();
    _p4 = world.resources.get<FrameTime>();
    _p5 = world.resources.get<PlayerKnockback>();
    _p6 = world.resources.get<ShieldState>();
    _p7 = world.resources.get<ShieldDeflectVfx>();
  }

  @override
  SystemAccess get access =>
      const SystemAccess(reads: <Type>{SceneNodeRef}, writes: <Type>{});

  @override
  void run() {
    evaluateGameRules(_p0, _p1, _p2, _p3, _p4, _p5, _p6, _p7);
  }
}

/// Schedulable descriptor for [evaluateGameRules]. Pass to `app.addSystem` and reference in
/// `after`/`before`.
final evaluateGameRulesSystem = SystemDescriptor(
  const SystemRef('package:scene_game/rules/rules.dart', 'evaluateGameRules'),
  () => $EvaluateGameRulesAdapter(),
);

class $RequestRestartAdapter implements SystemAdapter, SystemAccessProvider {
  late final InputState _p0;
  late final CurrentState<GameStatus> _p1;
  late final NextState<GameStatus> _p2;

  @override
  void initialize(World world) {
    _p0 = world.resources.get<InputState>();
    _p1 = world.resources.get<CurrentState<GameStatus>>();
    _p2 = world.resources.get<NextState<GameStatus>>();
  }

  @override
  SystemAccess get access =>
      const SystemAccess(reads: <Type>{}, writes: <Type>{});

  @override
  void run() {
    requestRestart(_p0, _p1, _p2);
  }
}

/// Schedulable descriptor for [requestRestart]. Pass to `app.addSystem` and reference in
/// `after`/`before`.
final requestRestartSystem = SystemDescriptor(
  const SystemRef('package:scene_game/rules/rules.dart', 'requestRestart'),
  () => $RequestRestartAdapter(),
);

class $StartRunAdapter implements SystemAdapter, SystemAccessProvider {
  late final GameState _p0;
  late final CameraRig _p1;

  @override
  void initialize(World world) {
    _p0 = world.resources.get<GameState>();
    _p1 = world.resources.get<CameraRig>();
  }

  @override
  SystemAccess get access =>
      const SystemAccess(reads: <Type>{}, writes: <Type>{});

  @override
  void run() {
    startRun(_p0, _p1);
  }
}

/// Schedulable descriptor for [startRun]. Pass to `app.addSystem` and reference in
/// `after`/`before`.
final startRunSystem = SystemDescriptor(
  const SystemRef('package:scene_game/rules/rules.dart', 'startRun'),
  () => $StartRunAdapter(),
);
