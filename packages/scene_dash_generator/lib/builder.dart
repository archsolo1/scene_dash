import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'src/ecs_generator.dart';

/// Entry point referenced by `build.yaml`. Produces the combining part builder
/// that runs the scene_dash code generators over annotated source.
Builder sceneDashBuilder(BuilderOptions options) {
  return SharedPartBuilder(<Generator>[EcsGenerator()], 'scene_dash');
}
