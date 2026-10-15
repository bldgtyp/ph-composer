# LR-02: the grip and the drag gesture

DATE: 2026-10-15
STATUS: Complete 2026-10-15
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: [#128](https://github.com/bldgtyp/ph-composer/issues/128)

## Entry and scope

Requires LR-01 merged and Ed's confirmation of LR-D5 to LR-D9. Owns the panel side: the grip in
each Layer's dimension cell, the drag module, its styles, the six-dot glyph and the offline tests.
The grip and the gesture ship together; an inert grip never ships
(`.agents/skills/ph-composer-ui-polish/references/patterns.md`, "Assembly contextual Layer tools").

Load `.agents/skills/ph-composer-ui-polish/SKILL.md` and read
`.agents/skills/ph-composer-architecture-review/SKILL.md` before changing a file. Paths are
relative to `src/ph_composer/`.

## The gesture, stated once

Pointer down on a grip records the source Layer id, its index, the layout and the pointer origin. The first move beyond 6 px (36 px squared, as `library/drag.js`) begins the
drag: `owner.dragging = true`, `ui.Bubble.closeActive()`, body class `is-dragging`, a ghost label
appended to `document.body`, and the insertion line appended to the drawing. Every move re-reads
`drawing.getBoundingClientRect()` and converts the pointer's y to millimetres through
`owner.zoom`, then picks the nearest boundary from `layout.layers[].yMm` plus the drawing's
bottom: boundary `b` in `0..n`. The destination index is `b` when `b <= source`, else `b - 1`.
A destination equal to the source index shows the line muted and marks the drop a no-op. A pointer
released beyond the frame rect plus 40 px on any side is an outside drop (LR-D8); within the margin
above or below clamps to 0 or `n`.

Release: end the drag first (listeners off, ghost and line removed, flags cleared), then, if the
drop was inside and changed and `owner.allowed()` holds, send
`owner.action("layers.reorder", { layer_id, index })` once. `action` attaches `expected_values`;
a Model that moved refuses `target.changed` on the host and the ordinary failure notice shows
(LR-D4). Escape (capture phase), `window` blur, `Editor.dispose()`, a refresh while dragging and a Material
drag starting (it cannot, see guards) all end the drag with nothing sent. The trailing click the
browser emits after a drag is suppressed as `library/drag.js` does.

Guards at pointer down: `owner.busy()`, `owner.hasDimensionDraft()`, `owner.hasRecordDraft()`,
`owner.dragging` (a Material drag) and `owner.disposed || !owner.enabled` refuse to start, through
`owner.allowed()` so the user hears why. While a Layer drag is active `Editor.guard()` returns
"Finish moving the Layer first." so the sidebar's Material drag and every bubble refuse to open.

## Steps

1. **Glyph.** Add `grip_vertical` (Lucide `grip-vertical`, six dots) to `html/icons.js` under the
   existing ISC notice. Keep the four-dot `grip`.
2. **Module.** `html/features/assemblies/layer_drag.js`, written in ES5 (`var`, `function`) so it
   reads like `stage.js`, `layer_tools.js` and `library/drag.js`, defining
   `features/assemblies/layer_drag` with dependencies `features/assemblies/editor_shared` and
   `workspace`. It exports a constructor taking the owner (the Editor) and a `bind(grip, context)`
   that wires one grip: `context` carries the Layer id, its index, the layout, the drawing element
   and the frame element. Hold one drag state per Editor, not per grip. Expose `end()` for
   `Editor.dispose()` and `refresh()`; expose the boundary computation as a pure function
   `dropIndex(layout, zoom, drawingRect, clientY, sourceIndex)` so the stub DOM can test it with
   `.rect`.
3. **Stage.** In `stage.js`, beside the gear: `ui.iconButton("Drag Layer " + (index + 1),
   "grip_vertical")` with class `assembly-layer-grip`, `data-layer-drag-trigger` set to the Layer
   id, `data-editor-local` so `paintPending` leaves it alone, and `tabindex="-1"` (LR-D9). Bind it
   through the drag module. The hover corridor in `stage.js` reads `activeCell.lastChild` as the
   gear's box; after the grip is appended that must become the box of the two controls together
   (the gear's left to the grip's right), or the thin-Layer corridor loses the row at the grip.
   Write the test for that before moving the grip in.
4. **Editor.** `Editor` constructs the drag module, ends it in `dispose()` and at the top of
   `refresh()`, and extends `guard()` with the active-drag reason. The `dragging` flag is shared with
   the Material drag; both set and clear it, and neither can start while it is set.
5. **Styles and gutter.** Widen the gutter per LR-D11 first, with the browser check's
   centring assertion in mind, then in `assembly.css`: the grip shares the gear's reveal rules (`.is-layer-hovered`,
   `:focus-within`, `.has-open-tools`) and hides with it while `.phc-dimension-inline.is-editing`
   owns the gutter. Cursor `grab`, `grabbing` on the body while dragging. The insertion line is
   `.assembly-drop-line`: 3 px, `--drawing-highlight`, full drawing width, `pointer-events: none`,
   `.is-noop` muted. The ghost is `.assembly-drag-ghost`, fixed, above bubbles, `pointer-events:
   none`. The thickness value and the drawing must not move when controls reveal (the browser
   check in LR-03 asserts it).
