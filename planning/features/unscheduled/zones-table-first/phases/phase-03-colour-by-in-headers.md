# ZT-03: Colour by in the column headers

DATE: 2026-10-04
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## Steps

1. Host: `Registry#colour_mode` accepts an optional `group:` string, validated as a non-empty string
   by `registry_validation.rb`. The legend payload's `modes` carry `group`. Zones' Assembly mode and
   Windows' Window Type mode declare `"construction"` (D2). Update the declaration schema and
   `docs/API_REFERENCE.md` if the mode list is part of a published read.
2. `sections/colour_by.js` becomes parts a pane places, and no longer registers an inspector
   section or a `tools` select:
   - `colourBy.headerToggle(state, binding)`: a header action for a column bound to `{ mode }` or
     `{ group }`; `aria-pressed` while its mode (or any mode in its group) is on, named "Colour by
     <mode>". Pressing an unpressed single-mode toggle activates it; pressing the pressed one turns
     Colour by Off. A group with several modes opens an anchored menu of them, with the active one
     marked and an Off item.
   - `colourBy.legendStrip()`: the mode's label, then one chip per row (swatch, label, count).
     A chip click runs `select_row`; an isolate icon on chip hover or focus runs `isolate`, and
     "Show all" while a row is isolated (D3). Empty when Off, keeping its slot.
   - `colourBy.unboundModes(bound)`: the modes no visible column binds, for an options menu (D1).
   The section keeps owning the view channel and session reset.
3. Zones / Faces binds Name to `ph_composer.zones.by_zone`, Building-Segment and Level to their
   modes, Type and Boundary to the faces modes, Assembly to group `"construction"`. The legend strip
   takes the control row slot the select held (the pane's `tools` region). A Table options menu in
   the control row lists unbound modes (D1) and the show/hide choice for Ground depth.
4. Tests: `tests/colour_by_panel_test.js` rewritten for the parts (toggle one at a time, pressed off
   returns Off, the group menu, chip select and isolate, empty strip when Off); a Ruby test for
   `group:` validation and its appearance in the legend.

## Acceptance

`make ci` passes. Every Colour-by mode is reachable on Zones / Faces; no mode id from another feature
appears in `features/zones/`.
