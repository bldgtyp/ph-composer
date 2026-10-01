# P0-C tooling and empty extension: evidence

DATE: 2026-09-18
STATUS: Complete. Empty extension loads on the current host; A03/A04 provisional until the final RBZ.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft; origin exists, issue not created)

## Scope and commits

Branch `phase-zero-foundation`. Source baseline `f358ebf51532046da1fa16f0ee7462df84e1ddaa`, read
from a detached `git archive` copy. No predecessor working-tree file was used.

| Commit | Unit |
| --- | --- |
| `db00b48` | Loader, composition root and offline Ruby harness |
| `56180ff` | RBZ builder, shipping allowlist and namespace/designPH checks |
| `716ee85` | Offline gate (Makefile), lint rule sets, CI matrix, Ruby coverage |
| `992972e` | Development host bridge and helpers |
| `12ebc3c` | Review fixes: installer test, `Phn::` denial, numeric Ruby version guard |

## Source to target

| Frozen source | Target | Disposition |
| --- | --- | --- |
| `src/ph_navigator_sketchup.rb` | `src/ph_composer.rb` | Adapted: `PhComposer`, id `ph_composer`, version `0.1.0-dev`, AGPL copyright line |
| `src/ph_navigator_sketchup/extension.rb` | `src/ph_composer/extension.rb` | Adapted: foundation walk over `core session shell runtime export` only; `FEATURES` empty and required by name, never walked; Panel/Commands/Sessions installs removed until their stages |
| `tests/support/sketchup/{host,geom,entities,model,ui}.rb`, `sketchup_stub.rb`, `sketchup_stub_test.rb`, `fixture_files.rb` | `tests/support/` | Adapted: names, temp prefixes and the fixture env var renamed; four lines wrapped to 120 |
| `tests/support/sketchup/http.rb` | none | Deferred with the library feature, its only consumer; its deviation test left with it |
| `tests/sketchup_stub_deviations_test.rb` | same | Adapted: three deviations pinned (read_default, open_file, Matrix inverse) |
| `tests/{test_helper,all_tests,loader_test}.rb` | same | Adapted: designPH, library and panel helpers removed; loader tests rewritten for the empty root; reset-contract test added |
| `tools/rbz/build.py` | same | Adapted: explicit shipping rules (see below); runtime footprint gate deferred to P0-F with the manifest |
| `tests/python/test_tools_ship_gates.py` | `tests/python/test_rbz_build.py` | Rewritten for the new refusals; manifest tests deferred to P0-F |
| `Makefile`, `.github/workflows/ci.yml` | same | Adapted: live targets only, plus `ci-pending`; library, export-corpus, UI-preview and runtime targets removed |
| `.ruby-version`, `Gemfile`, `Gemfile.lock`, `.bundle/config`, `.npmrc`, `pnpm-lock.yaml` | same | Kept (same pins: rubocop 1.50.2, bundler 2.4.10, eslint 9.15.0) |
| `.rubocop.yml`, `.rubocop_todo.yml` | `.rubocop.yml` | Adapted: 120 ceiling per CODING_STANDARDS; no burn-down register |
| `eslint.config.mjs`, `package.json` | same | Adapted: `PhComposerUI` global, 120 ceiling, no burn-down list |
| `pyproject.toml`, `uv.lock` | same | Rewritten: dev tooling only, no honeybee-family dependencies; lock regenerated |
| `tools/coverage_ruby.rb` | same | Adapted: measures `src/ph_composer/`; the loader is proven by its reload test |
| `tools/hostkit/{host_bridge.rb,host_bridge.py}` and their tests | same | Adapted: renamed; `export`, `probe`, `transforms`, `findings`, `log` removed |
| `tools/hostkit/host_helpers.rb` | same | Rewritten: `PhComposerHost.state` and `shot` only; the Spaces helpers stay behind |
| `tools/hostkit/{host_gate.py,model_storage.rb,probe_verdict.rb,runtime_probe.rb}` | none yet | Deferred: Spaces gate with Spaces; runtime probe with P0-F; storage probe and verdict helper with the first probe that needs them |
| `tools/coverage_js.js`, `tools/panel_manifest.js`, `tests/support/{dom_stub,panel_files,panel_source}.js`, `tests/support/units_vectors.json` | none yet | Deferred to P0-E: their subject, `html/`, does not exist |
| `tools/runtime/{vendor.py,browser_check.py}` | none yet | Deferred to P0-F with the runtime and manifest |

No licensed payload, private fixture or third-party binary was copied. The Pyodide payload and
wheels remain in the predecessor until P0-F decides the minimal manifest.

## Shipping checks

