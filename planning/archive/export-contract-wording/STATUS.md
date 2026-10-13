# Export contract wording status

DATE: 2026-10-13
STATUS: Complete; merged to main 2026-10-13 in [PR #99](https://github.com/bldgtyp/ph-composer/pull/99). Archived.
ISSUE: https://github.com/bldgtyp/ph-composer/issues/98

The phased plan is the `## Stages` section of [PLAN.md](PLAN.md); there is no `phases/` folder.
Acceptance rows are in [ACCEPTANCE.md](ACCEPTANCE.md).

| Stage | Scope | State | Evidence |
| --- | --- | --- | --- |
| EW-01 | Correct three `USER_DATA` descriptions, regenerate `docs/API_REFERENCE.md` | Merged to main | Codex review (gpt-5.6-sol, during the GPT-6.1 Sol incident) posted on PR #99, one P3 fixed; CI green on Ruby 2.7.2 and 3.2.2; `make fixtures` changed 16 description lines in `docs/API_REFERENCE.md` and nothing else; `grep -rn "exported verbatim" src docs context tools` prints nothing; `make lint-ruby`, the reference and schema tests, `make fixtures-check` and `make ci` pass on the branch head |

Reviewed against source on 2026-10-13: the finding named two constants; a third sits in
`features/assemblies/declarations/shapes.rb`. The plan now covers all three.
