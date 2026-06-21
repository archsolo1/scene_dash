/// Per-frame timing, updated at the start of each rendered frame.
///
/// A resource; inject it into systems with `@Resource()`.
final class FrameTime {
  /// Seconds elapsed since the previous frame.
  double delta = 0;

  /// Total time elapsed since the app started.
  Duration elapsed = Duration.zero;

  /// Number of frames rendered so far.
  int frame = 0;
}
