# B3 spike: window component

DATE: 2026-09-18
STATUS: Complete. Result: the flat cutting component works as the window unit. The cut is a
rendered opening, not host topology, and glue survives host edits it should not survive. The
window-types plan has five consequences, under "Disposition".
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## Setup

- **Host:** SketchUp 26.1.188, Ruby 3.2.2, macOS 26.6.2, Apple M1 Max (Metal). A fresh process on a
  copy of the Simple template (`7987cc22…7452f4`), driven through `ph_composer_host_bridge`. The
  predecessor and designPH were also loaded.
- **Generator:** `tools/spikes/window/window_spike.rb`, one Model operation per step.
- **Zones:** two Zone-like groups, 5 × 4 × 3 m. `zone_a` sits at the top level. `zone_b` sits
  inside a `parent` group offset by 8 m. Each south wall is one 15.0 m² face.
- **Definition** `b3_window_type`: one face per glazed element, each 1,000 × 1,200 mm, 50 mm apart,
  in the definition's XY plane. Behaviour: `is2d`, `cuts_opening`, `SnapTo_Arbitrary`,
  `no_scale_mask` 127 (every handle off). The definition carries `window_type_id`.
- **Placement:** axes in the face plane, with the Z axis on the face normal. The instance is added
  to the face's own entities and `glued_to` the face.
  - `direct` and `repeated` on `zone_a`;
  - `nested` on `zone_b` (a group inside a group);
  - `mirrored` on `zone_b`, with an X scaling of −1.
- **Model:** `_private/host/spikes/window/window.skp` (`cd956894…c98b08c9`).

## Observations

| Step | Host face loops | Host face area | Glue | Other |
| --- | --- | --- | --- | --- |
| Before placement | 1 | 15.0 m² | none | outer-loop area 15.0 m² |
| Two 2-element units per wall | 1 | 10.2 m² (15.0 − 2 × 2.4) | each unit to its wall | outer-loop area 15.0 m²; the mirrored unit reads determinant sign −1 |
| First layout: one unit overhanging the wall end by 50 mm | 1 | 11.4 m² on that wall | glued | the overhanging unit subtracted nothing |
| First layout: two units overlapping by 1.1 m | 1 | 10.2 m² | glued | both full areas subtracted; the overlap counted twice |
| Definition rewritten to 3 elements (one operation) | 1 | `zone_a` 9.0, `zone_b` 7.8 m² | unchanged | all four instances changed; they now overhang and overlap, with no refusal |
| `transform!` scaling 1.5 in X on one unit | 1 | 9.6 m² | unchanged | `no_scale_mask` did not stop it; `xscale` reads 1.5 |
| Vertical line splitting `zone_a`'s wall at 2,625 mm | 1 and 1 | 5.475 m² (old pid 48911, outer 7.875) and 7.125 m² (new pid 49016, outer 7.125) | both units still glued to 48911 | the unit lying wholly on the new face stays glued to the old one; the new face shows no reduction |
| Explode `direct` | 3 (outer plus 2 inner) and 1 | new pids 49050 and 49051 | the stretched unit still glued to pid 48911 | pid 48911 is now a 0.03 m² inward-facing scrap left by the explode; `glued_to` reports it valid |

- **The opening is real in the view.** From inside `zone_a`, with the pane faces hidden, the
  openings show the sky, the ground and the axis outside
  (`inside_panes_hidden.png`, `5d747adf…ed829f21`).
- **The host face's topology does not change:** one loop. `Face#area` is the only thing that
  reports the cut.
- **Undo and Redo:** `Sketchup.undo` and `Sketchup.redo` over the four edits restored every state
  exactly: glue, scale, face persistent ids and areas. Ed's Edit menu named each step ("Undo B3
  place", "Undo B3 setup"), and one Undo removed all four placements.
- **Save and fresh-process reopen:** unit and face persistent ids, glue (including the stale one),
  `xscale` 1.5, determinant sign −1 and the definition's behaviour all persisted. The Model opened
  unmodified.
- **Ed's native check:**
  - A single click on the glass selected the Zone group. Inside the group, one click selected the
    whole unit, both panes as one.
  - With a unit selected, the Scale tool showed no handles.
  - Move slid the unit along the wall, and the opening followed. Dragging the unit off the wall
    pulled it off the face.
  - Ed first read "no hole", because the panes filled the openings and showed their back faces.
    The generator drew the panes facing into the wall (local −Z, world +Y). With that understood,
    Ed confirmed he could see through the openings.

## Disposition

The flat component stays the window-unit representation (window-types Q1). A flat unit is easy to
click and manage, so Ed's more-geometry fallback is not needed. The Window plan must carry these
five consequences:

1. **Author panes facing out.** Each element face's normal is the definition's +Z, so the front
   face shows outside. A definition that gets this wrong looks uncut.
2. **Never read net area from `Face#area`.** The cut does not change host topology, and
   `Face#area` subtracts every glued cutting instance's full area: an overlap counts twice and an
   overhang can count as nothing. Export uses the host's outer loop as the gross polygon, which is
   honeybee's shape (Q26), plus Apertures from each unit's outline. Overlap and overhang are
   refused or reported from those outlines.
3. **Verify glue geometrically.** A split host face leaves its units glued to the original face
   even when they lie on the new one, and that new face is not cut. An explode can leave glue on
   an unrelated scrap face. "Unit unhosted" must check that the glued face exists, is coplanar and
   contains the unit's outline, not only that `glued_to` is non-nil. Solve adjacencies
   (zones Q12) must re-host or report the units on every face it splits.
4. **`no_scale_mask` is a UI restriction only.** The Scale tool shows no handles, but
   `Transformation` scaling applies freely. Q8's finding, "size differs from type", reads `xscale`
   and `yscale`. A mirrored unit reads a negative determinant.
5. **A type edit re-validates placements.** A definition rewrite is one operation and one Undo
   step, and every instance follows. Growing a type can push units off their host or into each
   other with no host refusal.

## Limits

- One host; no SketchUp 2023 and no Windows.
- Picking and the placement tool were not built. Selection was checked by Ed's clicks.
- Where a glued, cutting instance sits exactly on a split line was not measured. The split in this
  run fell between the two units.
- The overhang case subtracted nothing on one run and part of the area after the rewrite. The
  rule SketchUp applies was not isolated; the plan relies on none of it.
