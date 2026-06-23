/// Physics collision-layer identity, shared across features.
library;

/// Collision-group membership bits for the demo's physics bodies.
///
/// Every body is tagged with its layer ([player] on the player collider,
/// [platform] on the ramp, [rock] on each rock, [collectable] on each pickup),
/// so physics-query results can be classified by collider layer without
/// rebuilding ECS-to-node lookup sets each frame: e.g. the lose-condition system
/// reads `overlapSphere` hits and keeps only colliders whose [rock] bit is set.
/// (Bits also feed Rapier's collision groups; pickups use a [platform]-only mask
/// so they roll on the ramp without rock/player contacts.)
abstract final class PhysicsLayers {
  static const int player = 1 << 0;
  static const int platform = 1 << 1;
  static const int rock = 1 << 2;
  static const int collectable = 1 << 3;
}
