# Library contracts status

DATE: 2026-10-13
STATUS: Scoped; implementation ready after registration reliability RR-02, not authorized.
ISSUE: none (local planning draft)

The phased plan is the `## Stages` section of [PLAN.md](PLAN.md); there is no `phases/` folder.
Acceptance rows are in [ACCEPTANCE.md](ACCEPTANCE.md).

| Stage | Scope | State | Evidence |
| --- | --- | --- | --- |
| LC-01 | `display_label` on the adapter; required wire `id`; admission, file and provider sorting; name-free fixture | Scoped | none yet |
| LC-02 | Resolver, coordinator, candidate schema and shared library UI read the label | Scoped | none yet |
| LC-03 | `Materials::Operations.update(source:)`; replace callback delegates | Scoped | none yet |
| LC-04 | Outside name-free walkthrough; LIBRARY_FILE_FORMAT, EXTENSIBILITY, CONTRACTS; dual-Ruby `make ci`; native copy, Undo, reopen | Scoped | none yet |

Reviewed against source on 2026-10-13: the exact `name` read sites are listed in the plan; LC-03
can land independently of LC-01 and LC-02.
