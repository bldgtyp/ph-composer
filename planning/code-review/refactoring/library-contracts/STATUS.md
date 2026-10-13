# Library contracts status

DATE: 2026-10-13
STATUS: Implemented on branch `refactor/group-5-library-contracts`; native LC-04 receipt pending.
ISSUE: [#111](https://github.com/bldgtyp/ph-composer/issues/111)

The phased plan is the `## Stages` section of [PLAN.md](PLAN.md); there is no `phases/` folder.
Acceptance rows are in [ACCEPTANCE.md](ACCEPTANCE.md).

| Stage | Scope | State | Evidence |
| --- | --- | --- | --- |
| LC-01 | `display_label` on the adapter; required wire `id`; admission, file and provider sorting; name-free fixture | Implemented on branch | `tests/library_label_test.rb` (registration, refusals naming the adapter, nil/number/object/blank/raising labels, trim, sort, equal labels, folder merge and reload); registration, admission, file and provider suites green |
| LC-02 | Resolver, coordinator, candidate schema and shared library UI read the label | Implemented on branch | resolver suite (8, incl. unlabelled local by source only), coordinator suite, name-free copy and reuse in `library_label_test.rb`; `library_copy_test.js` name-free dialog, sidebar label sort/search; no `values.name` in `html/library`; `make fixtures`, `make runtime-manifest` |
| LC-03 | `Materials::Operations.update(source:)`; replace callback delegates | Implemented on branch | `material_library_kind_test.rb` (14): replace equals the ordinary update plus `source`, ordinary update refuses `source` in values, `source` kept when not supplied; existing replacement keeps user_data, extension payload and Assembly references |
| LC-04 | Outside name-free walkthrough; LIBRARY_FILE_FORMAT, EXTENSIBILITY, CONTRACTS; dual-Ruby `make ci`; native copy, Undo, reopen | Implemented on branch; native pending | `tools/examples/library_provider/` tag kind and holder: list, preview, create with assignment, reviewed replacement, export, fresh-Model import with typed holder reference (`example_library_provider_test.rb`); docs updated; gate results below |

Reviewed against source on 2026-10-13: the exact `name` read sites are listed in the plan; LC-03
can land independently of LC-01 and LC-02.

## Gate evidence

Source `349f6ea` on `refactor/group-5-library-contracts`, rebased on `main` `4d7a5a7`, 2026-10-13:
`make ci` on Ruby 3.2 and on Ruby 2.7.2 both pass (1566 Ruby runs, 19136 assertions; 537 JS tests;
Python 9 runs; RBZ verified, 399 files). `make coverage` passes at 95.60% (required 92%).
