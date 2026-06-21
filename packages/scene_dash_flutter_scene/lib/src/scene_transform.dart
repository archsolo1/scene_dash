import 'package:scene_dash/scene_dash.dart';
import 'package:vector_math/vector_math.dart' show Quaternion, Vector3;

/// The standard transform component the bridge synchronizes onto bound nodes.
///
/// Holds a node-local translation, rotation and scale. Named `SceneTransform`
/// (not `Transform`) to avoid colliding with Flutter's `Transform` widget.
/// Games that already have their own transform type can use
/// `CustomSceneSyncPlugin<T>` instead.
@ObjectComponent()
final class SceneTransform {
  /// Node-local position.
  final Vector3 translation;

  /// Node-local orientation.
  final Quaternion rotation;

  /// Node-local scale.
  final Vector3 scale;

  SceneTransform(double x, double y, double z)
      : translation = Vector3(x, y, z),
        rotation = Quaternion.identity(),
        scale = Vector3.all(1);

  SceneTransform.zero() : this(0, 0, 0);

  SceneTransform.fromVector(Vector3 position)
      : translation = position.clone(),
        rotation = Quaternion.identity(),
        scale = Vector3.all(1);

  SceneTransform.trs({
    Vector3? translation,
    Quaternion? rotation,
    Vector3? scale,
  })  : translation = translation?.clone() ?? Vector3.zero(),
        rotation = rotation?.clone() ?? Quaternion.identity(),
        scale = scale?.clone() ?? Vector3.all(1);

  double get x => translation.x;

  set x(double value) {
    translation.x = value;
  }

  double get y => translation.y;

  set y(double value) {
    translation.y = value;
  }

  double get z => translation.z;

  set z(double value) {
    translation.z = value;
  }

  SceneTransform setTranslation(double x, double y, double z) {
    translation.setValues(x, y, z);
    return this;
  }

  SceneTransform setScale(double x, double y, double z) {
    scale.setValues(x, y, z);
    return this;
  }

  SceneTransform setUniformScale(double value) {
    scale.setValues(value, value, value);
    return this;
  }

  SceneTransform setRotationIdentity() {
    rotation.setValues(0, 0, 0, 1);
    return this;
  }
}