`tools/rbz/build.py` refuses, on build and on `--check`: a root entry other than the loader;
entries outside `ph_composer/`; any path segment `_private`, `hostkit`, `examples`, `fixtures`
or `tests`; suffixes outside `.rb .js .css .html .svg .json .py .md .txt`; lines matching
designPH or the predecessor namespace (`design[_ ]?ph`, `ph[_ -]?navigator`, `\bphn` followed by `.`, `_` or `::`, case
insensitive, with "design phase" deliberately admitted); and `alert(`, `confirm(`, `prompt(` calls
in panel files. Reviewed citations go line by line into `shipping_allowlist.json`; an entry that
no longer matches is itself a failure. The allowlist is empty. Thirteen pytest cases show each
refusal and the installer's replace-only-this-extension behavior.

## Commands and results

Local toolchain: rbenv Ruby 2.7.2 and 3.2.2, bundler 2.4.10, Node 22.22.2, pnpm 10.33.0, uv 0.9.1,
Python 3.11.13 (uv-managed).

| Command | Result |
| --- | --- |
| `make ci` (Ruby 3.2.2) | exit 0. Syntax 20 Ruby files; rubocop 21 files (adds the Gemfile), no offences; eslint no files yet; ruff clean; Ruby 30 runs, 78 assertions; pytest 13 passed; hostkit Ruby 4 runs, 15 assertions; hostkit pytest 16 passed; mypy clean over 4 files; RBZ 2 files verified |
| `make ci RUBY=$(rbenv prefix 2.7.2)/bin/ruby` | exit 0, same counts |
| `make coverage` | Ruby line coverage 100.0% of 13 lines in `src/ph_composer/extension.rb` |
| `make install`, `make bridge-install` | Loader and folder extracted from the RBZ into the SketchUp 2026 Plugins folder |

`make ci` prints its pending list on every run: the JavaScript suite and panel manifest (P0-E);
runtime pin and manifest checks and the footprint gate (P0-F).

## Host evidence

SketchUp 26.1.188 on macOS, Ruby 3.2.2. Fresh process, launched through the bridge on a copy of
the stock `en-US/Templates/Temp01b - Simple.skp` template (SHA-256
`2ae1418dddca85afb7c271896a005d14d814df562a231633631ea3ec57121063`), stored under ignored
`_private/host/`.

```json
{"sketchup": "26.1.188", "ruby": "3.2.2",
 "extension": {"registered": true, "id": "ph_composer", "version": "0.1.0-dev", "loaded": true, "features": []},
 "model": {"file_name": "p0c-empty.skp", "modified": false, "active_path_depth": 0}}
```

Only `ph_composer/extension.rb` appears in `$LOADED_FEATURES` under the extension folder. The
console log showed no PH-Composer error or warning. SketchUp quit cleanly through the bridge.

Observations and limits:

- A plain `open -a SketchUp` with no document left SketchUp at its Welcome screen, and neither
  installed bridge started within 120 seconds. Launching with a document worked. This is why
  `launch` always opens a Model; it is an observation from one run, not a measured host rule.
- The predecessor extension, its bridge and designPH are also installed in that Plugins folder;
  the predecessor's bridge log shows it starting in the same process (pid 99648). Namespaces are
  disjoint (`PhComposer`, `PhComposerHostBridge` versus `Bldgtyp::*`); this run does not show
  PH-Composer loading alone.
- No SketchUp 2023 host run. The Ruby 2.7.2 evidence is offline only.

## Review

One bounded review of `125fb9a..992972e` against the architecture rubric (Sonnet, single agent).
No correctness defect found; composition root names no feature; no Ruby 2.7 incompatibility.
Fixed: `install`, the only path that deletes inside the real Plugins folder, had no test; the deny
pattern missed `Phn::`; the Ruby span compared version strings lexically. `make ci` re-run on both
Rubies after the fixes, exit 0.

## Acceptance

- A01: transplanted-file dispositions for P0-C recorded above. Later stages record theirs.
- A03 (provisional): RBZ inventory holds only the loader and extension folder; development
  examples, host kit and private fixtures refused by rule and tested. License notices are not yet
  relevant: nothing third-party ships. Recheck at P0-G after panel and runtime assets land.
- A04 (provisional): namespace and designPH deny checks run on every build; the empty extension
  loads with its exact installed identity on the current host. Recheck at P0-G.
- A02 remains P0-G: both Ruby versions pass offline, but the Chromium 88 and typed-Python parts
  have no shipped code to check yet.

## Next stage

P0-D, records, sessions and public operations, following CONTRACTS C1 through C5. It starts from
an extension with no foundation modules loaded beyond the composition root.
