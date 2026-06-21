import 'dart:async';

import '../schedule/schedule_label.dart';
import '../schedule/system_label.dart';
import '../system/game_system.dart';
import '../system/system_adapter.dart';
import 'plugin.dart';

/// The registration surface handed to a [Plugin.build].
///
/// A plugin uses the builder to register systems, declare event channels,
/// insert resources and pull in dependency plugins. It deliberately does *not*
/// expose frame execution — that belongs to the app/scene driver.
abstract interface class AppBuilder {
  /// Registers a `@System` [system] into [schedule] under [label], optionally
  /// constrained to run `after`/`before` other labels.
  ///
  /// The system's generated adapter is obtained via [GameSystem.createAdapter].
  AppBuilder addSystem(
    GameSystem system, {
    required ScheduleLabel schedule,
    required SystemLabel label,
    List<SystemLabel> after,
    List<SystemLabel> before,
  });

  /// Registers a system [adapter] directly. Used by hand-written adapters
  /// (tests, advanced integrations) that do not go through a `@System` class.
  AppBuilder addSystemAdapter(
    SystemAdapter adapter, {
    required ScheduleLabel schedule,
    required SystemLabel label,
    List<SystemLabel> after,
    List<SystemLabel> before,
  });

  /// Declares an event channel for event type [T] (idempotent).
  AppBuilder addEvent<T>();

  /// Inserts (or replaces) the resource instance for type [T].
  AppBuilder insertResource<T extends Object>(T resource);

  /// Registers cleanup to run once when the app shuts down.
  AppBuilder addCleanup(FutureOr<void> Function() cleanup);

  /// Builds [plugin] into this app if it has not already been added.
  AppBuilder addPlugin(Plugin plugin);
}
