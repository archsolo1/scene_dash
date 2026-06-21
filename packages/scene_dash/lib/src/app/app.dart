import 'dart:async';

import '../schedule/access_conflict.dart';
import '../schedule/schedule.dart';
import '../schedule/schedule_label.dart';
import '../schedule/schedules.dart';
import '../schedule/system_label.dart';
import '../schedule/system_registration.dart';
import '../system/game_system.dart';
import '../system/system_adapter.dart';
import '../world/world.dart';
import 'app_builder.dart';
import 'plugin.dart';

/// The pure-Dart ECS engine: a [World] plus a set of named [Schedule]s and the
/// plugin/registration lifecycle.
///
/// [App] is scene-agnostic by design — the core package must not depend on
/// `flutter_scene`. The `scene_dash_flutter_scene` package wraps an [App] in a
/// `Game` that owns the `Scene`, attaches the frame driver and exposes
/// `start()`/`onTick`. Tests and headless simulations can drive [App] directly.
final class App implements AppBuilder {
  /// The ECS world this app operates on.
  final World world = World();

  final Map<ScheduleLabel, Schedule> _schedules = <ScheduleLabel, Schedule>{};
  final Set<Type> _addedPlugins = <Type>{};
  final List<FutureOr<void> Function()> _cleanups =
      <FutureOr<void> Function()>[];

  /// How the app reacts to access conflicts between unordered systems.
  final AccessConflictPolicy accessConflictPolicy;

  /// Optional sink for diagnostics (e.g. access-conflict warnings). When the
  /// policy is [AccessConflictPolicy.warn], each conflict is passed here.
  final void Function(String message)? onDiagnostic;

  /// Access conflicts detected across all schedules during [start].
  final List<AccessConflict> accessConflicts = <AccessConflict>[];

  /// True once schedules have been compiled and frozen.
  bool _finalized = false;
  bool _shutdown = false;

  /// Creates an app with the built-in schedules registered.
  App({
    this.accessConflictPolicy = AccessConflictPolicy.warn,
    this.onDiagnostic,
  }) {
    for (final label in Schedules.all) {
      _schedules[label] = Schedule(label);
    }
  }

  /// Registers an additional, custom schedule. Must be called before [start].
  void addSchedule(ScheduleLabel label) {
    _assertOpen();
    _schedules.putIfAbsent(label, () => Schedule(label));
  }

  @override
  AppBuilder addPlugin(Plugin plugin) {
    _assertOpen();
    final type = plugin.runtimeType;
    if (_addedPlugins.contains(type)) return this;
    for (final dependency in plugin.dependencies) {
      if (!_addedPlugins.contains(dependency)) {
        throw StateError(
          'Plugin $type requires $dependency, which has not been added. '
          'Add $dependency before $type.',
        );
      }
    }
    _addedPlugins.add(type);
    plugin.build(this);
    return this;
  }

  @override
  AppBuilder addSystem(
    GameSystem system, {
    required ScheduleLabel schedule,
    required SystemLabel label,
    List<SystemLabel> after = const <SystemLabel>[],
    List<SystemLabel> before = const <SystemLabel>[],
  }) {
    return addSystemAdapter(
      system.createAdapter(),
      schedule: schedule,
      label: label,
      after: after,
      before: before,
    );
  }

  @override
  AppBuilder addSystemAdapter(
    SystemAdapter adapter, {
    required ScheduleLabel schedule,
    required SystemLabel label,
    List<SystemLabel> after = const <SystemLabel>[],
    List<SystemLabel> before = const <SystemLabel>[],
  }) {
    _assertOpen();
    final target = _schedules[schedule];
    if (target == null) {
      throw StateError('Unknown schedule: ${schedule.id}');
    }
    target.add(
      SystemRegistration(
        adapter: adapter,
        label: label,
        after: after,
        before: before,
      ),
    );
    return this;
  }

  @override
  AppBuilder addEvent<T>() {
    _assertOpen();
    world.registerEvent<T>();
    return this;
  }

  @override
  AppBuilder insertResource<T extends Object>(T resource) {
    _assertOpen();
    world.resources.insert<T>(resource);
    return this;
  }

  @override
  AppBuilder addCleanup(FutureOr<void> Function() cleanup) {
    _assertOpen();
    _cleanups.add(cleanup);
    return this;
  }

  /// Compiles and freezes all schedules, initializes every system adapter, then
  /// runs the [Schedules.startup] schedule once.
  void start() {
    if (_finalized) {
      throw StateError('App has already been started.');
    }
    final detect = accessConflictPolicy != AccessConflictPolicy.ignore;
    for (final schedule in _schedules.values) {
      schedule.compile(world, detectConflicts: detect);
      accessConflicts.addAll(schedule.conflicts);
    }
    _reportAccessConflicts();
    _finalized = true;
    runSchedule(Schedules.startup);
  }

  void _reportAccessConflicts() {
    if (accessConflicts.isEmpty) return;
    switch (accessConflictPolicy) {
      case AccessConflictPolicy.ignore:
        return;
      case AccessConflictPolicy.warn:
        final sink = onDiagnostic;
        if (sink != null) {
          for (final conflict in accessConflicts) {
            sink(conflict.toString());
          }
        }
      case AccessConflictPolicy.error:
        throw StateError(
          'Access conflicts detected between unordered systems:\n'
          '${accessConflicts.map((c) => '  - $c').join('\n')}',
        );
    }
  }

  /// Runs the named schedule, then flushes deferred commands.
  void runSchedule(ScheduleLabel label) {
    if (!_finalized) {
      throw StateError('Call start() before running schedules.');
    }
    final schedule = _schedules[label];
    if (schedule == null) {
      throw StateError('Unknown schedule: ${label.id}');
    }
    schedule.run();
    world.commands.apply();
  }

  /// Advances all event channels, reclaiming consumed events. Call once per
  /// frame at a safe boundary (typically frame start).
  void updateEvents() => world.updateEvents();

  /// Runs the [Schedules.shutdown] schedule and all cleanup callbacks once.
  Future<void> shutdown() async {
    if (!_finalized || _shutdown) return;
    _shutdown = true;
    runSchedule(Schedules.shutdown);
    for (var i = _cleanups.length - 1; i >= 0; i--) {
      await _cleanups[i]();
    }
  }

  void _assertOpen() {
    if (_finalized) {
      throw StateError(
        'The app is frozen; systems and schedules cannot be added after '
        'start().',
      );
    }
  }
}
