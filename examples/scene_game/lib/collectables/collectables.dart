import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_scene/scene.dart';
import 'package:flutter_scene_rapier/flutter_scene_rapier.dart';
import 'package:scene_dash/scene_dash.dart';
import 'package:scene_dash_flutter_scene/scene_dash_flutter_scene.dart';
import 'package:vector_math/vector_math.dart' show Matrix4, Vector3, Vector4;

import '../fx/instanced_pool.dart';
import '../game/game_state.dart';
import '../game/physics_layers.dart';
import '../player/data/config.dart';
import '../player/player.dart';
import 'data/config.dart';

part 'collectables.g.dart';
part 'data/components.dart';
part 'data/resources.dart';
part 'data/bundles.dart';
part 'vfx/vfx.dart';
part 'systems/systems.dart';

/// Installs rolling shield pickups, the shield state, and the player's shield
/// feedback and deflection VFX. [ShieldState] is constructed in `main()` and
/// shared with the HUD; this plugin is the sole place it is registered.
@GamePlugin()
final class CollectablesPlugin extends Plugin {
  const CollectablesPlugin({required this.shield});

  final ShieldState shield;

  @override
  void build(AppBuilder app) {
    app
      ..insertResource<ShieldState>(shield)
      ..insertResource<CollectableSpawner>(CollectableSpawner())
      ..insertResource<ShieldDeflectVfx>(ShieldDeflectVfx())
      // fixedPrePhysics so the body is mounted before the native step.
      ..addSystem(
        spawnShieldPickupsSystem,
        schedule: Schedules.fixedPrePhysics,
        runIf: inState(GameStatus.playing),
      )
      ..addSystem(spawnShieldDeflectVfxSystem, schedule: Schedules.startup)
      ..addSystem(
        updateShieldStateSystem,
        schedule: Schedules.update,
        runIf: inState(GameStatus.playing),
      )
      ..addSystem(animateShieldPickupsSystem, schedule: Schedules.update)
      // After the shield tick so a fresh shield isn't ticked down this frame.
      ..addSystem(
        collectShieldPickupsSystem,
        schedule: Schedules.update,
        after: [updateShieldStateSystem],
        runIf: inState(GameStatus.playing),
      )
      ..addSystem(
        updateShieldVisualsSystem,
        schedule: Schedules.update,
        after: [updateShieldStateSystem],
      )
      ..addSystem(cleanupPickupsSystem, schedule: Schedules.update)
      ..addSystem(updateShieldDeflectVfxSystem, schedule: Schedules.update);
  }
}
