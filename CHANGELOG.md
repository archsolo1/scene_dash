## recent

* Allocation-free `Node` transform extensions in `scene_dash_flutter_scene`:
  `setLocalTRS`/`setLocalUniform` (in-place rebuild that trips the dirty
  flag) and `globalTranslationInto`/`localTranslationInto` (the no-alloc
  replacement for `getTranslation()`).
* `DespawnOnExit` is now annotated `@ObjectComponent`, so bundles can carry
  it as a field and a spawn recipe scopes itself to a state value.
* `scene_game` example modernized onto the new primitives: per-feature
  `OnEnter`/`OnExit` reset systems replace the 12-resource `StartRunSystem`;
  blaster/shield/spawners/run-clock use `GameTimer`/`GameStopwatch`; bundles
  self-scope with `DespawnOnExit`; shared `approach`/layer-filter helpers;
  the HUD snapshot is a record typedef; crab gait math extracted to
  `player/animation/gait.dart` with pose-geometry regression tests.
* `Commands.spawn` now returns `EntityCommands` (was `Entity`),
  so a spawn can be decorated in place — `commands.spawn(bundle)..insert(...)`
  — matching Bevy's `commands.spawn(...).insert(...)`. Take `.entity` off the
  result where the handle itself is needed. This also makes the documented
  `DespawnOnExit` spawn idiom compile as written.
* Run-condition composition: `.and`/`.or` combinators on `RunCondition`,
  `not(...)`, and a `hasEvents<T>()` condition (Bevy's `on_event`) that passes
  while an event channel has anything buffered.
* `addSystems(schedule, [a, b, c], runIf: ..., chained: ...)` batch
  registration — the shape of Bevy's `add_systems(Update, (a, b, c))`, with
  `chained` adding sequential `after` constraints like `.chain()`.
* `GameTimer` (one-shot or repeating, with `justFinished`,
  `completionsThisTick`, `fraction`) and `GameStopwatch`: tick-driven timing
  value types modeled on Bevy's `Timer`/`Stopwatch`. Driven by
  `FrameTime`/`FixedTime` deltas, so they follow the `GameClock` for free.
* Game-time clock: a `GameClock` resource with `timeScale`, `paused`, and
  `freezeFor` (hitstop). The standard driver applies it at frame start, and
  `Game.onTick` now drives `Scene.update` explicitly with the scaled delta,
  so physics stepping, animations, and gameplay slow or halt together; the
  fixed timestep itself is unchanged (slow motion runs fewer fixed steps).
  `FrameTime` gains `unscaledDelta` for systems that keep moving while game
  time is stopped (HUD, camera shake, pause menus).
* First-class game states: `addState<S>(initial)` registers a state machine
  with `CurrentState<S>`/`NextState<S>` resources, `OnEnter`/`OnExit`
  lifecycle schedules, an `inState` run condition, and automatic despawning of
  `DespawnOnExit`-scoped entities on transition. Transitions apply at the
  frame-start boundary (`App.applyStateTransitions`); chained transitions
  settle in one pass and cycles fail loudly.

