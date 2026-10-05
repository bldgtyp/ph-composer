# Zones / Faces: table-first layout: status

DATE: 2026-10-04
STATUS: In progress
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## State

In progress on `feature/zones-table-first`. Ed accepted the proposed answers to Q1 to Q9 on
2026-10-04 (recorded as D1 to D9 in [PLAN](PLAN.md)) and authorized every stage.

| Stage | State |
| --- | --- |
| ZT-01 Zone columns | Implemented on branch; `make ci` passes |
| ZT-02 Header actions and column menus | Implemented on branch; `make ci` passes |
| ZT-03 Colour by in headers | Implemented on branch; `make ci` passes |
| ZT-04 Checked set and Locate | Implemented on branch; `make ci` passes |
| ZT-05 Selection bar | Implemented on branch; `make ci` passes |
| ZT-06 No inspector, contracts | Scoped |
| ZT-07 Host acceptance | Scoped |

## Next step

ZT-06, [phases/phase-06-no-inspector-and-contracts.md](phases/phase-06-no-inspector-and-contracts.md).

## Blockers

None.

## Verification

None.

## Ledger

| Date | Event |
| --- | --- |
| 2026-10-04 | Ed asked for the table-first layout during Zones / Faces polish; mockup made. |
| 2026-10-04 | Ed accepted the mockup: colour-by icons only on hover, the floating bar, Ground depth as a shown column, every Colour-by mode kept on Zones / Faces (Window Type through the Assembly header). |
| 2026-10-04 | Ed split Select from Locate: a checkbox set for bulk assignment, one-way sync from SketchUp's selection, Locate frames without selecting, row icons only on hover. Folded into this packet. |
| 2026-10-04 | Ed accepted the proposed answers to Q1 to Q9 and authorized implementation; staged plan ZT-01 to ZT-07 written. |
