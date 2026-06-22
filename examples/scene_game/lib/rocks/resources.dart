part of 'rocks.dart';

/// Spawn cadence plus RNG, injected as a resource.
final class RockSpawner {
  final math.Random random;
  double _accumulator = 0;

  RockSpawner({int? seed}) : random = math.Random(seed);

  /// Advances the timer; returns the number of rocks due this step.
  int tick(double dt, {required double survived}) {
    _accumulator += dt;
    var due = 0;
    final interval = rockSpawnIntervalForSurvival(survived);
    while (_accumulator >= interval) {
      _accumulator -= interval;
      due++;
    }
    return due;
  }

  /// A random X within the ramp's spawn band.
  double nextLane() => (random.nextDouble() * 2 - 1) * rockSpawnHalfWidth;

  bool nextIsFlaming(double survived) {
    return random.nextDouble() < flamingRockChanceForSurvival(survived);
  }

  void reset() => _accumulator = 0;
}
