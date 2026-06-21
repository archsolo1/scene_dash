import 'dart:math' as math;

import 'package:vector_math/vector_math.dart' show Matrix4, Vector3;

import 'config.dart';

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

final class ImpactMotion {
  final Vector3 position = Vector3.zero();
  final Vector3 velocity = Vector3.zero();
  double spin = 0;
  bool active = false;

  void start({required Vector3 playerPosition, required Vector3 rockPosition}) {
    final away = playerPosition - rockPosition;
    away.y = 0;
    if (away.length2 < 0.001) {
      away.setValues(0, 0, 1);
    } else {
      away.normalize();
    }

    active = true;
    spin = 0;
    position.setFrom(playerPosition);
    velocity.setValues(
      away.x * knockbackHorizontal,
      knockbackUp,
      away.z * knockbackHorizontal,
    );
  }

  void reset() {
    active = false;
    spin = 0;
    position.setZero();
    velocity.setZero();
  }

  void advance(double dt) {
    if (!active) return;
    velocity.y -= impactGravity * dt;
    position
      ..x += velocity.x * dt
      ..y += velocity.y * dt
      ..z += velocity.z * dt;
    spin += impactSpinSpeed * dt;
  }

  Matrix4 transform() {
    return Matrix4.translation(position)
      ..rotateX(spin)
      ..rotateZ(spin * 0.65);
  }
}
