import 'package:scene_dash/scene_dash.dart';
import 'package:test/test.dart';

final class A {
  final int v;
  A(this.v);
}

final class B {
  final int v;
  B(this.v);
}

final class C {
  final int v;
  C(this.v);
}

final class D {
  final int v;
  D(this.v);
}

final class Tagged {
  const Tagged();
}

World _world() {
  return World()
    ..stores.register<A>(ObjectComponentStore<A>())
    ..stores.register<B>(ObjectComponentStore<B>())
    ..stores.register<C>(ObjectComponentStore<C>())
    ..stores.register<D>(ObjectComponentStore<D>())
    ..stores.register<Tagged>(TagStore());
}

Entity _spawn(
  World world, {
  int? a,
  int? b,
  int? c,
  int? d,
  bool tagged = false,
}) {
  final e = world.entities.spawn();
  if (a != null) world.insertNow<A>(e, A(a));
  if (b != null) world.insertNow<B>(e, B(b));
  if (c != null) world.insertNow<C>(e, C(c));
  if (d != null) world.insertNow<D>(e, D(d));
  if (tagged) world.insertNow<Tagged>(e, const Tagged());
  return e;
}

void main() {
  group('Query3', () {
    test('matches only entities with all three components', () {
      final world = _world();
      final all = _spawn(world, a: 1, b: 2, c: 3);
      _spawn(world, a: 1, b: 2); // missing C
      _spawn(world, a: 1, c: 3); // missing B

      final matched = <Entity>[];
      world.query3<A, B, C>().each((e, a, b, c) {
        matched.add(e);
        expect(a.v + b.v + c.v, 6);
      });
      expect(matched, <Entity>[all]);
    });

    test('honours requires/excludes filters', () {
      final world = _world();
      final ok = _spawn(world, a: 1, b: 1, c: 1, tagged: true);
      _spawn(world, a: 1, b: 1, c: 1); // not tagged → excluded by requires

      final matched = <Entity>[];
      world.query3<A, B, C>(
          withTypes: const [Tagged]).each((e, a, b, c) => matched.add(e));
      expect(matched, <Entity>[ok]);
    });
  });

  group('Query4', () {
    test('matches only entities with all four components', () {
      final world = _world();
      final all = _spawn(world, a: 1, b: 2, c: 3, d: 4);
      _spawn(world, a: 1, b: 2, c: 3); // missing D

      final sums = <int>[];
      world.query4<A, B, C, D>().each((e, a, b, c, d) {
        sums.add(a.v + b.v + c.v + d.v);
      });
      expect(sums, <int>[10]);
      expect(all.isValid, isTrue);
    });

    test('excludes filter removes matches', () {
      final world = _world();
      _spawn(world, a: 1, b: 1, c: 1, d: 1, tagged: true);
      final kept = _spawn(world, a: 1, b: 1, c: 1, d: 1);

      final matched = <Entity>[];
      world.query4<A, B, C, D>(
          withoutTypes: const [Tagged]).each((e, a, b, c, d) => matched.add(e));
      expect(matched, <Entity>[kept]);
    });
  });
}
