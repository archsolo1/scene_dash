import 'package:flutter_test/flutter_test.dart';
import 'package:scene_game/game/game_state.dart';

/// Pure-logic coverage for the run's loss/reset state machine - no scene or GPU.
void main() {
  test('a fresh game starts playing with a clean timer', () {
    final game = GameState();
    expect(game.status, GameStatus.playing);
    expect(game.survived, 0);
    expect(game.lostReason, isNull);
  });

  test('survival accumulates and reports tenths', () {
    final game = GameState()
      ..addSurvival(1.24)
      ..addSurvival(0.30);
    expect(game.survived, closeTo(1.54, 1e-9));
    expect(game.survivedTenths, 15);
  });

  test('lose transitions once and keeps the first reason', () {
    final game = GameState()..lose('You fell off the platform');
    expect(game.status, GameStatus.lost);
    expect(game.lostReason, 'You fell off the platform');

    game.lose('A later loss reason');
    expect(
      game.lostReason,
      'You fell off the platform',
      reason: 'first loss wins',
    );
  });

  test('reset returns the game to a clean playing state', () {
    final game = GameState()
      ..addSurvival(5)
      ..lose('You fell off the platform')
      ..reset();
    expect(game.status, GameStatus.playing);
    expect(game.survived, 0);
    expect(game.lostReason, isNull);
  });
}
