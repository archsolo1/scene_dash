import 'system_adapter.dart';

/// Base class for user-authored systems.
///
/// A `@System` class extends [GameSystem] and declares a synchronous `run(...)`
/// method whose parameters (queries, resources, commands, event readers and
/// writers) are injected by a generated [SystemAdapter].
///
/// The generator emits a `mixin _$YourSystem on YourSystem` that implements
/// [createAdapter]; apply it with `class YourSystem extends GameSystem with
/// _$YourSystem`. `AppBuilder.addSystem` calls [createAdapter] to obtain the
/// adapter, so game code registers the system itself, never the adapter.
abstract base class GameSystem {
  const GameSystem();

  /// Builds the generated adapter that injects this system's parameters and
  /// invokes its `run` method. Provided by the generated `_$YourSystem` mixin.
  SystemAdapter createAdapter();
}
