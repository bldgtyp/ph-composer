# PR #3 foundation corrections

DATE: 2026-09-30
STATUS: Scoped; decisions answered 2026-09-30, awaiting implementation authorization
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none yet (merge-set issue to be drafted for Ed's approval, see [R-D6](DECISIONS.md#r-d6-issue-intake))
PR: https://github.com/bldgtyp/ph-composer/pull/3
BRANCH UNDER REVIEW: `codex/phase-one-geometry-contracts` at `99b6fc7`

## Scope

The 2026-09-30 review of PR #3 found four reproduced authoring defects (M1 to M4), one editor
draft-loss defect (U1), one inherited dispatcher defect (A03), incomplete public schemas for the
building operations (A01), and an ownership problem that lets Zones and FaceAssignment reach into
each other's private stores. Ed chose one owning feature, `zones`, built for the cleanest final
state rather than the smallest diff. This packet turns that review into
phased, test-first work and tracks it to merge readiness.

The review documents under [`review/`](review/README.md) are the behavior contract for this
packet. There is no separate PRD. Findings, reproductions and source line references stay there;
phase files link to them rather than restating them.

Out of scope, each retained by its owning packet: SketchUp 2023 floor, Windows, METr, authored
Assemblies, public distribution, and the external agent adapter (review finding A05).

## Finding IDs

`M1`-`M4` are model findings, `U1` the Overview draft finding, `P-*` pipeline findings and
`A01`-`A06` agent-interface findings. **These `A01`-`A06` are review finding IDs, not the Phase 1
acceptance cases `A01`-`A16`** in [`phase-one/ACCEPTANCE.md`](../../phase-one/ACCEPTANCE.md).
Where both appear, this packet writes the acceptance cases as "case A07" and so on. New native
cases proposed here use `R01`-`R06`.

## Read order

1. [STATUS.md](STATUS.md): the tracker. One row per finding, merge-gate column, phase ledger.
2. [DECISIONS.md](DECISIONS.md): Ed's answers of 2026-09-30, with the options ruled out.
3. [PLAN.md](PLAN.md): phase map, dependencies, branch/commit shape, verification profile.
4. `phases/phase-NN-*.md`: the executable phase files, in order.
5. [`review/`](review/README.md): the findings, reproductions and architecture assessment.

## Phase map

Phases 01a to 05 close the merge set for PR #3. Phases 06 to 09 are the recommended foundation
work that the review does not require before merge; per [R-D5](DECISIONS.md#r-d5-branch-and-merge-shape)
they run on a branch from `main` after PR #3 merges.

| Phase | Title | Merge set | Waits for |
| --- | --- | --- | --- |
| [01a](phases/phase-01a-model-correctness.md) | Model correctness: M1, M2, M4, M3 feature half | Yes | Authorization |
| [01b](phases/phase-01b-invocation-validation.md) | Invocation validation: A03 | Yes | Authorization |
| [01c](phases/phase-01c-overview-draft-ownership.md) | Overview draft ownership: U1 | Yes | Authorization |
| [02](phases/phase-02-zones-ownership.md) | `zones` ownership, entity descriptors, core references, internal refactors | Yes | 01a |
| [03](phases/phase-03-building-operation-schemas.md) | Building-operation schemas and examples: A01 | Yes | Phase 02 |
| [04](phases/phase-04-authority-and-skill-repair.md) | Stale authorities and UI skill reference | Yes | None (docs only) |
| [05](phases/phase-05-merge-closure.md) | Merge closure: full gates, native run, review, merge | Yes | 01a to 04 |
| [06](phases/phase-06-api-hardening.md) | Bounded reads, export task descriptions, registration validation: A02, A04, A06 | No | PR #3 merged |
| [07](phases/phase-07-hbjson-metadata-policy.md) | Canonical HBJSON metadata policy, declared keys | No | PR #3 merged |
| [08](phases/phase-08-responsibility-refactors.md) | Non-`zones` responsibility refactors | No | PR #3 merged |
| [09](phases/phase-09-foundation-closure.md) | Foundation closure and archive | No | 06 to 08 |
