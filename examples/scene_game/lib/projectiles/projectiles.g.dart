// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'projectiles.dart';

// **************************************************************************
// EcsGenerator
// **************************************************************************

class $ShootProjectilesSystemAdapter
    implements SystemAdapter, SystemAccessProvider {
  $ShootProjectilesSystemAdapter(this._system);

  final ShootProjectilesSystem _system;
  late final Commands _p0;
  late final Single<SceneNodeRef> _p1;
  late final InputState _p2;
  late final GameState _p3;
  late final Blaster _p4;
  late final LockOnReticle _p5;
  late final FixedTime _p6;

  @override
  void initialize(World world) {
    world.ensureObjectStore<SceneNodeRef>();
    world.ensureTagStore<Player>();
    _p0 = world.commands;
    _p1 = Single<SceneNodeRef>(
      world.query1<SceneNodeRef>(
        withTypes: const <Type>[Player],
        withoutTypes: const <Type>[],
      ),
    );
    _p2 = world.resources.get<InputState>();
    _p3 = world.resources.get<GameState>();
    _p4 = world.resources.get<Blaster>();
    _p5 = world.resources.get<LockOnReticle>();
    _p6 = world.resources.get<FixedTime>();
  }

  @override
  SystemAccess get access =>
      const SystemAccess(reads: <Type>{SceneNodeRef}, writes: <Type>{});

  @override
  void run() {
    _system.run(_p0, _p1, _p2, _p3, _p4, _p5, _p6);
  }
}

/// Schedulable descriptor for [ShootProjectilesSystem]. Pass to `app.addSystem` and reference in
/// `after`/`before`.
final shootProjectilesSystem = SystemDescriptor(
  const SystemRef(
    'package:scene_game/projectiles/projectiles.dart',
    'ShootProjectilesSystem',
  ),
  () => $ShootProjectilesSystemAdapter(const ShootProjectilesSystem()),
);

class $UpdateProjectilesSystemAdapter
    implements SystemAdapter, SystemAccessProvider {
  $UpdateProjectilesSystemAdapter(this._system);

  final UpdateProjectilesSystem _system;
  late final Query2<Projectile, SceneNodeRef> _p0;
  late final PhysicsWorld _p1;
  late final SceneNodeIndex _p2;
  late final ImpactVfx _p3;
  late final LockOnReticle _p4;
  late final FrameTime _p5;
  late final Commands _p6;

  @override
  void initialize(World world) {
    world.ensureObjectStore<Projectile>();
    world.ensureObjectStore<SceneNodeRef>();
    _p0 = world.query2<Projectile, SceneNodeRef>(
      withTypes: const <Type>[],
      withoutTypes: const <Type>[],
    );
    _p1 = world.resources.get<PhysicsWorld>();
    _p2 = world.resources.get<SceneNodeIndex>();
    _p3 = world.resources.get<ImpactVfx>();
    _p4 = world.resources.get<LockOnReticle>();
    _p5 = world.resources.get<FrameTime>();
    _p6 = world.commands;
  }

  @override
  SystemAccess get access => const SystemAccess(
    reads: <Type>{SceneNodeRef},
    writes: <Type>{Projectile},
  );

  @override
  void run() {
    _system.run(_p0, _p1, _p2, _p3, _p4, _p5, _p6);
  }
}

/// Schedulable descriptor for [UpdateProjectilesSystem]. Pass to `app.addSystem` and reference in
/// `after`/`before`.
final updateProjectilesSystem = SystemDescriptor(
  const SystemRef(
    'package:scene_game/projectiles/projectiles.dart',
    'UpdateProjectilesSystem',
  ),
  () => $UpdateProjectilesSystemAdapter(const UpdateProjectilesSystem()),
);

class $UpdateChargeVisualsAdapter
    implements SystemAdapter, SystemAccessProvider {
  late final Single<PlayerVisuals> _p0;
  late final Blaster _p1;
  late final FrameTime _p2;

  @override
  void initialize(World world) {
    world.ensureObjectStore<PlayerVisuals>();
    world.ensureTagStore<Player>();
    _p0 = Single<PlayerVisuals>(
      world.query1<PlayerVisuals>(
        withTypes: const <Type>[Player],
        withoutTypes: const <Type>[],
      ),
    );
    _p1 = world.resources.get<Blaster>();
    _p2 = world.resources.get<FrameTime>();
  }

  @override
  SystemAccess get access =>
      const SystemAccess(reads: <Type>{}, writes: <Type>{PlayerVisuals});

  @override
  void run() {
    updateChargeVisuals(_p0, _p1, _p2);
  }
}

/// Schedulable descriptor for [updateChargeVisuals]. Pass to `app.addSystem` and reference in
/// `after`/`before`.
final updateChargeVisualsSystem = SystemDescriptor(
  const SystemRef(
    'package:scene_game/projectiles/projectiles.dart',
    'updateChargeVisuals',
  ),
  () => $UpdateChargeVisualsAdapter(),
);

class $SpawnImpactVfxAdapter implements SystemAdapter, SystemAccessProvider {
  late final Scene _p0;
  late final ImpactVfx _p1;

  @override
  void initialize(World world) {
    _p0 = world.resources.get<Scene>();
    _p1 = world.resources.get<ImpactVfx>();
  }

