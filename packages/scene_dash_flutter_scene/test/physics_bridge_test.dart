import 'dart:async';

import 'package:flutter_scene/scene.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scene_dash/scene_dash.dart';
import 'package:scene_dash_flutter_scene/scene_dash_flutter_scene.dart';

/// Minimal fake world: only the collision stream and lifecycle hooks are real;
/// query methods are unused and forwarded to [noSuchMethod].
final class _FakeWorld extends PhysicsWorld {
  final controller = StreamController<CollisionEvent>.broadcast();

  @override
  String get backendName => 'fake';

  @override
  Stream<CollisionEvent> get collisions => controller.stream;

  @override
  void step(double fixedDt) {}

  @override
  void interpolateTransforms(double alpha) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _Collider extends Component {}

CollisionBegan _collision() => CollisionBegan(
      nodeA: Node(),
      nodeB: Node(),
      colliderA: _Collider(),
      colliderB: _Collider(),
      contacts: const [],
    );

void main() {
  test('PhysicsEventBridge subscribes on start and disposes idempotently',
      () async {
    final world = _FakeWorld();
    final bridge = PhysicsEventBridge(world);
    expect(world.controller.hasListener, isFalse);

    bridge
      ..start()
      ..start();
    expect(world.controller.hasListener, isTrue);

    world.controller.add(_collision());
    await Future<void>.delayed(Duration.zero);
    expect(bridge.pending, 1);

    await bridge.dispose();
    await bridge.dispose();
    expect(bridge.pending, 0);
    expect(world.controller.hasListener, isFalse);

    await world.controller.close();
  });

  test('PhysicsPlugin exposes the world as an injectable resource', () {
    final world = _FakeWorld();
    final app = App()..addPlugin(PhysicsPlugin(world));
    app.start();
    expect(identical(app.world.resources.get<PhysicsWorld>(), world), isTrue);
    addTearDown(() async {
      await app.shutdown();
      await world.controller.close();
    });
  });

  test('buffers collisions and drains them into ECS events on frameStart',
      () async {
    final world = _FakeWorld();
    final app = App()..addPlugin(PhysicsPlugin(world));
    app.start();
    final reader = app.world.eventChannel<CollisionEvent>().reader();

    world.controller
      ..add(_collision())
      ..add(_collision());
    await Future<void>.delayed(Duration.zero); // let the stream deliver

    final bridge = app.world.resources.get<PhysicsEventBridge>();
    expect(bridge.pending, 2, reason: 'buffered, not yet published');

    app.runSchedule(Schedules.frameStart); // drain system runs
    expect(bridge.pending, 0);

    final events = reader.drain();
    expect(events, hasLength(2));
    expect(events.first, isA<CollisionBegan>());

    await world.controller.close();
  });

  test('shutdown cancels the physics subscription and clears pending events',
      () async {
    final world = _FakeWorld();
    final app = App()..addPlugin(PhysicsPlugin(world));
    app.start();
    expect(world.controller.hasListener, isTrue);

    final bridge = app.world.resources.get<PhysicsEventBridge>();
    world.controller.add(_collision());
    await Future<void>.delayed(Duration.zero);
    expect(bridge.pending, 1);

    await app.shutdown();
    await app.shutdown();

    expect(bridge.pending, 0);
    expect(world.controller.hasListener, isFalse);

    await world.controller.close();
  });
}
