/// Combinators and common building blocks for [RunCondition]s.
///
/// Conditions compose with [RunConditionOps.and] / [RunConditionOps.or] and
/// invert with [not], so a gate like "playing, unless a cutscene is showing"
/// stays declarative at the registration site:
///
/// ```dart
/// app.addSystem(steerEnemiesSystem,
///     schedule: Schedules.update,
///     runIf: inState(GamePhase.overworld).and(not(cutsceneActive)));
/// ```
library;

import '../world/world.dart';
import 'system_registration.dart';

/// A condition that passes when [condition] does not.
RunCondition not(RunCondition condition) =>
    (World world) => !condition(world);

/// A condition that passes while the event channel for [T] buffers any
/// events — Bevy's `on_event`.
///
/// Keyed off the channel buffer: `true` while any event is still buffered —
/// events not yet consumed by every reader, capped by the retention window
/// (under the default retention, the frame an event is sent plus the
/// following one). The channel must have been registered with
/// `addEvent<T>()`; the condition throws otherwise, so a typo'd event type
/// fails loudly rather than silently never running.
///
/// ```dart
/// app.addSystem(playHitEffectsSystem,
///     schedule: Schedules.update, runIf: hasEvents<HitEvent>());
/// ```
RunCondition hasEvents<T>() =>
    (World world) => world.eventChannel<T>().isNotEmpty;

/// Short-circuiting composition of [RunCondition]s.
extension RunConditionOps on RunCondition {
  /// Passes only when both this condition and [other] pass. [other] is not
  /// evaluated when this condition fails.
  RunCondition and(RunCondition other) =>
      (World world) => this(world) && other(world);

  /// Passes when either this condition or [other] passes. [other] is not
  /// evaluated when this condition passes.
  RunCondition or(RunCondition other) =>
      (World world) => this(world) || other(world);
}
