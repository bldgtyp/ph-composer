# Phase 1 decisions and evidence still needed

DATE: 2026-09-20
STATUS: METr deferral accepted by Ed on 2026-09-20; other recommendations remain for review.
ISSUE: none (local planning draft)

## Product decisions

| ID | Decision | Recommendation | Gates |
| --- | --- | --- | --- |
| P1-Q1 | METr before further feature development? | Ed deferred METr export and consumer acceptance on 2026-09-20. Phase 1 ends with HBJSON/report. Revisit floor-area requirements against the features available when METr resumes; no workaround now | Resolved: deferred, return milestone unscheduled |
| P1-Q2 | Which wheels does canonical translation need? | Select and verify the HBJSON-only wheel set, using B1 as evidence. Review honeybee-ph for that path; do not inherit a minimum solely because PHX requires it. Keep Pyodide 0.24.1. PHX and its nine-wheel acceptance are deferred | P1-C/E translation/runtime integration |
| P1-Q3 | Confirm the development-only construction proof? | Retain the roadmap's deterministic fixture, activated only in a development composition and refused in normal packaged/user builds. No persisted placeholder Assembly and no missing-reference fallback | P1-C; repeats Export Q7 for explicit closure |
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
- **P1-D:** confirm the proposed 1,000-affected-face Classify ceiling against host measurements,
  including reciprocal retirement targets. Test the accepted limit and one above it. This is an
  engineering bound to settle before the gesture is accepted, not a new product interview.
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
