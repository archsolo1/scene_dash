import 'package:scene_dash/scene_dash.dart';
import 'package:test/test.dart';

final class Position {
  double x;
  double y;
  Position(this.x, this.y);
}

final class Velocity {
  double x;
  double y;
  Velocity(this.x, this.y);
}

final class Player {
  const Player();
}

final class Frozen {
  const Frozen();
}

World _worldWithStores() {
  return World()
    ..stores.register<Position>(ObjectComponentStore<Position>())
    ..stores.register<Velocity>(ObjectComponentStore<Velocity>())
    ..stores.register<Player>(TagStore())
    ..stores.register<Frozen>(TagStore());
}

Entity _spawn(
  World world, {
  Position? position,
  Velocity? velocity,
  bool player = false,
  bool frozen = false,
}) {
  final entity = world.entities.spawn();
  if (position != null) world.insertNow<Position>(entity, position);
  if (velocity != null) world.insertNow<Velocity>(entity, velocity);
  if (player) world.insertNow<Player>(entity, const Player());
  if (frozen) world.insertNow<Frozen>(entity, const Frozen());
  return entity;
}

void main() {
  group('Query1', () {
    test('visits every entity with the component', () {
      final world = _worldWithStores();
      _spawn(world, position: Position(1, 1));
      _spawn(world, position: Position(2, 2));
      _spawn(world, velocity: Velocity(0, 0)); // no position

      final seen = <double>[];
      world.query1<Position>().each((entity, position) {
        seen.add(position.x);
      });
      expect(seen, unorderedEquals(<double>[1, 2]));
    });
  });

  group('Query2', () {
    test('matches only entities having both components', () {
      final world = _worldWithStores();
      final both =
          _spawn(world, position: Position(1, 1), velocity: Velocity(1, 0));
      _spawn(world, position: Position(2, 2)); // no velocity
      _spawn(world, velocity: Velocity(9, 9)); // no position

      final matched = <Entity>[];
      world.query2<Position, Velocity>().each((entity, p, v) {
        matched.add(entity);
        p.x += v.x; // immediate field write through the object reference
      });

      expect(matched, <Entity>[both]);
      expect(world.stores.object<Position>().valueOf(both.index)!.x, 2);
    });

    test('applies requires (with) and excludes (without) filters', () {
      final world = _worldWithStores();
      final activePlayer = _spawn(
        world,
        position: Position(0, 0),
        velocity: Velocity(1, 1),
        player: true,
      );
      _spawn(
        world,
        position: Position(0, 0),
        velocity: Velocity(1, 1),
        player: true,
        frozen: true,
      ); // excluded by Frozen
      _spawn(
        world,
        position: Position(0, 0),
        velocity: Velocity(1, 1),
      ); // not a Player

      final matched = <Entity>[];
      world.query2<Position, Velocity>(
        withTypes: const [Player],
        withoutTypes: const [Frozen],
      ).each((entity, p, v) => matched.add(entity));

      expect(matched, <Entity>[activePlayer]);
    });

    test('chooses the smallest store as driver but yields correct matches', () {
      final world = _worldWithStores();
      // Many positions, few velocities: driver should be the velocity store.
      for (var i = 0; i < 50; i++) {
        _spawn(world, position: Position(i.toDouble(), 0));
      }
      final a =
          _spawn(world, position: Position(100, 0), velocity: Velocity(1, 0));
      final b =
          _spawn(world, position: Position(200, 0), velocity: Velocity(2, 0));

      final matched = <Entity>{};
      world.query2<Position, Velocity>().each((e, p, v) => matched.add(e));
      expect(matched, <Entity>{a, b});
    });
  });

  group('debug guards', () {
    test('rejects structural mutation while a query iterates', () {
      final world = _worldWithStores();
      _spawn(world, position: Position(0, 0));
      final extra = world.entities.spawn();

      expect(
        () => world.query1<Position>().each((entity, position) {
          world.insertNow<Position>(extra, Position(9, 9));
        }),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
