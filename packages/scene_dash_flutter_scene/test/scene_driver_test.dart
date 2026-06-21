import 'package:flutter_scene/scene.dart' show Component, Scene;
import 'package:flutter_test/flutter_test.dart';
import 'package:scene_dash/scene_dash.dart';
import 'package:scene_dash_flutter_scene/scene_dash_flutter_scene.dart';
// Driver is intentionally not part of the public API; reach into src to verify
// the flutter_scene Component forwarding.
import 'package:scene_dash_flutter_scene/src/scene_driver.dart';

import 'support.dart';

void main() {
  test('EcsSceneDriver is a flutter_scene Component', () {
    final driver = EcsSceneDriver(EcsFrameLoop(App()));
    expect(driver, isA<Component>());
  });

  test('driver forwards fixedUpdate/update to the loop', () {
    final log = <String>[];
    final app = App()
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
    final loop = EcsFrameLoop(app)..ensureTimeResources();
    app.start();

    final driver = EcsSceneDriver(loop);
    driver.fixedUpdate(0.02);
    expect(log, <String>['fixed']);

    driver.update(0.016);
    expect(log, <String>['fixed', 'update', 'renderSync']);
  });

  test('Game.shutdown runs app shutdown and removes the scene driver',
      skip: 'Constructs a real flutter_scene Scene, which needs Flutter GPU / '
          'Impeller — unavailable under headless `flutter test`. Belongs in an '
          'on-device integration_test.', () async {
    final scene = Scene();
    final game = Game(scene: scene);
    final log = <String>[];
    game.app.addSystemAdapter(
      CountAdapter('shutdown', log),
      schedule: Schedules.shutdown,
      label: const SystemLabel('p.shutdown'),
    );

    await game.start();
    expect(scene.root.getComponent<EcsSceneDriver>(), isNotNull);

    await game.shutdown();
    await game.shutdown();

    expect(log, <String>['shutdown']);
    expect(scene.root.getComponent<EcsSceneDriver>(), isNull);
  });
}
