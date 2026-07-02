import 'package:flutter_scene/scene.dart';
import 'package:vector_math/vector_math.dart' show Matrix4, Vector3;

/// A fixed-capacity [InstancedMesh] pool: one node and one draw call for many
/// identical visuals, animated allocation-free via the reusable [scratch]
/// matrix. 0.18 instancing is transform-only (no per-instance colour), so
/// fades are done with scale and the material is shared by the pool.
final class InstancedPool {
  InstancedPool({
    required Geometry geometry,
    required Material material,
    required this.capacity,
  }) : mesh = InstancedMesh(geometry: geometry, material: material) {
    for (var i = 0; i < capacity; i++) {
      mesh.addInstance(_hidden);
    }
  }

  final InstancedMesh mesh;
  final int capacity;

  /// Mutate in place, then pass to `mesh.setInstanceTransform` — one matrix
  /// reused for every write.
  final Matrix4 scratch = Matrix4.identity();

  /// Frustum culling is off: the instances move every frame, so a per-frame
  /// aggregate-bounds recompute would be wasted work.
  void addTo(Scene scene) {
    scene.root.add(
      Node()
        ..addComponent(InstancedMeshComponent(mesh))
        ..frustumCulled = false,
    );
  }

  /// "Hides" the instance at [index] by moving it far off-screen.
  void hide(int index) => mesh.setInstanceTransform(index, _hidden);
}

final Matrix4 _hidden = Matrix4.translation(Vector3(0, -9999, 0));
