# Scene-Dash benchmarks

These benchmarks exist to measure the **real cost of the object-first
sparse-set architecture** — most importantly, a straightforward `List<Actor>`
loop next to the equivalent Scene-Dash query. They are a regression and
sanity tool, not marketing. queries buy organization and component selection, at
a measurable per-entity cost.

## Running

```bash
dart run benchmarks/object_query_benchmark.dart    [entityCount]   # default 10000
dart run benchmarks/spawn_despawn_benchmark.dart   [entityCount]
dart run benchmarks/representative_benchmark.dart  [entityCount]
dart run benchmarks/transform_sync_benchmark.dart  [entityCount]   # full vs changed-only sync
```

## Caveats

- These run under the **JIT** (`dart run`). Real performance claims must be made
  on a **release/AOT** build and, for the rendering path, a representative
  **mobile** target. The harness reports machine-relative `ns/op` (one "op" is
  one entity), so treat absolute values as signals, not truth.
- Microbenchmarks miss cache effects of real workloads. A representative scene
  workload (10k entities, 1k visible nodes, spawning/despawning, changed-only
  node sync) belongs with the `flutter_scene` integration (Phase 4/5).
- Captured runs can be saved under [`results/`](results/).

## Indicative results (one dev machine, JIT, N = 10,000)

These are illustrative only — re-run locally.

| Benchmark | Flat object loop | Object sparse query |
| --- | --- | --- |
| Integrate motion (`Query2`) | ~1.3 ns/op | ~10 ns/op |
| Single-component read (`Query1`) | ~0.6 ns/op | ~8 ns/op |
| Filtered (skip half via tag) | ~0.7 ns/op | ~9 ns/op |

| Structural op | ns/op |
| --- | --- |
| spawn (+2 components) | ~57 |
| despawn | ~21 |
| component insert | ~23 |
| component remove (swap) | ~17 |
| command-buffer apply | ~35 |

**Takeaway:** the sparse query costs roughly an order of magnitude more per
entity than a flat loop here — driven by the `denseIndexOf` membership lookups
and the per-entity callback. That is the architectural cost the project chose to
accept for ergonomics and component selection, and it is why packed typed-array
storage stays an optional, benchmark-gated phase rather than the default.

## Representative per-frame workload (Phase 5)

`representative_benchmark.dart` runs a realistic steady-state frame: many
entities across five stores (`Position`, `Velocity`, `Health`, `Player`,
`Frozen`) and three filtered queries (a `Query2` excluding a tag, a filtered
`Query1`, and a `Query3`). Indicative `ns/op` (per entity), JIT:

| Query | N = 10,000 | N = 100,000 |
| --- | --- | --- |
| `Query2<Position,Velocity>` excl. `Frozen` | ~10.5 | ~11.1 |
| `Query1<Position>` req. `Player` | ~6.1 | ~6.2 |
| `Query3<Position,Velocity,Health>` | ~4.0 | ~4.3 |

**Per-op cost is flat as N grows (linear scaling).** A full frame of all three
queries is ~0.2 ms at 10k entities and ~2 ms at 100k — comfortably inside a
16 ms frame.

The object-query path is not a per-frame bottleneck, so adding component
change-versions + changed-only query iteration for *query speed* would be
speculative complexity (`docs/concept.md`: don't optimize without
benchmark evidence). The remaining question — whether changed-only *scene sync*
is worth it — needed both a microbenchmark of the sync arithmetic and an
on-device measurement.

## Transform-sync microbenchmark (`transform_sync_benchmark.dart`)

Isolates the synchronization *arithmetic* the integration runs every frame —
composing a `SceneTransform`'s translation/rotation/scale into a node's local
`Matrix4` and marking it dirty — over a flat list (no query), so it measures the
matrix/dirty work only. It compares the current unconditional sync against a
dirty-flag changed-only sync swept across changed ratios. Indicative `ns/op`
(per entity), JIT:

| Row | N = 1,000 | N = 10,000 | N = 50,000 |
| --- | --- | --- | --- |
| full TRS sync (unconditional) | ~12.2 | ~13.5 | ~14.7 |
| translation-only sync | ~2.6 | ~6.8 | ~7.2 |
| changed-only, 0% changed (dirty check only) | ~0.6 | ~0.6 | ~1.0 |
| changed-only, 10% changed | ~1.8 | ~4.1 | ~4.2 |
| changed-only, 50% changed | ~5.9 | ~9.6 | ~11.4 |
| changed-only, 100% changed | ~11.1 | ~13.5 | ~16.9 |

