import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart' show BuildStep;
import 'package:scene_dash/scene_dash.dart';
import 'package:source_gen/source_gen.dart';

import 'component_kind.dart';

const _systemChecker = TypeChecker.typeNamed(System, inPackage: 'scene_dash');
const _bundleChecker = TypeChecker.typeNamed(Bundle, inPackage: 'scene_dash');
const _packedChecker = TypeChecker.typeNamed(
  PackedComponent,
  inPackage: 'scene_dash',
);
const _queryChecker = TypeChecker.typeNamed(Query, inPackage: 'scene_dash');
const _resourceChecker = TypeChecker.typeNamed(
  Resource,
  inPackage: 'scene_dash',
);
const _gamePluginChecker = TypeChecker.typeNamed(
  GamePlugin,
  inPackage: 'scene_dash',
);

const _queryTypeNames = {'Query1', 'Query2', 'Query3', 'Query4'};

/// Aggregating generator for the scene_dash annotations.
///
/// Validates components and generates a `SystemAdapter` + `mixin _$YourSystem`
/// for every `@System`, a `mixin _$YourBundle` for every `@Bundle`, and plugin
/// dependency metadata for `@GamePlugin`.
///
/// The architecture is object-first: `@ObjectComponent` and `@Tag` are the
/// supported component models. `@PackedComponent` is recognized-but-rejected —
/// packed typed-array storage is an optional, benchmark-gated future phase (see
/// `docs/concept.md`), not part of the active roadmap.
class EcsGenerator extends Generator {
  const EcsGenerator();

  @override
  String generate(LibraryReader library, BuildStep buildStep) {
    final buffer = StringBuffer();

    // Reject packed components: object components are the default model and
    // packed typed-array storage is an optional future phase, not implemented.
    for (final element in library.classes) {
      if (_packedChecker.hasAnnotationOf(element, throwOnUnresolved: false)) {
        throw InvalidGenerationSource(
          'Packed components are not supported: object components are the '
          'default storage model. Use @ObjectComponent. Packed typed-array '
          'storage is an optional future phase (see docs/concept.md).',
          element: element,
        );
      }
    }

    for (final element in library.classes) {
      if (_systemChecker.hasAnnotationOf(element, throwOnUnresolved: false)) {
        buffer.writeln(_generateSystem(element));
      }
      if (_bundleChecker.hasAnnotationOf(element, throwOnUnresolved: false)) {
        buffer.writeln(_generateBundle(element));
      }
      final pluginAnno = _gamePluginChecker.firstAnnotationOf(
        element,
        throwOnUnresolved: false,
      );
      if (pluginAnno != null) {
        final plugin = _generatePlugin(element, ConstantReader(pluginAnno));
        if (plugin != null) buffer.writeln(plugin);
      }
    }

    return buffer.toString();
  }
}

// --- System generation ---

String _generateSystem(ClassElement system) {
  final name = system.name;
  if (name == null) {
    throw InvalidGenerationSource('@System class has no name.');
  }

  final run = system.getMethod('run');
  if (run == null) {
    throw InvalidGenerationSource(
      '@System $name must declare a synchronous `run(...)` method.',
      element: system,
    );
  }
  if (run.returnType is! VoidType && !run.returnType.isDartCoreNull) {
    // Allow void only; async systems return Future and are disallowed.
    final rt = run.returnType.getDisplayString();
    if (rt != 'void') {
      throw InvalidGenerationSource(
        '@System $name.run must return void (got $rt). Systems must be '
        'synchronous.',
        element: system,
      );
    }
  }

  final adapter = '_\$${name}Adapter';
  final fields = <String>[];
  final ensures = <String>{};
  final inits = <String>[];
  final args = <String>[];
  final reads = <String>{};
  final writes = <String>{};

  var index = 0;
  for (final param in run.formalParameters) {
    final field = '_p$index';
    final type = param.type;
    final typeStr = type.getDisplayString();
    final interfaceName = type is InterfaceType ? type.element.name : null;

    if (interfaceName != null && _queryTypeNames.contains(interfaceName)) {
      _emitQueryParam(
        param: param,
        type: type as InterfaceType,
        field: field,
        fields: fields,
        ensures: ensures,
        inits: inits,
        reads: reads,
        writes: writes,
      );
    } else if (_resourceChecker.hasAnnotationOf(param,
        throwOnUnresolved: false)) {
      fields.add('late final $typeStr $field;');
      inits.add('$field = world.resources.get<$typeStr>();');
    } else if (interfaceName == 'Commands') {
      fields.add('late final Commands $field;');
      inits.add('$field = world.commands;');
    } else if (interfaceName == 'EventReader' ||
        interfaceName == 'EventWriter') {
      final eventType =
          (type as InterfaceType).typeArguments.first.getDisplayString();
      final factory = interfaceName == 'EventReader' ? 'reader' : 'writer';
      fields.add('late final $typeStr $field;');
      inits.add('world.registerEvent<$eventType>();');
      inits.add('$field = world.eventChannel<$eventType>().$factory();');
    } else {
      throw InvalidGenerationSource(
        'Unsupported parameter `${param.name} : $typeStr` in $name.run. '
        'Expected a Query1..Query4, an @Resource(), Commands, EventReader or '
        'EventWriter.',
        element: system,
      );
    }

    args.add(field);
    index++;
  }

  final fieldBlock = fields.map((f) => '  $f').join('\n');
  final ensureBlock = ensures.map((e) => '    $e').join('\n');
  final initBlock = inits.map((i) => '    $i').join('\n');
  final argList = args.join(', ');
  // Reads are queried components that are not declared as writes.
  reads.removeAll(writes);
  final readsList = reads.join(', ');
  final writesList = writes.join(', ');

  return '''
class $adapter implements SystemAdapter, SystemAccessProvider {
  $adapter(this._system);

  final $name _system;
$fieldBlock

  @override
  void initialize(World world) {
$ensureBlock
$initBlock
  }

  @override
  SystemAccess get access => const SystemAccess(
        reads: <Type>{$readsList},
        writes: <Type>{$writesList},
      );

  @override
  void run() {
    _system.run($argList);
  }
}

base mixin _\$$name on GameSystem {
  @override
  SystemAdapter createAdapter() => $adapter(this as $name);
}
''';
}

