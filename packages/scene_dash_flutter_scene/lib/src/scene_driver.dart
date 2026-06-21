import 'package:flutter_scene/scene.dart' show Component;

import 'ecs_frame_loop.dart';

/// The single internal `flutter_scene` [Component] that drives Scene-Dash from
/// the scene lifecycle. Attached to the scene root by [Game.start].
///
/// `flutter_scene` calls [fixedUpdate] each fixed step (before its physics step,
/// possibly several times per frame) and [update] once per frame after
/// interpolation. This is the only ticker Scene-Dash uses — it never owns its
/// own accumulator or render loop.
final class EcsSceneDriver extends Component {
  final EcsFrameLoop _loop;

  EcsSceneDriver(this._loop);

  @override
  void fixedUpdate(double fixedDt) => _loop.fixedStep(fixedDt);

  @override
  void update(double deltaSeconds) => _loop.update(deltaSeconds);
}
