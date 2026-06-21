import 'package:scene_dash/scene_dash.dart';

import 'scene_commands.dart';
import 'scene_node_ref.dart';

/// Adds bound nodes to the scene graph automatically.
///
/// When an entity gains a [SceneNodeRef] whose node has no parent yet, this
/// system queues it under the scene root (through [SceneCommands]). Once the
/// node is parented it is skipped, so a node the game parents itself (custom
/// hierarchy) is left alone.
///
/// [Game] registers this in [Schedules.renderSync] automatically, so a `@Bundle`
/// can create its own `Node` and the entity becomes visible without any manual
/// scene-graph wiring.
final class SceneNodeMountAdapter implements SystemAdapter {
  final SceneCommands _sceneCommands;
  late final Query1<SceneNodeRef> _bound;

  SceneNodeMountAdapter(this._sceneCommands);

  @override
  void initialize(World world) {
    world.ensureObjectStore<SceneNodeRef>();
    _bound = world.query1<SceneNodeRef>();
  }

  @override
  void run() {
    _bound.each((entity, binding) {
      if (binding.node.parent == null) {
        _sceneCommands.add(binding.node);
      }
    });
  }
}