  @override
  SystemAccess get access =>
      const SystemAccess(reads: <Type>{}, writes: <Type>{});

  @override
  void run() {
    spawnImpactVfx(_p0, _p1);
  }
}

/// Schedulable descriptor for [spawnImpactVfx]. Pass to `app.addSystem` and reference in
/// `after`/`before`.
final spawnImpactVfxSystem = SystemDescriptor(
  const SystemRef(
    'package:scene_game/projectiles/projectiles.dart',
    'spawnImpactVfx',
  ),
  () => $SpawnImpactVfxAdapter(),
);

class $UpdateImpactVfxAdapter implements SystemAdapter, SystemAccessProvider {
  late final ImpactVfx _p0;
  late final FrameTime _p1;

  @override
  void initialize(World world) {
    _p0 = world.resources.get<ImpactVfx>();
    _p1 = world.resources.get<FrameTime>();
  }

  @override
  SystemAccess get access =>
      const SystemAccess(reads: <Type>{}, writes: <Type>{});

  @override
  void run() {
    updateImpactVfx(_p0, _p1);
  }
}

/// Schedulable descriptor for [updateImpactVfx]. Pass to `app.addSystem` and reference in
/// `after`/`before`.
final updateImpactVfxSystem = SystemDescriptor(
  const SystemRef(
    'package:scene_game/projectiles/projectiles.dart',
    'updateImpactVfx',
  ),
  () => $UpdateImpactVfxAdapter(),
);

class $SpawnLockOnReticleAdapter
    implements SystemAdapter, SystemAccessProvider {
  late final Scene _p0;
  late final LockOnReticle _p1;

  @override
  void initialize(World world) {
    _p0 = world.resources.get<Scene>();
    _p1 = world.resources.get<LockOnReticle>();
  }

  @override
  SystemAccess get access =>
      const SystemAccess(reads: <Type>{}, writes: <Type>{});

  @override
  void run() {
    spawnLockOnReticle(_p0, _p1);
  }
}

/// Schedulable descriptor for [spawnLockOnReticle]. Pass to `app.addSystem` and reference in
/// `after`/`before`.
final spawnLockOnReticleSystem = SystemDescriptor(
  const SystemRef(
    'package:scene_game/projectiles/projectiles.dart',
    'spawnLockOnReticle',
  ),
  () => $SpawnLockOnReticleAdapter(),
);

class $UpdateLockOnReticleAdapter
    implements SystemAdapter, SystemAccessProvider {
  late final Single<SceneNodeRef> _p0;
  late final Query1<SceneNodeRef> _p1;
  late final Blaster _p2;
  late final CameraRig _p3;
  late final LockOnReticle _p4;
  late final FrameTime _p5;

  @override
  void initialize(World world) {
    world.ensureObjectStore<SceneNodeRef>();
    world.ensureTagStore<Player>();
    world.ensureTagStore<Rock>();
    _p0 = Single<SceneNodeRef>(
      world.query1<SceneNodeRef>(
        withTypes: const <Type>[Player],
        withoutTypes: const <Type>[],
      ),
    );
    _p1 = world.query1<SceneNodeRef>(
      withTypes: const <Type>[Rock],
      withoutTypes: const <Type>[],
    );
    _p2 = world.resources.get<Blaster>();
    _p3 = world.resources.get<CameraRig>();
    _p4 = world.resources.get<LockOnReticle>();
    _p5 = world.resources.get<FrameTime>();
  }

  @override
  SystemAccess get access =>
      const SystemAccess(reads: <Type>{SceneNodeRef}, writes: <Type>{});

  @override
  void run() {
    updateLockOnReticle(_p0, _p1, _p2, _p3, _p4, _p5);
  }
}

/// Schedulable descriptor for [updateLockOnReticle]. Pass to `app.addSystem` and reference in
/// `after`/`before`.
final updateLockOnReticleSystem = SystemDescriptor(
  const SystemRef(
    'package:scene_game/projectiles/projectiles.dart',
    'updateLockOnReticle',
  ),
  () => $UpdateLockOnReticleAdapter(),
);

class $DisposeLockOnReticleAdapter
    implements SystemAdapter, SystemAccessProvider {
  late final LockOnReticle _p0;

  @override
  void initialize(World world) {
    _p0 = world.resources.get<LockOnReticle>();
  }

  @override
  SystemAccess get access =>
      const SystemAccess(reads: <Type>{}, writes: <Type>{});

  @override
  void run() {
    disposeLockOnReticle(_p0);
  }
}

/// Schedulable descriptor for [disposeLockOnReticle]. Pass to `app.addSystem` and reference in
/// `after`/`before`.
final disposeLockOnReticleSystem = SystemDescriptor(
  const SystemRef(
    'package:scene_game/projectiles/projectiles.dart',
    'disposeLockOnReticle',
  ),
  () => $DisposeLockOnReticleAdapter(),
);

mixin _$ProjectileBundle implements SceneDashBundle {
  @override
  void insertInto(World world, Entity entity) {
    final self = this as ProjectileBundle;
    world.ensureObjectStore<Projectile>().insert(entity.index, self.projectile);
    world.ensureObjectStore<SceneNodeRef>().insert(entity.index, self.node);
    world.ensureTagStore<PhysicsDriven>().add(entity.index);
  }
}
