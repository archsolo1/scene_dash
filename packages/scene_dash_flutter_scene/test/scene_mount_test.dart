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

  test('detaches a mounted node when its entity is despawned', () {
    final root = Node();
    final commands = SceneCommands(root);
    final node = Node();
    final world = World()
      ..stores.register<SceneNodeRef>(ObjectComponentStore<SceneNodeRef>());
    final entity = world.entities.spawn();
    world.insertNow<SceneNodeRef>(entity, SceneNodeRef(node));

    final adapter = SceneNodeMountAdapter(commands)..initialize(world);
    adapter.run();
    commands.flush();
    expect(node.parent, same(root), reason: 'mounted on spawn');

    world.despawnNow(entity);
    adapter.run();
    expect(commands.isEmpty, isFalse, reason: 'detach queued');
    commands.flush();
    expect(node.parent, isNull, reason: 'detached on despawn');
  });

  test('detaches when the SceneNodeRef component is removed', () {
    final root = Node();
    final commands = SceneCommands(root);
    final node = Node();
    final world = World()
      ..stores.register<SceneNodeRef>(ObjectComponentStore<SceneNodeRef>());
    final entity = world.entities.spawn();
    world.insertNow<SceneNodeRef>(entity, SceneNodeRef(node));

    final adapter = SceneNodeMountAdapter(commands)..initialize(world);
    adapter.run();
    commands.flush();
    expect(node.parent, same(root));

    // Remove just the component (entity stays alive).
    world.removeNow<SceneNodeRef>(entity);
    adapter.run();
    commands.flush();
    expect(node.parent, isNull, reason: 'detached on component removal');
  });

  test('detaches the old node and mounts the new one on replacement', () {
    final root = Node();
    final commands = SceneCommands(root);
    final oldNode = Node();
    final world = World()
      ..stores.register<SceneNodeRef>(ObjectComponentStore<SceneNodeRef>());
    final entity = world.entities.spawn();
    world.insertNow<SceneNodeRef>(entity, SceneNodeRef(oldNode));

    final adapter = SceneNodeMountAdapter(commands)..initialize(world);
    adapter.run();
    commands.flush();
    expect(oldNode.parent, same(root));

    final newNode = Node();
    world.insertNow<SceneNodeRef>(entity, SceneNodeRef(newNode)); // replace
    adapter.run();
    commands.flush();
    expect(oldNode.parent, isNull, reason: 'old node detached');
    expect(newNode.parent, same(root), reason: 'new node mounted');
  });

  test('does not auto-detach a game-parented node when despawned', () {
    final root = Node();
    final elsewhere = Node();
    root.add(elsewhere);
    final commands = SceneCommands(root);

    final node = Node();
    elsewhere.add(node); // custom parenting → never adopted
    final world = World()
      ..stores.register<SceneNodeRef>(ObjectComponentStore<SceneNodeRef>());
    final entity = world.entities.spawn();
    world.insertNow<SceneNodeRef>(entity, SceneNodeRef(node));

    final adapter = SceneNodeMountAdapter(commands)..initialize(world);
    adapter.run();
    world.despawnNow(entity);
    adapter.run();
    commands.flush();

    expect(node.parent, same(elsewhere), reason: 'game owns this node');
  });
}
