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

class $StartRunSystemAdapter implements SystemAdapter, SystemAccessProvider {
  $StartRunSystemAdapter(this._system);

  final StartRunSystem _system;
  late final Single<SceneNodeRef> _p0;
  late final Single<PlayerVisuals> _p1;
  late final InputState _p2;
  late final GameState _p3;
  late final RockSpawner _p4;
  late final CameraRig _p5;
  late final PlayerKnockback _p6;
  late final Blaster _p7;
  late final ImpactVfx _p8;
  late final LockOnReticle _p9;
  late final ShieldState _p10;
  late final CollectableSpawner _p11;
  late final ShieldDeflectVfx _p12;

  @override
  void initialize(World world) {
    world.ensureObjectStore<SceneNodeRef>();
    world.ensureTagStore<Player>();
    world.ensureObjectStore<PlayerVisuals>();
    _p0 = Single<SceneNodeRef>(
      world.query1<SceneNodeRef>(
        withTypes: const <Type>[Player],
        withoutTypes: const <Type>[],
      ),
    );
    _p1 = Single<PlayerVisuals>(
      world.query1<PlayerVisuals>(
        withTypes: const <Type>[Player],
        withoutTypes: const <Type>[],
      ),
    );
    _p2 = world.resources.get<InputState>();
    _p3 = world.resources.get<GameState>();
    _p4 = world.resources.get<RockSpawner>();
    _p5 = world.resources.get<CameraRig>();
    _p6 = world.resources.get<PlayerKnockback>();
    _p7 = world.resources.get<Blaster>();
    _p8 = world.resources.get<ImpactVfx>();
    _p9 = world.resources.get<LockOnReticle>();
    _p10 = world.resources.get<ShieldState>();
    _p11 = world.resources.get<CollectableSpawner>();
    _p12 = world.resources.get<ShieldDeflectVfx>();
  }

  @override
  SystemAccess get access => const SystemAccess(
    reads: <Type>{},
    writes: <Type>{SceneNodeRef, PlayerVisuals},
  );

  @override
  void run() {
    _system.run(
      _p0,
      _p1,
      _p2,
      _p3,
      _p4,
      _p5,
      _p6,
      _p7,
      _p8,
      _p9,
      _p10,
      _p11,
      _p12,
    );
  }
}

/// Schedulable descriptor for [StartRunSystem]. Pass to `app.addSystem` and reference in
/// `after`/`before`.
final startRunSystem = SystemDescriptor(
  const SystemRef('package:scene_game/rules/rules.dart', 'StartRunSystem'),
  () => $StartRunSystemAdapter(const StartRunSystem()),
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
