import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_scene/scene.dart';
import 'package:flutter_scene_rapier/flutter_scene_rapier.dart';
import 'package:scene_dash/scene_dash.dart';
import 'package:scene_dash_flutter_scene/scene_dash_flutter_scene.dart';
import 'package:vector_math/vector_math.dart' show Matrix4, Vector3, Vector4;

import '../fx/anim.dart';
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

/// Installs the player's blaster, projectiles, charge/impact VFX and the
/// lock-on reticle. The [Blaster] is constructed in `main()` and shared with
/// the HUD; this plugin is the sole place it is registered.
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
      ..addSystem(
        resetProjectilesOnRunStartSystem,
        schedule: OnEnter(GameStatus.playing),
      )
      ..addSystem(
        stopBlasterOnRunEndSystem,
        schedule: OnExit(GameStatus.playing),
      )
      // Shooting reads the player position after movePlayer has moved it.
      ..addSystem(
        shootProjectilesSystem,
        schedule: Schedules.fixedPrePhysics,
        after: [movePlayerSystem],
        runIf: inState(GameStatus.playing),
      )
      ..addSystems(Schedules.startup, [
        spawnImpactVfxSystem,
        spawnLockOnReticleSystem,
      ])
      ..addSystems(Schedules.update, [
        updateProjectilesSystem,
        updateChargeVisualsSystem,
        updateImpactVfxSystem,
        updateLockOnReticleSystem,
      ])
      ..addSystem(disposeLockOnReticleSystem, schedule: Schedules.shutdown);
  }
}
