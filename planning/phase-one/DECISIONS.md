# Phase 1 decisions and evidence still needed

DATE: 2026-09-20
STATUS: METr deferral and P1-C fixture composition resolved; the P1-D gesture bound is settled pending host measurement; P1-E runtime-wheel selection remains open.
ISSUE: none (local planning draft)

## Product decisions

| ID | Decision | Recommendation | Gates |
| --- | --- | --- | --- |
| P1-Q1 | METr before further feature development? | Ed deferred METr export and consumer acceptance on 2026-09-20. Phase 1 ends with HBJSON/report. Revisit floor-area requirements against the features available when METr resumes; no workaround now | Resolved: deferred, return milestone unscheduled |
| P1-Q2 | Which wheels does canonical translation need? | P1-C proved the native development path with exact direct pins recorded in its evidence. P1-E still selects and vendors the minimal Pyodide wheel set, reviews honeybee-ph for that path and retains Pyodide 0.24.1. PHX-specific acceptance remains deferred | Partially resolved by P1-C; shipped runtime selection remains P1-E |
| P1-Q3 | Confirm the development-only construction proof? | Resolved in P1-C: the deterministic provider lives under tools only, is absent from the RBZ, and the normal composition refuses to build Rooms without an authored provider. No persisted placeholder Assembly and no missing-reference fallback | Resolved 2026-09-20; retain through P1-E |
| P1-Q4 | Remaining Export interview, Q2/Q4 | No canonical files on blocking validation, no implicit SKP save, HBJSON/report always selected. Exporter defaults under Q5 wait with METr | P1-E workflow |

Export Q1 is already D2: keep the canonical pair on optional-exporter failure. Q3's checked
stale-adjacency preflight is already accepted by the Zones interview. Do not reopen either.
The face interview status still requests confirmation of its recorded answers; confirm that
record together with these choices rather than repeat its 22-question interview.

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
  accepted UI baseline and local polish skill. Phase 0's muted Planned tabs are an open carryover;
  any change to their accepted presence needs a recorded UI decision.
- **P1-E:** retain the separate runtime page as the proposed default. Verify actual runtime
  requests and cancellation rather than infer them from the spike's standalone browser page.
- **Deferred METr milestone:** confirm the file extension and floor-area requirements in its
  actual import UI when work resumes. B1 produced JSON but did not open it there.

## Carryovers outside this milestone

The Phase 0 archive also records the unknown-outcome warning wording, Pyodide license notice
ambiguity, missing extension LICENSE in the RBZ, and a possible upstream PHX#157 comment.
Keep truthful failure outcomes; settle notices before public distribution. Posting an upstream
comment is optional and is not authorized by this planning request. The user-facing external
agent adapter, SketchUp 2023/Windows support proof and public naming remain separately gated.

The METr deferral is recorded in `planning/DECISIONS.md` and the roadmap. Once Ed chooses the
remaining recommendations, update the owning PRD and this table.
