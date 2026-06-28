import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_scene/scene.dart';
import 'package:flutter_scene_rapier/flutter_scene_rapier.dart';
import 'package:scene_dash/scene_dash.dart';
import 'package:scene_dash_flutter_scene/scene_dash_flutter_scene.dart';
import 'package:vector_math/vector_math.dart' show Matrix4, Vector3, Vector4;

import '../fx/instanced_pool.dart';
import '../game/camera_rig.dart';
import '../game/game_state.dart';
import '../game/physics_layers.dart';
import '../player/data/config.dart';
import '../player/player.dart';
import '../rocks/data/config.dart';
import '../rocks/rocks.dart';
import '../world/data/config.dart';
import 'data/config.dart';
import 'vfx/reticle_widget.dart';

part 'data/components.dart';
part 'projectiles.g.dart';
part 'data/resources.dart';
part 'data/bundles.dart';
part 'vfx/vfx.dart';
part 'systems/systems.dart';
part 'vfx/charge_vfx.dart';
part 'vfx/impact_vfx.dart';
part 'vfx/reticle.dart';

/// Installs the player's blaster: tap-to-burst, hold-to-charge, the charged
/// projectile, charge VFX, pooled impact VFX and the lock-on reticle.
///
/// The [Blaster] is constructed once in `main()` and shared with the HUD, so the
/// plugin receives it and is the sole place it is registered as a resource.
@GamePlugin()
final class ProjectilesPlugin extends Plugin {
  const ProjectilesPlugin({required this.blaster});

  final Blaster blaster;

  @override
  void build(AppBuilder app) {
    app
      ..insertResource<Blaster>(blaster)
      ..insertResource<ImpactVfx>(ImpactVfx())
      ..insertResource<LockOnReticle>(LockOnReticle())
      // Shooting reads the player position after movePlayer has moved it this
      // fixed step, so order it explicitly behind that system.
      ..addSystem(
        shootProjectilesSystem,
        schedule: Schedules.fixedPrePhysics,
        after: [movePlayerSystem],
      )
      ..addSystem(spawnImpactVfxSystem, schedule: Schedules.startup)
      ..addSystem(spawnLockOnReticleSystem, schedule: Schedules.startup)
      ..addSystem(updateProjectilesSystem, schedule: Schedules.update)
      ..addSystem(updateChargeVisualsSystem, schedule: Schedules.update)
      ..addSystem(updateImpactVfxSystem, schedule: Schedules.update)
      ..addSystem(updateLockOnReticleSystem, schedule: Schedules.update)
      ..addSystem(disposeLockOnReticleSystem, schedule: Schedules.shutdown);
  }
}
