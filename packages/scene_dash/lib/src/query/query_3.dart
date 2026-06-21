import '../entity/entity.dart';
import '../storage/component_store.dart';
import '../storage/object_store.dart';
import '../world/world.dart';
import 'query.dart';

/// Callback invoked once per matching entity for a three-component query.
typedef Query3Callback<A, B, C> = void Function(
  Entity entity,
  A a,
  B b,
  C c,
);

/// A cached query over three object components [A], [B] and [C], with optional
/// `requires`/`excludes` filters.
final class Query3<A, B, C> extends Query {
  final World _world;
  final ObjectComponentStore<A> _a;
  final ObjectComponentStore<B> _b;
  final ObjectComponentStore<C> _c;
  final List<ComponentStore> _withStores;
  final List<ComponentStore> _withoutStores;

  late final List<ComponentStore> _driverCandidates = <ComponentStore>[
    _a,
    _b,
    _c,
    ..._withStores,
  ];

  Query3(
    this._world,
    this._a,
    this._b,
    this._c,
    this._withStores,
    this._withoutStores,
  );

  /// Invokes [callback] for every live entity that has [A], [B] and [C] and
  /// satisfies the filters.
  void each(Query3Callback<A, B, C> callback) {
    final driver = Query.chooseDriver(_driverCandidates);
    final driverIsA = identical(driver, _a);
    final driverIsB = identical(driver, _b);
    final driverIsC = identical(driver, _c);
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

        if (!Query.passesFilters(entityIndex, _withStores, _withoutStores)) {
          continue;
        }

        callback(
          _world.entities.resolve(entityIndex),
          _a.valueAt(aDense),
          _b.valueAt(bDense),
          _c.valueAt(cDense),
        );
      }
    } finally {
      _world.endQuery();
    }
  }
}
