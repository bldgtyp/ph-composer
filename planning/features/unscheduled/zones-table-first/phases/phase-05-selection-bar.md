# ZT-05: the floating selection bar

DATE: 2026-10-04
STATUS: Implemented on branch
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## Steps

1. A kit part, `selection_bar.js` (D5): a bar in the overlay layer over the bottom of a work surface,
   holding a count line and whatever controls its owner places, and a clear icon. While shown it pads
   its scroll area by its own height so the last rows stay reachable; it never reflows the table.
   Styles in `table.css` or a new kit stylesheet listed in `index.html` and TECH_STACK's owner list.
2. Zones / Faces places it while any Face is checked: "N Faces selected" (", M hidden" under a
   filter, D7), then Type, Boundary and Assembly. These are the selection inspector's rules moved
   and pointed at the checked set: each choice is one `classify` or `assign_assembly` request for
   every checked Face, one Undo step; a value they do not share reads Mixed; a value a chip cannot
   set keeps that control read only; Assembly is disabled with its reason while an unclassified Face
   is checked; past `gesture_face_limit` the controls are disabled with the limit as the reason (I6).
   The Assembly picker takes its targets from the checked set (references and values from the Faces
   read), not from the `.selected` snapshot.
3. Checked rows take the selection tint.
4. While the Classify tool is on, the bar shows the Classify palette instead (the palette's chips,
   Attached zone picker and Stop), whether or not any Face is checked. The toggle in the header stays
   the tool's pressed state; Escape unwinds one layer.
5. Tests: the bar's count and hidden count, Mixed, one request per choice carrying every checked
   Face, the unclassified Assembly reason, the limit, the palette replacing the controls while the
   tool is on.

## Acceptance

`make ci` passes. A checked set across two Zones is edited from the bar in one Undo step.

## Outcome

Implemented 2026-10-04. `selection_bar.js` is the kit part (`SelectionBar(label, onClear)`, `show(text,
clearable)`, `hide()`, `reserve(scroll)`), styled in `overlay.css`. Zones / Faces places it in a section of
its own, `ph_composer.zones.selection_bar`, ordered last so it reads what the tree and the palette just
painted; the bar's layer is a zero-height sibling of the table inside the pane's positioned main region.
The inspector's Face-selection section is gone: its controls moved into the bar and act on the checked
set (`barTargets`). The Classify palette is now a `main`-region section the bar adopts while
`classify.showing()`; the toggle no longer asks `panel.inspectorHeld`. The palette read publishes
`gesture_face_limit`, and past it the bar's controls are disabled with a `reasonButton`. The Assembly
`Picker` takes an optional `targets()` and refuses, with its reason in the tooltip, while an
unclassified Face is checked. Tests in `tests/overview_panel_test.js` and
`tests/assembly_assignment_panel_test.js`. `make ci` passes. Visual check of the bar is with ZT-06.