6. **Manifests.** `make panel-manifest` (a panel module was added), then
   `uv run tools/runtime/vendor.py --refresh-manifest`, then `make ci`.

## Source

| File | Disposition |
| --- | --- |
| `html/icons.js` | Add `grip_vertical` |
| `html/features/assemblies/layer_drag.js` | New |
| `html/features/assemblies/stage.js` | Grip per Layer; corridor box fix; gutter constants |
| `html/features/assemblies/canvas.js` | `ASSEMBLY_CANVAS_ORIGIN_X_PX` |
| `html/features/assemblies/editor.js` | Construct, dispose, refresh, guard |
| `html/features/assemblies/assembly.css` | Grip, line, ghost, cursors |
| `html/index.html`, `tools/ui-preview/index.html`, the runtime manifest | Regenerated |
| `tests/assembly_builder_test.js`, `tests/icons_test.js` | Tests below |

## Tests (write first)

In `tests/assembly_builder_test.js`, using `setup()`'s two-Layer fixture extended to four Layers
(board, studs, a membrane, sheathing) with `.rect` on the drawing and the frame:

1. `dropIndex` returns 0 above the first boundary, `n - 1` below the last, the nearest boundary for
   a pointer on a membrane band, and the source index for a release on either boundary of the
   source Layer; the result is the same with `orientation` set to `last_layer_outside`.
2. A drag from the last Layer's grip to the first boundary sends exactly one request named
   `ph_composer.assemblies.assemblies.layers.reorder` with that Layer's id, `index: 0` and
   `expected_values` equal to the record's `layers`, `orientation` and `air_barrier`. After
   `result(o)` with the reordered record, the selection and the open state survive, the grips are
   rebound to the new order, and nothing else was sent.
3. A release on the source's own boundary sends nothing; a release outside the frame margin sends
   nothing; a move under the 6 px threshold then release sends nothing and suppresses no click.
4. Escape mid-drag, `window` blur mid-drag and `editor.dispose()` mid-drag each remove the ghost
   and the line, clear `editor.dragging` and `document.body` classes, remove the document listeners
   (`document.listenerLists.mousemove` is empty) and send nothing.
5. Pointer down is refused with a notice while a dimension draft, a record draft or a request is
   pending, and while `editor.dragging` is already set by the Material drag; a Material drag cannot
   start while a Layer drag is active.
6. A snapshot `refresh()` during a drag ends it, removes the ghost and the line, and sends nothing.
   A `target.changed` outcome on the request shows the ordinary failure notice and leaves the
   drawing truthful (the refreshed record).
7. The grip has `aria-label` "Drag Layer N", `tabindex` `-1`, and is hidden (the same class state as
   the gear) while the thickness inline field is editing.
8. In `tests/icons_test.js`: `grip_vertical` renders six circles.

## Gate

`make ci` on both Rubies after the manifests; `make coverage` holds the 94 percent JavaScript floor.
One review carrying both rubrics: the UI polish questions are the reveal rules, the two highlight
roles (red line for the transient drop, teal untouched for selection), the stationary drawing and
Escape unwinding; the architecture questions are the module's single public entry, no record
mutation in the UI and the one action per drop.

## Out of scope

Browser checks (LR-03). Keyboard reordering. Auto-scroll (LR-D7). Any change to `library/drag.js`.

## Done when

Tests 1 to 8 pass, the review is recorded in [STATUS.md](../STATUS.md), the PR is merged, and the
stage row reads `Merged to main`. The grip is visible on the preview page and drags there, but that
is a developer observation, not acceptance.
