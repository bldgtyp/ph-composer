# Window Types and placement: status

DATE: 2026-09-18
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (no remote)

## State

PRD drafted 2026-09-18 as a port of the predecessor's Window Types packet
(`../ph-navigator-sketchup/planning/archive/window-types/`) and its shipped code, with the
designPH dependency removed and the export mapping checked against honeybee-ph and PHX source.
Interviewed the same day: two rounds, 20 decisions, recorded in the PRD and folded into its
behavior sections. Shared understanding reached, pending Ed's confirmation of the record.

## Next step

The component host spike ran in P0-B on 2026-09-18 ([B3](../../archive/phase-00-foundation/evidence/spike-window.md)). The flat cutting component
stays. PLAN.md must carry five consequences:
1. panes authored facing out;
2. net area never read from `Face#area`;
3. glue verified geometrically, since splits and explodes leave stale glue;
4. `no_scale_mask` is UI-only;
5. a type edit re-validates placements.
Then PLAN.md.

## Blockers

- Carried from the archived [zones-and-adjacency packet](../../archive/phase-01-zones-and-adjacency/STATUS.md)
  on 2026-09-30: Solve adjacencies reports, rather than cuts, an overlap involving a concave outline
  or a Face with a hole. Windows cut holes in real walls, so this needs an answer before an
  assembly- or window-bearing model relies on adjacency.
- The foundation transplant has not started.
- No GitHub remote, so no issue yet.

## Verification

None. Nothing is implemented.

## Ledger

| Date | Event |
| --- | --- |
| 2026-09-18 | PRD drafted. |
| 2026-09-18 | Interview complete: 20 decisions. Notable: flat component per type, one face per glazed element, generated in code; no shading of any kind; install depth as an attribute, exported to METr's reveal depth; scaling refused by the definition; opaque doors as g-value 0; Frame segment renamed Frame; the whole type editor ports. |
| 2026-09-18 | Scoping review clarified that placement may precede face classification, but export blocks until the host face is a classified Outdoors face. |
| 2026-09-18 | Architecture review run against `context/EXTENSIBILITY.md` and folded into the PRD, then removed. Q21: a unit id, and a copy gets its own at the feature's next mutation, a recorded exception to spaces Q20. Q22: Make unique is a detached-definition finding with Reset to type; Restore unit is a limited repair. Q23: g-value 0 is outside honeybee-schema's range and is disclosed. Q24: psi-install exports into the frame elements, no aperture install types, so PHX synthesizes no variant window types. Q25: seams restated against assemblies Q23 and spaces Q19 and Q22; no Zone stamp on the unit. Q26: the host Face exports gross, and the cut opening is measured in the spike. Also added: `user_data` on five records, a deterministic construction identifier, three validation rows, the Frame segment rename repaired. |
