# Assemblies and materials: status

DATE: 2026-09-30
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## State

PRD drafted 2026-09-18 as a port of the predecessor's Assembly Builder packet
(`../ph-navigator-sketchup/planning/archive/assembly-builder/`) and its shipped code, with the
designPH dependency removed and the export mapping checked against honeybee-ph and PHX source.
Interviewed the same day: two rounds, 18 decisions, recorded in the PRD and folded into its
behavior sections. Shared understanding reached, pending Ed's confirmation of the record.

## Next step

Ed's answers to the [Phase 2 decisions](../DECISIONS.md), his confirmation of the interview
record, and authorization. Then [P2-01](../phases/p2-01-contracts-and-groundwork.md) and
[P2-02](../phases/p2-02-material-and-assembly-records.md). [PLAN.md](PLAN.md) allocates the PRD
to stages P2-02 to P2-07. The SD assembly helper stays later.

## Blockers

- Any row among D2-1 to D2-4 still open in the [Phase 2 decisions](../DECISIONS.md). Its answer column is current.
- No implementation issue has been created at `bldgtyp/ph-composer`.

Cleared since the PRD was drafted: the foundation merged through PR #1, and translation sections
declare typed dependencies, so the face-to-construction join has its seam.

## Verification

None. Nothing is implemented.

## Ledger

| Date | Event |
| --- | --- |
| 2026-09-18 | PRD drafted. |
| 2026-09-18 | Interview complete: 18 decisions. Notable: METr's words Assembly, Layer and Material; declared-U removed, every assembly has real layers, SD helper later as three ordinary layers; Building-Segment and Layer-Segment always qualified, applied across the other packets; hint values in the palette's words; two U-values in the Builder; assembly colour field. |
| 2026-10-01 | D2-1 revised by Ed: definitions sit below Zones, and placed things above. See the [Phase 2 decisions](../DECISIONS.md). |
| 2026-09-30 | Phase 2 planning: PRD amended for what Phase 1 merged, PLAN.md added, stale blockers cleared. Packet moved under `features/phase-02-envelope/`. Nothing implemented. |
| 2026-09-18 | Architecture review run against `context/EXTENSIBILITY.md` and folded into the PRD, then removed. Q21: membranes ride in a `ph_composer` block on the construction's `user_data`. Q22: mixed and steel stud layers match PH-Navigator's Grasshopper route. Q23: named operations between assemblies and face-assignment, and a declared section dependency for the face-to-construction join. Also added: the membrane rule and validation rows, layer-keyed material identifiers, one spacing per Layer, `user_data` on both records. Open: the steel stud METr read-back in the PHX acceptance step, and whether the contributor registry can express a section dependency. |
