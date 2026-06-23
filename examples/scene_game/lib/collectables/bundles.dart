part of 'collectables.dart';

/// A rolling shield pickup: a dynamic Rapier sphere that rolls down the ramp,
/// with a pulsing glow child. Rapier owns the root transform ([PhysicsDriven]);
/// the glow child is animated separately.
///
/// Its collider sits on [PhysicsLayers.collectable] with a mask of only
/// [PhysicsLayers.platform], so it interacts with the ramp but creates no rock,
/// player, or projectile contacts.
@Bundle()
final class ShieldPickupBundle with _$ShieldPickupBundle {
  final Collectable collectable;
  final ShieldPickup shieldPickup;
  final ShieldPickupState state;
  final ShieldPickupVisuals visuals;
  final SceneNodeRef node;
  final PhysicsDriven physics;

  factory ShieldPickupBundle({required double x}) {
    final glow = _makeGlow();
    return ShieldPickupBundle._(SceneNodeRef(_makeNode(x, glow)), glow);
  }

  ShieldPickupBundle._(this.node, Node glow)
    : collectable = const Collectable(),
      shieldPickup = const ShieldPickup(),
      state = ShieldPickupState(),
      visuals = ShieldPickupVisuals(glow),
      physics = const PhysicsDriven();

  static final Material _material = PhysicallyBasedMaterial()
    ..baseColorFactor = Vector4(0.25, 0.7, 1.0, 1)
    ..metallicFactor = 0.32
    ..roughnessFactor = 0.22
    ..emissiveFactor = Vector4(0.1, 0.45, 0.8, 1);
  static final Material _glowMaterial = PhysicallyBasedMaterial()
    ..baseColorFactor = Vector4(0.4, 0.85, 1.0, 0.32)
    ..emissiveFactor = Vector4(0.5, 1.1, 1.5, 1)
    ..metallicFactor = 0
    ..roughnessFactor = 0.2
    ..alphaMode = AlphaMode.blend;

  // All pickups share one geometry/material; build them once, not per spawn.
  static final _geometry = SphereGeometry(radius: collectableRadius);
  static final _glowGeometry = SphereGeometry(radius: collectableRadius * 1.5);

  static Node _makeGlow() => Node(
    mesh: Mesh(_glowGeometry, _glowMaterial),
    localTransform: Matrix4.identity(),
  )..frustumCulled = false;

  static Node _makeNode(double x, Node glow) {
    return Node(
        mesh: Mesh(_geometry, _material),
        localTransform: Matrix4.translation(
          Vector3(x, shieldPickupSpawnY, shieldPickupSpawnZ),
        ),
      )
      ..add(glow)
      ..addComponent(
        RapierRigidBody(
          type: BodyType.dynamic_,
          ccdEnabled: true,
          // A downhill nudge plus a roll so it tumbles down the ramp.
          linearVelocity: Vector3(0, 0, 4),
          angularVelocity: Vector3(3, 0, 0),
        ),
      )
      ..addComponent(
        RapierCollider(
          shape: SphereShape(radius: collectableRadius),
          collisionLayer: PhysicsLayers.collectable,
          collisionMask: PhysicsLayers.platform,
        ),
      );
  }
}
