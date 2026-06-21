import 'package:flutter_scene/scene.dart';
import 'package:flutter_scene_rapier/flutter_scene_rapier.dart';
import 'package:scene_dash/scene_dash.dart';
import 'package:vector_math/vector_math.dart' show Matrix4, Vector3, Vector4;

import '../game/config.dart';

part 'world.g.dart';

/// Installs world setup: lighting, post-processing, and the ramp.
@GamePlugin()
final class WorldPlugin extends Plugin {
  const WorldPlugin();

  @override
  void build(AppBuilder app) {
    app.addSystem(
      const SetupWorldSystem(),
      schedule: Schedules.startup,
      label: const SystemLabel('world.setup'),
    );
  }
}

/// Startup system: configures the scene look and builds the static ramp.
///
/// Scene-wide setup is native `flutter_scene` work done directly on the
/// `@Resource() Scene`. The ramp is a plain scene node, not an ECS entity: it
/// never moves, so it carries a fixed Rapier body and matching box collider.
@System()
final class SetupWorldSystem extends GameSystem with _$SetupWorldSystem {
  const SetupWorldSystem();

  void run(@Resource() Scene scene) {
    // Shadows and cross-stripes make the slope read clearly instead of as a
    // flat grey box.
    scene
      ..skybox = Skybox(GradientSkySource())
      ..environment = EnvironmentMap.studio()
      ..directionalLight = DirectionalLight(
        direction: Vector3(-0.45, -1.0, -0.35),
        color: Vector3(1.0, 0.96, 0.88),
        intensity: 4,
        castsShadow: true,
      )
      ..exposure = 1.1;
    scene.postProcess.bloom
      ..enabled = true
      ..threshold = 1.1
      ..intensity = 0.35;
    scene.postProcess.vignette
      ..enabled = true
      ..intensity = 0.3;

    final ramp =
        Node(
            mesh: Mesh(
              CuboidGeometry(Vector3(rampWidth, rampThickness, rampLength)),
              PhysicallyBasedMaterial()
                ..baseColorFactor = Vector4(0.30, 0.33, 0.38, 1)
                ..metallicFactor = 0
                ..roughnessFactor = 0.85,
            ),
            localTransform: Matrix4.rotationX(rampInclineRadians),
          )
          ..addComponent(RapierRigidBody(type: BodyType.fixed))
          ..addComponent(
            RapierCollider(
              shape: BoxShape(
                halfExtents: Vector3(
                  rampWidth / 2,
                  rampThickness / 2,
                  rampLength / 2,
                ),
              ),
            ),
          );

    _addLaneStripes(ramp);
    scene.root.add(ramp);
  }

  /// Bright cross-stripes painted on the ramp surface.
  void _addLaneStripes(Node ramp) {
    final stripe = PhysicallyBasedMaterial()
      ..baseColorFactor = Vector4(0.9, 0.85, 0.5, 1)
      ..roughnessFactor = 0.6
      ..emissiveFactor = Vector4(0.25, 0.22, 0.08, 1);
    const count = 7;
    final geometry = CuboidGeometry(Vector3(rampWidth * 0.94, 0.06, 0.35));
    for (var i = 1; i < count; i++) {
      final z = -rampLength / 2 + rampLength * i / count;
      ramp.add(
        Node(
          mesh: Mesh(geometry, stripe),
          localTransform: Matrix4.translation(
            Vector3(0, rampThickness / 2 + 0.04, z),
          ),
        ),
      );
    }
  }
}
