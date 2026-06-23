import 'dart:math' as math;

import 'package:flutter_scene/scene.dart';
import 'package:flutter_scene_rapier/flutter_scene_rapier.dart';
import 'package:scene_dash/scene_dash.dart';
import 'package:scene_dash_flutter_scene/scene_dash_flutter_scene.dart';
import 'package:vector_math/vector_math.dart' show Matrix4, Vector3, Vector4;

import '../game/game_state.dart';
import '../game/physics_layers.dart';
import '../world/config.dart';
import '../world/ramp.dart';
import 'config.dart';

part 'player.g.dart';
part 'components.dart';
part 'resources.dart';
part 'bundles.dart';
part 'systems.dart';

/// Installs the player feature.
@GamePlugin()
final class PlayerPlugin extends Plugin {
  const PlayerPlugin();

  @override
  void build(AppBuilder app) {
    app
      ..insertResource<PlayerKnockback>(PlayerKnockback())
      ..addSystem(spawnPlayerSystem, schedule: Schedules.startup)
      ..addSystem(movePlayerSystem, schedule: Schedules.fixedPrePhysics)
      ..addSystem(animateCrabLegsSystem, schedule: Schedules.update);
  }
}
