# Two browser checks fail because the preview host fell behind the panel

DATE: 2026-10-15
STATUS: Complete. Merged to main through PR #131 (`ff72e2e`) on 2026-10-15; archived 2026-10-21. Reproduced at 87bdc62 and bisected 2026-10-15.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: [#130](https://github.com/bldgtyp/ph-composer/issues/130)

## Defect

Two Playwright checks fail on `main` at 87bdc62:

1. `tools/ui-preview/library_checks.cjs`: the wait for the dialog "Review Mineral wool" times out at
   every width.
2. `tools/ui-preview/windows_checks.cjs`: `the edge is painted` asserts 0 painted edges, expected 1.

Neither the checks nor the panel are wrong. Each failure is the preview's stand-in host
(`tools/ui-preview/host.js`) missing a field that a merged change moved from the panel to the Ruby host.
No check was edited.

## Library: `display_label` (first bad commit b5623ab, PR #112)

PR #112 made a library row's label the host's projection through the kind adapter. Admission adds
`display_label` to each catalog row (`library/admission.rb`), the resolver adds it to each candidate
(`library/resolver.rb`), and the panel reads it: `library/copy.js` titles the review dialog
`"Review " + row.display_label`. The stand-in host's `libraryQuery` sent no `display_label`, and its
`libraryResolution` still sent `name` on each candidate. The dialog opened as "Review undefined", so the
check's wait by name never matched.

The check was passing at c2e68b7 and `git bisect run` names b5623ab as the first failing commit.

## Windows: `display.install_topology` (first bad commit 80b1d8f, PR #108)

PR #108 moved edge classification out of the install editor. The Ruby snapshot now publishes each Type
row's `display.install_topology` (`Installs.topology_facts`, derived on every read), and the editor paints
only an edge whose host fact says `paintable`. The offline editor tests got a builder for those facts
(`withTopology` in `tests/support/window_fixtures.js`), but the preview fixture and host did not. Every
edge read as "Edge not read · cannot paint", so the click painted nothing.

The check passes at 80b1d8f^ and fails at 80b1d8f.

## Why it reached main

`make ci` does not run `make ui-checks`, because Playwright is not a project dependency. The offline
JavaScript suites build their own host facts, so they kept passing while the preview host lagged.

## Correction

In `tools/ui-preview/host.js`:

- `libraryQuery` adds `display_label: row.snapshot.name` to each row. Both preview kinds' adapters
  project `name` (`assemblies/library_kind.rb`, `windows/library_kinds.rb`).
- `libraryResolution` sends `display_label` on each candidate in place of `name`, as the resolver does.
- The `ph_composer.windows.types` section is built by `windowTypes()`, which derives each row's
  `display.install_topology` from its values at publish time, so a grid change in the preview cannot
  leave stale facts. The rule is a copy of the test-support builder, which itself mirrors
  `Installs.topology_facts` for these grids. That is now two JavaScript copies of one Ruby rule.

## Verification

- `library_checks.cjs` passes at 1280, 900, 420 and 280; `windows_checks.cjs` passes at all four widths.
- The full `make ui-checks` passes.
- `make ci` with `LANG=en_US.UTF-8` passes.

## Follow-ups, not in this change

- An offline guard against this drift: for example, a Node test that loads `host.js` and checks that its
  library rows and Type rows carry the fields the panel reads, or a CI job that installs Playwright and
  runs `make ui-checks`.
- The stand-in host's name match is case-sensitive and resolves any single name match to
  `review_required`; the Ruby resolver folds case and returns `reuse` when the mapped values are equal.
  This predates both commits and does not affect the checks.
