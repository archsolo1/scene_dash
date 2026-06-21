// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'world.dart';

// **************************************************************************
// EcsGenerator
// **************************************************************************

class _$SetupWorldSystemAdapter implements SystemAdapter, SystemAccessProvider {
  _$SetupWorldSystemAdapter(this._system);

  final SetupWorldSystem _system;
  late final Scene _p0;

  @override
  void initialize(World world) {
    _p0 = world.resources.get<Scene>();
  }

  @override
  SystemAccess get access =>
      const SystemAccess(reads: <Type>{}, writes: <Type>{});

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
