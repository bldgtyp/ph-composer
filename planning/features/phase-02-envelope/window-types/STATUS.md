# Window Types and placement: status

DATE: 2026-09-30
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/14

## State

PRD drafted 2026-09-18 as a port of the predecessor's Window Types packet
(`../ph-navigator-sketchup/planning/archive/window-types/`) and its shipped code, with the
designPH dependency removed and the export mapping checked against honeybee-ph and PHX source.
Interviewed the same day: two rounds, 20 decisions, recorded in the PRD and folded into its
behavior sections. Shared understanding reached, pending Ed's confirmation of the record.

## Next step

Ed's answers to the [Phase 2 decisions](../DECISIONS.md), his confirmation of the interview
record, and authorization. [PLAN.md](PLAN.md) allocates the PRD to stages P2-10 to P2-15 and binds
each of the five consequences of the component spike
([B3](../../../archive/phase-00-foundation/evidence/spike-window.md)) to a stage step.

## Blockers

- Any row among D2-2, D2-4, D2-5, D2-6 and D2-10 still open in the [Phase 2 decisions](../DECISIONS.md). Its answer column is current.
- No implementation issue has been created at `bldgtyp/ph-composer`.

Restated 2026-09-30. The blocker carried from the archived
[zones-and-adjacency packet](../../../archive/phase-01-zones-and-adjacency/STATUS.md) said that
windows cut holes in real walls, so Solve's refusal to cut a holed Face needed an answer. B3
measured that a glued cutting unit leaves its host Face at one loop, so a windowed wall is not a
holed Face. Two things remain. A host Face that Solve splits leaves its units glued to the wrong
piece, which D2-5 answers by having Solve report such a Face. And a truly holed or concave Face,
which only an explode or hand drawing produces, is still reported and not cut; that limit stays
with Zones and does not block this packet.

## Verification

None. Nothing is implemented.

## Ledger

| Date | Event |
| --- | --- |
| 2026-09-18 | PRD drafted. |
| 2026-09-18 | Interview complete: 20 decisions. Notable: flat component per type, one face per glazed element, generated in code; no shading of any kind; install depth as an attribute, exported to METr's reveal depth; scaling refused by the definition; opaque doors as g-value 0; Frame segment renamed Frame; the whole type editor ports. |
| 2026-09-18 | Scoping review clarified that placement may precede face classification, but export blocks until the host face is a classified Outdoors face. |
| 2026-10-01 | D2-1 revised by Ed: definitions sit below Zones, and placed things above. See the [Phase 2 decisions](../DECISIONS.md). |
| 2026-09-30 | Phase 2 planning: PRD amended for what Phase 1 merged, PLAN.md added, the carried holed-Face blocker restated against B3. Packet moved under `features/phase-02-envelope/`. Nothing implemented. |
| 2026-09-18 | Architecture review run against `context/EXTENSIBILITY.md` and folded into the PRD, then removed. Q21: a unit id, and a copy gets its own at the feature's next mutation, a recorded exception to spaces Q20. Q22: Make unique is a detached-definition finding with Reset to type; Restore unit is a limited repair. Q23: g-value 0 is outside honeybee-schema's range and is disclosed. Q24: psi-install exports into the frame elements, no aperture install types, so PHX synthesizes no variant window types. Q25: seams restated against assemblies Q23 and spaces Q19 and Q22; no Zone stamp on the unit. Q26: the host Face exports gross, and the cut opening is measured in the spike. Also added: `user_data` on five records, a deterministic construction identifier, three validation rows, the Frame segment rename repaired. |
