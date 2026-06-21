import 'dart:async';

import 'package:flutter_scene/scene.dart' show CollisionEvent, PhysicsWorld;
import 'package:scene_dash/scene_dash.dart';

/// Buffers a [PhysicsWorld]'s collision stream so it can be republished as ECS
/// events on the schedule clock.
///
/// `flutter_scene` delivers collisions through an async [Stream]; ECS systems
/// read synchronously via `EventReader`. This bridge subscribes once and
/// accumulates events, and [drainTo] moves them into an ECS event channel when
/// a system runs. The initial implementation does **not** promise same-substep
/// delivery — events surface on the next drain.
final class PhysicsEventBridge {
  /// The physics world whose collisions are bridged.
  final PhysicsWorld world;

  List<CollisionEvent> _buffer = <CollisionEvent>[];
  StreamSubscription<CollisionEvent>? _subscription;

  PhysicsEventBridge(this.world);

  /// Number of events currently buffered.
  int get pending => _buffer.length;

  /// Starts listening to the physics world's collision stream.
  void start() {
    if (_subscription != null) return;
    _subscription = world.collisions.listen(_buffer.add);
  }

  /// Sends all buffered events to [writer] and clears the buffer.
  void drainTo(EventWriter<CollisionEvent> writer) {
    if (_buffer.isEmpty) return;
    final pending = _buffer;
    _buffer = <CollisionEvent>[];
    for (var i = 0; i < pending.length; i++) {
      writer.send(pending[i]);
    }
  }

  /// Cancels the collision-stream subscription.
  Future<void> dispose() async {
    final subscription = _subscription;
    _subscription = null;
    _buffer.clear();
    await subscription?.cancel();
  }
}
