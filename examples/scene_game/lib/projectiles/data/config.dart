/// Projectile, blaster and lock-on reticle tuning for the scene game example.
///
/// The charge-scaling helpers belong here because they derive projectile
/// behaviour from charge.
library;

// --- Blaster ---

/// Shots per burst. A burst can save the player, but cannot hold the lane
/// forever.
const int blasterBurstShots = 3;

/// Seconds between shots inside one burst.
const double blasterBurstInterval = 0.11;

/// Seconds after a burst before another can start.
const double blasterCooldown = 1.25;

/// Seconds the fire control must stay held before a quick tap turns into a
/// charge. Releasing before this still fires the normal burst.
const double blasterChargeThreshold = 0.25;

/// Seconds of holding that reaches full charge. Holding longer does not charge
/// further; [Blaster.charge01] clamps at 1.0.
const double blasterMaxChargeDuration = 1.25;

/// Seconds of cooldown after firing a charged shot (longer than the burst
/// cooldown so a charged shot is a committed move, not spammable).
const double chargedShotCooldown = 1.6;

// --- Projectiles ---

const double projectileRadius = 0.18;
const double projectileSpeed = 22;
const double projectileLaunchUp = 3.2;
const double projectileLifetime = 0.8;
const double projectileHitRadius = 1.05;
const double projectileKnockback = 13;
const double projectileLift = 4;

/// Base angular kick a normal (burst) shot imparts to a rock.
const double projectileBaseSpin = 9;

// --- Charged projectiles ---

/// Charged-projectile transform scale (multiplied onto [projectileRadius]) at
/// minimum and maximum charge. A charged shot is always clearly bigger than a
/// burst pellet, growing toward [chargedProjectileMaxScale] at full charge.
const double chargedProjectileMinScale = 1.6;
const double chargedProjectileMaxScale = 4.4;

/// Impact-sphere radius for a charged shot at minimum and maximum charge.
const double chargedProjectileMinHitRadius = 1.8;
const double chargedProjectileMaxHitRadius = 3.4;

/// Charged shots pierce through several rocks before despawning.
const int chargedProjectileMaxHits = 6;

/// Peak horizontal knockback and upward lift applied to a rock by a full-charge
/// shot. A burst pellet keeps the unscaled [projectileKnockback]/[projectileLift].
const double chargedProjectileMaxKnockback = 30;
const double chargedProjectileMaxLift = 10;

/// Peak angular kick (rad/s magnitude) imparted to a rock by a full-charge shot.
const double chargedProjectileMaxSpin = 16;

/// Smallest charge a charged shot can carry. A release just past
/// [blasterChargeThreshold] maps to `charge01 == 0`, which would be
/// indistinguishable from a burst pellet (`charge == 0`); flooring at this value
/// keeps `0.0` meaning "burst" and any charged shot strictly above it.
const double minChargedCharge = 0.06;

// --- Lock-on reticle ---

/// Half-width of the firing lane the lock-on reticle considers: a rock is a
/// candidate target when its X is within this of the player's X.
const double reticleLaneHalfWidth = 1.7;

// --- Charge-derived scaling ---

/// Transform scale (relative to [projectileRadius]) for a charged shot of the
/// given normalized [charge]. Burst pellets keep scale 1.
double chargedProjectileScale(double charge) {
  final t = charge.clamp(0.0, 1.0);
  return chargedProjectileMinScale +
      (chargedProjectileMaxScale - chargedProjectileMinScale) * t;
}

/// Overlap radius used to detect a projectile hit, scaled from [charge]. A burst
/// pellet (charge 0) keeps the unscaled [projectileHitRadius].
double projectileHitRadiusForCharge(double charge) {
  if (charge <= 0) return projectileHitRadius;
  final t = charge.clamp(0.0, 1.0);
  return chargedProjectileMinHitRadius +
      (chargedProjectileMaxHitRadius - chargedProjectileMinHitRadius) * t;
}

/// Horizontal knockback applied to a hit rock, scaled from [charge].
double projectileKnockbackForCharge(double charge) {
  if (charge <= 0) return projectileKnockback;
  final t = charge.clamp(0.0, 1.0);
  return projectileKnockback +
      (chargedProjectileMaxKnockback - projectileKnockback) * t;
}

/// Upward lift applied to a hit rock, scaled from [charge].
double projectileLiftForCharge(double charge) {
  if (charge <= 0) return projectileLift;
  final t = charge.clamp(0.0, 1.0);
  return projectileLift + (chargedProjectileMaxLift - projectileLift) * t;
}

/// Angular kick magnitude applied to a hit rock, scaled from [charge].
double projectileSpinForCharge(double charge) {
  if (charge <= 0) return projectileBaseSpin;
  final t = charge.clamp(0.0, 1.0);
  return projectileBaseSpin +
      (chargedProjectileMaxSpin - projectileBaseSpin) * t;
}
