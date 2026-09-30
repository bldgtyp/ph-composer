# Phase 08: responsibility refactors and cleanup

DATE: 2026-09-30
STATUS: Blocked
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)
MERGE SET: No
BLOCKED ON: Phase 02 (module layout)

## Scope

Separate responsibilities where the review found concrete mixing, not where a metric is merely
high. Source of candidates: [ARCHITECTURE.md, refactor table](../review/ARCHITECTURE.md#refactor-responsibilities-where-the-measurements-support-it)
and [PIPELINE-UI-REVIEW.md, focused corrections](../review/PIPELINE-UI-REVIEW.md#foundation-assessment-and-focused-corrections).
Metrics are advisory; long cohesive geometry or recovery procedures may stay long.

Take each candidate as its own commit, behavior-preserving, with existing tests as the net.
Skip a candidate when the change does not reduce what a reader must hold in mind; record the skip.

| Candidate | Change | Priority |
| --- | --- | --- |
| Reciprocal-pair validity | One predicate shared by `Adjacency.state`, `current_pair?`, snapshot validation and retirement; live resolution stays separate from detached comparison | High: removes divergent copies of one rule |
| `PartitionAndPairStep#cut_partition` | Separate native splitting from post-cut identity/reference projection; one transaction owner | Medium |
| `SplitIdentityRepair.keeper_path` | Name endpoint proof versus explicit keeper selection; keep conservative ambiguity refusal | Medium |
| `Registry::Validation#check_export_contributors` | Separate preflight ownership, schema and result-field checks (coordinate with Phase 06 A06) | Medium |
| `Export::Workflow.start` | Separate reviewed repairs from destination consent and task start; transaction policy stays in one place. Explicit task stages without a state-machine library | Medium |
| `Zones::Overlap.partition` | Separate polygon validation from region construction only if it helps | Low |
| Colour-by hatch clipping | Shared pure edge-intersection helper; preserve measured holed/concave/performance evidence | Low; needs case A08 rerun |
| `FaceGeometry.world_normal` | Leave unless a smaller transform helper serves real callers | Low |
| RP | Remove unused `revision` param from `Zones::Repair.restore_plan` and its callers | Cleanup |

Do not delete modules for lacking a production caller: public seams, test resets, synthetic
examples, empty exporter composition and development spikes are intentional.

## Ledger screen

Per candidate. Hatch clipping flags A08 and needs its native pixel/timing check.

## Done when

- Each taken candidate is a separate commit with unchanged test outcomes and no golden change.
- Skipped candidates recorded with a one-line reason in **Result**.
- STATUS rows REF and RP set to `Implemented on branch`.

## Result

(Fill on completion: taken, skipped and why.)
