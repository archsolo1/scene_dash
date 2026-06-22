part of 'projectiles.dart';

final class Blaster {
  double cooldown = 0;
  double burstTimer = 0;
  int queuedShots = 0;

  bool get canStartBurst => cooldown <= 0 && queuedShots == 0;

  void startBurst() {
    queuedShots = blasterBurstShots;
    burstTimer = 0;
    cooldown = blasterCooldown;
  }

  bool consumeShot(double dt) {
    if (cooldown > 0) {
      cooldown -= dt;
      if (cooldown < 0) cooldown = 0;
    }
    if (queuedShots == 0) return false;

    burstTimer -= dt;
    if (burstTimer > 0) return false;

    queuedShots--;
    burstTimer = blasterBurstInterval;
    return true;
  }

  void reset() {
    cooldown = 0;
    burstTimer = 0;
    queuedShots = 0;
  }
}
