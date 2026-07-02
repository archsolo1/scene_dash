part of '../rocks.dart';

@Tag()
final class Rock {
  const Rock();
}

/// Tags the faster, on-fire rocks; only they get [RockTrails] puffs.
@Tag()
final class Flaming {
  const Flaming();
}

/// The rock's hit-flash shell node, a child of the physics-driven root so the
/// Rapier transform sync never disturbs it. Only its scale changes, so the
/// flash material stays shared — mutating it would flash every rock.
@ObjectComponent()
final class RockVisuals {
  const RockVisuals(this.shell);

  final Node shell;
}

/// Transient hit-reaction state, inserted when a projectile connects and
/// removed when the flash finishes.
@ObjectComponent()
final class RockHitReaction {
  RockHitReaction({required this.strength}) : remaining = rockHitReactionDuration;

  double remaining;
  final double strength;
}
