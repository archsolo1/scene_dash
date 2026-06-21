import 'package:flutter_scene/scene.dart' show Node;
import 'package:scene_dash/scene_dash.dart';

import 'scene_commands.dart';
import 'scene_node_ref.dart';

/// Keeps the scene graph in sync with entity-bound [SceneNodeRef]s: mounts new
/// nodes and detaches them again when their entity goes away.
///
/// Each run it reconciles the set of bound nodes against the scene:
///
/// * a newly bound node with no parent is queued under the scene root (through
///   [SceneCommands]) and remembered;
/// * a node the integration previously mounted whose binding has gone — the
///   entity was despawned, the [SceneNodeRef] was removed, or it was replaced
///   with a different node — is queued for detachment.
///
/// A node the game parents itself (custom hierarchy) is never adopted and never
/// auto-detached: only nodes this adapter mounted are tracked. This makes the
/// common case — `commands.spawn(bundle)` then later `commands.despawn(entity)`
/// — clean up its scene node automatically, with no manual `SceneCommands.remove`
/// in game code.
///
/// [Game] registers this in [Schedules.renderSync] automatically.
final class SceneNodeMountAdapter implements SystemAdapter {
  final SceneCommands _sceneCommands;
  late final Query1<SceneNodeRef> _bound;

  /// Nodes this adapter mounted and is responsible for detaching.
  final Set<Node> _mounted = <Node>{};

  /// Scratch set of nodes seen this run (reused to avoid per-frame allocation).
  final Set<Node> _seen = <Node>{};

  SceneNodeMountAdapter(this._sceneCommands);

  @override
  void initialize(World world) {
    world.ensureObjectStore<SceneNodeRef>();
    _bound = world.query1<SceneNodeRef>();
  }

  @override
  void run() {
    _seen.clear();
    _bound.each((entity, binding) {
      final node = binding.node;
      _seen.add(node);
      if (_mounted.contains(node)) return;
      // Adopt only nodes that have no parent yet; a node the game parented
      // itself is left alone (and never tracked for auto-detach).
      if (node.parent == null) {
        _sceneCommands.add(node);
        _mounted.add(node);
      }
    });
    // Detach nodes we mounted whose binding disappeared (despawn, component
    // removal, or replacement with a different node).
    _mounted.removeWhere((node) {
      if (_seen.contains(node)) return false;
      _sceneCommands.remove(node);
      return true;
    });
  }
}
