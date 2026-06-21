import 'package:flutter_scene/scene.dart';

import 'view_state.dart';

/// A chase camera driven by ECS-updated [CameraRig] state.
Camera buildGameCamera(Duration elapsed, CameraRig rig) {
  return PerspectiveCamera(position: rig.position, target: rig.target);
}
