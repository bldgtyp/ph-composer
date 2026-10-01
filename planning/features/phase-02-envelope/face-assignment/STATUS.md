# Face assignment: status

DATE: 2026-10-01
STATUS: Implemented on branch; named acceptance consolidated; Phase 2 integration/handoff remains open.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/14

## State

PRD drafted and interviewed 2026-09-18. Two rounds, 22 decisions, recorded in the PRD and folded
into its behavior sections. Shared understanding reached, pending Ed's confirmation of the record.

## Next step

Phase 1's allocation is complete and its evidence is in the archived
[Phase 1 packet](../../../archive/phase-01-faces-and-zones/README.md). What remains is assembly
assignment, planned in the [Phase 2 packet](../README.md): stage
[P2-05](../phases/p2-05-assign-assemblies-to-faces.md) for the write, usage, routes and Colour-by
mode, and [P2-06](../phases/p2-06-construction-export.md) for the export rows. [PLAN.md](PLAN.md)
carries the allocation and the PRD carries the Phase 2 amendments. P2-05 and P2-06 are
implemented. E06 passes; E05 retains only affected held-Classify integration. Follow [Phase 2 status](../STATUS.md).

## Blockers

The relevant Phase 2 decisions are answered and implementation issue #14 exists. Complete
E05/E06 and affected Phase 1 host attestations remain; the held Classify context case is in
the [final manual batch](../MANUAL_BATCH.md).

## Verification

Documentation consistency checked against the authorized zones-and-adjacency corrections:
pair removal, absent conditions after retirement, payload preservation and export omissions.
The P1-B subset is implemented. Offline tests and the current-host walkthrough verify panel-closed
classification, metadata preservation, native Undo/Redo and fresh-process reopen. P1-C verifies
the face extraction schema, complete world geometry, reciprocal emitted targets and strict
development-construction boundary in the exact reloaded HBJSON. D5 verifies the Colour-by seam offline: an outside
feature's mode, the two shipped modes, the unclassified and incomplete states, per-colour
batching, the HUD, tag and revision invalidation, and the overlay's lifecycle. D6's native tool
checks and D7's eight Overview questions have current-host evidence. The [atomic Attached-zone continuation](../../../archive/phase-01-faces-and-zones/evidence/p1-d-attached-zone-atomic.md)
now verifies the public create-and-assign action and inline dialog, including exact native rollback,
Undo/Redo and fresh reopen. A07’s named current-host cases pass. The [isolated GPU continuation](../../../archive/phase-01-faces-and-zones/evidence/p1-d-gpu-timing.md)
completes A08’s named current-host cases in the [acceptance register](../../../archive/phase-01-faces-and-zones/ACCEPTANCE.md).

Documentation-only architecture review completed 2026-09-18; all four findings addressed in the
planning contracts under Ed's authorization. The standalone review was removed after incorporation.
Local PHX construction resolution was inspected. No feature runtime or host tests were run in
that review. The later Phase 0 B2 overlay
spike passed; it does not satisfy this feature's native lifecycle gate.

## Deferred conveniences

- **One-click Make Unique for a Face in a shared Group.** The
  [PR #3 corrections](../../../archive/phase-01-faces-and-zones-refactor/DECISIONS.md#r-d10-a-face-inside-a-shared-group-m1)
  (R-D10) make Classify and Reverse refuse a Face inside a Group that shares its definition, with
  a notice telling the user to Make Unique by hand. A later convenience could offer the Make Unique
  from the notice and retry in one Undo step. It needs its own native Undo and host acceptance.
  Not scheduled.

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
| 2026-09-30 | PR #3 foundation corrections decided: Face code moves under the `zones` feature (`ph_composer.zones.faces.*`); shared-Group Faces refuse with a Make Unique instruction (R-D10); Attached-zone delete refuses when an orphaned Face still uses it (R-D11). See [the corrections packet](../../../archive/phase-01-faces-and-zones-refactor/README.md). |
| 2026-10-01 | D2-1 revised by Ed: definitions sit below Zones, and placed things above. See the [Phase 2 decisions](../DECISIONS.md). |
| 2026-09-30 | Phase 2 planning: assembly assignment allocated to P2-05 and P2-06; PRD amended; packet moved under `features/phase-02-envelope/`. |
| 2026-09-30 | PR #3 merge-set corrections implemented on the branch: code owner `src/ph_composer/features/zones/`, M1 to M4 fixed, native cases R01 to R04 pass ([evidence](../../../archive/phase-01-faces-and-zones/evidence/pr3-corrections-native.md)). |

## Current Phase 2 checkpoint

Implementation is delivered. E06 passes; E05 retains the affected A09 held-Classify gate. Historical notes above preserve their original frontiers. Continue only held-Classify and the final handoff in [P2-17](../evidence/p2-17-acceptance.md#register-consolidation-at-f4f6576). No packet is archived or released.
