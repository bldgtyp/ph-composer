# P3b-05: the Thermal Bridges tab

DATE: 2026-10-03
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## Entry and scope

Requires P3b-04 and D3b-17, with PRD Q10. Owns the panel: the Thermal Bridges tab with its Types
and Schedule subtabs, the assign bar, and the right-click menu on a selection of Edges. Every
control calls an operation P3b-02 to P3b-04 registered; the panel computes nothing. After this
stage authoring is complete on screen: milestone T-M2, the first point worth a hands-on pass by
Ed.

Behavior owner: the [thermal-bridges PRD](../PRD.md), "Types tab", "Assign" and
"Schedule". Load `.agents/skills/ph-composer-ui-polish/SKILL.md` first and read the Thermal
Bridges row of the [UI baseline](../../../ui-baseline/README.md).

Paths are relative to `src/ph_composer/`.

## Steps

1. **The pane.** Enable the reserved tab in `html/index.html`: a `data-tab` and a
   `data-pane="thermal_bridges"`. This is the composition-root edit the rules permit. Coordinate
   with P3a-06, which edits the same file to rename Zones / Faces to Zones and remove the reserved
   Spaces tab (Spaces became a view of the Zones tab on 2026-10-15); whichever lands second
   rebases.
2. **Types subtab.** `html/features/thermal_bridges/types.js` on `html/inventory.js`: name,
   psi-value (`LINEAR_PSI` field, signed), group (a chip showing METr's word, storing honeybee-ph's
   string), colour swatch through `inventory_forms.js`, used length (`LENGTH_M`), notes and a
   datasheet link. Add, duplicate, delete with the `ReplacementForm`, in-place and range edits
   through `record_edits` and `inventory_grid`. Group words: confirm METr's third word on its
   screen and record it (D3b-03).
3. **Assign bar.** In the Types subtab: the current selection's count from `edges.selected`, how
   many are assignable and why the rest are not, a type picker, a quantity field, Assign and Clear.
   Assign with nothing assignable is disabled with its reason.
4. **Schedule subtab.** `schedule.js`: one row per run with Zone, Building-Segment, type, length,
   psi, quantity and W/K; findings on their rows with their repair; totals by type and by group;
   a row click calls `runs.locate`. Grouping and filtering through `ui.ViewControls` never change
   the Model.
5. **Right-click menu.** `assign_menu` through `feature.menu_entries`: "Thermal bridge" with one
   item per type and Clear, available only when the selection holds an assignable Edge. Each item
   invokes `edges.assign` through the selection client with the read revision.
6. **Preview and manifests.** A preview fixture in `tools/ui-preview/host.js` and a check under
   `tools/ui-preview/`; regenerate the panel manifest and the vendor manifest.

## Source

| PH-Composer file | Disposition |
| --- | --- |
| `html/features/windows/section.js`, `inventory.js` | Pattern for a pane with subtabs and an inventory |
| `html/features/zones/assembly_assignment.js`, `classify.js` | Pattern for acting on the native selection from the panel |
| `features/zones/faces/classify_menu.rb` | Pattern for the right-click submenu |

## Tests (write first)

1. The Types table sends `types.update` with `values` and `expected_values` and keeps a refused
   draft.
2. The group chip shows METr's word and sends honeybee-ph's string.
3. The assign bar disables Assign with a reason when nothing selected is assignable.
4. A schedule row click sends `runs.locate` with that run's params.
5. The panel layout test: nothing outside `html/features/` names thermal bridges.
6. Menu availability is false with only Faces selected and true with one assignable Edge.

## Host gate

Fresh process, Ed at the mouse for the gesture checks: create, edit, duplicate and delete with
replacement in Types; select the roof perimeter natively and assign from the bar and from the
right-click menu; switch display units with a draft open; Locate from the Schedule into a nested
Zone; the UI polish review with native window captures.

## Out of scope

The Colour-by mode (P3b-06). The tool (P3b-07). Export rows in the Export tab (P3b-08).

## Done when

- T05 has evidence in `../evidence/p3b-05-thermal-bridges-tab.md`, with the UI polish review.
- `make ci` and `make ui-checks` pass.
