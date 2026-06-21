import 'package:flutter_scene/scene.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scene_dash/scene_dash.dart';
import 'package:scene_dash_flutter_scene/scene_dash_flutter_scene.dart';

World _worldWithBinding(Node node) {
  final world = World()
    ..stores.register<SceneNodeRef>(ObjectComponentStore<SceneNodeRef>());
  final entity = world.entities.spawn();
  world.insertNow<SceneNodeRef>(entity, SceneNodeRef(node));
  return world;
}

void main() {
  test('mounts an unparented bound node under the root, once', () {
    final root = Node();
    final commands = SceneCommands(root);
    final node = Node();
    final world = _worldWithBinding(node);

    final adapter = SceneNodeMountAdapter(commands)..initialize(world);

    adapter.run();
    expect(node.parent, isNull, reason: 'queued, not yet flushed');
    commands.flush();
    expect(node.parent, same(root));

    // Already parented → nothing more is queued.
    adapter.run();
    expect(commands.isEmpty, isTrue);
  });

  test('leaves a node the game parented itself alone', () {
    final root = Node();
    final elsewhere = Node()..add(Node());
    root.add(elsewhere);
    final commands = SceneCommands(root);

    final node = Node();
    elsewhere.add(node); // custom parenting
    final world = _worldWithBinding(node);

    SceneNodeMountAdapter(commands)
      ..initialize(world)
      ..run();

    expect(commands.isEmpty, isTrue, reason: 'already parented');
    expect(node.parent, same(elsewhere));
  });
}
