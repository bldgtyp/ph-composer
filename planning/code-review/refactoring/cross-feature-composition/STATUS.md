# Cross-feature composition status

DATE: 2026-10-13
STATUS: Scoped; implementation ready after registration reliability RR-02, not authorized.
ISSUE: none (local planning draft)

The phased plan is the `## Stages` section of [PLAN.md](PLAN.md); there is no `phases/` folder.
Acceptance rows are in [ACCEPTANCE.md](ACCEPTANCE.md).

| Stage | Scope | State | Evidence |
| --- | --- | --- | --- |
| C-01 | Typed participant declaration, `participants:` edge, validation, discovery, three new codes | Scoped | none yet |
| C-02 | `request.participate`, `ParticipantInvocation`, `ProjectedEngine#projected`, contribution postcondition | Scoped | none yet |
| C-03 | Migrate Library copy, the Windows import caller; convert `retire_pairs` to a direct call; remove the raw accessor | Scoped | none yet |
| C-04 | Outside two-feature example, CONTRACTS and EXTENSIBILITY, dual-Ruby `make ci`, one native compound action | Scoped | none yet |

Reviewed against source on 2026-10-13. The Zones `retire_pairs` participant, called with non-JSON
arguments from the same feature, was missing from the first draft; C-03 converts it. The
`ProposalScope` facade was dropped for the existing projected-engine guard; see the plan's
"Decisions and deviations" and [DECISIONS.md](../DECISIONS.md).
