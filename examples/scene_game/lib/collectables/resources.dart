part of 'collectables.dart';

/// Cadence + RNG for shield-pickup spawns. The spawn system gates on an
/// [OptionalSingle] so at most one pickup is active; the spawner only advances
/// while no pickup exists, so a new one appears [shieldPickupInterval] seconds
/// after the previous one is gone.
final class CollectableSpawner {
  CollectableSpawner({int? seed}) : random = math.Random(seed);

  final math.Random random;
  double _accumulator = 0;

  /// Advances the timer; returns whether a spawn is due this step.
  bool tick(double dt) {
    _accumulator += dt;
    if (_accumulator >= shieldPickupInterval) {
      _accumulator = 0;
      return true;
    }
    return false;
  }

  /// A random X within the pickup spawn band.
  double nextLane() =>
      (random.nextDouble() * 2 - 1) * shieldPickupSpawnHalfWidth;

  void reset() => _accumulator = 0;
}

/// The single global shield. A resource because this example has exactly one
/// player and one active shield. Implements [ShieldView] so the HUD can read it
/// without depending on the collectables feature.
final class ShieldState implements ShieldView {
  double _remaining = 0;

  @override
  bool get active => _remaining > 0;

  /// Seconds of shield left (ShieldState-specific; not part of [ShieldView]).
  double get remaining => _remaining;

  @override
  double get normalized => (_remaining / shieldDuration).clamp(0.0, 1.0);

  @override
  bool get expiringSoon => active && _remaining <= shieldWarningWindow;

  /// Collection activates or refreshes the shield to its full duration.
  void activate() => _remaining = shieldDuration;

  /// Counts the shield down; never below zero.
  void tick(double dt) {
    if (_remaining <= 0) return;
    _remaining -= dt;
    if (_remaining < 0) _remaining = 0;
  }

  /// Deflecting a rock consumes a small amount of remaining time.
  void absorbHit() {
    _remaining -= shieldDeflectTimeCost;
    if (_remaining < 0) _remaining = 0;
  }

  void reset() => _remaining = 0;
}

const int _deflectCapacity = 40;
const double _deflectDuration = 0.4;

/// Pooled instanced shield-deflection VFX: one [InstancedPool], one node, one
/// draw call — no new scene node per deflection.
final class ShieldDeflectVfx {
  /// Built by `spawnShieldDeflectVfx`; null until then.
  InstancedPool? pool;

  final Float32List age = Float32List(_deflectCapacity)
    ..fillRange(0, _deflectCapacity, _deflectDuration);
  final Float32List origin = Float32List(_deflectCapacity * 3);
  int _cursor = 0;

  /// Records a deflection burst at [position] into a recycled slot.
  void emit(Vector3 position) {
    age[_cursor] = 0;
    origin[_cursor * 3] = position.x;
    origin[_cursor * 3 + 1] = position.y;
    origin[_cursor * 3 + 2] = position.z;
    _cursor = (_cursor + 1) % _deflectCapacity;
  }

  void reset() => age.fillRange(0, _deflectCapacity, _deflectDuration);
}
