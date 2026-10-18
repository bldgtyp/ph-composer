# P3a1-04: Candidate geometry and typed editable fields

DATE: 2026-10-17
STATUS: Implemented on branch `feat/phase-03a1-p3a1-04`.
ISSUE: [#221](https://github.com/bldgtyp/ph-composer/issues/221)

## Entry and ownership

Workstream: W2. Order: V4. Depends on: P3a1-03.
Review findings: A09, Spaces portion of A10. Acceptance: C04 in [ACCEPTANCE](../ACCEPTANCE.md).
Behavior: [PRD](../PRD.md). Proposed boundaries: [CONTRACTS](../CONTRACTS.md) section 2.
Decisions: [DECISIONS](../DECISIONS.md) D3a1-03, 10, 12. Delivery rules: [PLAN](../PLAN.md).

## Source and intended change surface

Existing files changed:

- [features/spaces/scan/occurrences.rb](../../../../src/ph_composer/features/spaces/scan/occurrences.rb): the walk already visits every Face directly inside a Space or Volume; candidates are the Faces it sees with no Floor Segment record, plus loose Faces directly inside the Space
- [features/spaces/reads.rb](../../../../src/ph_composer/features/spaces/reads.rb): `candidate_faces` read beside the scoped reads of 03
- [features/spaces/declarations/spaces.rb](../../../../src/ph_composer/features/spaces/declarations/spaces.rb): `ph_composer.spaces.candidate_faces.list` declared, scoped to one Space or one Volume
- [features/spaces/mark_placement.rb](../../../../src/ph_composer/features/spaces/mark_placement.rb): its eligibility rule becomes one shared function the read and `floors.mark` both call
- [features/spaces/declarations/operations.rb](../../../../src/ph_composer/features/spaces/declarations/operations.rb): `values` and `expected_values` typed per kind from the field definitions in [features/spaces/schema.rb](../../../../src/ph_composer/features/spaces/schema.rb); `MINOR` bump and changelog line under D3a1-10
- [features/zones/zone/occurrences.rb](../../../../src/ph_composer/features/zones/zone/occurrences.rb): unchanged; Zones still stops at the stamped container

## Implementation steps

1. Add `candidate_faces.list`: root-to-occurrence persistent-id path, plane and area summary, whether
   the Face is directly in the Space (a Volume candidate) or in the Volume (a Floor candidate), its
   marking status, and the operation it is eligible for or the `target.*` refusal it would meet
   (locked, shared storage, nested container, stray record). Reading stamps nothing and repairs nothing.
2. Share the eligibility rule with `floors.mark` and `volumes.create` so a candidate the read calls
   eligible is accepted by the action under the same revision.
3. Page and project through 03's policy; full loops are a `fields` opt-in.
4. Type `values` and `expected_values` for Space, Volume and Floor Segment from the existing field
   definitions: units, nullable fields with null meaning clear, derived fields excluded. Bump `MINOR`
   once with its changelog line; no legacy open-object shape is kept (D3a1-10).
5. Update the generated reference and the public recipe draft with the candidate read and the
   host-required limits that remain: drawing geometry and choosing an unfamiliar solid.

## Acceptance checks

- FX1's unmarked Volume Face is listed, `floors.mark` commits it, read-back shows the Floor Segment,
  unmark removes the record and the candidate reappears.
- A loose Space-root Face is listed as a Volume candidate and `volumes.create` accepts it once the
  context precondition of 05 is met; locked, shared, nested and stray paths report the matching refusal.
- Typed edit schemas agree with runtime validation for all three kinds, units and null clearing;
  a cross-kind or malformed edit refuses with no metadata or reference loss.
- Reads leave dictionaries, identities, selection and the edit path unchanged; every candidate page
  is bounded.

## Native/client gate

Native fixture of a stamped Space and Volume: candidate, mark, unmark, read-back, including locked
and shared cases, through the live connection. No unstamped shortcut fixture.

## Cleanup and documentation

CL03 and CL04 preparation: the semantic recipe stops traversing geometry privately once this read
exists; native fixture setup and the Mark floor tool remain.
Record affected context/docs, exact checks and evidence in [STATUS](../STATUS.md) through docs-pass.
Shipping source/tests cite durable context rather than this plan. Preserve unrelated dirty work.

## Done when

C04 passes on the stub and the host, the generated schemas are current, the recipe names the
candidate read and the standard review passes.
Applicable full gates, review level, manifest handling and DCO/hook rules are in [PLAN](../PLAN.md).
A planning document or unexecuted check is not implementation evidence.

## Out of scope

Drawing or moving arbitrary geometry, widening Zone traversal into Space ownership, and identity
repair during reads.
