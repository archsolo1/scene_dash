/// Shield-pickup and shield tuning for the scene game example. Depends on player
/// and world dimensions for the collection distance and pass bounds.
library;

import '../../player/data/config.dart';
import '../../world/data/config.dart';

// --- Shield pickups ---

const double collectableRadius = 0.5;

/// Spawn band for shield pickups, at the high (-Z) end of the ramp so they roll
/// down toward the player like rocks do.
const double shieldPickupSpawnZ = -14;
const double shieldPickupSpawnY = 7.5;
const double shieldPickupSpawnHalfWidth = 5;

/// Seconds between shield-pickup spawn attempts. At most one pickup exists at a
/// time, so a new one only appears once the previous one is gone.
const double shieldPickupInterval = 9;

/// Pickups are despawned once they fall below this Y or roll past this Z.
const double collectableKillY = -25;
final double collectablePassZ = rampLength * 0.5 + 3;

/// Squared collection distance: the shield is collected when the player's centre
/// is within (the central body radius + collectableRadius + margin) of the
/// pickup.
final double shieldCollectDistanceSq = _square(
  playerCollisionRadius + collectableRadius + 0.5,
);

double _square(double value) => value * value;

// --- Shield ---

/// Seconds an activated shield lasts before expiring.
const double shieldDuration = 6;

/// Final seconds of a shield's life during which it visibly warns of expiry.
const double shieldWarningWindow = 1.5;

/// Seconds of shield time consumed by deflecting a single rock.
const double shieldDeflectTimeCost = 0.4;

/// Outward, upward and angular velocity applied to a rock the shield deflects.
const double shieldDeflectOutward = 16;
const double shieldDeflectUp = 12;
const double shieldDeflectSpin = 10;
