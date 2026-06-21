/// A type-keyed container of singleton application resources.
///
/// Resources are ordinary Dart objects (config, input state, timers, physics
/// worlds, ...). Each type has at most one instance, injected into systems via
/// the `@Resource()` annotation.
final class Resources {
  final Map<Type, Object> _resources = <Type, Object>{};

  /// Inserts or replaces the resource instance for type [T].
  void insert<T extends Object>(T resource) {
    _resources[T] = resource;
  }

  /// The resource of type [T]. Throws [StateError] if none is registered.
  T get<T extends Object>() {
    final resource = _resources[T];
    if (resource == null) {
      throw StateError('No resource of type $T has been inserted.');
    }
    return resource as T;
  }

  /// The resource of type [T], or `null` if none is registered.
  T? tryGet<T extends Object>() => _resources[T] as T?;

  /// Whether a resource of type [T] is registered.
  bool contains<T extends Object>() => _resources.containsKey(T);

  /// Removes the resource of type [T], returning it if present.
  T? remove<T extends Object>() => _resources.remove(T) as T?;
}
