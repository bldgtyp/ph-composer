# Zones / Faces: table-first layout: status

DATE: 2026-10-04
STATUS: Implemented on branch
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
| ZT-06 No inspector, contracts | Implemented on branch; reviewed; `make ci` and `make ui-checks` pass |
| ZT-07 Host acceptance | Implemented on branch; host acceptance passed 2026-10-04; [evidence](evidence/zt-07-host-walkthrough.md) |

## Next step

Review and merge `feature/zones-table-first`; then run ZT-07's close list (archive, close the locate bug as Superseded, retire native case R05).

## Blockers

None.

## Verification

- `make ci` passes at each stage commit and at ZT-06.
- `make ui-checks` passes at 1280, 900, 420 and 280 (ZT-06).
- One fresh-context review of the ZT-01 to ZT-06 diff; findings and dispositions in the ZT-06 Outcome.
- Host acceptance (ZT-07) passed on 2026-10-04 on the final installed build; three host-found defects fixed and rechecked.

## Ledger

| Date | Event |
| --- | --- |
| 2026-10-04 | Ed asked for the table-first layout during Zones / Faces polish; mockup made. |
| 2026-10-04 | Ed accepted the mockup: colour-by icons only on hover, the floating bar, Ground depth as a shown column, every Colour-by mode kept on Zones / Faces (Window Type through the Assembly header). |
| 2026-10-04 | Ed split Select from Locate: a checkbox set for bulk assignment, one-way sync from SketchUp's selection, Locate frames without selecting, row icons only on hover. Folded into this packet. |
| 2026-10-04 | Ed accepted the proposed answers to Q1 to Q9 and authorized implementation; staged plan ZT-01 to ZT-07 written. |
| 2026-10-04 | ZT-01 to ZT-06 implemented on `feature/zones-table-first`; review findings fixed; host gate ZT-07 outstanding. |
| 2026-10-04 | ZT-07 host walkthrough passed after three host-found fixes; three pre-existing defects recorded as follow-ups. |
