part of '../player.dart';

/// The player: a kinematic sphere driven by Rapier's character controller.
/// [PhysicsDriven] tells the generic transform sync to leave the node alone;
/// the feedback nodes ([PlayerVisuals]) are built once and attached as children.
@Bundle()
final class PlayerBundle with _$PlayerBundle {
  final Player player;
  final SceneNodeRef node;
  final PhysicsDriven physics;
  final PlayerVisuals visuals;

  factory PlayerBundle() {
    final visuals = PlayerVisuals.create();
    return PlayerBundle._(SceneNodeRef(_makeNode(visuals)), visuals);
  }

  PlayerBundle._(this.node, this.visuals)
    : player = const Player(),
      physics = const PhysicsDriven();

  static Node _makeNode(PlayerVisuals visuals) {
    final playerMaterial = PhysicallyBasedMaterial()
      ..baseColorFactor = Vector4(0.05, 0.54, 1.0, 1)
      ..metallicFactor = 0.28
      ..roughnessFactor = 0.18
      ..emissiveFactor = Vector4(0.0, 0.14, 0.32, 1);
    final markerMaterial = PhysicallyBasedMaterial()
      ..baseColorFactor = Vector4(1, 1, 1, 1)
      ..metallicFactor = 0.12
      ..roughnessFactor = 0.2
      ..emissiveFactor = Vector4(0.55, 0.72, 1.0, 1);

    final root =
        Node(
            mesh: Mesh(
              SphereGeometry(radius: playerBodyVisualRadius),
              playerMaterial,
            ),
            localTransform: Matrix4.translation(
              Vector3(0, playerStartY, playerStartZ),
            ),
          )
          ..add(
            Node(
              mesh: Mesh(
                CuboidGeometry(
                  Vector3(0.18, 0.18, playerBodyVisualRadius * 1.6),
                ),
                markerMaterial,
              ),
              localTransform: Matrix4.translation(
                Vector3(0, playerBodyVisualRadius, 0),
              ),
            ),
          )
          ..addComponent(RapierRigidBody(type: BodyType.kinematic))
          ..addComponent(
            RapierCollider(
              shape: SphereShape(radius: playerCollisionRadius),
              collisionLayer: PhysicsLayers.player,
            ),
          )
          ..addComponent(
            RapierKinematicCharacterController(
              up: Vector3(0, 1, 0),
              slide: true,
              snapToGround: 0.5,
              autostep: true,
            ),
          );

    visuals.attachTo(root);
    return root;
  }
}
