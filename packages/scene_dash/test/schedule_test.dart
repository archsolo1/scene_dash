import 'package:scene_dash/scene_dash.dart';
import 'package:test/test.dart';

/// A minimal hand-written adapter that records when it runs.
final class RecordingAdapter implements SystemAdapter {
  final String name;
  final List<String> log;
  RecordingAdapter(this.name, this.log);

  @override
  void initialize(World world) {}

  @override
  void run() => log.add(name);
}

void main() {
  group('Schedule ordering', () {
    test('runs unconstrained systems in registration order', () {
      final log = <String>[];
      final app = App()
        ..addSystemAdapter(
          RecordingAdapter('a', log),
          schedule: Schedules.update,
          label: const SystemLabel('a'),
        )
        ..addSystemAdapter(
          RecordingAdapter('b', log),
          schedule: Schedules.update,
          label: const SystemLabel('b'),
        );
      app.start();
      app.runSchedule(Schedules.update);
      expect(log, <String>['a', 'b']);
    });

    test('respects after edges', () {
      final log = <String>[];
      final app = App()
        ..addSystemAdapter(
          RecordingAdapter('move', log),
          schedule: Schedules.update,
          label: const SystemLabel('move'),
          after: const [SystemLabel('input')],
        )
        ..addSystemAdapter(
          RecordingAdapter('input', log),
          schedule: Schedules.update,
          label: const SystemLabel('input'),
        );
      app.start();
      app.runSchedule(Schedules.update);
      expect(log, <String>['input', 'move']);
    });

    test('detects duplicate labels at start', () {
      final log = <String>[];
      final app = App()
        ..addSystemAdapter(
          RecordingAdapter('a', log),
          schedule: Schedules.update,
          label: const SystemLabel('dup'),
        )
        ..addSystemAdapter(
          RecordingAdapter('b', log),
          schedule: Schedules.update,
          label: const SystemLabel('dup'),
        );
      expect(app.start, throwsStateError);
    });

    test('detects references to unknown labels at start', () {
      final log = <String>[];
      final app = App()
        ..addSystemAdapter(
          RecordingAdapter('a', log),
          schedule: Schedules.update,
          label: const SystemLabel('a'),
          after: const [SystemLabel('does-not-exist')],
        );
      expect(app.start, throwsStateError);
    });

    test('detects dependency cycles at start', () {
      final log = <String>[];
      final app = App()
        ..addSystemAdapter(
          RecordingAdapter('a', log),
          schedule: Schedules.update,
          label: const SystemLabel('a'),
          after: const [SystemLabel('b')],
        )
        ..addSystemAdapter(
          RecordingAdapter('b', log),
          schedule: Schedules.update,
          label: const SystemLabel('b'),
          after: const [SystemLabel('a')],
        );
      expect(app.start, throwsStateError);
    });

    test('rejects registering systems after start', () {
      final app = App()..start();
      expect(
        () => app.addSystemAdapter(
          RecordingAdapter('late', <String>[]),
          schedule: Schedules.update,
          label: const SystemLabel('late'),
        ),
        throwsStateError,
      );
    });

    test('rejects builder mutations after start', () {
      final app = App()..start();

      expect(() => app.addPlugin(const _EmptyPlugin()), throwsStateError);
      expect(app.addEvent<String>, throwsStateError);
      expect(() => app.insertResource<Object>(Object()), throwsStateError);
      expect(() => app.addCleanup(() {}), throwsStateError);
    });

    test('shutdown runs schedule then async cleanups once in reverse order',
        () async {
      final log = <String>[];
      final app = App()
        ..addSystemAdapter(
          RecordingAdapter('shutdown', log),
          schedule: Schedules.shutdown,
          label: const SystemLabel('shutdown.probe'),
        )
        ..addCleanup(() async {
          await Future<void>.delayed(Duration.zero);
          log.add('cleanup-a');
        })
        ..addCleanup(() {
          log.add('cleanup-b');
        });

      app.start();
      await app.shutdown();
      await app.shutdown();

      expect(log, <String>['shutdown', 'cleanup-b', 'cleanup-a']);
    });
  });
}

final class _EmptyPlugin extends Plugin {
  const _EmptyPlugin();

  @override
  void build(AppBuilder app) {}
}
