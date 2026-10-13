# Foundation purity status

DATE: 2026-10-13
STATUS: Scoped optional improvement; implementation ready, lowest priority. Not authorized.
ISSUE: none (local planning draft)

The phased plan is the `## Stages` section of [PLAN.md](PLAN.md); there is no `phases/` folder.
Acceptance rows are in [ACCEPTANCE.md](ACCEPTANCE.md).

| Stage | Scope | State | Evidence |
| --- | --- | --- | --- |
| P-01 | `FaceGeometry.build` and array `world_normal`; `FaceCapture.call`; bare-process pure test | Scoped | none yet |
| P-02 | Rename nineteen callers; remove `FaceGeometry.capture`; goldens unchanged | Scoped | none yet |
| P-03 | Pure versus adapter table in canon; contributor pointer; `make ci` | Scoped | none yet |

Reviewed against source on 2026-10-13: the caller inventory is in the plan; the extraction is one
adapter module and one rename.
