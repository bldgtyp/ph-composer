# Foundation purity status

DATE: 2026-10-13
STATUS: Scoped optional improvement; implementation ready, lowest priority. Not authorized.
ISSUE: [#120](https://github.com/bldgtyp/ph-composer/issues/120)

The phased plan is the `## Stages` section of [PLAN.md](PLAN.md); there is no `phases/` folder.
Acceptance rows are in [ACCEPTANCE.md](ACCEPTANCE.md).

| Stage | Scope | State | Evidence |
| --- | --- | --- | --- |
| P-01 | `FaceGeometry.build` and array `world_normal`; `FaceCapture.call`; bare-process pure test | Implemented on branch | `tests/face_geometry_pure_test.rb` (6) passes in a bare process and as a subprocess of `tests/face_geometry_test.rb`; adapter equivalence test (digest and glue flag) |
| P-02 | Rename nineteen callers; remove `FaceGeometry.capture`; goldens unchanged | Implemented on branch | 30 call sites renamed (source, tests, examples); no `FaceGeometry.capture` remains; `make fixtures` changed nothing |
| P-03 | Pure versus adapter table in canon; contributor pointer; `make ci` | Implemented on branch | EXTENSIBILITY "Organization and dependencies" table; DEVELOPMENT pointer; gate below |

Reviewed against source on 2026-10-13: the caller inventory is in the plan; the extraction is one
adapter module and one rename.
