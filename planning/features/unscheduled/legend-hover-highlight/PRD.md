# Legend hover-to-highlight

DATE: 2026-09-30
STATUS: Requested
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## Problem

The [face-assignment PRD](../../phase-02-envelope/face-assignment/PRD.md) Q18 names four legend affordances: click to
select and zoom, counts, Show only this, and hover to highlight. Phase 1 shipped the first three.
Ed chose on 2026-09-20 to measure hover before shipping it ([Phase 1 plan](../../../archive/phase-01-faces-and-zones/PLAN.md),
"What D7 left open").

The D7 host run answered that measurement: at 512 classified Faces, the Ruby Overview snapshot
alone costs 39 to 47 ms, well over a 16.7 ms frame
([Overview evidence](../../../archive/phase-01-faces-and-zones/evidence/p1-d-overview.md), Q1). One command, snapshot and
repaint per pointer move is therefore not an acceptable design. The feature waits on a cheaper,
measured path.

## Behavior

- Pointer enters a legend row: that row's entities draw with a distinct highlight in the viewport.
  Pointer leaves the row or the legend: the highlight clears. Moving between rows moves it.
- Applies to the panel legend of every Colour-by mode, through the shared service. No mode adds
  its own hover code.
- View-only. Writes no record, no material, opens no operation, leaves no Undo entry, does not
  change the selection. Model fingerprints stay unchanged, as for Colour-by today.
- Composes with Show only this and isolation: hover highlights within what is visible and never
  un-hides anything.
- Keyboard focus on a legend row gives the same highlight, so the affordance is not pointer-only.

## Design direction

The expensive part is the panel snapshot, not drawing. The row-to-entity grouping and the
tessellated fills already exist in the Colour-by drawing cache.

1. The panel sends one small view command carrying the legend row key, only when the hovered row
   changes, trailing-throttled (for example one per animation frame). Never per pointer move.
2. The shared overlay stores the highlighted key as view state and draws that row's cached fills
   with a highlight style, then invalidates the view. No snapshot rebuild, no cache rebuild, no
   Model walk.
3. Cache invalidation already clears on geometry, tag, scene and context changes; a stale key
   simply draws nothing.

## Acceptance shape

- Offline: the command is view-only, deduplicates unchanged keys, and a hover on an unknown or
  stale key draws nothing and writes nothing; no mode-specific branch in the shared renderer.
- Host, on the 512-Face and 1,032-triangle Phase 1 fixtures: time from row change to redraw, and
  added redraw cost with a highlight active, with p95 inside one 16.7 ms frame; sweeping the
  pointer down the full legend shows no stall. Record exact host and fixture as prior evidence did.
- If the budget is missed, report the measurement and stop. Do not ship an unmeasured fallback.

## Open questions

| # | Question |
| --- | --- |
| Q1 | Highlight style: brighter fill, outline, or dimming everything else (which Show only this already does)? |
| Q2 | Should the viewport HUD legend echo the hovered row? |
