# P3b-06: the thermal-bridge Colour-by mode

DATE: 2026-10-03
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## Entry and scope

Requires P3b-04, P3a-05 (`derived` geometry) and D3b-11 and D3b-12. Owns the one Colour-by addition
thermal bridges need, a stroke weight (H14), and the `by_type` mode. It is P3a-05's third user,
after Spaces and the Window Type operation marks, and adds no second way to draw a coloured line;
tessellation is unchanged.

Behavior owner: the [thermal-bridges PRD](../PRD.md), "Colour-by mode". Contract:
`context/EXTENSIBILITY.md`, "Colour-by modes", as P3a-05 amended it. Get the stronger independent
review: this stage changes a contribution contract.

Paths are relative to `src/ph_composer/`.

## Steps

1. **Confirm the entity contract.** With P3a-05 landed, check that an entry whose `entity` is an
   Edge and whose `derived` holds one world segment draws only the derived segment, keeps the
   occurrence-path visibility check, and still serves Locate and Show only this through its
   `entity`. If P3a-05 tessellates every entity regardless, an Edge yields nothing (F8), which is
   the wanted result; record the check.
2. **Stroke weight (H14).** `colour_mode(..., stroke:)`: an optional weight for that mode's
   `derived` segments, validated at registration, drawn on P3a-05's path. Outline and hatch weights
   are unchanged. Fold the addition into `context/EXTENSIBILITY.md`.
3. **The mode.** `features/thermal_bridges/colour_modes.rb` registers
   `ph_composer.thermal_bridges.by_type`, entity kind `edge`, one entry per assigned Edge
   occurrence carrying the Edge as `entity`, its path, its world segment in `derived`, the type as
   value and its colour, and a label carrying the type's total length (D3b-12). An Edge naming a
   missing type is `state: :incomplete`. Unassigned Edges produce no entry.
4. **Units in the label.** Answer CONTRACTS section 7 question 6 if P3b-01 has not: format the
   length in display units if Ruby can read the preference, otherwise in metres with the panel
   legend in display units, and record which.
5. **Measure.** Draw cost at 5,000 assigned Edges on the proving host, against the overlay spike's
   method.

## Source

| PH-Composer file | Disposition |
| --- | --- |
| `features/zones/faces/colour_modes.rb` (`BY_ASSEMBLY`) | Pattern for colouring by a record's own `color` |
| `features/windows/colour_modes.rb` | Pattern for entries with an occurrence path |
| `colour_by/overlay.rb`, `shell/registry.rb`, `shell/declarations.rb` | Extend for `stroke:` only |

## Tests (write first)

1. An entry with an Edge `entity` and one `derived` segment under a rotated parent draws that
   segment in world coordinates and nothing else; a Face entry is unchanged.
2. `stroke:` outside its range refuses registration; absent keeps the existing weight.
3. The mode registers with no change under `colour_by/` beyond H14, and `colour_by/` names nothing
   of thermal bridges.
4. Legend labels carry total length per type; a missing type is incomplete.
5. A hidden ancestor on the path draws nothing and keeps the legend count.

## Host gate

Fresh process on the reference model: turn the mode on from the native Colour by menu; the four
types draw thick in their colours, depth-tested, inside a nested Zone; hide a tag and an ancestor;
Show only this and Locate from the legend; the HUD reads type and length; capture by window id
(`context/SKETCHUP_HOST_BEHAVIOR.md`, "Overlays"). Repeat the Colour-by cases the ledger screens,
S05 among them.

## Out of scope

Derived geometry and readouts (P3a-05). Highlights inside the edge tool (P3b-07).

## Done when

- T06 has evidence in `../evidence/p3b-06-colour-by.md`, with the stronger review recorded.
- `context/EXTENSIBILITY.md` describes the edge entry and `stroke:`; `make ci` passes.
