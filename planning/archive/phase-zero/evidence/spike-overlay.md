# B2 spike: overlay fill

DATE: 2026-09-18
STATUS: Complete. Result: pass. Filled overlays meet every frozen criterion at 1,000 triangles on
the proving host; the 10,000-triangle headroom case adds about 4 to 5 ms a frame.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## Expected (frozen before measuring)

Frozen 2026-09-18, as the P0-B plan proposes them, with no revision:

- **Cost:** at 1,000 triangles, the p95 added draw cost of the filled overlay is at most 16 ms.
  Added cost is the filled mode's frame interval minus the disabled mode's, on the same camera
  path, over five repeated paths after a warm-up. Ruby time inside `Overlay#draw` is recorded
  alongside, since it counts only marshalling and not the GPU.
- **Stalls:** no input-blocking stall over 100 ms attributable to the overlay, measured as the
  longest gap between UI-timer ticks during a path.
- **10,000 triangles** measures headroom and has no pass mark.
- **Correctness (Ed, native):**
  - fill is hidden by geometry in front of it;
  - hidden geometry is not filled;
  - alpha shows the Model through the fill;
  - clicking a face under the fill selects that face;
  - orbit stays usable.
- **Model unchanged:** materials, attributes and the Undo stack are the same before and after.

These are engineering screening criteria, not a product performance promise. Failure selects the
decision register's outline-only fallback and records which filled modes are unavailable.

## Host and inputs

- **Host:** SketchUp 26.1.188, Ruby 3.2.2, macOS 26.6.2 (25G83), Apple M1 Max, Metal 4. Built-in
  Retina display at 2048 × 1152. Fresh process, driven through `ph_composer_host_bridge`. The
  predecessor, its bridge and designPH were also loaded, as in every Phase 0 host run.
- **Model:** a copy of the stock Simple template (SHA-256 `7987cc22…7452f4`), with scenes from
  `tools/spikes/overlay/overlay_spike.rb` (`OverlaySpike.build`, one operation). Saved as
  `_private/host/spikes/overlay/overlay.skp` (`f73d1425…236bee1`).
- **Scenes:** three groups of 100, 1,000 and 10,000 target triangles. Measured by
  `Face#mesh.count_polygons`: 112, 1,012 and 10,012 including a 12-triangle occluding box.
- Each cell of about 20 triangles holds:
  - a concave L face and a face with a hole;
  - two overlapping faces in separate groups;
  - a reversed face;
  - a nested group holding a rotated, half-scaled component instance.
  Alternate cells stand vertical.
- **Overlay:** a `Sketchup::Overlay` that caches world-transformed triangles (`Face#mesh`) and loop
  edges once per scene. Hidden entities and the occluding box are skipped. Fill is RGBA
  (0, 110, 255, 110) with 2 px outlines.

## Results

**Forced redraws** (`OverlaySpike.measure(paths: 5, frames: 90)`): one warm-up path, then five
interleaved orbit paths per mode. Each frame is one `View#refresh`, so 450 frames per mode.
"Added" is the paired frame-by-frame difference from the disabled mode on the same camera step.
Ruby draw time is the time spent inside `Overlay#draw`.

| Scene | Mode | Median ms | p95 ms | Max ms | Added median ms | Added p95 ms | Ruby draw median / p95 ms |
| --- | --- | ---: | ---: | ---: | ---: | ---: | --- |
| 112 | disabled | 2.04 | 7.95 | 19.83 | 0 | 0 | none |
| 112 | outline | 1.61 | 6.66 | 17.93 | 0.15 | 4.78 | 0.06 / 0.10 |
| 112 | fill | 1.42 | 8.11 | 22.65 | 0.15 | 5.43 | 0.11 / 0.17 |
| 1,012 | disabled | 1.53 | 12.29 | 21.05 | 0 | 0 | none |
| 1,012 | outline | 1.38 | 12.43 | 18.39 | 0.23 | 9.38 | 0.21 / 0.27 |
| 1,012 | fill | 1.48 | 10.33 | 19.96 | 0.35 | 8.72 | 0.42 / 0.51 |
| 10,012 | disabled | 3.01 | 6.35 | 19.35 | 0 | 0 | none |
| 10,012 | outline | 4.94 | 5.40 | 15.61 | 1.94 | 2.52 | 1.78 / 1.94 |
| 10,012 | fill | 7.17 | 7.71 | 17.81 | 4.19 | 4.81 | 3.81 / 4.07 |

