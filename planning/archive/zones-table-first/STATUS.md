# Zones / Faces: table-first layout: status

DATE: 2026-10-04
STATUS: Complete
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## State

Complete. Merged to main through [PR #73](https://github.com/bldgtyp/ph-composer/pull/73) on 2026-10-04
(merge commit `5ef2d7d`) and archived. Ed accepted the proposed answers to Q1 to Q9 (D1 to D9 in
[PLAN](PLAN.md)) and authorized every stage. The PR review's two findings (checked-set sync on a selection
with no Faces, a clear sent while Locate is pending) were fixed and rechecked on the host before merge.

| Stage | State |
| --- | --- |
| ZT-01 Zone columns | Complete; merged in PR #73 |
| ZT-02 Header actions and column menus | Complete; merged in PR #73 |
| ZT-03 Colour by in headers | Complete; merged in PR #73 |
| ZT-04 Checked set and Locate | Complete; merged in PR #73 |
| ZT-05 Selection bar | Complete; merged in PR #73 |
| ZT-06 No inspector, contracts | Complete; merged in PR #73 |
| ZT-07 Host acceptance | Complete; host acceptance passed 2026-10-04; [evidence](evidence/zt-07-host-walkthrough.md) |

## Next step

None. Follow-ups merged on 2026-10-04: [PR #74](https://github.com/bldgtyp/ph-composer/pull/74) (Assembly
legend rows keyed by id), [PR #75](https://github.com/bldgtyp/ph-composer/pull/75) (legend selections framed by
world bounds through `core/view_framing.rb`) and [PR #76](https://github.com/bldgtyp/ph-composer/pull/76)
(Windows preview checks honour `UI_PREVIEW_PORT`). Still open: the outline has no size cap (not measured on a
large Assembly); a legend chip whose Faces span Zones checks nothing, because the selection read refuses a
selection across edit contexts.

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
| 2026-10-04 | PR review: two findings fixed and rechecked on the host; merged to main through PR #73. Follow-ups #74 to #76 merged. Packet archived; the locate bug closed as Superseded; native case R05 marked superseded in its label (the ledger has no retired state). |
