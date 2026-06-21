import 'package:flutter_test/flutter_test.dart';
import 'package:scene_dash/scene_dash.dart';
import 'package:scene_dash_flutter_scene/scene_dash_flutter_scene.dart';

import 'support.dart';

App _appWithProbes(List<String> log) {
  return App()
    ..addSystemAdapter(
      CountAdapter('frameStart', log),
      schedule: Schedules.frameStart,
      label: const SystemLabel('p.frameStart'),
    )
    ..addSystemAdapter(
      CountAdapter('fixed', log),
      schedule: Schedules.fixedPrePhysics,
      label: const SystemLabel('p.fixed'),
    )
    ..addSystemAdapter(
      CountAdapter('update', log),
      schedule: Schedules.update,
      label: const SystemLabel('p.update'),
    )
    ..addSystemAdapter(
      CountAdapter('renderSync', log),
      schedule: Schedules.renderSync,
      label: const SystemLabel('p.renderSync'),
    );
}

void main() {
  test('ensureTimeResources inserts defaults only when absent', () {
    final app = App();
    EcsFrameLoop(app).ensureTimeResources();
    expect(app.world.resources.contains<FrameTime>(), isTrue);
    expect(app.world.resources.contains<FixedTime>(), isTrue);

    // A pre-existing resource is not replaced.
    final app2 = App();
    final mine = FixedTime()..delta = 0.123;
    app2.world.resources.insert<FixedTime>(mine);
    EcsFrameLoop(app2).ensureTimeResources();
    expect(identical(app2.world.resources.get<FixedTime>(), mine), isTrue);
  });

  test('frameStart updates FrameTime and runs the frameStart schedule', () {
    final log = <String>[];
    final app = _appWithProbes(log);
    final loop = EcsFrameLoop(app)..ensureTimeResources();
    app.start();

    loop.frameStart(const Duration(milliseconds: 16), 0.016);
    final ft = app.world.resources.get<FrameTime>();
    expect(ft.frame, 1);
    expect(ft.delta, 0.016);
    expect(ft.elapsed, const Duration(milliseconds: 16));
    expect(log, <String>['frameStart']);
  });

  test('fixedStep updates FixedTime and runs fixedPrePhysics', () {
    final log = <String>[];
    final app = _appWithProbes(log);
    final loop = EcsFrameLoop(app)..ensureTimeResources();
    app.start();

    loop
      ..fixedStep(0.02)
      ..fixedStep(0.02);
    final t = app.world.resources.get<FixedTime>();
    expect(t.tick, 2);
    expect(t.delta, 0.02);
    expect(log, <String>['fixed', 'fixed']);
  });

  test('update runs update then renderSync in order', () {
    final log = <String>[];
    final app = _appWithProbes(log);
    final loop = EcsFrameLoop(app)..ensureTimeResources();
    app.start();

    loop.update(0.016);
    expect(log, <String>['update', 'renderSync']);
  });

  test('onFrameEnd fires after renderSync (scene-command flush point)', () {
    final log = <String>[];
    final app = _appWithProbes(log);
    final loop = EcsFrameLoop(app, onFrameEnd: () => log.add('flush'))
      ..ensureTimeResources();
    app.start();

    loop.update(0.016);
    expect(log, <String>['update', 'renderSync', 'flush']);
  });
}
