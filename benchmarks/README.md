# Scene-Dash benchmarks

These benchmarks measure the real cost of the object-first sparse-set
architecture. They are regression and sanity tools, not marketing material:
queries buy organization and component selection at a measurable per-entity
cost.

## Running

```bash
dart run benchmarks/object_query_benchmark.dart [entityCount]      # default 10000
dart run benchmarks/spawn_despawn_benchmark.dart [entityCount]
dart run benchmarks/representative_benchmark.dart [entityCount]
dart run benchmarks/transform_sync_benchmark.dart [entityCount]
dart run benchmarks/structural_churn_benchmark.dart
dart run benchmarks/despawn_store_scaling_benchmark.dart [entityCount]
dart run benchmarks/query_entity_allocation_benchmark.dart [entityCount]
dart run benchmarks/rts_workload_benchmark.dart [unitCount]
```

## Caveats

- Desktop `dart run` benchmarks run under the JIT. Real performance claims must
  be made on release/profile AOT builds and, for rendering, representative
  mobile hardware.
- The harness reports machine-relative `ns/op`; treat absolute values as
  signals, not truth.
- Microbenchmarks miss full frame costs such as Flutter build, native scene
  traversal, raster, allocation rate, GC, and thermal behavior.
- Captured runs can be saved under [`results/`](results/).

## Indicative Desktop Results

One dev-machine JIT run at N = 10,000:

| Benchmark | Flat object loop | Object sparse query |
| --- | ---: | ---: |
| Integrate motion (`Query2`) | ~1.3 ns/op | ~10 ns/op |
| Single-component read (`Query1`) | ~0.6 ns/op | ~8 ns/op |
| Filtered (skip half via tag) | ~0.7 ns/op | ~9 ns/op |

| Structural op | ns/op |
| --- | ---: |
| spawn (+2 components) | ~57 |
| despawn | ~21 |
| component insert | ~23 |
| component remove (swap) | ~17 |
| command-buffer apply | ~35 |

Takeaway: the sparse query costs roughly an order of magnitude more per entity
than a flat loop here, driven by sparse membership lookups and the per-entity
callback. That is the architectural cost accepted for ergonomics and component
selection; packed typed-array storage remains optional and benchmark-gated.

## Representative Per-Frame Workload

`representative_benchmark.dart` runs a steady-state frame across five stores
(`Position`, `Velocity`, `Health`, `Player`, `Frozen`) and three filtered
queries. Indicative JIT `ns/op`:

| Query | N = 10,000 | N = 100,000 |
| --- | ---: | ---: |
| `Query2<Position,Velocity>` excl. `Frozen` | ~10.5 | ~11.1 |
| `Query1<Position>` req. `Player` | ~6.1 | ~6.2 |
| `Query3<Position,Velocity,Health>` | ~4.0 | ~4.3 |

Per-op cost is flat as N grows. A full frame of all three queries is about
0.2 ms at 10k entities and about 2 ms at 100k on that machine.

## Transform-Sync Microbenchmark

`transform_sync_benchmark.dart` isolates the synchronization arithmetic: compose
a `SceneTransform` translation/rotation/scale into a node-local `Matrix4` and
mark it dirty. It does not include query iteration or renderer traversal.

Indicative JIT `ns/op`:

| Row | N = 1,000 | N = 10,000 | N = 50,000 |
| --- | ---: | ---: | ---: |
| full TRS sync | ~12.2 | ~13.5 | ~14.7 |
| translation-only sync | ~2.6 | ~6.8 | ~7.2 |
| changed-only, 0% changed | ~0.6 | ~0.6 | ~1.0 |
| changed-only, 10% changed | ~1.8 | ~4.1 | ~4.2 |
| changed-only, 50% changed | ~5.9 | ~9.6 | ~11.4 |
| changed-only, 100% changed | ~11.1 | ~13.5 | ~16.9 |

Decision: changed-only scene sync remains deferred. The arithmetic is
sub-millisecond for normal entity counts, and dirty tracking would not remove
the dominant per-node scene/render-item work measured on device below.

## On-Device Scene Benchmark

`examples/scene_benchmark` renders a 40x40 grid of **1,600 cubes** on a Pixel 8
(Android 16 / API 36) in Flutter profile mode with Flutter GPU / Impeller
Vulkan. The app prints `SCENE_BENCHMARK ...` lines and exits after collecting
Flutter `FrameTiming` samples.

The modes are:

- `static`: one `flutter_scene` `Node` per cube, no ECS.
- `ecs`: one entity per cube with `SceneNodeRef` + `SceneTransform`, mounted and
  fully synchronized through Scene-Dash.
- `instanced`: one `InstancedMesh` containing the same visible count.

Run:

```bash
cd examples/scene_benchmark

flutter run --profile -d 38180DLJH00074 --enable-flutter-gpu \
  --dart-define=benchmarkMode=static \
  --dart-define=warmupFrames=60 \
  --dart-define=sampleFrames=180

flutter run --profile -d 38180DLJH00074 --enable-flutter-gpu \
  --dart-define=benchmarkMode=ecs \
  --dart-define=warmupFrames=60 \
  --dart-define=sampleFrames=180

flutter run --profile -d 38180DLJH00074 --enable-flutter-gpu \
  --dart-define=benchmarkMode=instanced \
  --dart-define=warmupFrames=60 \
  --dart-define=sampleFrames=180
```

Captured on 2026-06-23 with Flutter `3.45.0-1.0.pre-594` on master and Dart
`3.13.0-228.0.dev`. Static was run twice; the table uses the second run because
the first static run showed a higher first-run median (`33.645 ms` build) than
the immediately repeated warm-build run.

| Mode (1,600 cubes) | build median | build p95 | raster median | raster p95 |
| --- | ---: | ---: | ---: | ---: |
| static, one `Node` per cube, no ECS | 28.163 ms | 31.641 ms | 0.954 ms | 1.357 ms |
| ECS + full sync, one `Node` per cube | 28.569 ms | 32.594 ms | 1.006 ms | 1.298 ms |
| one `InstancedMesh` | **1.179 ms** | **2.604 ms** | **0.517 ms** | **0.746 ms** |

The ECS run also printed profiler timings. In this capture,
`scene.syncTransform` ran 242 times with average `391 us`, latest `329 us`, and
max `1557 us` for 1,600 entities.

What this shows:

- The dominant cost for the per-node modes is `flutter_scene` walking and
  building render work for 1,600 individual nodes on the UI thread.
- The measured ECS/full-sync delta over static nodes is small in this capture:
  about `0.4 ms` median build, with the sync system itself averaging about
  `0.39 ms`.
- One `InstancedMesh` is about 24x faster than per-node rendering on the UI
  thread in this run (`28.163 ms -> 1.179 ms` median build).
- GPU raster is below `1.4 ms` in the per-node modes and below `0.8 ms` in the
  instanced mode, so this workload is UI-thread bound.

Conclusions:

1. Changed-only transform sync is not the lever. It can only reclaim part of a
   sub-millisecond ECS sync path, and cannot touch per-node render-item work.
2. Instancing is the lever. The instanced path uses plain `flutter_scene`
   `InstancedMesh`; Scene-Dash does not need a special public API for it.
3. Deeper ECS changes remain rejected until benchmarks justify them. These
   Pixel 8 numbers do not justify command-buffer rewrites, entity signatures,
   packed general-purpose storage, or public transform dirty tracking.
