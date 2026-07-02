/// Plain gameplay resources shared between ECS systems and the Flutter HUD.
library;

import 'package:flutter/foundation.dart';
import 'package:scene_dash/scene_dash.dart';

/// The run's mode, registered as a state machine (`addState<GameStatus>`).
/// Gameplay systems gate on `inState(GameStatus.playing)`; transitions are
/// requested through `NextState<GameStatus>`.
enum GameStatus { playing, lost }

/// Player input. Widgets write it; systems read it.
final class InputState {
  /// Horizontal dodge axis: -1 (left), 0, or +1 (right).
  double horizontal = 0;

  bool restartRequested = false;
  bool fireHeld = false;

  /// One-frame transition flags, cleared by the blaster system once consumed.
  bool firePressed = false;
  bool fireReleased = false;
  bool fireCanceled = false;

  /// Only the not-held -> held transition sets [firePressed] (key-repeat safe).
  void pressFire() {
    if (fireHeld) return;
    fireHeld = true;
    firePressed = true;
  }

  void releaseFire() {
    if (!fireHeld) return;
    fireHeld = false;
    fireReleased = true;
  }

  /// Fire was aborted (focus loss, disposal, or `onTapCancel`): charging stops
  /// without firing.
  void cancelFire() {
    if (!fireHeld) {
      // A press queued this same frame but never became a real hold.
      firePressed = false;
      return;
    }
    fireHeld = false;
    firePressed = false;
    fireCanceled = true;
  }

  void clearFireTransitions() {
    firePressed = false;
    fireReleased = false;
    fireCanceled = false;
  }
}

/// Read-only view of the blaster for the HUD, so `game/` does not depend on
/// the projectiles feature library (which depends on `game/`).
abstract interface class BlasterView {
  double get charge01;
  double get cooldown01;
  bool get isCharging;
  bool get isReady;
}

/// Read-only view of the active shield for the HUD.
abstract interface class ShieldView {
  bool get active;
  double get normalized;
  bool get expiringSoon;
}

/// Run data (timer, loss reason). The playing/lost mode itself lives in the
/// `GameStatus` state machine, not here.
final class GameState {
  final GameStopwatch _runClock = GameStopwatch();

  /// Seconds survived this run.
  double get survived => _runClock.elapsed;

  String? lostReason;

  int get survivedTenths => (survived * 10).floor();

  void addSurvival(double delta) => _runClock.tick(delta);

  /// Records why the run ended; the first recorded reason wins.
  void recordLoss(String reason) => lostReason ??= reason;

  void reset() {
    _runClock.reset();
    lostReason = null;
  }
}

/// What the HUD renders, as a record: structural `==` for free, so the
/// `ValueNotifier` only notifies when something visible actually changed.
typedef GameHudSnapshot = ({
  GameStatus status,
  int survivedTenths,
  String? lostReason,
  int fps,
  double blasterCharge01,
  double blasterCooldown01,
  bool blasterCharging,
  bool blasterReady,
  bool shieldActive,
  double shieldNormalized,
  bool shieldExpiring,
});

extension GameHudSnapshotLabels on GameHudSnapshot {
  String get survivedLabel => (survivedTenths / 10).toStringAsFixed(1);
}

GameHudSnapshot buildHudSnapshot(
  GameState state, {
  required GameStatus status,
  required int fps,
  BlasterView? blaster,
  ShieldView? shield,
}) {
  return (
    status: status,
    survivedTenths: state.survivedTenths,
    lostReason: state.lostReason,
    fps: fps,
    // Quantised to whole percent so the HUD only rebuilds on a visible step.
    blasterCharge01: _centi(blaster?.charge01 ?? 0),
    blasterCooldown01: _centi(blaster?.cooldown01 ?? 0),
    blasterCharging: blaster?.isCharging ?? false,
    blasterReady: blaster?.isReady ?? true,
    shieldActive: shield?.active ?? false,
    shieldNormalized: _centi(shield?.normalized ?? 0),
    shieldExpiring: shield?.expiringSoon ?? false,
  );
}

double _centi(double v) => (v.clamp(0.0, 1.0) * 100).round() / 100;

final class HudState extends ValueNotifier<GameHudSnapshot> {
  HudState(
    this._game, {
    required CurrentState<GameStatus> phase,
    BlasterView? blaster,
    ShieldView? shield,
  }) : _phase = phase,
       _blaster = blaster,
       _shield = shield,
       super(
         buildHudSnapshot(
           _game,
           status: phase.value,
           fps: 0,
           blaster: blaster,
           shield: shield,
         ),
       );

  final GameState _game;
  final CurrentState<GameStatus> _phase;
  final BlasterView? _blaster;
  final ShieldView? _shield;
  double _fpsWindowSeconds = 0;
  int _fpsWindowFrames = 0;
  int _fps = 0;

  void recordFrame(double deltaSeconds) {
    _fpsWindowSeconds += deltaSeconds;
    _fpsWindowFrames++;
    if (_fpsWindowSeconds >= 0.25) {
      _fps = (_fpsWindowFrames / _fpsWindowSeconds).round();
      _fpsWindowSeconds = 0;
      _fpsWindowFrames = 0;
    }
    refresh();
  }

  void refresh() {
    final next = buildHudSnapshot(
      _game,
      status: _phase.value,
      fps: _fps,
      blaster: _blaster,
      shield: _shield,
    );
    if (next == value) return;
    value = next;
  }
}
