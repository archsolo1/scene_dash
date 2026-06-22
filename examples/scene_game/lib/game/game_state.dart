/// Plain gameplay resources shared between ECS systems and the Flutter HUD.
library;

import 'package:flutter/foundation.dart';

/// Whether the run is ongoing or finished.
enum GameStatus { playing, lost }

/// Player input. Widgets write it; systems read it.
final class InputState {
  /// Horizontal dodge axis: -1 (left), 0, or +1 (right).
  double horizontal = 0;

  /// Set by pressing R or tapping restart; consumed by the restart system.
  bool restartRequested = false;

  /// Set by pressing Space or tapping fire; consumed by the blaster system.
  bool shootRequested = false;
}

/// The run's status and survival timer.
final class GameState {
  GameStatus status = GameStatus.playing;

  /// Seconds survived this run.
  double survived = 0;

  /// Why the player lost, shown on the game-over overlay.
  String? lostReason;

  int get survivedTenths => (survived * 10).floor();

  void addSurvival(double delta) {
    survived += delta;
  }

  void reset() {
    status = GameStatus.playing;
    survived = 0;
    lostReason = null;
  }

  void lose(String reason) {
    if (status == GameStatus.lost) return;
    status = GameStatus.lost;
    lostReason = reason;
  }
}

@immutable
final class GameHudSnapshot {
  const GameHudSnapshot({
    required this.status,
    required this.survivedTenths,
    required this.lostReason,
    required this.fps,
  });

  factory GameHudSnapshot.from(GameState state, {required int fps}) {
    return GameHudSnapshot(
      status: state.status,
      survivedTenths: state.survivedTenths,
      lostReason: state.lostReason,
      fps: fps,
    );
  }

  final GameStatus status;
  final int survivedTenths;
  final String? lostReason;
  final int fps;

  String get survivedLabel => (survivedTenths / 10).toStringAsFixed(1);

  @override
  bool operator ==(Object other) {
    return other is GameHudSnapshot &&
        other.status == status &&
        other.survivedTenths == survivedTenths &&
        other.lostReason == lostReason &&
        other.fps == fps;
  }

  @override
  int get hashCode => Object.hash(status, survivedTenths, lostReason, fps);
}

final class HudState extends ValueNotifier<GameHudSnapshot> {
  HudState(this._game) : super(GameHudSnapshot.from(_game, fps: 0));

  final GameState _game;
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
    final next = GameHudSnapshot.from(_game, fps: _fps);
    if (next == value) return;
    value = next;
  }
}
