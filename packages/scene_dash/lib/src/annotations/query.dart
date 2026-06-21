/// Declares the access pattern and filters for a query parameter of a
/// `@System` `run` method.
///
/// ```dart
/// void run(
///   @Query(
///     writes: [Transform],
///     requires: [Player],
///     excludes: [Disabled],
///   )
///   Query2<Transform, Velocity> players,
/// ) { ... }
/// ```
///
/// Naming note: the concept used `with:`/`without:`, but `with` is a reserved
/// word in Dart and cannot be a parameter name. This annotation therefore uses
/// [requires] (the "with" filter) and [excludes] (the "without" filter). The
/// generated code maps these onto the world's `withTypes`/`withoutTypes`.
final class Query {
  /// Component types this system mutates. Components not listed here are
  /// read-only for the query; writing them is rejected in debug builds.
  final List<Type> writes;

  /// Component or tag types an entity must have to match ("with" filter).
  final List<Type> requires;

  /// Component or tag types an entity must not have to match ("without"
  /// filter).
  final List<Type> excludes;

  const Query({
    this.writes = const <Type>[],
    this.requires = const <Type>[],
    this.excludes = const <Type>[],
  });
}
