# Face assignment: status

DATE: 2026-09-18
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (no remote)

## State

PRD drafted and interviewed 2026-09-18. Two rounds, 22 decisions, recorded in the PRD and folded
into its behavior sections. Shared understanding reached, pending Ed's confirmation of the record.

## Next step

Deferred by Ed 2026-09-18 until the other feature packets are drafted: the overlay spike (Q22), a
probe through the predecessor's bridge measuring overlay fill alpha, depth testing and the cost
of a few thousand filled faces. It gates the filled-face Colour-by modes and the Spaces volume
preview. Line-only overlays such as the sun path need the overlay lifecycle but not this fill
result. Then PLAN.md after the foundation transplant.

The four authorized architecture corrections are incorporated in the PRD: Attached zone reference
lifecycle, assembly requirements by export consumer, field-level edit intent and atomic gesture
operations. PLAN.md binds these requirements and the Colour-by contributor contract to foundation APIs.

## Blockers

- The foundation transplant has not started.
- No GitHub remote, so no issue yet.

## Verification

Documentation consistency checked against the authorized zones-and-adjacency corrections:
pair removal, absent conditions after retirement, payload preservation and export omissions.
Nothing is implemented; runtime and host gates remain outstanding.

Documentation-only architecture review completed 2026-09-18; all four findings addressed in the
planning contracts under Ed's authorization. The standalone review was removed after incorporation.
Local PHX construction resolution was inspected. No runtime or host tests were run; the overlay
spike remains deferred under Ed's existing instruction.

## Ledger

| Date | Event |
| --- | --- |
| 2026-09-18 | PRD drafted. |
| 2026-09-18 | Interview complete: 22 decisions. Notable: domain model confirmed as honeybee-shaped records; five boundary conditions with Attached zone as a Library record; overlay only, no materials; a shared Colour-by component with a registry and a viewport HUD legend; honeybee's colours; native double-click kept. |
| 2026-09-18 | Architecture review recorded four design findings, public-operation and Colour-by handoff requirements, and additional acceptance cases. |
| 2026-09-18 | Authorized corrections applied and related assembly/export contracts aligned. Focused documentation consistency review completed; implementation and native acceptance remain pending. |
| 2026-09-18 | Assemblies architecture review folded in: the PRD now names the four operations other features use (face read, Locate, Classify preset, Reassign), the face-to-construction dependency, and the assembly colour default per assemblies Q6. |
| 2026-09-18 | Spaces architecture review folded in: the Colour-by registry now takes an open entity kind, optional derived geometry and separate readouts; the Classify tool has no mode registry and Mark floor is a sibling tool owned by Spaces. |
| 2026-09-18 | Window-types architecture review folded in: the face read's area is stated as gross, and net opaque area comes from a declared window-types read once that packet lands. |
