# P1-D isolated GPU timing

DATE: 2026-09-29
STATUS: Isolated GPU execution measured on the current host. A08's named current-host cases pass.
ISSUE: none (local implementation packet)

## Scope and method

Installed code at `26d5fb9`, SketchUp 26.1.188, Ruby 3.2.2, macOS 26.6.2, Apple M1 Max.
Fresh SketchUp process PID 11093 opened the saved synthetic `p1d-colour-scale.skp`:
86 Zones, 516 classified Faces and 1,032 fill triangles. No shipping code changed.

Instruments' installed `Metal System Trace` template was recorded with `xcrun xctrace record`
attached to SketchUp. The exported `metal-gpu-intervals` table supplies GPU start, duration,
channel, frame and process. Analysis resolves XML reference elements and accepts only Active
intervals attributed to `SketchUp (11093)`. WindowServer and other applications are excluded.

One off path and one on path each move the camera through the same 120-step orbit, with a
50 ms repeating native UI timer. The helper binds the Model, verifies the 516-Face fixture,
activates the mode with `remember: false`, and refuses a Model switch. Both captures contain
120 complete orbit frames, each with ten GPU intervals spanning clear, main render,
transparency, merge, post-transparency and blit work. Startup frames are excluded; the first
ten orbit frames are discarded. The remaining 110 frames are paired by camera step.

GPU busy time is the union of the Active intervals within each frame. Overlapping vertex,
fragment and compute activity is counted once. This measures device execution rather than
CPU submission, time waiting in a queue or elapsed `View#refresh`. Added time is each on
frame's busy time minus its paired off frame's time, not a difference of percentile summaries.

## Results

| GPU busy time | Samples | Median ms | p95 ms | Maximum ms |
| --- | ---: | ---: | ---: | ---: |
| Colour-by off | 110 | 1.535 | 1.696 | 1.745 |
| Colour-by on | 110 | 1.753 | 1.947 | 2.021 |
| Paired added time | 110 | 0.211 | 0.683 | 1.210 |

Full fingerprints match before and after each orbit: Zone/Face records, transforms, loops,
stamps, entity dictionaries, Model attributes, materials and assignments. The Model remains
unmodified. Native Edit shows Undo and Redo disabled after capture. The viewport visibly
shows the coloured boxes and the 344 Wall / 86 Floor / 86 Roof or ceiling legend.

The initial idle trace had no SketchUp GPU activity. A first on capture ended before its last
two frames and was discarded. The reported on capture was repeated with a longer window;
both accepted traces have all 120 complete orbit frames. An initial multi-window bridge/UI
Model mismatch was resolved by opening only the scale fixture in a fresh process before any
accepted timing run.

Raw traces, XML, helper and analysis scripts remain gitignored under `_private/host/` with
the `p1d-gpu-` prefix. Instruments traces contain local environment and unrelated process
metadata and are not public fixtures.

## Disposition and limits

This closes the isolated GPU measurement left by the [Colour-by continuation](p1-d-colour-by-continuation.md).
Together with the existing five-path redraw/cadence screening and native visual, invalidation
and lifecycle evidence, A08's named current-host cases pass. The GPU run is one paired path
of classified fills on this host; it does not claim a five-path GPU benchmark, hatch GPU
cost, large-project performance, SketchUp 2023 or Windows support. The earlier CPU hatch
generation measurement remains separate. No full offline suite was repeated for evidence-only
changes; code gates at `26d5fb9` remain applicable.

P1-D still requires A06's clean one-to-many partition pairing and Face/Zone extension-reference
targets. The PRD already requires clean partitions to solve; the current blanket
`adjacency.multiple_neighbours` report does not satisfy that case. The recorded two 6 m²
Faces against one 12 m² counterpart is the next native regression fixture.

The subsequent [multi-neighbour continuation](p1-d-multi-neighbour-adjacency.md) implements and
verifies that regression and the stacked-Zone case. A06's extension-reference boundary remains open.
