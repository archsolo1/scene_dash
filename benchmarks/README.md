# Scene-Dash benchmarks

These benchmarks measure the real cost of the object-first sparse-set
architecture. They are regression and sanity tools, not marketing material:
queries buy organization and component selection at a measurable per-entity
cost.

## Running Pure-Dart Benchmarks

JIT runs are useful while iterating:

```bash
dart run benchmarks/object_query_benchmark.dart [entityCount]
dart run benchmarks/spawn_despawn_benchmark.dart [entityCount]
dart run benchmarks/representative_benchmark.dart [entityCount]
dart run benchmarks/transform_sync_benchmark.dart [entityCount]
dart run benchmarks/structural_churn_benchmark.dart
dart run benchmarks/despawn_store_scaling_benchmark.dart [entityCount]
dart run benchmarks/query_entity_allocation_benchmark.dart [entityCount]
dart run benchmarks/rts_workload_benchmark.dart [unitCount]
```

Use AOT executables for numbers that should be compared over time:

```powershell
.\benchmarks\compile_aot_benchmarks.ps1

build\aot_benchmarks\object_query_benchmark.exe 10000
build\aot_benchmarks\representative_benchmark.exe 10000
build\aot_benchmarks\structural_churn_benchmark.exe
build\aot_benchmarks\despawn_store_scaling_benchmark.exe 10000
build\aot_benchmarks\query_entity_allocation_benchmark.exe 10000
build\aot_benchmarks\rts_workload_benchmark.exe 10000
build\aot_benchmarks\transform_sync_benchmark.exe 10000
```

Captured runs can be saved under [`results/`](results/). The current AOT
desktop capture is
[`results/2026-06-23-aot-desktop.txt`](results/2026-06-23-aot-desktop.txt).

## Pure-Dart AOT Snapshot

Captured on 2026-06-23 with Dart `3.13.0-228.0.dev`, compiled to desktop AOT
executables:

| Benchmark | AOT result |
| --- | ---: |
| flat motion loop, N = 10k | 0.97 ns/op |
| sparse `Query2` motion, N = 10k | 7.04 ns/op |
| sparse `Query1` read, N = 10k | 6.66 ns/op |
| representative move query, N = 10k | 6.71 ns/op |
| representative player scan, N = 10k | 4.06 ns/op |
| representative regen query, N = 10k | 2.67 ns/op |
| record+apply `Bundle2`, N = 18k | 126.20 ns/op |
| record+apply `Bundle6`, N = 18k | 398.69 ns/op |
| despawn with 128 stores, N = 10k | 249.23 ns/op |
| query entity ignored / consumed, N = 10k | 5.51 / 6.40 ns/op |
| RTS movement / state / selection, N = 10k | 6.69 / 8.01 / 8.33 ns/op |
| RTS grid rebuild / nearby lookup, N = 10k | 15.70 / 55.58 ns/op |
| transform full TRS sync, N = 10k | 19.31 ns/op |
| transform changed-only sync, 10% changed, N = 10k | 4.48 ns/op |

The desktop AOT and earlier JIT snapshots tell the same story: sparse queries
are several nanoseconds per entity slower than flat loops, but still tiny next
to on-device Flutter scene traversal. Treat desktop JIT/AOT numbers as
CPU-shape signals; use the Pixel 8 scene benchmark for render-facing claims.

## On-Device Scene Benchmark

`examples/scene_benchmark` renders a 40x40 grid of **1,600 cubes** on a Pixel 8
(Android 16 / API 36) in Flutter profile mode with Flutter GPU / Impeller
Vulkan. All modes use the same grid, cube geometry, material, camera, light,
viewport, and no animation.

Modes:

| Mode | Purpose |
| --- | --- |
| `static` | Direct `flutter_scene` `Node` per cube, no ECS. |
| `mountOnly` | Scene-Dash ECS lifecycle plus `SceneNodeRef` mounting, no `SceneTransform` sync. |
| `ecs` | Scene-Dash entity per cube with `SceneNodeRef` + `SceneTransform` full sync. |
| `instanced` | One `flutter_scene` `InstancedMesh` containing the same visible cubes. |

`profileSystems` defaults to `false`. Run `profileSystems=true` separately when
you need system timing lines; profiler data is reset after warmup so run counts
match the sampled frame window.