**Free-running cadence** (`cadence_start` / `cadence_stop`): a repeating zero-delay timer moves the
camera and invalidates the view, and the interval between draw calls is recorded (349 intervals
per run).

| Scene | Mode | Median ms | p95 ms | Max ms |
| --- | --- | ---: | ---: | ---: |
| 1,012 | disabled (two runs) | 1.41, 1.55 | 12.86, 13.12 | 18.63, 19.05 |
| 1,012 | fill (two runs) | 1.61, 1.65 | 12.35, 9.88 | 20.27, 19.66 |
| 1,012 | outline | 1.79 | 14.11 | 18.55 |
| 10,012 | disabled (two runs) | 3.07, 3.05 | 5.56, 6.76 | 18.45, 18.33 |
| 10,012 | fill (two runs) | 7.68, 7.67 | 8.24, 8.40 | 14.34, 13.06 |
| 10,012 | outline | 5.21 | 5.73 | 14.82 |

At 1,012 triangles the p95 differences come from host noise present in the disabled mode as well.
The medians differ by a fraction of a millisecond. At 10,012 the fill's cost is visible and steady,
at about 4.6 ms, and most of it is Ruby marshalling inside `draw`.

**Model unchanged:** `OverlaySpike.fingerprint` was identical before and after every scripted
measurement: entity count, material names, attribute-dictionary count and modified state. Scene
switching (`hidden` flags) is the spike's own setup and happened before each baseline. After Ed's
native check the count was 5 higher: his own edit, made while testing, not the overlay's.

**Native check (Ed, 2026-09-18),** with fill on over the 1,012 scene and a window capture
(`_private/host/spikes/overlay/fill_1000.png`, `01defe94…9bce5`):
- orbit was smooth;
- the fill stayed hidden behind the white box from every side and never drew over it;
- edges showed through the fill;
- the deliberately hidden cell had no fill;
- clicking a shape under the fill selected it as usual.

Ed also noted that the fill does not follow geometry he moved. That is expected of this spike,
whose cache is built once. A feature rebuilds the affected instance's cache from its observers, as
the predecessor's measured overlay fact already records.

## Verdict against the frozen criteria

| Criterion | Result |
| --- | --- |
| p95 added cost at 1,000 triangles ≤ 16 ms | Pass: 8.72 ms (forced redraw); cadence shows no median difference |
| No stall > 100 ms attributable to the overlay | Pass: worst frame in any mode 22.65 ms |
| 10,000-triangle headroom | Measured: about 4.2 to 4.6 ms added per frame |
| Occlusion, alpha, hidden geometry, picking, orbit | Pass (Ed, native) |
| Model unchanged | Pass |

## Disposition

Filled overlays are available. The outline-only fallback is not needed. Colour-by (face
assignment) and the Spaces volume preview may plan on filled modes. Their plans own the cache
invalidation from observers, and a budget for Models past about 10,000 overlaid triangles, where
Ruby marshalling dominates the added cost.

## Limits

- One host: Apple M1 Max and Metal on macOS 26. No Windows, no integrated-GPU Mac, no SketchUp 2023.
- `View#refresh` times return before the GPU finishes a frame; the cadence runs cover what a user
  sees. Neither isolates GPU time.
- Picking was checked by clicking, not by `PickHelper` under the overlay.
- A synthetic scene: flat faces only, no curved or smoothed geometry, no textures.
