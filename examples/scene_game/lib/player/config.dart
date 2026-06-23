/// Player tuning for the scene game example. Depends on world ramp geometry.
library;

import '../world/ramp.dart';

const double playerRadius = 0.6;
const double playerBodyVisualRadius = playerRadius;
const double playerCollisionRadius = playerRadius;
const double playerGroundClearance = 0.04;
const double playerStartZ = 6;

/// Sideways dodge speed across the ramp (X), in m/s.
const double playerStrafeSpeed = 8;

/// A rock contact no longer ends the run; it shoves the player. This is the push
/// speed (m/s) applied away from the rock, and how fast that push bleeds off.
/// Enough hits shove the player off an edge, which is the only way to lose.
const double knockbackPushSpeed = 15;
const double knockbackDecayRate = 18;

/// Once there is no ramp below the player, they visibly fall before the run
/// ends. This sits below the ramp's low edge so the fall reads on screen.
const double playerFallLoseY = -7;

// --- Crab legs ---

const int crabLegsPerSide = 3;
const int crabLegCount = crabLegsPerSide * 2;

const double crabLegUpperLength = 0.72;
const double crabLegLowerLength = 0.62;
const double crabLegThickness = 0.11;
const double crabLegSideOffset = playerBodyVisualRadius * 0.78;
const double crabLegFrontOffset = -0.48;
const double crabLegMiddleOffset = 0;
const double crabLegRearOffset = 0.48;
const List<double> crabLegForwardOffsets = <double>[
  crabLegFrontOffset,
  crabLegMiddleOffset,
  crabLegRearOffset,
];

const double crabLegCollapsedScale = 0.24;
const double crabLegExtensionDuration = 1.1;
const double crabLegExtensionStagger = 0.14;

const double crabGaitSpeed = 9;
const double crabLegLift = 0.18;
const double crabLegStride = 0.2;
const double crabLegBend = 0.28;

/// Radius of the translucent shield bubble drawn around the player. The bubble
/// is a player-attached visual, so its sizing lives with the player.
const double shieldBubbleRadius = playerBodyVisualRadius * 1.85;

/// Resting height of the player's centre at ramp depth [z] (sits on the ramp).
double playerGroundYAtZ(double z) =>
    rampSurfaceYAtZ(z) + playerCollisionRadius + playerGroundClearance;

final double playerStartY = playerGroundYAtZ(playerStartZ);
