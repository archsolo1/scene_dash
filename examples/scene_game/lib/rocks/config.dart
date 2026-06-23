/// Rock tuning and difficulty scaling for the scene game example.
library;

const double rockRadius = 0.7;

/// Spawn band at the high end of the ramp.
const double rockSpawnZ = -15;
const double rockSpawnY = 9;
const double rockSpawnHalfWidth = 6;

/// Starting seconds between rock spawns. The run ramps toward
/// [rockSpawnIntervalMin] so the game stays playable before becoming a small
/// physics/render stress test.
const double rockSpawnIntervalStart = 0.36;

/// Fastest rock spawn cadence once the run has warmed up.
const double rockSpawnIntervalMin = 0.15;

/// Seconds needed to reach the stress-test spawn cadence.
const double rockSpawnRampSeconds = 18;

/// Chance that a spawned rock is the faster flaming variant.
const double flamingRockChanceStart = 0.18;

/// Flaming rocks get more common as the spawn cadence ramps up.
const double flamingRockChanceMax = 0.38;

/// Extra downhill launch speed for flaming rocks, along the ramp's +Z descent.
const double flamingRockForwardVelocity = 15;

/// Initial tumble speed that makes flaming rocks read as more dangerous.
const double flamingRockSpinVelocity = 8;

/// Rocks that fall below this Y are despawned (off the platform, into the void).
const double rockKillY = -25;

/// Seconds a rock's hit-reaction flash shell plays after it is struck.
const double rockHitReactionDuration = 0.34;

double stressRamp(double survived) {
  return (survived / rockSpawnRampSeconds).clamp(0, 1).toDouble();
}

double rockSpawnIntervalForSurvival(double survived) {
  final ramp = stressRamp(survived);
  return rockSpawnIntervalStart +
      (rockSpawnIntervalMin - rockSpawnIntervalStart) * ramp;
}

double flamingRockChanceForSurvival(double survived) {
  final ramp = stressRamp(survived);
  return flamingRockChanceStart +
      (flamingRockChanceMax - flamingRockChanceStart) * ramp;
}
