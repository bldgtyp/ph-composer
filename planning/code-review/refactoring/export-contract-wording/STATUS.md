# Export contract wording status

DATE: 2026-10-13
STATUS: Implemented on branch `refactor/export-wording-ew-01` (2026-10-13); awaiting review and merge.
ISSUE: https://github.com/bldgtyp/ph-composer/issues/98

The phased plan is the `## Stages` section of [PLAN.md](PLAN.md); there is no `phases/` folder.
Acceptance rows are in [ACCEPTANCE.md](ACCEPTANCE.md).

| Stage | Scope | State | Evidence |
| --- | --- | --- | --- |
| EW-01 | Correct three `USER_DATA` descriptions, regenerate `docs/API_REFERENCE.md` | Implemented on branch | `make fixtures` changed 16 description lines in `docs/API_REFERENCE.md` and nothing else; `grep -rn "exported verbatim" src docs context tools` prints nothing; `make lint-ruby`, the reference and schema tests, `make fixtures-check` and `make ci` pass on the branch head |

Reviewed against source on 2026-10-13: the finding named two constants; a third sits in
`features/assemblies/declarations/shapes.rb`. The plan now covers all three.
