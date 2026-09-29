# P1-D Colour-by native continuation

DATE: 2026-09-29
STATUS: Native inspector toggles, foreground occlusion, alpha and orbit verified on the current
host. Feature redraw and cadence measured. Isolated GPU timing remains unverified.
ISSUE: none (local implementation packet)

## Scope and host

SketchUp 26.1.188, Ruby 3.2.2, macOS, installed branch code at `d27fa58`. No shipping code changed.
This continues A08; it does not close the remaining authoring or export gates. Previously passing
hole/concave tessellation, picking, visibility and Model lifecycle cases were not repeated.

Synthetic local fixtures and readbacks remain gitignored under `_private/host/`:
`p1d-colour-occlusion.skp`, `p1d-colour-scale.skp`, `p1d-colour-acceptance.rb`,
`p1d-colour-timing.json` and `p1d-colour-fingerprint.json`. The original copy-safety fixture was
preserved. Scale geometry was authored through public Make Zone and Suggest Classification calls.
Mode activation used `remember: false`, preserving the user's remembered choice.

## Native inspector and viewport

| Case | Result |
| --- | --- |
| Untick PH-Composer Colour by in SketchUp's Overlays inspector | Ed operated the native checkbox after the floating inspector could not be clicked reliably through computer control. Host readback changed `enabled?` to false. The supplied screenshot showed the yellow fill and upper-left legend both gone. Other overlay checkboxes stayed enabled. |
| Re-check the same overlay | Ed operated the checkbox. Host readback returned true; the screenshot and Ed's confirmation showed the yellow fill and legend restored. |
| Native toggle Model integrity | Full Zone/Face records, transforms, loops and stamps were unchanged; Model remained unmodified. Native Edit menu showed Undo and Redo disabled. |
| White unclassified panel 500 mm in front of a classified wall | Panel stayed white and completely covered the fill behind it in front perspective, parallel projection and an oblique view. |
| Alpha over a red wall material | Yellow fill blended to orange; deactivation restored the red wall. Full material definitions and assignments remained unchanged. |
| Rear view | Neither the red front wall nor the foreground white panel bled through the opposite classified wall. |
| Native Orbit | Computer control operated Orbit and dragged in an unobstructed part of the viewport; the camera moved to an oblique view with the white occluder still correctly drawn. |

The native checkbox suppresses drawing while the service retains its selected mode and cached
legend. Re-checking restores that drawing. It is a host visibility override, not a record edit or
mode deactivation. Explicit mode activation enables the overlay again, as the implementation does.

## Feature timing at scale

The scale Model contains 86 independently authored boxes, 516 classified Faces and 1,032 fill
triangles. One warm-up orbit was discarded, then five interleaved 90-frame paths ran with the
service off and on. Each step used the same camera path and measured elapsed `View#refresh`.
Added cost is each on step minus its paired off step, not the difference of percentile summaries.
The helper bound the Model and service and refused a Model switch during measurement.
An earlier run returned to the smaller fixture and was discarded entirely.

| Forced redraw | Samples | Median ms | p95 ms | Maximum ms |
| --- | ---: | ---: | ---: | ---: |
| Colour-by off | 450 | 2.488 | 8.187 | 13.343 |
| Colour-by on | 450 | 6.576 | 8.216 | 18.128 |
| Paired added cost | 450 | 4.815 | 7.532 | 16.498 |

A development-only overlay probe recorded draw-callback timestamps while a repeating zero-delay
UI timer moved the camera and invalidated the view. The same probe was present in both runs.
Each run used 360 steps, discarding the first ten intervals; it performed no geometry writes.

| Free-running cadence | Intervals | Median ms | p95 ms | Maximum ms |
| --- | ---: | ---: | ---: | ---: |
| Colour-by off | 350 | 2.735 | 8.389 | 12.125 |
| Colour-by on | 350 | 6.864 | 8.241 | 14.656 |

The p95 added redraw cost is below the prior overlay spike's 16 ms screening criterion near
1,000 triangles. No observed redraw or cadence gap reached its 100 ms stall criterion.
These are measurements of the current feature on one host, not a product performance promise.

Full records, Zone geometry, entity dictionaries, Model attributes, materials and assignments
matched the pre-display snapshot exactly. The file remained unmodified. The native Edit menu
still offered `Undo Suggest Classification`, the fixture's final authoring operation, with Redo
disabled; display changes added no Undo entry. The development probe was removed after each run.

## Limits and disposition

This verifies the foreground depth/alpha/orbit cases left by the earlier continuation. It adds
native feature timing beyond the earlier Ruby rebuild measurement. It does not isolate GPU
completion: `View#refresh` may return before GPU work finishes, and callback cadence includes
host scheduling. The [SketchUp View API](https://ruby.sketchup.com/Sketchup/View.html) exposes
refresh timing but does not document it as GPU timing. This preserves the same limitation as
the [original overlay spike](../../archive/phase-zero/evidence/spike-overlay.md).

Isolated GPU timing and the PRD's unclassified hatch versus the implemented stippled outline
remain open. SketchUp 2023, Windows, large-project performance, P1-E/F and public release claims
remain outside this run. No offline suite was repeated for this evidence-only change; the
required full code gates already passed at `d27fa58`.
