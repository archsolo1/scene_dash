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

class $RestartSystemAdapter implements SystemAdapter, SystemAccessProvider {
  $RestartSystemAdapter(this._system);

  final RestartSystem _system;
  late final Single<SceneNodeRef> _p0;
  late final Single<PlayerVisuals> _p1;
  late final Query1<SceneNodeRef> _p2;
  late final Query1<SceneNodeRef> _p3;
  late final Query1<SceneNodeRef> _p4;
  late final InputState _p5;
  late final GameState _p6;
  late final RockSpawner _p7;
  late final CameraRig _p8;
  late final PlayerKnockback _p9;
  late final Blaster _p10;
  late final ImpactVfx _p11;
  late final LockOnReticle _p12;
  late final ShieldState _p13;
  late final CollectableSpawner _p14;
  late final ShieldDeflectVfx _p15;
  late final Commands _p16;

  @override
  void initialize(World world) {
    world.ensureObjectStore<SceneNodeRef>();
    world.ensureTagStore<Player>();
    world.ensureObjectStore<PlayerVisuals>();
    world.ensureTagStore<Rock>();
    world.ensureObjectStore<Projectile>();
    world.ensureTagStore<Collectable>();
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
    _p2 = world.query1<SceneNodeRef>(
      withTypes: const <Type>[Rock],
      withoutTypes: const <Type>[],
    );
    _p3 = world.query1<SceneNodeRef>(
      withTypes: const <Type>[Projectile],
      withoutTypes: const <Type>[],
    );
    _p4 = world.query1<SceneNodeRef>(
      withTypes: const <Type>[Collectable],
      withoutTypes: const <Type>[],
    );
    _p5 = world.resources.get<InputState>();
    _p6 = world.resources.get<GameState>();
    _p7 = world.resources.get<RockSpawner>();
    _p8 = world.resources.get<CameraRig>();
    _p9 = world.resources.get<PlayerKnockback>();
    _p10 = world.resources.get<Blaster>();
    _p11 = world.resources.get<ImpactVfx>();
    _p12 = world.resources.get<LockOnReticle>();
    _p13 = world.resources.get<ShieldState>();
    _p14 = world.resources.get<CollectableSpawner>();
    _p15 = world.resources.get<ShieldDeflectVfx>();
    _p16 = world.commands;
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
      _p13,
      _p14,
      _p15,
      _p16,
    );
  }
}

/// Schedulable descriptor for [RestartSystem]. Pass to `app.addSystem` and reference in
/// `after`/`before`.
final restartSystem = SystemDescriptor(
  const SystemRef('package:scene_game/rules/rules.dart', 'RestartSystem'),
  () => $RestartSystemAdapter(const RestartSystem()),
);

class $EvaluateGameRulesAdapter implements SystemAdapter, SystemAccessProvider {
  late final Single<SceneNodeRef> _p0;
  late final PhysicsWorld _p1;
  late final GameState _p2;
  late final FrameTime _p3;
  late final PlayerKnockback _p4;
  late final ShieldState _p5;
  late final ShieldDeflectVfx _p6;

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
    _p3 = world.resources.get<FrameTime>();
    _p4 = world.resources.get<PlayerKnockback>();
    _p5 = world.resources.get<ShieldState>();
    _p6 = world.resources.get<ShieldDeflectVfx>();
  }

  @override
  SystemAccess get access =>
      const SystemAccess(reads: <Type>{SceneNodeRef}, writes: <Type>{});

  @override
  void run() {
    evaluateGameRules(_p0, _p1, _p2, _p3, _p4, _p5, _p6);
  }
}

/// Schedulable descriptor for [evaluateGameRules]. Pass to `app.addSystem` and reference in
/// `after`/`before`.
final evaluateGameRulesSystem = SystemDescriptor(
  const SystemRef('package:scene_game/rules/rules.dart', 'evaluateGameRules'),
  () => $EvaluateGameRulesAdapter(),
);
