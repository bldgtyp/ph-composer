# Assembly Layer drag reordering

Requested during the Assemblies UI refactor on 2026-10-07, planned in detail and delivered on
2026-10-15 through [PR #129](https://github.com/bldgtyp/ph-composer/pull/129); complete and archived.
Implement on a dedicated branch per stage after authorization, following Ed's rule that larger new
behavior leaves the simple refactor. The refactor added the contextual Layer gear and retains Move
outward/inward; it shipped no inert grip.

Read [PRD.md](PRD.md) for the behavior, [PLAN.md](PLAN.md) for the stages and the proposed
decisions, then [STATUS.md](STATUS.md) for the ledger. Each stage document under
[phases/](phases) is written to be handed to a coding agent on its own with the PRD and the plan.
The related refactor is [assemblies-ui-ux-refactor.md](../assemblies-ui-ux-refactor.md).
