/// Physics collision-layer identity, shared across features.
library;

import 'package:flutter_scene_rapier/flutter_scene_rapier.dart'
    show RapierCollider;

/// Collision-group membership bits. Every body is tagged with its layer so
/// physics-query results can be classified by collider layer without rebuilding
/// ECS-to-node lookup sets each frame.
abstract final class PhysicsLayers {
  static const int player = 1 << 0;
  static const int platform = 1 << 1;
  static const int rock = 1 << 2;
  static const int collectable = 1 << 3;
}

/// Whether [collider] belongs to [layer]. Overlap queries need this result-side
/// classification because `flutter_scene_rapier` 0.2.x accepts a `layerMask`
/// on overlap queries but does not yet forward it to the native bindings.
bool colliderOnLayer(Object? collider, int layer) =>
    collider is RapierCollider && (collider.collisionLayer & layer) != 0;
