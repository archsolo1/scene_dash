/// Scene-Dash: a Bevy-inspired, Dart-native ECS and plugin runtime for
/// `flutter_scene`.
///
/// This is the pure-Dart core. It has no dependency on Flutter, `flutter_scene`,
/// the analyzer or the code generator. Game code normally imports just this
/// library:
///
/// ```dart
/// import 'package:scene_dash/scene_dash.dart';
/// ```
library;

export 'src/annotations/bundle.dart';
export 'src/annotations/game_plugin.dart';
export 'src/annotations/object_component.dart';
export 'src/annotations/packed_component.dart';
export 'src/annotations/query.dart';
export 'src/annotations/resource.dart';
export 'src/annotations/system.dart';
export 'src/annotations/tag.dart';
export 'src/app/app.dart';
export 'src/app/app_builder.dart';
export 'src/app/plugin.dart';
export 'src/commands/bundle.dart';
export 'src/commands/commands.dart';
export 'src/commands/entity_commands.dart';
export 'src/entity/entity.dart';
export 'src/entity/entity_registry.dart';
export 'src/events/event_channel.dart'
    show EventChannel, EventReader, EventWriter;
export 'src/query/query_1.dart';
export 'src/query/query_2.dart';
export 'src/query/query_3.dart';
export 'src/query/query_4.dart';
export 'src/resources/resources.dart';
export 'src/schedule/access_conflict.dart';
export 'src/schedule/schedule_label.dart';
export 'src/schedule/schedules.dart';
export 'src/schedule/system_label.dart';
export 'src/storage/component_store.dart';
export 'src/storage/object_store.dart';
export 'src/storage/store_registry.dart';
export 'src/storage/tag_store.dart';
export 'src/system/game_system.dart';
export 'src/system/system_access.dart';
export 'src/system/system_adapter.dart';
export 'src/time/fixed_time.dart';
export 'src/time/frame_time.dart';
export 'src/world/world.dart';
