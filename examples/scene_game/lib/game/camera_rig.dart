import 'dart:math' as math;

import 'package:vector_math/vector_math.dart' show Vector3;

import '../world/data/config.dart';

final class CameraRig {
  final Vector3 position = Vector3(0, 12, 24);
  final Vector3 target = Vector3(0, 0, -2);

  void reset() {
    position.setValues(0, 12, 24);
    target.setValues(0, 0, -2);
  }

  void follow(Vector3 playerPosition, double dt) {
    final desiredTarget = Vector3(
      playerPosition.x * 0.55,
      playerPosition.y + 0.7,
      playerPosition.z - 2.8,
    );
    final desiredPosition = Vector3(
      playerPosition.x * 0.65,
      playerPosition.y + 10,
      playerPosition.z + 18,
    );
    final alpha = math.min(1.0, dt * cameraFollowSharpness);
    _lerpInto(target, desiredTarget, alpha);
    _lerpInto(position, desiredPosition, alpha);
  }

  void _lerpInto(Vector3 value, Vector3 target, double alpha) {
    value
      ..x += (target.x - value.x) * alpha
      ..y += (target.y - value.y) * alpha
      ..z += (target.z - value.z) * alpha;
  }
}
