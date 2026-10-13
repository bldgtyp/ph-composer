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

Review cycle 1 fixes `a633a2a`: both `make ci` runs pass again (1568 Ruby runs, 19144 assertions; 537 JS).

## Native receipt (LC-04)

Source `349f6ea` installed with `make install`, SketchUp 2026 (Ruby 3.2), fresh process from the blank
template, development bridge, 2026-10-13. Scratch driver: `group5_host.rb` (not committed).

| Step | Result |
| --- | --- |
| File library with two Materials loaded | completed; labels `group 5 BOARD`, `Group 5 wool` in label order; both `create` |
| Copy `g5-wool` with assignment to a new Assembly's first segment | committed in one operation; local Material `Group 5 wool`, 0.035 W/mK, source `g5-wool`; segment names it |
| Native Undo, Redo | **Outstanding.** Edit > Undo is disabled while SketchUp is in the background, and the full-screen approval went unanswered. Needs one Cmd+Z / Shift+Cmd+Z pass with SketchUp frontmost |
| Remove the provider, save, quit, reopen | provider gone from `library.providers`; local Material intact and labelled `Group 5 wool`, source `g5-wool`, segment still assigned |
