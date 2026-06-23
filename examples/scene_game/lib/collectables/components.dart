part of 'collectables.dart';

/// Tags any collectable entity.
@Tag()
final class Collectable {
  const Collectable();
}

/// Tags a shield pickup specifically.
@Tag()
final class ShieldPickup {
  const ShieldPickup();
}

/// Per-pickup animation/lifetime state (only its age so far).
@ObjectComponent()
final class ShieldPickupState {
  double age = 0;
}

/// Direct references to a pickup's visual child nodes, animated in place.
@ObjectComponent()
final class ShieldPickupVisuals {
  const ShieldPickupVisuals(this.glow);

  /// The pulsing/bobbing glow child (the physics-driven root is left alone).
  final Node glow;
}
