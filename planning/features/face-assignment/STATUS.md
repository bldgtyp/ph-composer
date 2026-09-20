# Face assignment: status

DATE: 2026-09-20
STATUS: In progress; P1-B authoring, P1-C export contribution and P1-D's gestures and Attached zones implemented.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## State

PRD drafted and interviewed 2026-09-18. Two rounds, 22 decisions, recorded in the PRD and folded
into its behavior sections. Shared understanding reached, pending Ed's confirmation of the record.

## Next step

Follow [PLAN.md](PLAN.md), which separates Phase 1 classification/Colour-by from Phase 2
assembly assignment. P1-B implements explicit Face reads, single-Face keep/set/clear intent,
suggestions and the minimal panel controls. P1-C now supplies the detached geometry contributor,
typed Python Face section and emitted Surface reference checks. P1-D's D1 and D2 add the bounded
Classify gesture and its 250-occurrence ceiling, Suggest classification for this Zone, Reverse
face, and the Attached zone record kind with its reference and delete-with-replacement lifecycle.
The Classify tool itself, Locate, the faces table and Colour-by remain, in D5 to D7.

## Blockers

- The Ground suggestion reads "lowest point at or below the Zone's ground depth", which makes
  every ground-floor wall read as Ground. honeybee's own `get_bc_from_position`, which the PRD
  cites as its source, returns Ground only when *every* vertex is at or below that depth.
  Confirmed against honeybee-core on 2026-09-20 and seen on the host: Suggest classification on a
  plain box set five of six Faces to Ground. Needs a PRD correction and a one-line fix.
- The remote exists at `bldgtyp/ph-composer`; an implementation issue has not been created.

## Verification

Documentation consistency checked against the authorized zones-and-adjacency corrections:
pair removal, absent conditions after retirement, payload preservation and export omissions.
The P1-B subset is implemented. Offline tests and the current-host walkthrough verify panel-closed
classification, metadata preservation, native Undo/Redo and fresh-process reopen. P1-C verifies
the face extraction schema, complete world geometry, reciprocal emitted targets and strict
development-construction boundary in the exact reloaded HBJSON. P1-D lifecycle, gesture and
overlay gates remain outstanding.

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
| 2026-09-20 | P1-B authoring core complete: explicit Face reads, geometric suggestions, keep/set/clear assignment, stamps and minimal Overview controls passed current-host acceptance. |
| 2026-09-20 | P1-C export contribution complete on the implementation branch: detached face geometry and typed Python sections produced the exact two-Zone HBJSON with reciprocal Surface targets. |
