part of 'projectiles.dart';

@ObjectComponent()
final class Projectile {
  double age = 0;
}

@ObjectComponent()
final class VfxEffect {
  VfxEffect({
    required this.material,
    required this.color,
    required this.duration,
    required this.startScale,
    required this.endScale,
    this.floatUp = 0,
    this.spin = 0,
  });

  final PhysicallyBasedMaterial material;
  final Vector4 color;
  final double duration;
  final double startScale;
  final double endScale;
  final double floatUp;
  final double spin;
  final Vector3 origin = Vector3.zero();
  double age = 0;
  bool initialized = false;
}
