# Face assignment: status

DATE: 2026-09-20
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## State

PRD drafted and interviewed 2026-09-18. Two rounds, 22 decisions, recorded in the PRD and folded
into its behavior sections. Shared understanding reached, pending Ed's confirmation of the record.

## Next step

Follow [PLAN.md](PLAN.md), which separates Phase 1 classification/Colour-by from Phase 2
assembly assignment. Phase 0 B2 passed; use its filled-overlay evidence and implement the
feature cache invalidation and scale checks. Bind field intent and reciprocal retirement to
P1-A's operation contract before writing the Classify tool.

## Blockers

- P1-B and later feature implementation are not authorized; confirm the recorded interview answers
  before the first face-assignment implementation stage.
- Zone occurrence/geometry operation contracts must land before dependent classification.
- The remote exists at `bldgtyp/ph-composer`; an implementation issue has not been created.

## Verification

Documentation consistency checked against the authorized zones-and-adjacency corrections:
pair removal, absent conditions after retirement, payload preservation and export omissions.
This feature is not implemented; runtime and host gates remain outstanding.

Documentation-only architecture review completed 2026-09-18; all four findings addressed in the
planning contracts under Ed's authorization. The standalone review was removed after incorporation.
Local PHX construction resolution was inspected. No feature runtime or host tests were run in
that review. The later Phase 0 B2 overlay
spike passed; it does not satisfy this feature's native lifecycle gate.

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
| 2026-09-20 | Post-Phase-0 refresh: added PLAN.md, removed completed foundation blockers and linked the shared Phase 1 stages and decisions. Planning only; feature implementation remains pending. |
