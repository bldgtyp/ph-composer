# Registration reliability status

DATE: 2026-10-13
STATUS: Scoped; implementation ready, not authorized.
ISSUE: none (local planning draft)

The phased plan is the `## Stages` section of [PLAN.md](PLAN.md); there is no `phases/` folder.
Acceptance rows are in [ACCEPTANCE.md](ACCEPTANCE.md).

| Stage | Scope | State | Evidence |
| --- | --- | --- | --- |
| RR-01 | Store and dictionary admission in validation; `publish` split into pure `prepare` and raise-free `commit`; reentrancy guard | Scoped | none yet |
| RR-02 | `VALUE_MEMBERS` ownership at publish; `Fields.detached` at construction for kinds, descriptors, targets and extensions; rewrite the one live-map test | Scoped | none yet |
| RR-03 | Outside walkthrough with a custom store; CONTRACTS and EXTENSIBILITY registration text; dual-Ruby `make ci`; native smoke | Scoped | none yet |

Reviewed against source on 2026-10-13. Four technical defaults from the first draft were dropped
(reference swap with restoration, subscription tokens, frozen maps, cyclic-container diagnostics);
the reasons are in the plan's "Decisions and deviations" and in [DECISIONS.md](../DECISIONS.md). Ed accepted them on 2026-10-13.
