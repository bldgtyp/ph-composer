# Spaces: status

DATE: 2026-09-18
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (no remote)

## State

PRD drafted 2026-09-18 from Ed's brief (Spaces inherit from their Zone, the one ventilation
override, equipment on the Zone, volume as the missing piece), the predecessor's Spaces feature,
honeybee-ph's Space classes, the 2019 dPH+ Rooms extension and the Phius iCFA and net volume
rules. Interviewed the same day: two rounds, 18 decisions, recorded in the PRD and folded into its
behavior sections. Shared understanding reached, pending Ed's confirmation of the record.

## Next step

PLAN.md, after the overlay spike and the foundation transplant. Phases as the interview left
them: records, Create Space and Mark floor, the table and tree, airflows and the balance view;
then preview, modes, labels and totals; then Height from solid; the drag handle last.

## Blockers

- The overlay spike, deferred by Ed on 2026-09-18 until the feature packets are drafted. The
  volume preview needs translucent depth-tested fills; if the host cannot do them, the preview
  falls back to edges and the drag handle waits.
- The foundation transplant. This packet is mostly a carry-over of the predecessor's Spaces
  feature with the designPH dependency replaced.
- No GitHub remote, so no issue yet.

## Verification

None. Nothing is implemented.

## Ledger

| Date | Event |
| --- | --- |
| 2026-09-18 | PRD drafted. |
| 2026-09-18 | Interview complete: 18 decisions. Notable: membership is the parent group with Spaces drawn anywhere; no iCFA enforcement; two-state iCFA factor; all three airflows; an airflow balance view grouped by Zone now and by ventilator later; Move Space to Zone; colour field dropped. |
