import 'package:flutter_scene/scene.dart';
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

  test('onBeforeUpdate fires before the update schedule (mount point)', () {
    final log = <String>[];
    final app = _appWithProbes(log);
    final loop = EcsFrameLoop(
      app,
      onBeforeUpdate: () => log.add('mount'),
      onFrameEnd: () => log.add('flush'),
    )..ensureTimeResources();
    app.start();

    loop.update(0.016);
    expect(log, <String>['mount', 'update', 'renderSync', 'flush']);
  });

  test('onCommandBoundary fires after frameStart commands', () {
    final log = <String>[];
    final app = _appWithProbes(log);
    final loop = EcsFrameLoop(app, onCommandBoundary: () => log.add('mount'))
      ..ensureTimeResources();
    app.start();

    loop.frameStart(const Duration(milliseconds: 16), 0.016);
    expect(log, <String>['frameStart', 'mount']);
  });

  test('mounts startup-spawned scene nodes before the first frame', () {
    final root = Node();
    final node = Node();
    final app = App()
      ..addSystemAdapter(
        _SpawnNodeAdapter(node),
        schedule: Schedules.startup,
        label: const SystemLabel('spawn.startup.node'),
      );
    final commands = SceneCommands(root);
    final mount = SceneNodeMountAdapter(commands, <Node, Entity>{});

    app.start();
    mount
      ..initialize(app.world)
      ..run();
    commands.flush();

    expect(node.parent, same(root));
  });

  test('mounts frameStart-spawned scene nodes at the frame boundary', () {
    final root = Node();
    final node = Node();
    final app = App()
      ..addSystemAdapter(
        _SpawnNodeAdapter(node),
        schedule: Schedules.frameStart,
        label: const SystemLabel('spawn.frameStart.node'),
      );
    final commands = SceneCommands(root);
    final mount = SceneNodeMountAdapter(commands, <Node, Entity>{});
    final loop = EcsFrameLoop(
      app,
      onCommandBoundary: () {
        mount.run();
        commands.flush();
      },
    )..ensureTimeResources();

    app.start();
    mount.initialize(app.world);
    loop.frameStart(const Duration(milliseconds: 16), 0.016);

    expect(node.parent, same(root));
  });

  test('mounts fixedPrePhysics-spawned scene nodes before physics returns', () {
    final root = Node();
    final node = Node();
    final app = App()
      ..addSystemAdapter(
        _SpawnNodeAdapter(node),
        schedule: Schedules.fixedPrePhysics,
        label: const SystemLabel('spawn.fixed.node'),
      );
    final commands = SceneCommands(root);
    final mount = SceneNodeMountAdapter(commands, <Node, Entity>{});
    final loop = EcsFrameLoop(
      app,
      onCommandBoundary: () {
        mount.run();
        commands.flush();
      },
    )..ensureTimeResources();

    app.start();
    mount.initialize(app.world);
    loop.fixedStep(1 / 60);

    expect(node.parent, same(root));
  });

  test('mounts update-spawned scene nodes before renderSync', () {
    final root = Node();
    final node = Node();
    final app = App()
      ..addSystemAdapter(
        _SpawnNodeAdapter(node),
        schedule: Schedules.update,
        label: const SystemLabel('spawn.update.node'),
      )
      ..addSystemAdapter(
        _ExpectParentAdapter(node, root),
        schedule: Schedules.renderSync,
        label: const SystemLabel('expect.renderSync.node'),
      );
    final commands = SceneCommands(root);
    final mount = SceneNodeMountAdapter(commands, <Node, Entity>{});
    final loop = EcsFrameLoop(
      app,
      onCommandBoundary: () {
        mount.run();
        commands.flush();
      },
    )..ensureTimeResources();

    app.start();
    mount.initialize(app.world);
    loop.update(0.016);
  });
}

final class _SpawnNodeAdapter implements SystemAdapter {
  _SpawnNodeAdapter(this.node);

  final Node node;
  late World _world;

  @override
  void initialize(World world) {
    _world = world;
  }

  @override
  void run() {
    _world.commands.spawn(_NodeBundle(node));
  }
}

final class _ExpectParentAdapter implements SystemAdapter {
  _ExpectParentAdapter(this.node, this.expectedParent);

  final Node node;
  final Node expectedParent;

  @override
  void initialize(World world) {}

  @override
  void run() {
    expect(node.parent, same(expectedParent));
  }
}

final class _NodeBundle implements SceneDashBundle {
  const _NodeBundle(this.node);

  final Node node;

  @override
  void insertInto(World world, Entity entity) {
    world.ensureObjectStore<SceneNodeRef>();
    world.insertNow<SceneNodeRef>(entity, SceneNodeRef(node));
  }
}
