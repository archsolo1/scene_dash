part of '../projectiles.dart';

enum BlasterPhase { ready, charging, bursting, cooldown }

/// Shots to spawn after advancing the [Blaster] one fixed step.
final class BlasterShots {
  const BlasterShots({this.burst = 0, this.charged});

  final int burst;

  /// Charged-shot strength in [0, 1], or null for none.
  final double? charged;

  bool get isEmpty => burst == 0 && charged == null;

  static const none = BlasterShots();
}

/// Tap-to-burst / hold-to-charge fire state machine; the HUD and charge VFX
/// read it through [BlasterView].
final class Blaster implements BlasterView {
  BlasterPhase _phase = BlasterPhase.ready;

  double _charge = 0;
  double _cooldown = 0;
  double _cooldownDuration = 0;

  int _queuedBurst = 0;
  double _burstTimer = 0;

  BlasterPhase get phase => _phase;

  @override
  double get charge01 {
    if (_phase != BlasterPhase.charging) return 0;
    const span = blasterMaxChargeDuration - blasterChargeThreshold;
    return ((_charge - blasterChargeThreshold) / span).clamp(0.0, 1.0);
  }

  @override
  double get cooldown01 {
    if (_cooldownDuration <= 0) return 0;
    return (_cooldown / _cooldownDuration).clamp(0.0, 1.0);
  }

  @override
  bool get isCharging =>
      _phase == BlasterPhase.charging && _charge >= blasterChargeThreshold;

  bool get isCoolingDown => _cooldown > 0;

  @override
  bool get isReady => _phase == BlasterPhase.ready;

  /// Advances the blaster one fixed step and returns the shots to spawn.
  BlasterShots update({
    required bool pressed,
    required bool released,
    required bool canceled,
    required bool held,
    required double dt,
  }) {
    // Counts down through both bursting and cooldown phases, so total recovery
    // after firing is one _cooldownDuration.
    if (_cooldown > 0) {
      _cooldown -= dt;
      if (_cooldown < 0) _cooldown = 0;
    }
    if (_phase == BlasterPhase.cooldown && _cooldown == 0) {
      _phase = BlasterPhase.ready;
    }

    double? charged;

    if (pressed && _phase == BlasterPhase.ready) {
      _phase = BlasterPhase.charging;
      _charge = 0;
    }

    if (_phase == BlasterPhase.charging) {
      if (canceled) {
        _phase = BlasterPhase.ready;
        _charge = 0;
      } else if (released) {
        if (_charge >= blasterChargeThreshold) {
          charged = charge01;
          _charge = 0;
          _startCooldown(chargedShotCooldown);
        } else {
          _charge = 0;
          _startBurst();
        }
      } else if (held) {
        _charge += dt;
        if (_charge > blasterMaxChargeDuration) {
          _charge = blasterMaxChargeDuration;
        }
      } else {
        // Held dropped with no transition flag (focus loss mid-step): abort so
        // the blaster can't get stuck charging.
        _phase = BlasterPhase.ready;
        _charge = 0;
      }
    }

    final burst = _emitBurstPellets(dt);
    if (charged != null) return BlasterShots(charged: charged);
    if (burst > 0) return BlasterShots(burst: burst);
    return BlasterShots.none;
  }

  void _startBurst() {
    _phase = BlasterPhase.bursting;
    _queuedBurst = blasterBurstShots;
    _burstTimer = 0;
    _cooldown = blasterCooldown;
    _cooldownDuration = blasterCooldown;
  }

  void _startCooldown(double duration) {
    _phase = BlasterPhase.cooldown;
    _cooldown = duration;
    _cooldownDuration = duration;
  }

  int _emitBurstPellets(double dt) {
    if (_phase != BlasterPhase.bursting) return 0;
    var fired = 0;
    _burstTimer -= dt;
    while (_queuedBurst > 0 && _burstTimer <= 0) {
      _queuedBurst--;
      fired++;
      _burstTimer += blasterBurstInterval;
    }
    if (_queuedBurst == 0) {
      _phase = _cooldown > 0 ? BlasterPhase.cooldown : BlasterPhase.ready;
    }
    return fired;
  }

  void reset() {
    _phase = BlasterPhase.ready;
    _charge = 0;
    _cooldown = 0;
    _cooldownDuration = 0;
    _queuedBurst = 0;
    _burstTimer = 0;
  }
}

const int _sparkCapacity = 64;
const int _chargedCapacity = 32;
const int _ringCapacity = 48;
const double _sparkDuration = 0.24;
const double _chargedDuration = 0.42;
const double _ringDuration = 0.34;

/// Pooled instanced impact VFX: cyan spark burst, violet charged burst and a
/// ground ring. 0.18 instancing is transform-only (no per-instance colour), so
/// charged hits use a separate pool/material instead of a colour mutation.
final class ImpactVfx {
  InstancedPool? sparkPool;
  InstancedPool? chargedSparkPool;
  InstancedPool? ringPool;

