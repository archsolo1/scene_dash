import 'package:scene_dash/scene_dash.dart';
import 'package:test/test.dart';

final class Position {
  double x;
  Position(this.x);
}

final class Config {
  final int value;
  const Config(this.value);
}

void main() {
  group('World helpers', () {
    late World world;

    setUp(() {
      world = World()
        ..stores.register<Position>(ObjectComponentStore<Position>());
    });

    test('has, get and tryGet reflect component membership', () {
      final entity = world.entities.spawn();
      final missing = world.entities.spawn();
      world.insertNow<Position>(entity, Position(3));

      expect(world.isAlive(entity), isTrue);
      expect(world.has<Position>(entity), isTrue);
      expect(world.get<Position>(entity).x, 3);
      expect(world.tryGet<Position>(entity)?.x, 3);

      expect(world.has<Position>(missing), isFalse);
      expect(world.tryGet<Position>(missing), isNull);
      expect(() => world.get<Position>(missing), throwsStateError);
    });

    test('helpers treat stale entities as absent', () {
      final entity = world.entities.spawn();
      world.insertNow<Position>(entity, Position(5));
      world.despawnNow(entity);

      expect(world.isAlive(entity), isFalse);
      expect(world.has<Position>(entity), isFalse);
      expect(world.tryGet<Position>(entity), isNull);
      expect(() => world.get<Position>(entity), throwsStateError);
    });

    test('resource helpers delegate to Resources', () {
      expect(world.hasResource<Config>(), isFalse);
      expect(world.tryResource<Config>(), isNull);

      world.resources.insert<Config>(const Config(9));

      expect(world.hasResource<Config>(), isTrue);
      expect(world.tryResource<Config>()?.value, 9);
      expect(world.resource<Config>().value, 9);
    });

    test('ensure helpers create and reuse stores in registration order', () {
      final ensuredPosition = world.ensureObjectStore<Position>();
      final ensuredConfig = world.ensureObjectStore<Config>();
      final tag = world.ensureTagStore<_WorldTag>();

      expect(world.ensureObjectStore<Position>(), same(ensuredPosition));
      expect(world.ensureObjectStore<Config>(), same(ensuredConfig));
      expect(world.ensureTagStore<_WorldTag>(), same(tag));
      expect(world.stores.all.toList(), <ComponentStore>[
        ensuredPosition,
        ensuredConfig,
        tag,
      ]);
    });
  });
}

final class _WorldTag {
  const _WorldTag();
}
