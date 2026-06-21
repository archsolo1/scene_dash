import '../entity/entity.dart';
import '../world/world.dart';
import 'bundle.dart';
import 'entity_commands.dart';

/// Records deferred structural changes to be applied at a safe boundary.
///
/// Field writes through query references are immediate, but structural changes
/// (spawning, inserting/removing components, despawning) are deferred and
/// applied once the current schedule finishes, so sparse-set swap removal can
/// never invalidate a query that is still iterating.
///
/// Entity *allocation* is the one exception: [spawn] reserves a live entity
/// immediately so callers get a usable handle, while the component insertions
/// for that entity are deferred like everything else.
final class Commands {
  final World _world;
  final List<void Function(World)> _queue = <void Function(World)>[];

  Commands(this._world);

  /// Whether there are no pending commands.
  bool get isEmpty => _queue.isEmpty;

  /// Reserves a new entity immediately and returns its handle. If [bundle] is
  /// given, its component insertions are queued and applied on the next [apply]
  /// (so the entity exists right away but is populated at a safe boundary).
  Entity spawn([SceneDashBundle? bundle]) {
    final entity = _world.entities.spawn();
    if (bundle != null) {
      _queue.add((world) => bundle.insertInto(world, entity));
    }
    return entity;
  }

  /// Returns a fluent command handle targeting [entity].
  EntityCommands entity(Entity entity) => EntityCommands(this, entity);

  /// Queues inserting [component] of type [T] onto [entity].
  void insert<T>(Entity entity, T component) {
    _queue.add((world) => world.insertNow<T>(entity, component));
  }

  /// Queues removing the component of type [T] from [entity].
  void remove<T>(Entity entity) {
    _queue.add((world) => world.removeNow<T>(entity));
  }

  /// Queues despawning [entity].
  void despawn(Entity entity) {
    _queue.add((world) => world.despawnNow(entity));
  }

  /// Applies and clears all pending commands. Must not be called while a query
  /// is iterating.
  void apply() {
    assert(
      !_world.isQueryActive,
      'Commands.apply() called while a query is iterating.',
    );
    if (_queue.isEmpty) return;
    // Iterate by index: a command may enqueue follow-up commands, which should
    // also be applied in this flush.
    for (var i = 0; i < _queue.length; i++) {
      _queue[i](_world);
    }
    _queue.clear();
  }
}