void _emitQueryParam({
  required FormalParameterElement param,
  required InterfaceType type,
  required String field,
  required List<String> fields,
  required Set<String> ensures,
  required List<String> inits,
  required Set<String> reads,
  required Set<String> writes,
}) {
  final queryType = type.getDisplayString();
  final components = type.typeArguments;

  final queryAnno = _queryChecker.firstAnnotationOf(
    param,
    throwOnUnresolved: false,
  );
  final reader = queryAnno == null ? null : ConstantReader(queryAnno);
  final requires = _typeList(reader, 'requires');
  final excludes = _typeList(reader, 'excludes');
  final writeTypes =
      _typeList(reader, 'writes').map((t) => t.getDisplayString()).toSet();

  for (final component in components) {
    ensures.add(ensureStoreCall(component, forQuery: true));
    // Access metadata: queried components are reads unless declared writes.
    final name = component.getDisplayString();
    if (writeTypes.contains(name)) {
      writes.add(name);
    } else {
      reads.add(name);
    }
  }
  for (final filter in [...requires, ...excludes]) {
    ensures.add(ensureStoreCall(filter, forQuery: false));
  }

  final arity = components.length;
  final typeArgs = components.map((t) => t.getDisplayString()).join(', ');
  final withList = requires.map((t) => t.getDisplayString()).join(', ');
  final withoutList = excludes.map((t) => t.getDisplayString()).join(', ');

  fields.add('late final $queryType $field;');
  inits.add(
    '$field = world.query$arity<$typeArgs>('
    'withTypes: const <Type>[$withList], '
    'withoutTypes: const <Type>[$withoutList]);',
  );
}

List<DartType> _typeList(ConstantReader? reader, String field) {
  if (reader == null) return const <DartType>[];
  final value = reader.read(field);
  if (value.isNull) return const <DartType>[];
  return [
    for (final entry in value.listValue)
      if (entry.toTypeValue() case final t?) t,
  ];
}

// --- Bundle generation ---

String _generateBundle(ClassElement bundle) {
  final name = bundle.name;
  if (name == null) {
    throw InvalidGenerationSource('@Bundle class has no name.');
  }

  final statements = <String>[];
  for (final fieldElement in bundle.fields) {
    if (fieldElement.isStatic) continue;
    final fieldName = fieldElement.name;
    if (fieldName == null) continue;
    final type = fieldElement.type;
    final typeStr = type.getDisplayString();

    switch (componentKindOf(type)) {
      case ComponentKind.object:
        statements.add(
          'world.ensureObjectStore<$typeStr>().insert(entity.index, '
          'self.$fieldName);',
        );
      case ComponentKind.tag:
        statements.add(
          'world.ensureTagStore<$typeStr>().add(entity.index);',
        );
      case ComponentKind.packed:
        throw InvalidGenerationSource(
          'Bundle $name has packed component field `$fieldName` ($typeStr). '
          'Packed components are not supported; use @ObjectComponent. Packed '
          'typed-array storage is an optional future phase (docs/concept.md).',
          element: bundle,
        );
      case ComponentKind.unknown:
        throw InvalidGenerationSource(
          'Bundle $name field `$fieldName` has type $typeStr, which is not a '
          'component (@ObjectComponent / @Tag / @PackedComponent).',
          element: bundle,
        );
    }
  }

  final body = statements.map((s) => '    $s').join('\n');

  return '''
mixin _\$$name implements SceneDashBundle {
  @override
  void insertInto(World world, Entity entity) {
    final self = this as $name;
$body
  }
}
''';
}

// --- Plugin generation ---

/// Emits a `base mixin _$YourPlugin on Plugin` that overrides [Plugin.dependencies]
/// from `@GamePlugin(requires: [...])`. Returns `null` when there are no
/// requirements (no mixin needed — apply it only when you declare `requires`).
String? _generatePlugin(ClassElement plugin, ConstantReader annotation) {
  final name = plugin.name;
  if (name == null) {
    throw InvalidGenerationSource('@GamePlugin class has no name.');
  }

  final requires = _typeList(annotation, 'requires');
  if (requires.isEmpty) return null;

  final deps = requires.map((t) => t.getDisplayString()).join(', ');

  return '''
base mixin _\$$name on Plugin {
  @override
  List<Type> get dependencies => const <Type>[$deps];
}
''';
}
