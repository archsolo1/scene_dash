import 'package:scene_dash/scene_dash.dart';
import 'package:test/test.dart';

final class Config {
  final int seed;
  const Config(this.seed);
}

void main() {
  group('Resources', () {
    test('inserts and reads a resource', () {
      final resources = Resources()..insert(const Config(42));
      expect(resources.get<Config>().seed, 42);
      expect(resources.contains<Config>(), isTrue);
    });

    test('throws when a resource is missing', () {
      final resources = Resources();
      expect(resources.get<Config>, throwsStateError);
      expect(resources.tryGet<Config>(), isNull);
    });

    test('insert replaces the existing instance', () {
      final resources = Resources()
        ..insert(const Config(1))
        ..insert(const Config(2));
      expect(resources.get<Config>().seed, 2);
    });

    test('remove returns and clears the resource', () {
      final resources = Resources()..insert(const Config(9));
      expect(resources.remove<Config>()?.seed, 9);
      expect(resources.contains<Config>(), isFalse);
    });
  });
}
