import 'package:flutter_scene/scene.dart' show CollisionEvent, PhysicsWorld;
import 'package:scene_dash/scene_dash.dart';

import 'physics_event_bridge.dart';

/// Optional bridge from one generic `flutter_scene` [PhysicsWorld] into the ECS.
///
/// It does **not** attach the world to the scene graph — the app owns that, as
/// the `flutter_scene` examples do:
///
/// ```dart
/// final physics = BasicPhysicsWorld(); // or a backend world
/// scene.root.addComponent(physics);
/// game.addPlugin(PhysicsPlugin(physics));
/// ```
///
/// The plugin:
///
/// * inserts the [PhysicsWorld] as a resource (for raycasts / overlap queries
///   from systems via `@Resource()`);
/// * registers a raw [CollisionEvent] channel;
/// * buffers the world's collision stream and drains it into that channel each
///   frame (in [Schedules.frameStart]) so systems read collisions with
///   `EventReader<CollisionEvent>`.
///
/// Same-substep collision delivery is not promised. Games that need entity
/// mapping or gameplay-specific collision events can define their own resources
/// and event types on top of the native physics world.
final class PhysicsPlugin extends Plugin {
  /// The physics world to bridge.
  final PhysicsWorld world;

  /// Label of the generated drain system.
  final SystemLabel drainLabel;

  PhysicsPlugin(
    this.world, {
    this.drainLabel = const SystemLabel('physics.drainEvents'),
  });

  @override
  void build(AppBuilder app) {
    final bridge = PhysicsEventBridge(world);
    app
      ..insertResource<PhysicsWorld>(world)
      ..insertResource<PhysicsEventBridge>(bridge)
      ..addEvent<CollisionEvent>()
      ..addSystemAdapter(
        _DrainPhysicsEventsAdapter(),
        schedule: Schedules.frameStart,
        label: drainLabel,
      )
      ..addCleanup(bridge.dispose);
  }
}

/// Hand-written adapter that flushes buffered collisions into the ECS event
/// channel each frame.
final class _DrainPhysicsEventsAdapter implements SystemAdapter {
  late final EventWriter<CollisionEvent> _writer;
  late final PhysicsEventBridge _bridge;

  @override
  void initialize(World world) {
    _writer = world.eventChannel<CollisionEvent>().writer();
    _bridge = world.resources.get<PhysicsEventBridge>()..start();
  }

  @override
  void run() => _bridge.drainTo(_writer);
}
