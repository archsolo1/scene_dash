/// Marks a class as a *tag*: a component with presence but no data.
///
/// A tag store only tracks which entities carry the tag, so tags are used for
/// classification and as `requires`/`excludes` query filters.
final class Tag {
  const Tag();
}
