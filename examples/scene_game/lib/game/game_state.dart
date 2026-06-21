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
  });

  factory GameHudSnapshot.from(GameState state) {
    return GameHudSnapshot(
      status: state.status,
      survivedTenths: state.survivedTenths,
      lostReason: state.lostReason,
    );
  }

  final GameStatus status;
  final int survivedTenths;
  final String? lostReason;

  String get survivedLabel => (survivedTenths / 10).toStringAsFixed(1);

  @override
  bool operator ==(Object other) {
    return other is GameHudSnapshot &&
        other.status == status &&
        other.survivedTenths == survivedTenths &&
        other.lostReason == lostReason;
  }

  @override
  int get hashCode => Object.hash(status, survivedTenths, lostReason);
}

final class HudState extends ValueNotifier<GameHudSnapshot> {
  HudState(this._game) : super(GameHudSnapshot.from(_game));

  final GameState _game;

  void refresh() {
    final next = GameHudSnapshot.from(_game);
    if (next == value) return;
    value = next;
  }
}
