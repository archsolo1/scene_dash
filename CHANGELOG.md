## Unreleased

* First-class game states: `addState<S>(initial)` registers a state machine
  with `CurrentState<S>`/`NextState<S>` resources, `OnEnter`/`OnExit`
  lifecycle schedules, an `inState` run condition, and automatic despawning of
  `DespawnOnExit`-scoped entities on transition. Transitions apply at the
  frame-start boundary (`App.applyStateTransitions`); chained transitions
  settle in one pass and cycles fail loudly.

## 0.0.1

* TODO: Describe initial release.
