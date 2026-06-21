import 'package:scene_dash/scene_dash.dart';

/// Scene-free frame dispatcher: maps `flutter_scene` lifecycle callbacks onto
/// Scene-Dash schedules and updates the time resources.
///
/// Kept independent of `flutter_scene` so the frame/fixed/update dispatch is
/// unit-testable without a live `Scene` or GPU. [Game] and the internal scene
/// driver both delegate here.
final class EcsFrameLoop {
  /// The engine this loop drives.
  final App app;

  /// Called at the end of [update] (after `renderSync`, before the scene
  /// renders) — a safe boundary to flush deferred scene-graph mutations.
  final void Function()? onFrameEnd;

  EcsFrameLoop(this.app, {this.onFrameEnd});

  /// Inserts default [FrameTime]/[FixedTime] resources if a plugin has not
  /// already provided them. Call before [App.start].
  void ensureTimeResources() {
    final resources = app.world.resources;
    if (!resources.contains<FrameTime>()) resources.insert(FrameTime());
    if (!resources.contains<FixedTime>()) resources.insert(FixedTime());
  }

  /// Frame start: update [FrameTime], run [Schedules.frameStart], then advance
  /// event channels for the new frame.
  void frameStart(Duration elapsed, double deltaSeconds) {
    app.world.resources.get<FrameTime>()
      ..delta = deltaSeconds
      ..elapsed = elapsed
      ..frame += 1;
    app.runSchedule(Schedules.frameStart);
    app.updateEvents();
  }

  /// Fixed step (before the scene physics step): update [FixedTime] and run
  /// [Schedules.fixedPrePhysics]. May run several times per frame.
  void fixedStep(double fixedDt) {
    app.world.resources.get<FixedTime>()
      ..delta = fixedDt
      ..tick += 1;
    app.runSchedule(Schedules.fixedPrePhysics);
  }

  /// Per-frame update: run [Schedules.update] then [Schedules.renderSync],
  /// then [onFrameEnd] (e.g. flush scene-graph mutations) before render.
  void update(double deltaSeconds) {
    app.world.resources.get<FrameTime>().delta = deltaSeconds;
    app.runSchedule(Schedules.update);
    app.runSchedule(Schedules.renderSync);
    onFrameEnd?.call();
  }
}
