# P0-G integrated acceptance: evidence

DATE: 2026-09-18
STATUS: In progress. Foundation-only milestone: Ed chose to run P0-G before P0-B, so A16 to A19
have no result and Phase 0 cannot close here.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft; origin exists, issue not created)

## Scope

Branch `phase-zero-foundation`. Tested source commit `0e71b2e`; every later P0-G commit changes
planning documents only (checked with `git diff --stat 0e71b2e..HEAD -- src tools tests Makefile`
at closure). No new code, so no new code review: the five coherent-slice reviews of P0-C through
P0-F stand, with every finding resolved in their evidence files.

## Offline gate

Run 2026-09-18 on macOS (Darwin 25.6.0) at `0e71b2e`, after `make runtime-manifest` (no change).

| Command | Result |
| --- | --- |
| `make ci` (Ruby 3.2.2) | exit 0 |
| `make ci RUBY=$(rbenv prefix 2.7.2)/bin/ruby` | exit 0 |
| `make coverage` | exit 0 |
| `NODE_PATH=<scratch>/node_modules make ui-checks` | exit 0, PASS: 4 viewports, draft through a unit switch, invalid entry, form Escape, refused edit, empty and Export panes |
| `make runtime-browser-check` (Chromium 88.0.4324.0) | exit 0: cold boot 2,027 ms, warm round trip 0.6 to 2 ms, both within the inherited ceilings |

Within `make ci`, on both Rubies:

- Ruby syntax: 99 files. Rubocop: 100 files, no offenses. Ruff check and format: pass. ESLint: pass.
  No lint target printed a skip. On 2.7.2 Bundler 2.1.4 warns that the lockfile was written by
  2.4.10; rubocop still ran over all 100 files.
- Ruby suite 220 runs, 1,023 assertions, 0 failures. JavaScript 112 tests, 0 failures. Python 77
  passed. Hostkit 9 runs plus the Python client tests. Mypy: no issues in 24 files.
- Fixtures up to date; panel manifest 17 modules, 2 pages; runtime verified 38 assets, 0 wheels,
  19,308,432 bytes; wheel pins agree.
- RBZ verified: 94 files, 5,289,408 bytes, 19,491,177 bytes installed against the 24 MB ceiling.

Coverage: Ruby 96.6% of 2,319 lines (minimum 93%), JavaScript 97.5% of 1,792 lines (minimum 94%),
Python 100% of 281 statements (minimum 92%).

Complexity: the repository has no complexity or CRAP tool. The available measures are rubocop's
`Metrics/MethodLength` and `Metrics/ClassLength` (`.rubocop.yml`), both clean.

### RBZ inventory

`dist/ph_composer.rbz`, SHA-256 `dce9b17b…6ca3270`, runtime manifest SHA-256 `3003bfaf…8e119b9916e`.
The builder's deny check (designPH, PH-Navigator, `phn`) and blocking-API check pass. The archive
holds no `examples`, `hostkit`, bridge, test, tools, `_private` or `.pyc` path. The only notice file
is `ph_composer/vendor/THIRD_PARTY_NOTICES.md`.

Finding: the RBZ does not carry the extension's own `LICENSE` (AGPL-3.0-or-later). AGPL section 4
asks that a conveyed copy come with the license text. Not fixed here, because it changes the
tested candidate; it belongs with the licensing gate before any release.

Lazy imports: `tests/python/test_imports.py` passes; importing the translation package loads no
honeybee, ladybug or PHX module.