The app prints stable machine-readable lines:

```text
SCENE_BENCHMARK config mode=<mode> profileSystems=<bool> gridSide=<n> visible=<n> warmupFrames=<n> sampleFrames=<n>
SCENE_BENCHMARK result mode=<mode> profileSystems=<bool> frames=<n> build_median_ms=<n> build_p95_ms=<n> raster_median_ms=<n> raster_p95_ms=<n>
SCENE_BENCHMARK system mode=<mode> profileSystems=<bool> schedule=<id> system=<id> runs=<n> latest_us=<n> avg_us=<n> max_us=<n>
```

Run one mode:

```powershell
cd examples\scene_benchmark

flutter run --profile -d 38180DLJH00074 --enable-flutter-gpu `
  --dart-define=benchmarkMode=ecs `
  --dart-define=profileSystems=false `
  --dart-define=warmupFrames=60 `
  --dart-define=sampleFrames=180
```

Run the five-round alternating matrix:

```powershell
cd examples\scene_benchmark

$device = '38180DLJH00074'
$runs = @(
  @('1','static'), @('1','ecs'), @('1','mountOnly'), @('1','instanced'),
  @('2','instanced'), @('2','mountOnly'), @('2','ecs'), @('2','static'),
  @('3','ecs'), @('3','static'), @('3','instanced'), @('3','mountOnly'),
  @('4','mountOnly'), @('4','instanced'), @('4','static'), @('4','ecs'),
  @('5','static'), @('5','instanced'), @('5','ecs'), @('5','mountOnly')
)

foreach ($run in $runs) {
  flutter run --profile -d $device --enable-flutter-gpu `
    --dart-define=benchmarkMode=$($run[1]) `
    --dart-define=profileSystems=false `
    --dart-define=warmupFrames=60 `
    --dart-define=sampleFrames=180
}

flutter run --profile -d $device --enable-flutter-gpu `
  --dart-define=benchmarkMode=ecs `
  --dart-define=profileSystems=true `
  --dart-define=warmupFrames=60 `
  --dart-define=sampleFrames=180
```

Aggregate captured output:

```powershell
cd benchmarks
dart aggregate_scene_benchmark.dart results\2026-06-23-pixel8-scene-benchmark-matrix.txt
```

## Pixel 8 Results

Captured on 2026-06-23 with Flutter `3.45.0-1.0.pre-594` on master and Dart
`3.13.0-228.0.dev`. The raw matrix is
[`results/2026-06-23-pixel8-scene-benchmark-matrix.txt`](results/2026-06-23-pixel8-scene-benchmark-matrix.txt).

Values are median-of-runs, with min-max range across five alternating runs.

| Mode | runs | build median | build p95 | raster median | raster p95 |
| --- | ---: | ---: | ---: | ---: | ---: |
| `static`, `profileSystems=false` | 5 | 21.014 ms (18.815-24.212) | 24.804 ms (20.780-27.696) | 0.851 ms (0.598-1.841) | 1.077 ms (0.737-2.370) |
| `mountOnly`, `profileSystems=false` | 5 | 22.014 ms (17.130-37.181) | 25.871 ms (19.181-41.370) | 1.425 ms (0.881-1.812) | 2.070 ms (1.150-2.264) |
| `ecs`, `profileSystems=false` | 5 | 25.990 ms (21.591-31.590) | 28.960 ms (23.579-37.000) | 0.954 ms (0.728-1.093) | 1.186 ms (0.898-1.359) |
| `instanced`, `profileSystems=false` | 5 | 3.620 ms (1.466-3.911) | 4.363 ms (3.871-4.492) | 0.565 ms (0.538-0.690) | 0.763 ms (0.671-0.897) |

The separate profiler-enabled ECS run reported:

| Mode | build median | raster median | system | runs | avg | max |
| --- | ---: | ---: | --- | ---: | ---: | ---: |
| `ecs`, `profileSystems=true` | 22.143 ms | 0.863 ms | `scene.syncTransform` | 180 | 375.044 us | 1714 us |

Profiler reset is working: `scene.syncTransform` ran 180 times for 180 sampled
frames, not warmup plus sample frames.
