/// Marks a class as an *object* component: a normal, dense Dart-object
/// component stored in a `List` parallel to the dense entity rows.
///
/// Use this for references and complex objects (scene-node handles,
/// inventories, ...) that cannot be flattened into numeric typed arrays.
///
/// Named `ObjectComponent` rather than `Component` because `flutter_scene`
/// already defines a `Component` type; the explicit name also makes storage
/// intent clear.
final class ObjectComponent {
  const ObjectComponent();
}
