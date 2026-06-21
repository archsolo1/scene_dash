/// Marks a class as a *system*: the generator inspects its synchronous `run(...)`
/// method and emits a `SystemAdapter` that resolves and injects the declared
/// queries, resources, commands and event handles.
///
/// The annotated class must extend `GameSystem` and its `run` method must be
/// synchronous.
final class System {
  const System();
}
