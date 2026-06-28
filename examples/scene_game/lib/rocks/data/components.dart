part of '../rocks.dart';

/// Tags a rolling rock entity.
@Tag()
final class Rock {
  const Rock();
}

/// Tags the faster, on-fire rocks. Used both for their material and to drive the
/// shared [RockTrails] instanced trail (only flaming rocks get puffs).
@Tag()
final class Flaming {
  const Flaming();
}

/// Rock-owned hit-feedback node: a slightly larger, emissive, translucent flash
/// shell created hidden as a child of the rock and pulsed on impact.
///
/// The shell is a child of the physics-driven root, so it is never disturbed by
/// the Rapier transform sync. Only its transform scale changes, so the flash
/// material can stay shared and immutable — mutating a shared base material for
/// one rock would flash every rock.
@ObjectComponent()
final class RockVisuals {
  const RockVisuals(this.shell);

  /// The pre-created flash shell child node, hidden (zero scale) until hit.
  final Node shell;
}

/// Transient hit-reaction state inserted on a rock when a projectile connects
/// and removed when the flash finishes. [strength] (0..1, from projectile
/// charge) scales how hard the shell pops.
@ObjectComponent()
final class RockHitReaction {
  RockHitReaction({required this.strength}) : remaining = rockHitReactionDuration;

  double remaining;
  final double strength;
}
