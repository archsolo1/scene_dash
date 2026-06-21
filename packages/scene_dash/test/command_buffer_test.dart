import 'package:scene_dash/scene_dash.dart';
import 'package:test/test.dart';

final class Health {
  final int value;
  const Health(this.value);
}

void main() {
  group('Commands (deferred structural changes)', () {
    late World world;

    setUp(() {
      world = World()..stores.register<Health>(ObjectComponentStore<Health>());
    });

    test('spawn reserves a live entity immediately', () {
      final entity = world.commands.spawn();
      expect(world.entities.isAlive(entity), isTrue);
    });

    test('insert is deferred until apply', () {
      final entity = world.commands.spawn();
      world.commands.insert<Health>(entity, const Health(100));

      expect(
          world.stores.object<Health>().containsIndex(entity.index), isFalse);
      world.commands.apply();
      expect(
        world.stores.object<Health>().valueOf(entity.index)?.value,
        100,
      );
    });

    test('remove and despawn are deferred until apply', () {
      final entity = world.commands.spawn();
      world.commands.insert<Health>(entity, const Health(50));
      world.commands.apply();

      world.commands.despawn(entity);
      expect(world.entities.isAlive(entity), isTrue, reason: 'still deferred');
      world.commands.apply();

      expect(world.entities.isAlive(entity), isFalse);
      expect(
          world.stores.object<Health>().containsIndex(entity.index), isFalse);
    });

    test('apply clears the queue', () {
      final entity = world.commands.spawn();
      world.commands.insert<Health>(entity, const Health(1));
      expect(world.commands.isEmpty, isFalse);
      world.commands.apply();
      expect(world.commands.isEmpty, isTrue);
    });

    test('entity commands provide fluent deferred operations', () {
      final entity = world.commands.spawn();
      world.commands
          .entity(entity)
          .insert<Health>(const Health(25))
          .remove<Health>()
          .insert<Health>(const Health(75));

      expect(world.tryGet<Health>(entity), isNull);
      world.commands.apply();
      expect(world.get<Health>(entity).value, 75);

      world.commands.entity(entity).despawn();
      expect(world.entities.isAlive(entity), isTrue);
      world.commands.apply();
      expect(world.entities.isAlive(entity), isFalse);
    });

    test('stale command targets assert when applied in debug mode', () {
      final entity = world.commands.spawn();
      world.commands.despawn(entity);
      world.commands.apply();

      world.commands.insert<Health>(entity, const Health(1));
      expect(world.commands.apply, throwsA(isA<AssertionError>()));
    });
  });
}
