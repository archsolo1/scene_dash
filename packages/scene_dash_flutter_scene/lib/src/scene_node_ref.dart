import 'package:flutter_scene/scene.dart' show Node;
import 'package:scene_dash/scene_dash.dart';

/// An object component that binds an ECS entity to a `flutter_scene` [Node].
///
/// Transform synchronization writes the bound node's **local** transform;
/// `flutter_scene` then performs its own hierarchy/world-transform propagation.
///
/// Annotated `@ObjectComponent` so that game code which references it in
/// `@Bundle`/`@Query` is classified correctly by the generator. The integration
/// does not run code generation itself; it registers the store on demand.
@ObjectComponent()
final class SceneNodeRef {
  /// The bound scene-graph node.
  final Node node;

  const SceneNodeRef(this.node);
}

/// Tag marking an entity whose node transform is owned by physics (or another
/// authority), so generic ECS transform synchronization must skip it.
///
/// See "transform authority" in `docs/concept.md` §22: every bound node must
/// have exactly one transform source.
@Tag()
final class PhysicsDriven {
  const PhysicsDriven();
}
