part of '../rocks.dart';

/// A dynamic rock. Rapier owns its node transform, hence [PhysicsDriven]. Each
/// rock carries a hidden flash shell child ([RockVisuals]) for the hit flash.
@Bundle()
final class RockBundle with _$RockBundle {
  final Rock rock;
  final SceneNodeRef node;
  final PhysicsDriven physics;
  final RockVisuals visuals;

  /// Every rock is scoped to the run: exiting `playing` despawns it.
  final DespawnOnExit scope;

  factory RockBundle({required double x, bool flaming = false}) {
    final shell = _makeShell();
    return RockBundle._(SceneNodeRef(_makeNode(x, flaming, shell)), shell);
  }

  RockBundle._(this.node, Node shell)
    : rock = const Rock(),
      physics = const PhysicsDriven(),
      visuals = RockVisuals(shell),
      scope = const DespawnOnExit(GameStatus.playing);

  static final Material _material = PhysicallyBasedMaterial()
    ..baseColorFactor = Vector4(0.42, 0.24, 0.18, 1)
    ..metallicFactor = 0.12
    ..roughnessFactor = 0.48;

  static final Material _flamingMaterial = PhysicallyBasedMaterial()
    ..baseColorFactor = Vector4(0.72, 0.22, 0.08, 1)
    ..emissiveFactor = Vector4(0.18, 0.04, 0.0, 1)
    ..metallicFactor = 0.18
    ..roughnessFactor = 0.26;

  // Only the shell's transform scale changes per hit, so this material is
  // shared and never mutated per rock.
  static final Material _shellMaterial = PhysicallyBasedMaterial()
    ..baseColorFactor = Vector4(1.0, 0.95, 0.7, 0.5)
    ..emissiveFactor = Vector4(1.2, 1.0, 0.6, 1)
    ..metallicFactor = 0
    ..roughnessFactor = 0.2
    ..alphaMode = AlphaMode.blend;

  // Built once, not per spawn — rocks are the highest-churn entity.
  static final _geometry = SphereGeometry(radius: rockRadius);
  static final _shellGeometry = SphereGeometry(radius: rockRadius * 1.12);

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

/// Tagged with [PhysicsLayers.rock] so overlap hits can be classified by
/// collider layer; the collision *mask* stays permissive (default).
RapierCollider buildRockCollider() => RapierCollider(
  shape: SphereShape(radius: rockRadius),
  collisionLayer: PhysicsLayers.rock,
);
