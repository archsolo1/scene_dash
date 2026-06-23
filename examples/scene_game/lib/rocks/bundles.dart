part of 'rocks.dart';

/// A dynamic rock. Rapier owns its node transform, hence [PhysicsDriven].
///
/// Each rock also carries a hidden flash shell child ([RockVisuals]) used by the
/// hit-reaction system for the visible impact flash.
@Bundle()
final class RockBundle with _$RockBundle {
  final Rock rock;
  final SceneNodeRef node;
  final PhysicsDriven physics;
  final RockVisuals visuals;

  factory RockBundle({required double x, bool flaming = false}) {
    final shell = _makeShell();
    return RockBundle._(SceneNodeRef(_makeNode(x, flaming, shell)), shell);
  }

  RockBundle._(this.node, Node shell)
    : rock = const Rock(),
      physics = const PhysicsDriven(),
      visuals = RockVisuals(shell);

  static final Material _material = PhysicallyBasedMaterial()
    ..baseColorFactor = Vector4(0.42, 0.24, 0.18, 1)
    ..metallicFactor = 0.12
    ..roughnessFactor = 0.48;

  static final Material _flamingMaterial = PhysicallyBasedMaterial()
    ..baseColorFactor = Vector4(0.72, 0.22, 0.08, 1)
    ..emissiveFactor = Vector4(0.18, 0.04, 0.0, 1)
    ..metallicFactor = 0.18
    ..roughnessFactor = 0.26;

  // One shared flash-shell look for every rock: only the shell's transform scale
  // changes per hit, so this material is shared and never mutated per rock.
  static final Material _shellMaterial = PhysicallyBasedMaterial()
    ..baseColorFactor = Vector4(1.0, 0.95, 0.7, 0.5)
    ..emissiveFactor = Vector4(1.2, 1.0, 0.6, 1)
    ..metallicFactor = 0
    ..roughnessFactor = 0.2
    ..alphaMode = AlphaMode.blend;

  // All rocks share one sphere geometry (only the material differs by variant),
  // so build it once instead of per spawn — rocks are the highest-churn entity.
  static final _geometry = SphereGeometry(radius: rockRadius);
  static final _shellGeometry = SphereGeometry(radius: rockRadius * 1.12);

  /// The hidden flash shell, created once per rock at zero scale.
  static Node _makeShell() {
    return Node(
      mesh: Mesh(_shellGeometry, _shellMaterial),
      localTransform: Matrix4.identity()..scaleByDouble(0, 0, 0, 1),
    )..frustumCulled = false;
  }

  static Node _makeNode(double x, bool flaming, Node shell) {
    final node = Node(
      mesh: Mesh(_geometry, flaming ? _flamingMaterial : _material),
      localTransform: Matrix4.translation(Vector3(x, rockSpawnY, rockSpawnZ)),
    )..add(shell);
    // The flame trail is an ECS component + shared instanced pool (see
    // systems.dart), inserted on the entity by SpawnRocksSystem — not a
    // per-rock flutter_scene component here.

    return node
      ..addComponent(
        RapierRigidBody(
          type: BodyType.dynamic_,
          ccdEnabled: true,
          linearVelocity: flaming
              ? Vector3(0, 0, flamingRockForwardVelocity)
              : Vector3.zero(),
          angularVelocity: flaming
              ? Vector3(flamingRockSpinVelocity, 0, 0)
              : Vector3.zero(),
        ),
      )
      ..addComponent(buildRockCollider());
  }
}

/// The collider for a rock, tagged with [PhysicsLayers.rock] so lose-condition
/// checks can classify a physics overlap hit by its collider layer instead of
/// rebuilding a set of every rock each frame. The collision *mask* stays
/// permissive (default) so rock contacts are unchanged.
RapierCollider buildRockCollider() => RapierCollider(
  shape: SphereShape(radius: rockRadius),
  collisionLayer: PhysicsLayers.rock,
);
