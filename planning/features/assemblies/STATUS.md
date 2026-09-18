# Assemblies and materials: status

DATE: 2026-09-18
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (no remote)

## State

PRD drafted 2026-09-18 as a port of the predecessor's Assembly Builder packet
(`../ph-navigator-sketchup/planning/archive/assembly-builder/`) and its shipped code, with the
designPH dependency removed and the export mapping checked against honeybee-ph and PHX source.
Interviewed the same day: two rounds, 18 decisions, recorded in the PRD and folded into its
behavior sections. Shared understanding reached, pending Ed's confirmation of the record.

## Next step

PLAN.md after the foundation transplant. Phases as the interview left them: records, Builder,
inventories, usage and export first; the SD assembly helper later.

## Blockers

- The face-to-construction join needs a declared dependency between translation sections. The
  foundation transplant settles whether its contributor registry can express one.
- The foundation transplant has not started. Most of this packet is transplant work.
- No GitHub remote, so no issue yet.

## Verification

None. Nothing is implemented.

## Ledger

| Date | Event |
| --- | --- |
| 2026-09-18 | PRD drafted. |
| 2026-09-18 | Interview complete: 18 decisions. Notable: METr's words Assembly, Layer and Material; declared-U removed, every assembly has real layers, SD helper later as three ordinary layers; Building-Segment and Layer-Segment always qualified, applied across the other packets; hint values in the palette's words; two U-values in the Builder; assembly colour field. |
| 2026-09-18 | Architecture review run against `context/EXTENSIBILITY.md` and folded into the PRD, then removed. Q21: membranes ride in a `ph_composer` block on the construction's `user_data`. Q22: mixed and steel stud layers match PH-Navigator's Grasshopper route. Q23: named operations between assemblies and face-assignment, and a declared section dependency for the face-to-construction join. Also added: the membrane rule and validation rows, layer-keyed material identifiers, one spacing per Layer, `user_data` on both records. Open: the steel stud METr read-back in the PHX acceptance step, and whether the contributor registry can express a section dependency. |
