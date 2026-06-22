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
  late final Query1<SceneNodeRef> _p1;
  late final InputState _p2;
  late final GameState _p3;
  late final Blaster _p4;
  late final FixedTime _p5;

  @override
  void initialize(World world) {
    world.ensureObjectStore<SceneNodeRef>();
    world.ensureTagStore<Player>();
    _p0 = world.commands;
    _p1 = world.query1<SceneNodeRef>(
      withTypes: const <Type>[Player],
      withoutTypes: const <Type>[],
    );
    _p2 = world.resources.get<InputState>();
    _p3 = world.resources.get<GameState>();
    _p4 = world.resources.get<Blaster>();
    _p5 = world.resources.get<FixedTime>();
  }

  @override
  SystemAccess get access =>
      const SystemAccess(reads: <Type>{SceneNodeRef}, writes: <Type>{});

  @override
  void run() {
    _system.run(_p0, _p1, _p2, _p3, _p4, _p5);
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
  late final FrameTime _p2;
  late final Commands _p3;

  @override
  void initialize(World world) {
    world.ensureObjectStore<Projectile>();
    world.ensureObjectStore<SceneNodeRef>();
    _p0 = world.query2<Projectile, SceneNodeRef>(
      withTypes: const <Type>[],
      withoutTypes: const <Type>[],
    );
    _p1 = world.resources.get<PhysicsWorld>();
    _p2 = world.resources.get<FrameTime>();
    _p3 = world.commands;
  }

  @override
  SystemAccess get access => const SystemAccess(
    reads: <Type>{SceneNodeRef},
    writes: <Type>{Projectile},
  );

  @override
  void run() {
    _system.run(_p0, _p1, _p2, _p3);
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

class $UpdateProjectileVfxSystemAdapter
    implements SystemAdapter, SystemAccessProvider {
  $UpdateProjectileVfxSystemAdapter(this._system);

  final UpdateProjectileVfxSystem _system;
  late final Query2<VfxEffect, SceneNodeRef> _p0;
  late final FrameTime _p1;
  late final Commands _p2;

  @override
  void initialize(World world) {
    world.ensureObjectStore<VfxEffect>();
    world.ensureObjectStore<SceneNodeRef>();
    _p0 = world.query2<VfxEffect, SceneNodeRef>(
      withTypes: const <Type>[],
      withoutTypes: const <Type>[],
    );
    _p1 = world.resources.get<FrameTime>();
    _p2 = world.commands;
  }

  @override
  SystemAccess get access => const SystemAccess(
    reads: <Type>{SceneNodeRef},
    writes: <Type>{VfxEffect},
  );

  @override
  void run() {
    _system.run(_p0, _p1, _p2);
  }
}

/// Schedulable descriptor for [UpdateProjectileVfxSystem]. Pass to `app.addSystem` and reference in
/// `after`/`before`.
final updateProjectileVfxSystem = SystemDescriptor(
  const SystemRef(
    'package:scene_game/projectiles/projectiles.dart',
    'UpdateProjectileVfxSystem',
  ),
  () => $UpdateProjectileVfxSystemAdapter(const UpdateProjectileVfxSystem()),
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

mixin _$ImpactVfxBundle implements SceneDashBundle {
  @override
  void insertInto(World world, Entity entity) {
    final self = this as ImpactVfxBundle;
    world.ensureObjectStore<SceneNodeRef>().insert(entity.index, self.node);
    world.ensureObjectStore<VfxEffect>().insert(entity.index, self.effect);
  }
}
