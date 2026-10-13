# Windows orchestration status

DATE: 2026-10-13
STATUS: Scoped; implementation ready, not authorized.
ISSUE: [#106](https://github.com/bldgtyp/ph-composer/issues/106)

The phased plan is the `## Stages` section of [PLAN.md](PLAN.md); there is no `phases/` folder.
Acceptance rows are in [ACCEPTANCE.md](ACCEPTANCE.md).

| Stage | Scope | State | Evidence |
| --- | --- | --- | --- |
| W-01 | `Windows::Authoring` coordinator; every action, grid gesture, library callback and settings write routed through it | Scoped | none yet |
| W-02 | Remove `Units::` from product and Type operations; record-only operation tests; coordinator tests; source dependency check | Scoped | none yet |
| W-03 | EXTENSIBILITY and CONTRACTS wording; stronger review; dual-Ruby `make ci`; native resize, locked-copy refusal and repair | Scoped | none yet |

Reviewed against source on 2026-10-13. The caller inventory the first draft deferred to its W-01 is
now in the plan; stages start with code.
