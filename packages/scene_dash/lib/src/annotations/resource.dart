/// Marks a `@System` `run` parameter as an injected application resource.
///
/// The generated adapter resolves the resource from the world once during
/// initialization and passes the same instance on every run.
final class Resource {
  const Resource();
}
