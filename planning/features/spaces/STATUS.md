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

- None from the overlay spike: it passed on 2026-09-18 ([B2](../../archive/phase-zero/evidence/spike-overlay.md)), and translucent
  depth-tested fills work on the proving host, so the volume preview needs no edge fallback.
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
| 2026-09-18 | Architecture review run against `context/EXTENSIBILITY.md` and folded into the PRD, then removed. Q19: Mark floor is a sibling tool owned by Spaces. Q20: a copy is the blocking `duplicate_identity` finding with a Make independent repair. Q21: any airflow set makes unset read as zero; all unset inherits the Zone's load; the exporter writes explicit zeros so PHX is unchanged. Q22: Colour-by gains an open entity kind, derived geometry and readouts. Q23: sloped floors export projected. Q24: Move Space to Zone's record transition. Also added: the port disposition, identifiers and `user_data` on the records, the m3/h to m3/s conversion, the Room section dependency, the balance view's grouping provider. Open: the translation-section dependency question in the foundation packet. |
