part of 'projectiles.dart';

@ObjectComponent()
final class Projectile {
  Projectile({this.charge = 0});

  double age = 0;

  /// Shot strength: `0.0` is a normal burst pellet; `(0, 1]` is a charged shot.
  /// Immutable for the projectile's life - hit force is derived from it.
  final double charge;

  /// Rock entity indices already hit by this charged projectile. Burst pellets
  /// despawn on first impact, so this remains empty for them.
  final Set<int> hitRocks = <int>{};

  bool get charged => charge > 0;
}
