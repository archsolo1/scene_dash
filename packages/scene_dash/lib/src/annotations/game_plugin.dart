/// Marks a class as a *plugin*: the generator produces or validates a stable
/// plugin id, duplicate-plugin detection, referenced system adapters, optional
/// dependencies and debug metadata.
///
/// The plugin still registers its systems explicitly in `build`; the annotation
/// does not hide that behaviour.
final class GamePlugin {
  /// Plugin types this plugin requires to have been added first.
  final List<Type> requires;

  const GamePlugin({this.requires = const <Type>[]});
}
