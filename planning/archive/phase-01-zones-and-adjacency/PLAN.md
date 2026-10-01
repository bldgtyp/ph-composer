# Zones and adjacency: implementation plan

DATE: 2026-09-25
STATUS: P1-A through P1-C complete on the implementation branch; P1-D is authorized and every slice
is implemented, with D7's host gate outstanding.
ISSUE: none (local implementation packet)

The [PRD](PRD.md) owns behavior. The [Phase 1 plan](../phase-01-faces-and-zones/PLAN.md) owns shared sequencing
and [acceptance](../phase-01-faces-and-zones/ACCEPTANCE.md). Phase 0 is merged; its record operations are
available, but entity-owned records and compound geometry operations still need design.

## Delivery allocation

| Stage | This feature delivers | Gate |
| --- | --- | --- |
| P1-A | Entity-owned Zone store, occurrence/endpoint schema and geometry proposal design; host investigation | Complete 2026-09-20: [contract](../phase-01-faces-and-zones/CONTRACTS.md), [evidence](../phase-01-faces-and-zones/evidence/p1-a-geometry.md) |
| P1-B | Complete 2026-09-20: feature install, Zone records, Make Zone, details, hierarchy/identity findings and focused public reads | [Script/UI and host evidence](../phase-01-faces-and-zones/evidence/p1-b-authoring.md) |
| P1-C | Complete 2026-09-20: full-wall solve/retire, stamps and stale findings; Zone extraction and Python Room section | [Reciprocal references, no-op solve and round-trip evidence](../phase-01-faces-and-zones/evidence/p1-c-adjacency-hbjson.md) |
| P1-D | Partial splitting, scope refusal, limited Restore, lifecycle reconciliation and Zone Colour-by registrations | Complete applicable PRD cases, native Undo/Redo, copy/path ambiguity and metadata preservation. The `retire_pairs` participant landed in D1, identity repair and limited Restore in D3, and the overlap geometry, whole-scope solve and scope refusal in D4. The partial-overlap cut landed in D4, and the Zone, Building-Segment and Level Colour-by modes in D5 |
| P1-E/F | Explicit all-Zone export preflight and integrated HBJSON proof | Room/Face references and Building-Segment metadata; METr mapping deferred |

## Contract work to bind before implementation

Use `PhComposer::API` and feature registration for queries/actions/snapshots. Implement under
`src/ph_composer/features/` with one composition-root entry. Proposed operation names and shapes
must be recorded with examples in P1-A; do not publish names before settling the schemas.

- **Reads:** list/read Zone occurrences, hierarchy/closure findings, endpoint state and solve
  preview. Return explicit references, SI geometry/stamps and findings. No write, repair or UI.
- **Writes:** Make Zone, edit Zone details, solve, retire pairs, explicit identity repair and
  limited Restore. P1-D identity repair targets a copied occurrence, assigns a fresh UUID, updates
  member stamps and retires copied pairs without rewriting the original pairs. Refuse ambiguity
  or shared storage; preserve metadata and report unresolved extension references. Resolve the
  selected/all scope once; callers submit explicit mutation references. The operation proposal
  validates every counterpart and commits topology and records through one dispatcher transaction.
- **Composition:** classification combines a Zone-owned retirement proposal with face-owned
  field changes. A proposal participant supplies this behavior; it must not open a nested Undo
  operation. Record the schema ownership split so installing Zones never imports face UI code.
- **Persistence:** entity dictionaries retain Zone/face ownership. Identity resolution returns
  found, missing or ambiguous explicitly. Changes to hierarchy or persistent ids cannot make
  an old adjacency current merely because its geometry resembles a new face.
- **Export:** a feature contributor supplies the Zone data and findings from the coherent
  snapshot. Its Python section owns Room construction and mapping; section ordering must allow
  final reciprocal Surface resolution after the emitted-face set is known.

A representative contributor adds one query or action inside this feature, declares it in its
`install`, and calls it through the public API. The walkthrough reads two occurrences, previews
and applies a solve, then reads both endpoints with the panel closed. Shell, session and the
export coordinator need no Zone-specific branch.

## Verification and limits

Use the PRD's fixtures and lifecycle cases, plus Phase 1 A01/A02/A03/A05/A06/A10/A16.
The whole-wall proof is an intermediate gate; it does not defer the accepted partial-overlap or
Restore contract out of Phase 1. Space stamps are accommodated by contract, but testing real
Spaces waits for that feature. EnergyPlus closure enforcement remains a later exporter gate.
