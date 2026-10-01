# Assemblies and materials: status

DATE: 2026-10-01
STATUS: In progress
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/14

## State

PRD drafted 2026-09-18 as a port of the predecessor's Assembly Builder packet
(`../ph-navigator-sketchup/planning/archive/assembly-builder/`) and its shipped code, with the
designPH dependency removed and the export mapping checked against honeybee-ph and PHX source.
Interviewed the same day: two rounds, 18 decisions, recorded in the PRD and folded into its
behavior sections. Ed authorized the full Phase 2 implementation on 2026-10-01.
Material and Assembly records (P2-02) and inventories (P2-03) are being implemented on
`codex/phase-02-envelope`; neither stage is attested complete.

## Next step

Integrate the record operations and generated API reference, run focused and full gates, then
verify the panel-closed walkthrough in a fresh native process. Integrate the inventories against
that read contract. Manual checks are reserved for Ed's final batch; preceding attestations remain
open. [Phase 2 status](../STATUS.md) and [groundwork evidence](../evidence/p2-01-groundwork.md)
carry the current branch, checks and resume state. The SD assembly helper stays later.

## Blockers

No record-stage product decision is open. Unavailable extension payloads remain preserved on
unrelated edits; Duplicate needs available copy rules and refuses without them, as the foundation
contract requires. The Phase 2 acceptance row now states that boundary explicitly.

Cleared since the PRD was drafted: the foundation merged through PR #1, and translation sections
declare typed dependencies, so the face-to-construction join has its seam.

## Verification

Records and pure commands are implemented from frozen predecessor `f358ebf`. Six focused Ruby
files pass after review fixes on both supported versions: 42 tests and 402 assertions. The integrated Ruby coverage
run passed 773 tests and 4,133 assertions at 96.6% line coverage. Independent review reproduced
an unbounded thermal workload and inconsistent duplicate-name whitespace; corrections passed
focused checks and the same reviewer's delta review. The combined coverage and full gates wait
for stable inventory assets. See
[record evidence](../evidence/p2-02-assembly-records.md) for the exact boundary and resume steps.

## Ledger

| Date | Event |
| --- | --- |
| 2026-09-18 | PRD drafted. |
| 2026-09-18 | Interview complete: 18 decisions. Notable: METr's words Assembly, Layer and Material; declared-U removed, every assembly has real layers, SD helper later as three ordinary layers; Building-Segment and Layer-Segment always qualified, applied across the other packets; hint values in the palette's words; two U-values in the Builder; assembly colour field. |
| 2026-10-01 | D2-1 revised by Ed: definitions sit below Zones, and placed things above. See the [Phase 2 decisions](../DECISIONS.md). |
| 2026-09-30 | Phase 2 planning: PRD amended for what Phase 1 merged, PLAN.md added, stale blockers cleared. Packet moved under `features/phase-02-envelope/`. Nothing implemented. |
| 2026-09-18 | Architecture review run against `context/EXTENSIBILITY.md` and folded into the PRD, then removed. Q21: membranes ride in a `ph_composer` block on the construction's `user_data`. Q22: mixed and steel stud layers match PH-Navigator's Grasshopper route. Q23: named operations between assemblies and face-assignment, and a declared section dependency for the face-to-construction join. Also added: the membrane rule and validation rows, layer-keyed material identifiers, one spacing per Layer, `user_data` on both records. Open: the steel stud METr read-back in the PHX acceptance step, and whether the contributor registry can express a section dependency. |
