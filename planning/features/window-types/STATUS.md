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

A host spike on the flat component: glue and cut inside a Zone group, clicking and selecting a
flat glued instance, a definition rewrite as one Undo step, `no_scale_mask`, and how a mirrored
instance reads from its transformation. Then PLAN.md after the
foundation transplant.

## Blockers

- The component host spike. Ed's fallback if a flat component is hard to manage is more geometry.
- The overlay spike, deferred by Ed on 2026-09-18, for the Window Type Colour-by mode and the
  placement preview's fill. Placement itself can preview with edges.
- The foundation transplant has not started.
- No GitHub remote, so no issue yet.

## Verification

None. Nothing is implemented.

## Ledger

| Date | Event |
| --- | --- |
| 2026-09-18 | PRD drafted. |
| 2026-09-18 | Interview complete: 20 decisions. Notable: flat component per type, one face per glazed element, generated in code; no shading of any kind; install depth as an attribute, exported to METr's reveal depth; scaling refused by the definition; opaque doors as g-value 0; Frame segment renamed Frame; the whole type editor ports. |
