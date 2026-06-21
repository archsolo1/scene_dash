import '../system/system_adapter.dart';
import 'system_label.dart';

/// A single system registered into a schedule, with its ordering constraints.
final class SystemRegistration {
  /// The adapter that initializes and runs the system.
  final SystemAdapter adapter;

  /// This system's unique label within its schedule.
  final SystemLabel label;

  /// Labels this system must run after.
  final List<SystemLabel> after;

  /// Labels this system must run before.
  final List<SystemLabel> before;

  const SystemRegistration({
    required this.adapter,
    required this.label,
    this.after = const <SystemLabel>[],
    this.before = const <SystemLabel>[],
  });
}