  // Per-instance age (>= duration means free), packed xyz origin and 0..1
  // strength, recycled round-robin via the cursors.
  final Float32List sparkAge = Float32List(_sparkCapacity)
    ..fillRange(0, _sparkCapacity, _sparkDuration);
  final Float32List sparkOrigin = Float32List(_sparkCapacity * 3);

  final Float32List chargedAge = Float32List(_chargedCapacity)
    ..fillRange(0, _chargedCapacity, _chargedDuration);
  final Float32List chargedOrigin = Float32List(_chargedCapacity * 3);
  final Float32List chargedStrength = Float32List(_chargedCapacity);

  final Float32List ringAge = Float32List(_ringCapacity)
    ..fillRange(0, _ringCapacity, _ringDuration);
  final Float32List ringOrigin = Float32List(_ringCapacity * 3);
  final Float32List ringStrength = Float32List(_ringCapacity);

  int _sparkCursor = 0;
  int _chargedCursor = 0;
  int _ringCursor = 0;

  /// Records an impact at [position] plus a ground ring under it; a charged hit
  /// ([strength] > 0) uses the violet pool.
  void emit(Vector3 position, {required double strength}) {
    final s = strength.clamp(0.0, 1.0).toDouble();
    if (s > 0) {
      _chargedCursor = _record(
        chargedAge,
        chargedOrigin,
        _chargedCursor,
        position.x,
        position.y,
        position.z,
        strength: chargedStrength,
        value: s,
      );
    } else {
      _sparkCursor = _record(
        sparkAge,
        sparkOrigin,
        _sparkCursor,
        position.x,
        position.y,
        position.z,
      );
    }
    _ringCursor = _record(
      ringAge,
      ringOrigin,
      _ringCursor,
      position.x,
      playerGroundYAtZ(position.z) + 0.03,
      position.z,
      strength: ringStrength,
      value: s,
    );
  }

  void reset() {
    sparkAge.fillRange(0, _sparkCapacity, _sparkDuration);
    chargedAge.fillRange(0, _chargedCapacity, _chargedDuration);
    ringAge.fillRange(0, _ringCapacity, _ringDuration);
  }
}

int _record(
  Float32List age,
  Float32List origin,
  int cursor,
  double x,
  double y,
  double z, {
  Float32List? strength,
  double value = 0,
}) {
  age[cursor] = 0;
  origin[cursor * 3] = x;
  origin[cursor * 3 + 1] = y;
  origin[cursor * 3 + 2] = z;
  if (strength != null) strength[cursor] = value;
  return (cursor + 1) % age.length;
}

/// The single reused lock-on reticle: one [WidgetComponent] on one node,
/// repositioned onto the current target each frame — never one node per rock.
/// [model] bridges the ECS systems (writers) and [ReticleWidget] (painter).
final class LockOnReticle {
  Node? node;
  WidgetComponent? component;

  final ReticleModel model = ReticleModel();

  double opacity = 0;
  double charge01 = 0;
  bool locked = false;
  double firedFlash = 0;
  double impactFlash = 0;

  // Scratch basis vectors so per-frame billboarding allocates nothing.
  final Vector3 _forward = Vector3.zero();
  final Vector3 _right = Vector3.zero();
  final Vector3 _up = Vector3.zero();
  static final Vector3 _worldUp = Vector3(0, 1, 0);

  void flashFired() => firedFlash = 1;

  void flashImpact() => impactFlash = 1;

  void pushToModel() => model.update(
    opacity: opacity,
    charge01: charge01,
    locked: locked,
    firedFlash: firedFlash,
    impactFlash: impactFlash,
  );

  /// Places [node] at the target position facing [camera], mutating the node
  /// transform in place (no allocation).
  void billboardAt(double tx, double ty, double tz, Vector3 camera) {
    final n = node;
    if (n == null) return;
    _forward
      ..setValues(camera.x - tx, camera.y - ty, camera.z - tz)
      ..normalize();
    _worldUp.crossInto(_forward, _right);
    if (_right.length2 < 1e-6) {
      // Degenerate (camera directly above): fall back to world X.
      _right.setValues(1, 0, 0);
    }
    _right.normalize();
    _forward.crossInto(_right, _up);

    final s = n.localTransform.storage;
    s[0] = _right.x;
    s[1] = _right.y;
    s[2] = _right.z;
    s[3] = 0;
    s[4] = _up.x;
    s[5] = _up.y;
    s[6] = _up.z;
    s[7] = 0;
    s[8] = _forward.x;
    s[9] = _forward.y;
    s[10] = _forward.z;
    s[11] = 0;
    s[12] = tx;
    s[13] = ty;
    s[14] = tz;
    s[15] = 1;
    n.localTransform = n.localTransform;
  }

  void hideNode() {
    final n = node;
    if (n == null) return;
    final m = n.localTransform
      ..setIdentity()
      ..setTranslationRaw(0, -9999, 0);
    n.localTransform = m;
  }

  void reset() {
    opacity = 0;
    charge01 = 0;
    locked = false;
    firedFlash = 0;
    impactFlash = 0;
    model.reset();
    hideNode();
  }

  /// The resource owns [model]; the widget does not dispose it.
  void disposeModel() => model.dispose();
}
