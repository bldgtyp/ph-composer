# Phase 1 decisions and evidence still needed

DATE: 2026-09-30
STATUS: Complete. Merged to main through [PR #3](https://github.com/bldgtyp/ph-composer/pull/3) (`abd86f4`) on 2026-09-30, with the follow-on [PR #6](https://github.com/bldgtyp/ph-composer/pull/6) (`9d92a26`); issue #2 closed. A01 to A14, A16 and R01 to R06 pass; A15 (METr) is deferred to its own packet.
Archived 2026-09-30. SketchUp 2023 floor, Windows, release and public distribution remain separate gates.
ISSUE: https://github.com/bldgtyp/ph-composer/issues/2

## Product decisions

| ID | Decision | Recommendation | Gates |
| --- | --- | --- | --- |
| P1-Q1 | METr before further feature development? | Ed deferred METr export and consumer acceptance on 2026-09-20. Phase 1 ends with HBJSON/report. Revisit floor-area requirements against the features available when METr resumes; no workaround now | Resolved: deferred, return milestone unscheduled |
| P1-Q2 | Which wheels does canonical translation need? | P1-E vendors eight exact HBJSON wheels, retains Pyodide 0.24.1 and verifies native/Pyodide parity and installed footprint. PHX-specific acceptance remains deferred | Resolved 2026-09-30; [runtime evidence](evidence/p1-e-export-workflow.md) |
| P1-Q3 | Confirm the development-only construction proof? | Resolved in P1-C: the deterministic provider lives under tools only, is absent from the RBZ, and the normal composition refuses to build Rooms without an authored provider. No persisted placeholder Assembly and no missing-reference fallback | Resolved 2026-09-20; retained and verified in P1-E |
| P1-Q4 | Remaining Export interview, Q2/Q4 | No canonical files on blocking validation, no implicit SKP save, HBJSON/report always selected. Exporter defaults under Q5 wait with METr | Confirmed by Ed 2026-09-29; implemented and verified 2026-09-30 |
| P1-Q5 | Which split piece retains the old Face UUID? | Ed chose explicit repair: use a provable stored original path, otherwise ask the user to choose the retaining piece; allocate new UUIDs to the other pieces | Resolved 2026-09-29; public action and native-menu recovery verified; clean one-to-many Solve is verified; extension-reference boundary verified under A06 |

Export Q1 is already D2: keep the canonical pair on optional-exporter failure. Q3's checked
stale-adjacency preflight is already accepted by the Zones interview. Do not reopen either.
The face interview's request for confirmation of its recorded answers was not settled in Phase 1.
It stays open in [the face-assignment status](../face-assignment/STATUS.md); confirm that
record rather than repeat its 22-question interview.

## Engineering decisions to settle in the owning stage

- **P1-A:** entity-store schemas, geometry operation participation and rollback verification,
  copy/split identity, tolerance measurements and bounded export geometry reads. The plan sets
  requirements but does not pretend these APIs exist. Resolve through design and evidence;
  involve Ed only if the result changes accepted behavior.
- **P1-D, settled 2026-09-20:** the Classify ceiling is 250 affected Face occurrences, reciprocal
  retirement targets included, deduplicated before counting. The proposed 1,000 was measured and
  rejected: a gesture affecting 1,000 Faces took about 13 seconds against the offline stub, because
  `Occurrences.resolve_face` walks the Model once per Face. Ed accepted lowering it on 2026-09-20.
  250 stays far above a realistic drag and bounds the worst case to roughly a quarter of that.
  A ceiling bounds the blast radius; it cannot bound elapsed time, because the cost scales with the
  Model as well as the gesture. The resolution cost is D6's to fix and is on that slice's
  dependency list. Implemented as a feature bound, not a schema bound, so one Face over it refuses
  the whole gesture with `gesture.too_large`; the offline suite covers exactly 250, 251, and
  refusal driven by reciprocal targets. Re-measure a real drag on the proving host in D6 and
  revise the constant if that measurement disagrees.
- **P1-D, settled in D1:** the ceiling applies to the Classify gesture only. Suggest classification
  for this Zone carries no ceiling, because it is a separate named batch over one Zone the user has
  already chosen rather than a pointer gesture whose target set the user cannot see. A Zone with
  more Faces than the gesture ceiling can still be suggested in one step.
- **P1-D:** first Zone/face screen layout, table components and feature navigation. Apply the
  accepted UI baseline and local polish skill. Phase 0's muted Planned tabs stay as they are: Ed
  confirmed on 2026-09-30 that they are fine for now. Any later change needs a recorded UI decision.
- **P1-E:** retain the separate runtime page as the proposed default. Verify actual runtime
  requests and cancellation rather than infer them from the spike's standalone browser page.
- **Deferred METr milestone:** confirm the file extension and floor-area requirements in its
  actual import UI when work resumes. B1 produced JSON but did not open it there.

- **P1-D, settled 2026-09-20 on the host:** a plain copy of a Zone Group is shared storage, not
  just a duplicated id, so identity repair refuses it and the user runs SketchUp's Make Unique
  first. Ed confirmed leaving it as two explicit steps rather than having repair make the Group
  unique itself, because that is a native edit affecting every other instance and hiding it inside
  a repair would change more of the Model than the repair names. Recorded as Q25 in the Zones PRD.

## Carryovers outside this milestone

The Phase 0 archive records the unknown-outcome warning wording, Pyodide license notice
ambiguity, missing extension LICENSE in the RBZ, and a possible upstream PHX#157 comment. P1-E
ships the extension LICENSE and exact upstream texts, while preserving source discrepancies for
the separate public-distribution review.
Keep truthful failure outcomes; settle notices before public distribution. Posting an upstream
comment is optional and is not authorized by this planning request. The user-facing external
agent adapter, SketchUp 2023/Windows support proof and public naming remain separately gated.

The METr deferral is recorded in `planning/DECISIONS.md` and the roadmap. The owning PRD and
this table now record the accepted Phase 1 choices and their implementation evidence.

## P1-Q5: native split identity frontier

The native reference run establishes that SketchUp copies one Face UUID onto both split pieces.
Surface records retain a prior endpoint path; ordinary non-Surface Face records do not persist
an original entity path. The current schema therefore cannot always prove which piece retains
the original authored identity. The Zones PRD prohibits resolving identity ambiguity by geometry.

Ed accepted the policy on 2026-09-29. It keeps one old identity only through a unique stored original path or explicit user
choice. Other pieces receive new UUIDs. Repair is explicit and previewed, with invalid Surface
links retired reciprocally inside the declared mutation scope, supported classification and
payloads retained, and unsafe extension data refused before writes. It does not silently create
new adjacencies; a subsequent explicit Solve remains subject to the one-to-many solver boundary.
Face/Zone extension-reference registration and incoming-reference handling now use the shared
read-only target and typed proposal contract in `context/EXTENSIBILITY.md`. Their [native
continuation](evidence/p1-d-entity-reference-targets.md) passes; independent review and its resolver corrections also pass.
Outside incoming references retain their original/keeper target. Identity removal with incoming
or unknowable references aborts rather than selecting a replacement by geometry.

The rejected alternative gave every resulting piece a new identity, so existing references to
the old identity would require explicit resolution. The accepted policy authorizes the recovery
implementation within P1-D; its public contract and native gate now pass in the
[split recovery evidence](evidence/p1-d-split-identity-recovery.md). Reference targets and clean one-to-many pairing have separate accepted continuation evidence;
this split recovery gate alone does not establish those boundaries.
