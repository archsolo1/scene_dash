import 'schedule_label.dart';

/// The built-in frame schedules, in their conceptual execution order.
///
/// There is intentionally no public `fixedPostPhysics` schedule until
/// `flutter_scene` exposes a stable post-step lifecycle hook.
abstract final class Schedules {
  /// Runs once, before the first frame.
  static const ScheduleLabel startup = ScheduleLabel('startup');

  /// Runs at the very start of each rendered frame (`SceneView.onTick`).
  static const ScheduleLabel frameStart = ScheduleLabel('frameStart');

  /// Runs each fixed step, before the scene's physics step.
  static const ScheduleLabel fixedPrePhysics = ScheduleLabel('fixedPrePhysics');

  /// Runs each frame after interpolation, during the scene component update.
  static const ScheduleLabel update = ScheduleLabel('update');

  /// Runs each frame after [update]; bridges ECS state into the scene graph.
  static const ScheduleLabel renderSync = ScheduleLabel('renderSync');

  /// Runs once, during teardown.
  static const ScheduleLabel shutdown = ScheduleLabel('shutdown');

  /// All built-in schedules in execution order.
  static const List<ScheduleLabel> all = <ScheduleLabel>[
    startup,
    frameStart,
    fixedPrePhysics,
    update,
    renderSync,
    shutdown,
  ];
}
