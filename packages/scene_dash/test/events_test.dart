import 'package:scene_dash/scene_dash.dart';
import 'package:test/test.dart';

final class Pinged {
  final int id;
  const Pinged(this.id);
}

void main() {
  group('EventChannel', () {
    test('a reader drains only events sent after it was created', () {
      final channel = EventChannel<Pinged>();
      channel.send(const Pinged(0)); // before reader exists
      final reader = channel.reader();
      channel.send(const Pinged(1));
      channel.send(const Pinged(2));

      expect(reader.drain().map((e) => e.id), <int>[1, 2]);
      expect(reader.drain(), isEmpty, reason: 'cursor advanced');
    });

    test('readers have independent cursors', () {
      final channel = EventChannel<Pinged>();
      final a = channel.reader();
      final b = channel.reader();

      channel.send(const Pinged(1));
      expect(a.drain().map((e) => e.id), <int>[1]);
      // b has not read yet, so it still sees the event.
      expect(b.drain().map((e) => e.id), <int>[1]);
    });

    test('update reclaims events all readers have consumed', () {
      final channel = EventChannel<Pinged>();
      final reader = channel.reader();
      channel.send(const Pinged(1));
      reader.drain();
      channel.update(); // event 1 fully consumed

      channel.send(const Pinged(2));
      expect(reader.drain().map((e) => e.id), <int>[2]);
    });

    test('a slow reader still receives events after update', () {
      final channel = EventChannel<Pinged>();
      final fast = channel.reader();
      final slow = channel.reader();

      channel.send(const Pinged(1));
      fast.drain(); // slow has not read
      channel.update(); // must keep event 1 for slow

      expect(slow.drain().map((e) => e.id), <int>[1]);
    });

    test('writer sends to readers', () {
      final channel = EventChannel<Pinged>();
      final reader = channel.reader();
      channel.writer().send(const Pinged(7));
      expect(reader.drain().map((e) => e.id), <int>[7]);
    });

    test('forEach reads unread events without affecting other readers', () {
      final channel = EventChannel<Pinged>();
      final a = channel.reader();
      final b = channel.reader();

      channel
        ..send(const Pinged(1))
        ..send(const Pinged(2));

      final seen = <int>[];
      a.forEach((event) => seen.add(event.id));

      expect(seen, <int>[1, 2]);
      expect(a.hasUnread, isFalse);
      expect(b.drain().map((e) => e.id), <int>[1, 2]);
    });

    test('forEach leaves cursor unchanged when callback throws', () {
      final channel = EventChannel<Pinged>();
      final reader = channel.reader();
      channel
        ..send(const Pinged(1))
        ..send(const Pinged(2));

      expect(
        () => reader.forEach((event) {
          if (event.id == 1) throw StateError('boom');
        }),
        throwsStateError,
      );

      expect(reader.drain().map((e) => e.id), <int>[1, 2]);
    });
  });

  group('World event channels', () {
    test('registers and exposes a channel', () {
      final world = World()..registerEvent<Pinged>();
      final reader = world.eventChannel<Pinged>().reader();
      world.eventChannel<Pinged>().send(const Pinged(3));
      expect(reader.drain().map((e) => e.id), <int>[3]);
    });

    test('throws for an unregistered event type', () {
      final world = World();
      expect(world.eventChannel<Pinged>, throwsStateError);
    });
  });
}