**What this shows.** The full TRS composition is ~13 ns/entity and changed-only
saves *proportionally to how static the scene is* (≈full cost × changed ratio,
plus a ~1 ns/entity dirty-check floor). But the absolute sync arithmetic is tiny:
even unconditional full sync at 10,000 entities is **~0.13 ms/frame**, and
changed-only at 10% changed only reclaims ~0.1 ms of that. That is dwarfed by the
~12 ms/frame `flutter_scene` spends building per-node draw commands on-device
(below) — work changed-only sync *cannot* remove, because the node still exists
and is still walked.

**Decision: changed-only scene sync is deferred** (consistent with
`docs/concept.md` Phase 5). The matrix arithmetic is sub-millisecond up to
50,000 entities, so a dirty-tracking mechanism — which would also require
wrapping `SceneTransform`'s currently-mutable vectors to be reliable — is not
justified by these numbers. The lever is instancing, not change tracking (see
below).

## On-device scene benchmark (`examples/scene_benchmark`)

A 40×40 grid of **1,600 entity-bound cubes** (10% animated), synced through the
integration every frame, on a **Pixel 8 (Android 16), profile mode, Flutter GPU /
Impeller**. The app prints per-frame `build` (UI thread: ECS + sync + building
the scene's draw commands) vs `raster` (GPU). Run it two ways:

```bash
flutter run --profile --enable-flutter-gpu examples/scene_benchmark      # one node per cube, ECS + full sync
flutter run --profile --enable-flutter-gpu --dart-define=useEcs=false    # static control: same nodes, no ECS
flutter run --profile --enable-flutter-gpu --dart-define=instanced=true  # one InstancedMesh for the whole grid
```

Cool-state (first samples; the per-node modes then climb together under
**thermal throttling** to ~22 ms — proof the climb is heat, not accumulating ECS
work; the instanced mode is so cheap it barely warms the device):

| Mode (1,600 cubes) | build (UI) | raster (GPU) |
| --- | --- | --- |
| **static** (one node per cube, no ECS) | ~12.3 ms | ~0.9 ms |
| **ECS + full sync** (one node per cube) | ~14.7 ms | ~0.9 ms |
| **instanced** (one `InstancedMesh`, ECS) | **~1.6 ms** | ~0.8 ms |

**What this proves:**

- The **dominant** per-frame cost of the per-node modes is `flutter_scene`
  building draw commands for 1,600 *individual* nodes on the UI thread —
  **~12 ms (~7.7 µs/node)** — present even with **no ECS at all**.
- The **entire** Scene-Dash ECS + full-sync overhead is the **~2.4 ms delta**
  (~1.5 µs/node): the `Query2` sync writing a TRS matrix and dirtying every node.
- One `InstancedMesh` collapses 1,600 nodes into a single render item:
  **~8× faster build (~12 ms → ~1.6 ms)**, even though 0.18.x's GPU backend is
  still "naive" (one draw per instance) — the win is on the **UI thread** (no
  per-node scene-graph walk / draw-command build), not the GPU.
- GPU raster is trivial (~1 ms) throughout; the frame is **UI-thread bound**.

**Conclusions.**

1. **Change tracking / changed-only sync is *not* the lever.** It could only
   reclaim part of the ~2.4 ms ECS overhead, and only for static-heavy scenes; it
   cannot touch the dominant per-node rendering cost. Deferred — the ECS is
   already cheap (~1.5 µs/node).
2. **Instancing is the lever, and it needs zero integration support.** The
   instanced path is *pure game code* — an `InstancedMesh` held as a resource, an
   `Instance` component, and a system writing instance transforms via the raw
   `flutter_scene` API (see `examples/scene_benchmark`, `--dart-define=instanced`).
   Scene-Dash's integration stays a thin lifecycle layer; it never grows a method per
   `flutter_scene` feature, and games benefit the moment `flutter_scene`'s
   instanced backend matures, with no changes on our side.
