import '../entity/entity.dart';
import '../storage/component_store.dart';
import '../storage/object_store.dart';
import '../world/world.dart';
import 'query.dart';

/// Callback invoked once per matching entity for a single-component query.
typedef Query1Callback<A> = void Function(Entity entity, A a);

/// A cached query over one object component [A], with optional `with`/`without`
/// filters.
final class Query1<A> extends Query {
  final World _world;
  final ObjectComponentStore<A> _a;
  final List<ComponentStore> _withStores;
  final List<ComponentStore> _withoutStores;

  /// Stores considered when choosing the smallest iteration driver.
  late final List<ComponentStore> _driverCandidates = <ComponentStore>[
    _a,
    ..._withStores,
  ];

  Query1(this._world, this._a, this._withStores, this._withoutStores);

  /// Invokes [callback] for every live entity that has component [A] and
  /// satisfies the filters. The component value is passed directly; no
  /// allocations occur per entity.
  void each(Query1Callback<A> callback) {
    final driver = Query.chooseDriver(_driverCandidates);
    final driverIsA = identical(driver, _a);
    _world.beginQuery();
    try {
      for (var i = 0; i < driver.length; i++) {
        final entityIndex = driver.entityIndexAt(i);

        final aDense = driverIsA ? i : _a.denseIndexOf(entityIndex);
        if (aDense < 0) continue;

        if (!Query.passesFilters(entityIndex, _withStores, _withoutStores)) {
          continue;
        }

        callback(_world.entities.resolve(entityIndex), _a.valueAt(aDense));
      }
    } finally {
      _world.endQuery();
    }
  }

  /// The number of entities the driver store currently holds. This is an upper
  /// bound on matches, not the exact match count.
  int get driverLength => Query.chooseDriver(_driverCandidates).length;
}
