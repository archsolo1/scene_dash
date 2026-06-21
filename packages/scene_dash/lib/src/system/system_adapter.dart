import '../world/world.dart';

/// The runtime contract for an executable system.
///
/// Generated code (Phase 2) produces a [SystemAdapter] per `@System` class that
/// resolves the system's queries and resources once in [initialize] and then
/// calls the user `run()` method in [run]. During Phase 1 these adapters are
/// written by hand for tests.
abstract interface class SystemAdapter {
  /// Resolves queries, resources and event handles from [world]. Called once,
  /// after all plugins have registered and stores exist.
  void initialize(World world);

  /// Executes the system. Called once per schedule run; must be synchronous.
  void run();
}
