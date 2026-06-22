/// Central tuning constants for the rock-dodge demo. Kept in one place so the
/// gameplay feel can be adjusted without hunting through systems.
library;

import 'dart:math' as math;

// --- Ramp (a wide, finite inclined platform) ---

/// Ramp size along X (width), Y (thickness) and Z (length), in world units.
const double rampWidth = 16;
const double rampThickness = 1;
const double rampLength = 36;

/// Ramp incline in radians (rotation about X). The +Z end tips downhill, so
/// rocks spawned at the -Z (high) end roll toward +Z.
const double rampInclineRadians = 0.18;

double rampSurfaceYAtZ(double z) {
  return rampThickness * 0.5 * math.cos(rampInclineRadians) -
      z * math.sin(rampInclineRadians);
}

double playerGroundYAtZ(double z) => rampSurfaceYAtZ(z) + playerRadius + 0.04;

bool isOverRampFootprint(double x, double z) {
  return x.abs() <= rampWidth * 0.5 && z.abs() <= rampLength * 0.5;
}

// --- Rocks (dynamic spheres that roll down) ---

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

// --- Player (kinematic character controller) ---

const double playerRadius = 0.6;
const double playerStartZ = 6;
final double playerStartY = playerGroundYAtZ(playerStartZ);

/// Sideways dodge speed across the ramp (X), in m/s.
const double playerStrafeSpeed = 8;

// --- Blaster ---

/// Shots per burst. A burst can save the player, but cannot hold the lane
/// forever.
const int blasterBurstShots = 3;

/// Seconds between shots inside one burst.
const double blasterBurstInterval = 0.11;

/// Seconds after a burst before another can start.
const double blasterCooldown = 1.25;

const double projectileRadius = 0.18;
const double projectileSpeed = 22;
const double projectileLaunchUp = 3.2;
const double projectileLifetime = 0.8;
const double projectileHitRadius = 1.05;
const double projectileKnockback = 13;
const double projectileLift = 4;

// --- Lose conditions ---

/// Extra margin added to (playerRadius + rockRadius) for the hit test.
const double hitPadding = 0.35;

/// Downward raycast length used to decide the player is still on the platform.
const double groundProbeDistance = 3;

/// Grace period after (re)spawn before fall detection runs, so dropping onto
/// the ramp at spawn is not mistaken for falling off, in seconds.
const double startupGrace = 0.6;

// --- Hit reaction ---

/// When a rock connects, the player gets a short authored tumble so the hit is
/// visible even though normal movement is kinematic-controller driven.
const double knockbackHorizontal = 7;
const double knockbackUp = 6;
const double impactGravity = 20;
const double impactSpinSpeed = 11;

// --- Camera ---

const double cameraFollowSharpness = 8;

// --- World ---

const double gravityStrength = 18;

// --- Physics collision layers ---

/// Collision-group membership bits for the demo's physics bodies.
///
/// Used to classify physics-query results without rebuilding ECS-to-node lookup
/// sets each frame: e.g. the lose-condition system reads `overlapSphere` hits and
/// keeps only colliders whose [rock] bit is set. (Bits also feed Rapier's
/// collision groups; the demo keeps collision *masks* permissive so contacts are
/// unchanged.)
abstract final class PhysicsLayers {
  static const int player = 1 << 0;
  static const int platform = 1 << 1;
  static const int rock = 1 << 2;
}
