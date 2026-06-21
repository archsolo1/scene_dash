/// Marks a class as a *bundle*: a typed recipe grouping several components for
/// a single entity.
///
/// Each field of the annotated class is one component to insert. The generator
/// emits the insertion code so `commands.spawn(bundle)` adds every component in
/// one call.
final class Bundle {
  const Bundle();
}
