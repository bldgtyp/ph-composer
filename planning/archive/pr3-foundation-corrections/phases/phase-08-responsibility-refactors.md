# Phase 08: responsibility refactors and cleanup

DATE: 2026-09-30
STATUS: Complete (lands with PR #6)
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/5
MERGE SET: No

## Scope

Separate responsibilities where the review found concrete mixing, not where a metric is merely
high. Source of candidates: [ARCHITECTURE.md, refactor table](../review/ARCHITECTURE.md#refactor-responsibilities-where-the-measurements-support-it)
and [PIPELINE-UI-REVIEW.md, focused corrections](../review/PIPELINE-UI-REVIEW.md#foundation-assessment-and-focused-corrections).
Metrics are advisory; long cohesive geometry or recovery procedures may stay long.

Take each candidate as its own commit, behavior-preserving, with existing tests as the net.
Skip a candidate when the change does not reduce what a reader must hold in mind; record the skip.

The `zones`-internal candidates (reciprocal-pair validity, `cut_partition`, `keeper_path`,
`Overlap.partition`) and the `restore_plan` parameter moved to Phase 02 under
[R-D9](../DECISIONS.md#r-d9-phase-order-under-cleanest-final-state). This phase keeps the rest.

| Candidate | Change | Priority |
| --- | --- | --- |
| `Export::Workflow.start` | Separate reviewed repairs from destination consent and task start; transaction policy stays in one place. Explicit task stages without a state-machine library | Medium |
| `Registry::Validation#check_export_contributors` | Separate preflight ownership, schema and result-field checks; coordinate with Phase 06 A06 and Phase 07's `user_data` key declaration | Medium |
| Colour-by hatch clipping | Shared pure edge-intersection helper; preserve measured holed/concave/performance evidence | Low; needs case A08 rerun |
| `FaceGeometry.world_normal` (core) | Leave unless a smaller transform helper serves real callers | Low |

Do not delete modules for lacking a production caller: public seams, test resets, synthetic
examples, empty exporter composition and development spikes are intentional.

## Ledger screen

Per candidate. Hatch clipping flags A08 and needs its native pixel/timing check.

## Done when

- Each taken candidate is a separate commit with unchanged test outcomes and no golden change.
- Skipped candidates recorded with a one-line reason in **Result**.
- STATUS row REF set to `Implemented on branch`.

## Result

Taken, each its own behavior-preserving commit with the suite unchanged and no golden change:

- `Export::Workflow.start` (`bd11e2d`): chosen repairs, native destination and replacement consent,
  the Model-unchanged check and the repair runs are named steps; `start` keeps every early return,
  so the stopping policy reads in one place. Cyclomatic 17 to below the advisory threshold.
- `Registry::Validation#check_export_contributors` (`a1f3ca0`): preflight ownership, contract and
  section version, user_data keys (Phase 07) and result-field ownership are separate methods.

Skipped:

- Colour-by hatch clipping: the one shared rule is a dozen lines of edge-crossing arithmetic in a
  measured hot path; sharing it needs a native A08 pixel and GPU-timing rerun to keep that
  evidence, which costs more than the reader saves.
- `FaceGeometry.world_normal`: matrix arithmetic explains its score and no caller wants a smaller
  helper, as the plan expected.

Ledger screen: A12 and A16 flag for `export/workflow.rb` (panel export path) and every case for
`shell/`; A08 is not affected because hatch clipping was not touched.
