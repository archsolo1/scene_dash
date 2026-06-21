import 'package:flutter_scene/scene.dart' show Scene;
import 'package:scene_dash/scene_dash.dart';

import 'ecs_frame_loop.dart';
import 'scene_commands.dart';
import 'scene_driver.dart';
import 'scene_mount.dart';
import 'scene_sync.dart';
import 'scene_transform.dart';

/// The scene-aware facade over the core [App].
///
/// `Game` composes an [App] with a `flutter_scene` [Scene] and installs the
/// standard bridge behavior automatically, so feature plugins register only
/// their own systems. On [start] it:
///
/// * exposes the real [Scene] and [SceneCommands] as `@Resource()`s;
/// * auto-mounts entity-bound nodes ([SceneNodeRef]) into the scene;
/// * synchronizes the standard [SceneTransform] onto bound nodes each frame;
/// * attaches the internal [EcsSceneDriver] and exposes [onTick] for `SceneView`.
///
/// (Use `CustomSceneSyncPlugin<T>` only for a non-standard transform type.)
///
/// ```dart
/// await Scene.initializeStaticResources();
/// final scene = Scene();
/// final game = Game(scene: scene)
///   ..addPlugin(const InputPlugin())
///   ..addPlugin(const PlayerPlugin());
/// await game.start();
///
/// return SceneView(scene, cameraBuilder: buildCamera, onTick: game.onTick);
/// ```
final class Game {
  /// The app-owned scene this game renders into.
  final Scene scene;

  /// The underlying scene-agnostic engine.
  final App app;

  /// Deferred scene-graph mutations, flushed once per frame (and after
  /// startup). Also injectable into systems as an `@Resource()`.
  late final SceneCommands sceneCommands = SceneCommands(scene.root);

  late final EcsFrameLoop _loop =
      EcsFrameLoop(app, onFrameEnd: sceneCommands.flush);

  bool _started = false;
  bool _shutdown = false;
  EcsSceneDriver? _driver;

  Game({
    required this.scene,
    AccessConflictPolicy accessConflictPolicy = AccessConflictPolicy.warn,
    void Function(String message)? onDiagnostic,
  }) : app = App(
          accessConflictPolicy: accessConflictPolicy,
          onDiagnostic: onDiagnostic,
        );

  /// The ECS world.
  World get world => app.world;

  /// Registers [plugin]. Mirrors [App.addPlugin] for fluent setup.
  Game addPlugin(Plugin plugin) {
    app.addPlugin(plugin);
    return this;
  }

  /// Finalizes the app and attaches the scene driver to the scene root.
  ///
  /// Call `await Scene.initializeStaticResources()` before rendering (as the
  /// `flutter_scene` examples do); it is not this method's responsibility.
  Future<void> start() async {
    if (_started) {
      throw StateError('Game has already been started.');
    }
    _loop.ensureTimeResources();
    // Expose the real flutter_scene Scene and the deferred scene-command buffer
    // to systems via `@Resource()`. The bridge integrates flutter_scene; it does
    // not wrap it — systems configure skybox/environment/lighting/etc. directly
    // on `@Resource() Scene`.
    app.world.resources
      ..insert<Scene>(scene)
      ..insert<SceneCommands>(sceneCommands);
    // Standard bridge systems (renderSync): auto-mount entity-bound nodes so a
    // `@Bundle` can create its own node and simply become visible, and sync the
    // standard SceneTransform onto bound nodes.
    app
      ..addSystemAdapter(
        SceneNodeMountAdapter(sceneCommands),
        schedule: Schedules.renderSync,
        label: const SystemLabel('scene.mountNodes'),
      )
      ..addSystemAdapter(
        SyncSceneNodesAdapter<SceneTransform>.full(
          (transform, target) => target.setFromTranslationRotationScale(
            transform.translation,
            transform.rotation,
            transform.scale,
          ),
        ),
        schedule: Schedules.renderSync,
        label: const SystemLabel('scene.syncTransform'),
      );
    app.start();
    // Apply any scene mutations queued by startup systems before first render.
    sceneCommands.flush();
    final driver = EcsSceneDriver(_loop);
    scene.root.addComponent(driver);
    _driver = driver;
    _started = true;
  }

  /// `SceneView.onTick` handler: runs frame-start work.
  void onTick(Duration elapsed, double deltaSeconds) {
    _loop.frameStart(elapsed, deltaSeconds);
  }

  /// Shuts down the underlying app and detaches the internal scene driver.
  Future<void> shutdown() async {
    if (!_started || _shutdown) return;
    _shutdown = true;
    await app.shutdown();
    final driver = _driver;
    if (driver != null) {
      scene.root.removeComponent(driver);
      _driver = null;
    }
    sceneCommands.flush();
  }
}
