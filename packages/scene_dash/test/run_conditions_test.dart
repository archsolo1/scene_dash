import 'package:scene_dash/scene_dash.dart';
import 'package:test/test.dart';

final class Flag {
  bool value = false;
}

bool _flagSet(World world) => world.resource<Flag>().value;

void main() {
  late World world;

  setUp(() {
    world = World()..resources.insert(Flag());
  });

  test('not inverts a condition', () {
    expect(not(_flagSet)(world), isTrue);
    world.resource<Flag>().value = true;
    expect(not(_flagSet)(world), isFalse);
  });

  test('and passes only when both pass, and short-circuits', () {
    var evaluated = false;
    bool probe(World _) {
      evaluated = true;
      return true;
    }

    final both = _flagSet.and(probe);
    expect(both(world), isFalse);
    expect(evaluated, isFalse, reason: 'right side skipped when left fails');

    world.resource<Flag>().value = true;
    expect(both(world), isTrue);
    expect(evaluated, isTrue);
  });

  test('or passes when either passes, and short-circuits', () {
    var evaluated = false;
    bool probe(World _) {
      evaluated = true;
      return false;
    }

    world.resource<Flag>().value = true;
    final either = _flagSet.or(probe);
    expect(either(world), isTrue);
    expect(evaluated, isFalse, reason: 'right side skipped when left passes');

    world.resource<Flag>().value = false;
    expect(either(world), isFalse);
    expect(evaluated, isTrue);
  });

  test('hasEvents tracks the channel buffer', () {
    world.registerEvent<String>();
    final condition = hasEvents<String>();

    expect(condition(world), isFalse);
    world.eventChannel<String>().send('hit');
    expect(condition(world), isTrue);

    // With no readers, maintenance drops everything.
    world.updateEvents();
    expect(condition(world), isFalse);
  });

  test('hasEvents holds unread events through the retention window', () {
    world.registerEvent<String>();
    // A registered reader that does not drain: the event survives the pass
    // for the frame it was sent plus one more (default retention of 2),
    // then expires.
    world.eventChannel<String>().reader();
    final condition = hasEvents<String>();

    world.eventChannel<String>().send('hit');
    world.updateEvents();
    expect(condition(world), isTrue);
    world.updateEvents();
    expect(condition(world), isFalse);
  });

  test('hasEvents on an unregistered channel fails loudly', () {
    expect(() => hasEvents<int>()(world), throwsStateError);
  });
}
