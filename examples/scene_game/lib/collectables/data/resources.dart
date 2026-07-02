part of '../collectables.dart';

/// Cadence + RNG for shield-pickup spawns.
final class CollectableSpawner {
  CollectableSpawner({int? seed}) : random = math.Random(seed);

  final math.Random random;
  double _accumulator = 0;

  bool tick(double dt) {
    _accumulator += dt;
    if (_accumulator >= shieldPickupInterval) {
      _accumulator = 0;
      return true;
    }
    return false;
  }

  double nextLane() =>
      (random.nextDouble() * 2 - 1) * shieldPickupSpawnHalfWidth;

  void reset() => _accumulator = 0;
}

/// The single global shield; [ShieldView] lets the HUD read it without
/// depending on the collectables feature.
final class ShieldState implements ShieldView {
  double _remaining = 0;

  @override
  bool get active => _remaining > 0;

  double get remaining => _remaining;

  @override
  double get normalized => (_remaining / shieldDuration).clamp(0.0, 1.0);

  @override
  bool get expiringSoon => active && _remaining <= shieldWarningWindow;

  /// Activates or refreshes the shield to its full duration.
  void activate() => _remaining = shieldDuration;

  void tick(double dt) {
    if (_remaining <= 0) return;
    _remaining -= dt;
    if (_remaining < 0) _remaining = 0;
  }

  /// Deflecting a rock consumes some remaining time.
  void absorbHit() {
    _remaining -= shieldDeflectTimeCost;
    if (_remaining < 0) _remaining = 0;
  }

  void reset() => _remaining = 0;
}

const int _deflectCapacity = 40;
const double _deflectDuration = 0.4;

/// Pooled instanced shield-deflection VFX — no new scene node per deflection.
final class ShieldDeflectVfx {
  InstancedPool? pool;

  final Float32List age = Float32List(_deflectCapacity)
    ..fillRange(0, _deflectCapacity, _deflectDuration);
  final Float32List origin = Float32List(_deflectCapacity * 3);
  int _cursor = 0;

  void emit(Vector3 position) {
    age[_cursor] = 0;
    origin[_cursor * 3] = position.x;
    origin[_cursor * 3 + 1] = position.y;
    origin[_cursor * 3 + 2] = position.z;
    _cursor = (_cursor + 1) % _deflectCapacity;
  }

  void reset() => age.fillRange(0, _deflectCapacity, _deflectDuration);
}
