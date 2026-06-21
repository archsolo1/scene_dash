/// A stable identifier for a schedule (a named phase of the frame).
///
/// Schedules group systems and define when, relative to the frame and the
/// physics step, those systems run.
final class ScheduleLabel {
  /// The unique identifier string.
  final String id;

  const ScheduleLabel(this.id);

  @override
  bool operator ==(Object other) => other is ScheduleLabel && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ScheduleLabel($id)';
}
