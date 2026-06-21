import '../entity/entity.dart';
import '../storage/component_store.dart';
import '../storage/object_store.dart';
import '../world/world.dart';
import 'query.dart';

/// Callback invoked once per matching entity for a four-component query.
typedef Query4Callback<A, B, C, D> = void Function(
  Entity entity,
  A a,
  B b,
  C c,
  D d,
);

/// A cached query over four object components [A], [B], [C] and [D], with
/// optional `requires`/`excludes` filters.
final class Query4<A, B, C, D> extends Query {
  final World _world;
  final ObjectComponentStore<A> _a;
  final ObjectComponentStore<B> _b;
  final ObjectComponentStore<C> _c;
  final ObjectComponentStore<D> _d;
  final List<ComponentStore> _withStores;
  final List<ComponentStore> _withoutStores;

  late final List<ComponentStore> _driverCandidates = <ComponentStore>[
    _a,
    _b,
    _c,
    _d,
    ..._withStores,
  ];

  Query4(
    this._world,
    this._a,
    this._b,
    this._c,
    this._d,
    this._withStores,
    this._withoutStores,
  );

  /// Invokes [callback] for every live entity that has [A], [B], [C] and [D]
  /// and satisfies the filters.
  void each(Query4Callback<A, B, C, D> callback) {
    final driver = Query.chooseDriver(_driverCandidates);
    final driverIsA = identical(driver, _a);
    final driverIsB = identical(driver, _b);
    final driverIsC = identical(driver, _c);
    final driverIsD = identical(driver, _d);
    _world.beginQuery();
    try {
      for (var i = 0; i < driver.length; i++) {
        final entityIndex = driver.entityIndexAt(i);

        final aDense = driverIsA ? i : _a.denseIndexOf(entityIndex);
        if (aDense < 0) continue;

        final bDense = driverIsB ? i : _b.denseIndexOf(entityIndex);
        if (bDense < 0) continue;

        final cDense = driverIsC ? i : _c.denseIndexOf(entityIndex);
        if (cDense < 0) continue;

        final dDense = driverIsD ? i : _d.denseIndexOf(entityIndex);
        if (dDense < 0) continue;

        if (!Query.passesFilters(entityIndex, _withStores, _withoutStores)) {
          continue;
        }

        callback(
          _world.entities.resolve(entityIndex),
          _a.valueAt(aDense),
          _b.valueAt(bDense),
          _c.valueAt(cDense),
          _d.valueAt(dDense),
        );
      }
    } finally {
      _world.endQuery();
    }
  }
}
