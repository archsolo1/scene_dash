import 'component_store.dart';
import 'object_store.dart';
import 'tag_store.dart';

/// Maps a component [Type] to its single [ComponentStore].
///
/// Until code generation exists (Phase 2), stores are registered manually. The
/// registry is the source of truth queries and commands consult to find the
/// store for a component type.
final class StoreRegistry {
  final Map<Type, ComponentStore> _stores = <Type, ComponentStore>{};

  /// All registered stores. Used by despawn to strip an entity from every
  /// store it might belong to.
  Iterable<ComponentStore> get all => _stores.values;

  /// Registers [store] as the store for component type [T]. Throws if a store
  /// for [T] is already registered.
  void register<T>(ComponentStore store) {
    if (_stores.containsKey(T)) {
      throw StateError('A store for $T is already registered.');
    }
    _stores[T] = store;
  }

  /// Whether a store is registered for [type].
  bool isRegistered(Type type) => _stores.containsKey(type);

  /// The store registered for [type], or throws if none exists.
  ComponentStore require(Type type) {
    final store = _stores[type];
    if (store == null) {
      throw StateError(
        'No component store registered for $type. Register it before use.',
      );
    }
    return store;
  }

  /// The object store for component type [T].
  ObjectComponentStore<T> object<T>() => require(T) as ObjectComponentStore<T>;

  /// The tag store for tag type [T].
  TagStore tag<T>() => require(T) as TagStore;
}
