# UI and UX polish: status

DATE: 2026-10-04
STATUS: Implementing on branch `feature/ui-ux-polish`; not merged, no host acceptance yet.
ISSUE: none (local planning draft)

## Delivery ledger

| Item | State | Evidence / next action |
| --- | --- | --- |
| Initial intake | Complete | UX-001 through UX-022 and nine attachment references in REQUESTS |
| Planning organization | Complete | PLAN, DECISIONS and ACCEPTANCE; local document checks |
| P0 investigations | In progress, per slice | UX-007 reproduced in preview (below); UX-016 audit in [evidence/ASSEMBLY_PARITY.md](evidence/ASSEMBLY_PARITY.md); Colour by "Show only this" is a viewport isolate, no table filter (`colour_by/service.rb#isolate`) |
| P1 shared tables | Implemented on branch | UX-003, 004, 005, 011, 012, 013; D3, D4 taken. `make ci` and `make ui-checks` pass |
| P2 shared feedback/dialogs | Implemented on branch | UX-002, 010, 020 (shared contract); D1, D5, D7 taken. `make ci` passes |
| P3 Library flows/surfaces | Proposed | |
| P4 Zones / Faces workspace | Proposed | |
| P5 Assembly Builder | Audit done, not built | |
| P6 Windows toolbar | Proposed | |
| P7 sorting | Implemented on branch | Not a defect at its scope: Order by sorted Zones only, so with one Zone it changed nothing. D8 now orders Faces within each Zone; `overview_panel_test.js` covers Name, Area and both directions |
| Skill/pattern changes | Updated per slice | P1: editable-table rule, page header, control-row count, enum pill. P2: success tone, reason button, dialog close and focus return |
| Design System sync | Pending merge | Re-sync the artifact from main after merge |
| Host acceptance | Not run | One native SketchUp pass at the end of the branch |

## P0 findings

- UX-007 (2026-10-04, `?fixture=authoring`, 1280 px): Order by Name and Area, and the direction toggle,
  reorder the two Zones as intended. Faces never move: `overview.js` `ordered()` keeps each Zone's Faces
  in projection order. A Model with one Zone (Ed's screenshots S2 to S5) therefore shows no change.

## For Ed's verification pass

- Chip tints: Wall's pale amber sits near the "?" flag's amber. Accept honeybee's hue, or choose another.
- Counts moved from page headers to control rows app-wide (D4).
- No footer help strip (D5): blocked reasons open beside their action instead.

## Next action

Continue the loop: P3, P4, P5, P6, then one native host pass.
