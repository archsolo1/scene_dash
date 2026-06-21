/// Central tuning constants for the rock-dodge demo. Kept in one place so the
/// gameplay feel can be adjusted without hunting through systems.
library;

// --- Ramp (a wide, finite inclined platform) ---

/// Ramp size along X (width), Y (thickness) and Z (length), in world units.
const double rampWidth = 16;
const double rampThickness = 1;
const double rampLength = 36;

/// Ramp incline in radians (rotation about X). The +Z end tips downhill, so
/// rocks spawned at the -Z (high) end roll toward +Z.
const double rampInclineRadians = 0.18;

// --- Rocks (dynamic spheres that roll down) ---

const double rockRadius = 0.7;

/// Spawn band at the high end of the ramp.
const double rockSpawnZ = -15;
const double rockSpawnY = 9;
const double rockSpawnHalfWidth = 6;

/// Seconds between rock spawns.
const double rockSpawnInterval = 0.55;

/// Rocks that fall below this Y are despawned (off the platform, into the void).
const double rockKillY = -25;

// --- Player (kinematic character controller) ---

const double playerRadius = 0.6;
const double playerStartZ = 6;
const double playerStartY = 2;

/// Sideways dodge speed across the ramp (X), in m/s.
const double playerStrafeSpeed = 8;

/// Constant downward bias applied each step so the controller hugs the slope
/// and actually falls when it walks off an edge, in m/s.
const double playerStickSpeed = 14;

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
