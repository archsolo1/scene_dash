import '../world/world.dart';
import 'access_conflict.dart';
import 'schedule_graph.dart';
import 'schedule_label.dart';
import 'system_registration.dart';

/// One named phase of the frame: an ordered collection of systems.
///
/// Systems are added during plugin build. At startup the schedule is [compile]d
/// once (topologically sorted and frozen); after that, [run] executes the
/// systems in their compiled order. Registration after compilation is rejected.
final class Schedule {
  /// The label identifying this schedule.
  final ScheduleLabel label;

  final List<SystemRegistration> _registrations = <SystemRegistration>[];
  List<SystemRegistration>? _compiled;

  /// Access conflicts detected between unordered systems during [compile].
  final List<AccessConflict> conflicts = <AccessConflict>[];

  Schedule(this.label);

  /// Whether this schedule has been compiled (and is therefore frozen).
  bool get isCompiled => _compiled != null;

  /// Number of systems registered.
  int get systemCount => _registrations.length;

  /// Adds a system registration. Throws if the schedule is already frozen.
  void add(SystemRegistration registration) {
    if (isCompiled) {
      throw StateError(
        'Cannot register systems in schedule "${label.id}" after it is '
        'compiled.',
      );
    }
    _registrations.add(registration);
  }

  /// Topologically sorts and freezes the schedule, then initializes every
  /// system adapter against [world].
  ///
  /// When [detectConflicts] is true, [conflicts] is populated with any
  /// access conflicts between unordered systems.
  void compile(World world, {bool detectConflicts = true}) {
    final result = ScheduleGraph.compile(
      label,
      _registrations,
      detectConflicts: detectConflicts,
    );
    for (final registration in result.ordered) {
      registration.adapter.initialize(world);
    }
    conflicts
      ..clear()
      ..addAll(result.conflicts);
    _compiled = result.ordered;
  }

  /// Runs every system in compiled order. Must be compiled first.
  void run() {
    final compiled = _compiled;
    if (compiled == null) {
      throw StateError('Schedule "${label.id}" has not been compiled.');
    }
    for (var i = 0; i < compiled.length; i++) {
      compiled[i].adapter.run();
    }
  }
}
