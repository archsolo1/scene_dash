import 'package:scene_dash/scene_dash.dart';
import 'package:vector_math/vector_math.dart' show Matrix4;

import 'scene_node_ref.dart';

/// Extracts a node-local translation `(x, y, z)` from a game transform
/// component of type [T].
typedef NodeTranslation<T> = (double x, double y, double z) Function(
    T transform);

/// Writes a game transform component [source] into [target], the bound node's
/// mutable local transform matrix.
typedef NodeTransformWriter<T> = void Function(T source, Matrix4 target);

/// Hand-written system adapter that writes each entity's transform onto its
/// bound [SceneNodeRef] node.
///
/// It mutates the existing local-transform matrix in place (no per-entity
/// `Matrix4` allocation) and marks the node dirty so `flutter_scene`
/// recomputes world transforms. Entities tagged [PhysicsDriven] are excluded —
/// their nodes are driven by another authority.
final class SyncSceneNodesAdapter<T extends Object> implements SystemAdapter {
  final NodeTransformWriter<T> _writeTransform;
  late final Query2<T, SceneNodeRef> _query;

  SyncSceneNodesAdapter(NodeTranslation<T> translationOf)
      : _writeTransform = _writerFromTranslation(translationOf);

  SyncSceneNodesAdapter.full(this._writeTransform);

  @override
  void initialize(World world) {
    world
      ..ensureObjectStore<T>()
      ..ensureObjectStore<SceneNodeRef>()
      ..ensureTagStore<PhysicsDriven>();
    _query = world.query2<T, SceneNodeRef>(
      withoutTypes: const [PhysicsDriven],
    );
  }

  @override
  void run() {
    _query.each((entity, transform, binding) {
      _writeTransform(transform, binding.node.localTransform);
      binding.node.markTransformDirty();
    });
  }

  static NodeTransformWriter<T> _writerFromTranslation<T>(
    NodeTranslation<T> translationOf,
  ) {
    return (source, target) {
      final (x, y, z) = translationOf(source);
      target.setTranslationRaw(x, y, z);
    };
  }
}

/// Synchronizes a game's own transform component [T] onto bound nodes, for
/// games that do not use the integration's standard `SceneTransform` (which `Game`
/// syncs automatically):
///
/// ```dart
/// game.addPlugin(CustomSceneSyncPlugin<MyTransform>(
///   translationOf: (t) => (t.x, t.y, t.z),
/// ));
///
/// game.addPlugin(CustomSceneSyncPlugin<MyFullTransform>(
///   writeTransform: (source, target) {
///     target.setFromTranslationRotationScale(
///       source.translation,
///       source.rotation,
///       source.scale,
///     );
///   },
/// ));
/// ```
final class CustomSceneSyncPlugin<T extends Object> extends Plugin {
  final NodeTranslation<T>? translationOf;
  final NodeTransformWriter<T>? writeTransform;
  final SystemLabel label;

  CustomSceneSyncPlugin({
    this.translationOf,
    this.writeTransform,
    this.label = const SystemLabel('scene.syncCustomTransform'),
  }) {
    if ((translationOf == null) == (writeTransform == null)) {
      throw ArgumentError(
        'Provide exactly one of translationOf or writeTransform.',
      );
    }
  }

  @override
  void build(AppBuilder app) {
    final writer = writeTransform;
    app.addSystemAdapter(
      writer == null
          ? SyncSceneNodesAdapter<T>(translationOf!)
          : SyncSceneNodesAdapter<T>.full(writer),
      schedule: Schedules.renderSync,
      label: label,
    );
  }
}
