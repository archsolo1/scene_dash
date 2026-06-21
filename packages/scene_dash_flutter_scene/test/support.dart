import 'package:scene_dash/scene_dash.dart';

/// A trivial hand-written adapter that records when it runs. Used to observe
/// which schedules the frame loop / driver dispatch.
final class CountAdapter implements SystemAdapter {
  final String name;
  final List<String> log;

  CountAdapter(this.name, this.log);

  @override
  void initialize(World world) {}

  @override
  void run() => log.add(name);
}
