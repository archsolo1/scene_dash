# scene_benchmark

An on-device timing harness for the Scene-Dash `flutter_scene` integration. It
renders a 40×40 grid of 1,600 entity-bound cubes (10% animated), synced through
the integration every frame, and prints per-frame `build` (UI thread) vs
`raster` (GPU) times.

It exists to answer a performance question honestly: *where does the per-frame
cost actually go?* See [`benchmarks/README.md`](../../benchmarks/README.md) for
the full analysis. Short version: the dominant cost is `flutter_scene` building
per-node draw commands on the UI thread, not the ECS — which is why changed-only
sync is deferred and instancing is the real lever.

## Run

```bash
# One node per cube, ECS + full sync (the default).
flutter run --profile --enable-flutter-gpu examples/scene_benchmark

# Static control: same nodes, no ECS.
flutter run --profile --enable-flutter-gpu --dart-define=useEcs=false

# One InstancedMesh for the whole grid (pure game code, no integration support).
flutter run --profile --enable-flutter-gpu --dart-define=instanced=true
```

Run in `--profile` (not debug) for meaningful numbers, and prefer a real mobile
device over an emulator.
