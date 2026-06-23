part of 'projectiles.dart';

@Bundle()
final class ProjectileBundle with _$ProjectileBundle {
  ProjectileBundle({required Vector3 position, double charge = 0})
    : projectile = Projectile(charge: charge),
      node = SceneNodeRef(_makeNode(position, charge));

  final Projectile projectile;
  final SceneNodeRef node;
  final PhysicsDriven physics = const PhysicsDriven();

  // Every projectile is visually identical within its kind, so geometry and
  // materials never change between spawns — build them once and share them
  // instead of rebuilding engine geometry/buffers on each high-churn spawn.
  // Charged strength is shown with transform scale on the visual child, not a
  // per-shot material.
  static final Material _material = PhysicallyBasedMaterial()
    ..baseColorFactor = Vector4(0.5, 0.9, 1.0, 1)
    ..emissiveFactor = Vector4(0.3, 0.85, 1.0, 1)
    ..metallicFactor = 0.08
    ..roughnessFactor = 0.18;
  static final Material _glowMaterial = glowMaterial(
    Vector4(0.38, 0.9, 1.0, 0.42),
    alpha: 0.42,
  );
  static final Material _trailMaterial = glowMaterial(
    Vector4(0.18, 0.55, 1.0, 0.2),
    alpha: 0.2,
  );

  // One shared charged look (a hotter violet-white), distinct from the cyan
  // burst pellet.
  static final Material _chargedMaterial = PhysicallyBasedMaterial()
    ..baseColorFactor = Vector4(0.86, 0.72, 1.0, 1)
    ..emissiveFactor = Vector4(0.72, 0.42, 1.15, 1)
    ..metallicFactor = 0.1
    ..roughnessFactor = 0.16;
  static final Material _chargedGlowMaterial = glowMaterial(
    Vector4(0.8, 0.55, 1.0, 0.5),
    alpha: 0.5,
  );
  static final Material _chargedTrailMaterial = glowMaterial(
    Vector4(0.82, 0.46, 1.0, 0.34),
    alpha: 0.34,
  );

  static final _geometry = SphereGeometry(radius: projectileRadius);
  static final _glowGeometry = SphereGeometry(radius: projectileRadius * 1.35);
  static final _trailGeometry = CuboidGeometry(Vector3(0.07, 0.07, 0.78));

  static Node _makeNode(Vector3 position, double charge) {
    final scale = charge > 0 ? chargedProjectileScale(charge) : 1.0;
    final mainMaterial = charge > 0 ? _chargedMaterial : _material;
    final glowMat = charge > 0 ? _chargedGlowMaterial : _glowMaterial;
    final trailMat = charge > 0 ? _chargedTrailMaterial : _trailMaterial;
    final colliderRadius = projectileRadius * scale;
    final trailThickness = charge > 0 ? scale * 1.8 : 1.0;
    final trailLength = charge > 0 ? scale * 2.4 : 1.0;
    final trailOffsetZ = charge > 0 ? 0.38 * trailLength : 0.38;

    // The visual is a child of the physics-driven root: the integration writes
    // the root's local transform (translation + rotation) from the Rapier body
    // every frame, which would erase a root scale, so the charged size lives on
    // this untouched child instead.
    final visual =
        Node(
            mesh: Mesh(_geometry, mainMaterial),
            localTransform: Matrix4.identity()
              ..scaleByDouble(scale, scale, scale, 1),
          )
          ..frustumCulled = false
          ..add(Node(mesh: Mesh(_glowGeometry, glowMat))..frustumCulled = false)
          ..add(
            Node(
              mesh: Mesh(_trailGeometry, trailMat),
              localTransform: Matrix4.translation(Vector3(0, 0, trailOffsetZ))
                ..scaleByDouble(trailThickness, trailThickness, trailLength, 1),
            )..frustumCulled = false,
          );

    return Node(localTransform: Matrix4.translation(position))
      ..frustumCulled = false
      ..add(visual)
      ..addComponent(
        RapierRigidBody(
          type: BodyType.dynamic_,
          mass: 0.04,
          ccdEnabled: true,
          linearVelocity: Vector3(0, projectileLaunchUp, -projectileSpeed),
          linearDamping: 0,
        ),
      )
      ..addComponent(
        RapierCollider(
          shape: SphereShape(radius: colliderRadius),
          isTrigger: true,
        ),
      );
  }
}
