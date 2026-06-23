import '../commands/commands.dart';
import '../entity/entity.dart';
import '../entity/entity_registry.dart';
import '../events/event_channel.dart';
import '../query/query_1.dart';
import '../query/query_2.dart';
import '../query/query_3.dart';
import '../query/query_4.dart';
import '../resources/resources.dart';
import '../storage/object_store.dart';
import '../storage/store_registry.dart';
import '../storage/tag_store.dart';

/// The container for all ECS state: entities, component stores, resources and
/// event channels.
///
/// The world exposes *immediate* structural operations ([insertNow],
/// [removeNow], [despawnNow]) that mutate storage directly. Game code should
/// normally go through deferred `Commands` instead; the immediate variants are
/// what the command buffer and generated bundle adapters call once it is safe
/// to apply structural changes.
final class World {
  /// Generational entity allocator.
  final EntityRegistry entities = EntityRegistry();

  /// Component-type to store mapping.
  final StoreRegistry stores = StoreRegistry();

  /// Singleton application resources.
  final Resources resources = Resources();

  /// The shared deferred-command buffer for this world. Systems record
  /// structural changes here; the app flushes it after each schedule.
  late final Commands commands = Commands(this);

  final Map<Type, Object> _eventChannels = <Type, Object>{};

  /// Number of queries currently iterating. Used by debug guards to detect
  /// structural mutation during active iteration.
  int _activeQueries = 0;

  /// Returns the object store for component type [T], registering a fresh one
  /// if none exists yet. Idempotent. Generated adapters and bundle inserts call
  /// this so component types are registered on first use.
  ObjectComponentStore<T> ensureObjectStore<T>() => stores.ensureObject<T>();

  /// Returns the tag store for tag type [T], registering a fresh one if none
  /// exists yet. Idempotent.
  TagStore ensureTagStore<T>() => stores.ensureTag<T>();

  /// Registers an event channel for event type [T] if one does not yet exist.
  void registerEvent<T>() {
    _eventChannels.putIfAbsent(T, EventChannel<T>.new);
  }

  /// The event channel for event type [T]. Throws if it was never registered.
  EventChannel<T> eventChannel<T>() {
    final channel = _eventChannels[T];
    if (channel == null) {
      throw StateError(
        'No event channel registered for $T. Call addEvent<$T>() first.',
      );
    }
    return channel as EventChannel<T>;
  }

  /// Advances every event channel, reclaiming fully-consumed events.
  void updateEvents() {
    for (final channel in _eventChannels.values) {
      (channel as dynamic).update();
    }
  }

  /// Whether [entity] currently refers to a live entity.
  bool isAlive(Entity entity) => entities.isAlive(entity);

  /// Whether live [entity] currently has component or tag [T].
  bool has<T>(Entity entity) {
    if (!entities.isAlive(entity) || !stores.isRegistered(T)) return false;
    return stores.require(T).containsIndex(entity.index);
  }

  /// The component of type [T] on live [entity].
  ///
  /// Throws if the entity is stale, the component store is not registered, or
  /// the entity does not currently have [T].
  T get<T>(Entity entity) {
    if (!entities.isAlive(entity)) {
      throw StateError('Cannot get $T from stale entity $entity.');
    }
    final store = stores.object<T>();
    final value = store.valueOf(entity.index);
    if (value == null) {
      throw StateError('Entity $entity does not have component $T.');
    }
    return value;
  }

  /// The component of type [T] on [entity], or `null` if absent or stale.
  T? tryGet<T>(Entity entity) {
    if (!entities.isAlive(entity) || !stores.isRegistered(T)) return null;
    return stores.object<T>().valueOf(entity.index);
  }

  /// The resource of type [T].
  T resource<T extends Object>() => resources.get<T>();

  /// The resource of type [T], or `null` if none is registered.
  T? tryResource<T extends Object>() => resources.tryGet<T>();

  /// Whether a resource of type [T] is registered.
  bool hasResource<T extends Object>() => resources.contains<T>();

  /// Inserts or replaces component [component] (of type [T]) on [entity].
  void insertNow<T>(Entity entity, T component) {
    assert(
      _activeQueries == 0,
      'Structural mutation (insert) while a query is iterating.',
    );
    assert(
      entities.isAlive(entity),
      'Cannot insert $T on stale entity $entity.',
    );
    if (!entities.isAlive(entity)) return;
    stores.require(T).insertDynamic(entity.index, component);
  }

  /// Removes the component of type [T] from [entity], if present.
  void removeNow<T>(Entity entity) {
    assert(
      _activeQueries == 0,
      'Structural mutation (remove) while a query is iterating.',
    );
    assert(
      entities.isAlive(entity),
      'Cannot remove $T from stale entity $entity.',
    );
    if (!entities.isAlive(entity)) return;
    if (stores.isRegistered(T)) {
      stores.require(T).removeEntityIndex(entity.index);
    }
  }

  /// Despawns [entity], stripping it from every store first.
  void despawnNow(Entity entity) {
    assert(
      _activeQueries == 0,
      'Structural mutation (despawn) while a query is iterating.',
    );
    assert(entities.isAlive(entity), 'Cannot despawn stale entity $entity.');
    if (!entities.isAlive(entity)) return;
    final index = entity.index;
    for (final store in stores.all) {
      store.removeEntityIndex(index);
    }
    entities.despawn(entity);
  }

  /// Creates a single-component query over component type [A].
  Query1<A> query1<A>({
    List<Type> withTypes = const <Type>[],
    List<Type> withoutTypes = const <Type>[],
  }) {
    return Query1<A>(
      this,
      stores.object<A>(),
      withTypes.map(stores.require).toList(growable: false),
      withoutTypes.map(stores.require).toList(growable: false),
    );
  }

  /// Creates a two-component query over component types [A] and [B].
  Query2<A, B> query2<A, B>({
    List<Type> withTypes = const <Type>[],
    List<Type> withoutTypes = const <Type>[],
  }) {
    return Query2<A, B>(
      this,
      stores.object<A>(),
      stores.object<B>(),
      withTypes.map(stores.require).toList(growable: false),
      withoutTypes.map(stores.require).toList(growable: false),
    );
  }

  /// Creates a three-component query over [A], [B] and [C].
  Query3<A, B, C> query3<A, B, C>({
    List<Type> withTypes = const <Type>[],
    List<Type> withoutTypes = const <Type>[],
  }) {
    return Query3<A, B, C>(
      this,
      stores.object<A>(),
      stores.object<B>(),
      stores.object<C>(),
      withTypes.map(stores.require).toList(growable: false),
      withoutTypes.map(stores.require).toList(growable: false),
    );
  }

  /// Creates a four-component query over [A], [B], [C] and [D].
  Query4<A, B, C, D> query4<A, B, C, D>({
    List<Type> withTypes = const <Type>[],
    List<Type> withoutTypes = const <Type>[],
  }) {
    return Query4<A, B, C, D>(
      this,
      stores.object<A>(),
      stores.object<B>(),
      stores.object<C>(),
      stores.object<D>(),
      withTypes.map(stores.require).toList(growable: false),
      withoutTypes.map(stores.require).toList(growable: false),
    );
  }

  /// Begins query iteration (debug guard bookkeeping). Returns when iteration
  /// is allowed to proceed.
  void beginQuery() => _activeQueries++;

  /// Ends query iteration started by [beginQuery].
  void endQuery() => _activeQueries--;

  /// Whether any query is currently iterating.
  bool get isQueryActive => _activeQueries > 0;
}
