import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:scene_dash/scene_dash.dart';
import 'package:source_gen/source_gen.dart';

/// How a component type is stored, determined from its scene_dash annotation.
enum ComponentKind { object, tag, packed, unknown }

const _objectChecker = TypeChecker.typeNamed(
  ObjectComponent,
  inPackage: 'scene_dash',
);
const _tagChecker = TypeChecker.typeNamed(Tag, inPackage: 'scene_dash');
const _packedChecker = TypeChecker.typeNamed(
  PackedComponent,
  inPackage: 'scene_dash',
);

/// Classifies [type] by inspecting the annotations on its declaring class.
ComponentKind componentKindOf(DartType type) {
  final element = type.element;
  if (element is! ClassElement) return ComponentKind.unknown;
  if (_objectChecker.hasAnnotationOf(element, throwOnUnresolved: false)) {
    return ComponentKind.object;
  }
  if (_tagChecker.hasAnnotationOf(element, throwOnUnresolved: false)) {
    return ComponentKind.tag;
  }
  if (_packedChecker.hasAnnotationOf(element, throwOnUnresolved: false)) {
    return ComponentKind.packed;
  }
  return ComponentKind.unknown;
}

/// The source-level name of [type] (without nullability), for use in generated
/// code. The generated part shares the host library's imports, so a simple
/// display name resolves correctly.
String typeName(DartType type) => type.getDisplayString();

/// Emits the `world.ensure...Store<T>()` call appropriate for [type], or throws
/// an [InvalidGenerationSource] if the type is packed (unsupported) or
/// unannotated.
///
/// [forQuery] is `true` when the type is a *queried* component (must be an
/// object component) versus a `requires`/`excludes` filter (object or tag).
String ensureStoreCall(DartType type, {required bool forQuery}) {
  final name = typeName(type);
  switch (componentKindOf(type)) {
    case ComponentKind.object:
      return 'world.ensureObjectStore<$name>();';
    case ComponentKind.tag:
      if (forQuery) {
        throw InvalidGenerationSource(
          'A query component type must be an @ObjectComponent, but $name is a '
          '@Tag. Use it in `requires`/`excludes` instead.',
        );
      }
      return 'world.ensureTagStore<$name>();';
    case ComponentKind.packed:
      throw InvalidGenerationSource(
        'Packed component $name is not supported; use @ObjectComponent. '
        'Packed typed-array storage is an optional future phase '
        '(docs/concept.md).',
      );
    case ComponentKind.unknown:
      throw InvalidGenerationSource(
        'Type $name is used as a component but is not annotated with '
        '@ObjectComponent, @Tag or @PackedComponent.',
      );
  }
}
