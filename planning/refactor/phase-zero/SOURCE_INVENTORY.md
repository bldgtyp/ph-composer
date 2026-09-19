# Phase 0 source inventory

DATE: 2026-09-18
STATUS: Closure verified by P0-A on 2026-09-18. No source has been transplanted or verified in PH-Composer.
AUTHOR: Ed May, BLDGTYP, with Codex
ISSUE: none (local planning draft; origin exists, issue not created)

## Baseline

This is a path-level inventory of PH-Navigator for SketchUp commit
`f358ebf51532046da1fa16f0ee7462df84e1ddaa`, read with `git ls-tree` and `git show`.
It does not follow the predecessor checkout. “Keep” means product-neutral source suitable for
transplant review; “Adapt” means it has a known dependency to remove or redesign; “Drop” stays
behind; “Defer” belongs to a later feature or investigation. Target paths are proposed owners,
not implementation claims.

Shipping paths without a `src/` prefix are relative to the frozen
`src/ph_navigator_sketchup/` directory. Tooling paths are relative to the predecessor root.
Brace expressions identify source groups. P0-A verified the transitive closure on 2026-09-18; its
corrections are applied below and detailed in [evidence/phase-00-handoff.md](evidence/phase-00-handoff.md).

## Shipping foundation

| Frozen predecessor paths | Disposition | Target owner and adaptation boundary |
| --- | --- | --- |
| `src/ph_navigator_sketchup.rb`, `extension.rb` | Adapt | `extension.rb`, composition root. Rename module/id/loader/menu/callback; retain explicit registration but remove fixed predecessor feature list. |
| `core/{canonical_json,coerce,deep_copy,diagnostics,dictionaries,errors,geometry_reference,json_walk,local_file_url,model_fingerprint,model_operation,model_walker,polygon2d,units,vec3}.rb` | Adapt | `core/`. Keep primitives; remove designPH diagnostics, dictionary assumptions and export-fingerprint semantics. `material_categories.rb` defers to Assemblies/materials. |
| `core/records/{identity,schema}.rb` | Adapt | `core/records/`. Foundation identity/schema seam, redesigned for PH-Composer kinds, `user_data`, extension data and references. |
| `core/records/sources.rb` | Adapt | `core/records/`. Retain only accepted neutral manual/derived/library provenance; drop `DesignPhModel`. Provider provenance may not privilege a source. |
| `session/{model_session,sessions,host_observers,timer}.rb` | Adapt | `session/`. One ModelSession, generation and host events. P0-A found nothing generic to extract from `features/spaces/{pending_work,reconciler,undo_ledger}.rb`; the C3 dirty flag and suppression depth are new session code, and the three files defer with Spaces. |
| `shell/{action_channel,actions,message,panel,preferences,protocol,commands,feature_flags}.rb` | Adapt | `shell/`. One action/transport boundary and preferences; replace predecessor callback, designPH gate/snapshot and feature flags with the accepted public-operation contract. Drop every `VersionGate` call and the Spaces context-menu branch in `commands.rb`. The contract proof's synthetic feature is a development-only composition entry. |
| `html/{module,dom,fields,icons,panel,request,snapshot,workspace,table,view_controls,overlay,record_edits,record_form}.js`, `html/{base,shell,table,overlay}.css`, `html/index.html`, `html/sections/{shell,export}.js` | Adapt | `html/`. Shared kit and empty Overview/Export shells. Regenerate module/style inventory and remove `Phn`, `phn_message`, product sections and designPH gating. `workspace.js` drops its `domain_options` dependency; `domain_options.js` defers to Assemblies. P0-E correction: `table.js`, `view_controls.js`, `record_edits.js` and `table.css` defer to the first screen with a record table, because they are built around the Spaces sticky columns and the Library materials defaults; see [evidence/phase-04-panel-units.md](evidence/phase-04-panel-units.md). |
| `core/units.rb`, `html/{units,unit_tables,unit_numbers,unit_field,unit_preferences,length_expression}.js` | Adapt | `core/units.rb`, flat `html/` files. Shared Units infrastructure only: SI storage, display preferences, parser/formatter and inherited registry rows. |
| `export/{artifact_hygiene,artifact_pair,contributors,export_attribute_snapshot,export_change_guard,export_privacy,export_report,report_html,reporter,result,workflow_run}.rb`, `export/export_report.css` | Adapt | `export/`. Empty run, contributor registry, guard, hygiene and report shell. No user file output. P0-F disposition: `artifact_pair`, `artifact_hygiene`, `export_privacy` (as `privacy.rb`), `export_report` (as `report.rb`), `report_html` and the stylesheet (as `report.css`) adapted; contributors became a registry declaration (`export_contributor`); `export_attribute_snapshot`, `export_change_guard`, `reporter`, `result` and `workflow_run` defer to the first real export run, which has a collection and a translation to guard and report on; see [evidence/phase-05-runtime.md](evidence/phase-05-runtime.md). |
| `export/{container_index,export_collector,export_workflow}.rb` | Adapt | `export/`, after collection is redesigned around PH-Composer records and synthetic contributors. These files directly call designPH extraction/tables. P0-F: written fresh as `export/{collection,record_reader,workflow}.rb` over records; container indexing defers with geometry collection. |
| `runtime/{asset_server,http,runtime_gate,runtime_manifest,task_runner}.rb`, `html/runtime.js` | Adapt | `runtime/`, `html/runtime.js`. Lazy manifest-enforced development probe and teardown; rename globals/package. Empty Export neither boots runtime nor writes artifacts. P0-F disposition: the loader moved to its own page, `html/runtime/`, outside the panel, hosted by the new `runtime/runtime_host.rb`; `task_runner` defers to the first sliced collection, since nothing in Phase 0 slices work; see [evidence/phase-05-runtime.md](evidence/phase-05-runtime.md). |
| `python/ph_navigator_translation/{__init__,contract/{__init__,coerce,parse,records},result/{__init__,account,candidates,reconciliation,summary}}.py` | Pattern reference | `python/ph_composer_translation/`, written fresh. `contract/` imports the feature sections and `result/` imports `build`, `kinds`, `report`, `evidence` and `cause_codes`, so stripping cannot work. Only `contract/coerce.py` is a near-verbatim candidate. Section registration/dependency behavior follows C6 in `CONTRACTS.md`. |

## Tooling and verification

| Frozen predecessor paths | Disposition | Target owner and gate |
| --- | --- | --- |
| `Makefile`, `.github/workflows/ci.yml`, `.ruby-version`, `Gemfile{,.lock}`, `.rubocop*`, `package.json`, `eslint.config.mjs`, `pyproject.toml`, `uv.lock`, `.npmrc` | Adapt | Repository root. Preserve matrix/pins, revise roots and package names. |
| `tools/rbz/build.py`, `tools/panel_manifest.js`, `tools/runtime/{vendor.py,browser_check.py}` | Adapt | `tools/`. RBZ allowlist, generated panel manifest, vendor hashes and Chromium runtime gate. Exclude bridge/private/non-manifest assets. |
| Conceptual foundation test groups: loader, JSON, core, session, shell, runtime and export; exact JS examples `tests/{dom_stub,coverage_js,css_selectors,icons,load_order,panel_app,protocol_agreement,request,runtime_js,snapshot_reader,record_edits_units}_test.js` (no `snapshot_test.js` exists at the SHA; the Ruby `snapshot_test.rb` belongs to the shell group); exact Python examples `tests/python/{synthetic,test_contract,test_imports,test_tools_ship_gates}.py` | Adapt | `tests/`. Rewrite fixtures/actions/snapshots for one synthetic record and feature. No designPH data or feature behavior survives. |
| `tests/support/sketchup/`, `tests/support/dom_stub.js`, `tests/support/panel_files.js`, `tests/support/panel_source.js`, `tests/support/sketchup_stub.rb`, `tests/support/units_vectors.json`, `tests/sketchup_stub_deviations_test.rb` | Adapt | `tests/support/`. Offline host double and shared vectors; cannot replace native fresh-process proof. |
| `tools/hostkit/{host_bridge.py,host_bridge.rb,host_gate.py,host_helpers.rb,model_storage.rb,probe_verdict.rb,runtime_probe.rb}` and tests | Adapt | `tools/hostkit/`. Development-only bridge/probe. Remove library/designPH actions; never ship it. |
| `tools/{coverage_ruby.rb,coverage_js.js}`, coverage test | Keep | `tools/`, `tests/`. Preserve measurement; set Phase 0 thresholds in the detailed plan. |

## Drop and defer

| Frozen predecessor group | Disposition | Owner or reason |
| --- | --- | --- |
| `designph/**`, `features/**/designph/**`, `features/**/push/**`, designPH extraction/panel code | Drop | Retired integration. No read/write/migration/dictionary/source kind/screen word/fixture crosses the boundary. |
| `features/spaces/**` except the three generic session candidates | Defer | Spaces owns TFA, active path, geometry, scan, creation/recovery and feature state. |
| `features/assemblies/**`, `html/assembly*`, `html/material_form.js`, `html/sections/assemblies.js` | Defer | Assemblies/materials owns records, thermal/UI/message parts. |
| `features/windows/**`, `html/window*` | Defer | Window Types owns types, occurrence, placement, grid, assignment, overlay and review. |
| `features/organization_library/**`, `html/library*`, `html/sections/library.js` | Defer | Later neutral provider contract. Credentials, network transport, address/defaults and catalog fixtures do not land. |
| Feature Python: `{apertures,bridges,build,constructions/**,phn_assemblies/**,spaces/**,phn_windows,window_shading,hb,facetypes,entry,report}.py` | Defer | Feature translations and HBJSON output arrive with their owners. Phase 0 has only a lazy shell and synthetic dependency proof. |
| `vendor/wheels/{honeybee_*,ladybug_*,ph_units-*}.whl` | Drop from the Phase 0 default manifest | Preserve the frozen pin evidence, but plan the minimal shell runtime without unused wheels until a later package decision authorizes them. P0-F: omitted by `PACKAGE_PINS = ()` in `tools/runtime/vendor.py`; versions unchanged. |
| Feature snapshots, licensed/private corpus, library server and feature preview checks | Drop or defer | Use synthetic foundation fixtures. Preview infrastructure itself may be adapted. |

## Dependency traps

1. The entrypoint's directory walk and fixed `FEATURES` list conceal feature coupling. Foundation registers only shells; the contract proof's synthetic feature is development-only.
2. `core/records/sources.rb`, `shell/{protocol,panel}.rb`, `html/{panel,runtime,snapshot}.js` and export collection retain designPH/`phn` contracts. The shipping-string allowlist must include dictionaries, actions, callback names, fixtures and assets.
3. Export collector/workflow code directly depends on `DesignPhExtraction` and `DesignPhTables`; this is a redesign, not a rename.
4. The runtime loader imports `ph_navigator_translation` and vendor wheels. The Phase 0 default is a distinct lazy package shell and no unused honeybee-family payload, while preserving the frozen pin evidence for later selection.
5. `window.sketchup.phn_message`, JS module declarations and generated panel manifest must change together.
6. Spaces reconciliation mixes generic deferred work with authored feature behavior. Extract a primitive or leave it deferred.
7. Stub/bridge/`make install` evidence cannot prove observer cleanup, edit-path behavior, native Undo/Redo or fresh panel assets.

## Frozen runtime, tooling and gate evidence

| Item | Source value | Phase 0 allocation |
| --- | --- | --- |
| Ruby | 2.7.2 support floor and 3.2.2 proving host; `.ruby-version` 3.2.2 | Final offline gate on both. SketchUp 2023 host proof is later. |
| JavaScript | ESLint 9.15.0; CI Node 22; ECMAScript 2020/Chromium 88 rule | Syntax/lint in CI; shipped panel remains Chromium 88 compatible. |
| Python | `requires-python ==3.11.*`; uv, pytest, pytest-cov, ruff, mypy | Package shell imports, lint/type check; no undeclared model libraries. |
| Ruby lint | RuboCop 1.50.2, Bundler 2.4.10 compatible with Ruby 2.7 | CI installs it. A local skipped lint is not evidence. |
| Runtime | Pyodide 0.24.1, Python 3.11.3, Emscripten 3.1.45; SHA-pinned manifest schema 1. Frozen manifest: 129 assets, 21,707,322 bytes including its 36,009-byte control file. | Preserve the pin evidence. Default Phase 0 shell omits unused wheels; run pins/check and refresh manifest after shipped `python/` or `html/` changes. Browser test remains outside offline CI. |
| Frozen manifest gates | Panel ready: 1,000 ms target / 2,000 ms ceiling; cold boot: 4,000 / 6,000 ms, Windows ceiling 12,000 ms; warm round trip: 20 / 100 ms; installed size: 22,000,000 / 24,000,000 bytes; boot deadline: 15,000 ms; pump: 20 / 50 ms. | Carry these as predecessor evidence. The Phase 0 plan records the adopted thresholds and reports actual payload bytes after its package selection. |
| CI | `make ci`: syntax, lint, Ruby/JS/Python tests, fixture freshness, hostkit tests, mypy, runtime checks, RBZ build/check | Transplant complete target after roots change. Predecessor coverage minima, outside CI: Ruby 93, JS 94, Python 92. |
| Host | SketchUp 2026.1 macOS / Ruby 3.2.2 predecessor proving evidence | Foundation fresh-process gate: install/relaunch, panel/model switch/edit path, synthetic native Undo/Redo, save/reopen, empty Export cancel, runtime teardown. |

## Units acceptance allocation

Frozen shared sources are `core/units.rb`,
`html/{units,unit_tables,unit_numbers,unit_field,unit_preferences,length_expression}.js`,
`tests/record_edits_units_test.js`, `tests/support/units_vectors.json`, and
`planning/archive/units/ACCEPTANCE.md`.

| Acceptance IDs | Phase 0 synthetic control or later owner |
| --- | --- |
| A1 | Synthetic physical equivalence in the shared control, including SI storage after SI and IP entry. |
| A2 | Defer to Assembly and Window Types dimensions; no product builder lands in Phase 0. |
| A3 | Defer to each feature's screen coverage. |
| A4-A5 | Shared parser: invalid input retention/refusal and mixed-unit arithmetic. |
| A6 | Shared active-draft behavior through a display-unit switch. |
| A7-A10 | Shared precision, architectural formatting, known-value vectors and host-model-unit independence. |
| A11-A12 | Shared preference/no-dirty behavior, one synthetic native edit Undo/Redo and save/reopen, restart restoration and stale-session refusal. Multi-document host evidence remains in the foundation gate. |
| A13-A14 | Defer to validation/export and feature workflow packets; Phase 0's empty Export writes no files. |
| A15 | Shared control accessibility and no-op switch behavior in Phase 0. Large Spaces repaint U1-F1 remains with Spaces. |

The source verification is the frozen `planning/archive/units/ACCEPTANCE.md`, which defines A1
through A15. Phase 0 must name only the portions its synthetic control actually proves. The
predecessor result used feature screens and designPH-dependent host models and is not
PH-Composer acceptance evidence.

## Limits

The paths, versions and predecessor gates are verified at the frozen SHA. They are not
PH-Composer implementation evidence. This work did not run the predecessor suite, inspect
licensed/private material, build an RBZ or perform host work. The settled namespace and accepted
behavior and proposed API design are owned by `TECH_STACK.md` and `CONTRACTS.md`; implementation names may change
coherently under that contract. Package selection and coverage measurements are recorded in the
relevant implementation phases, not implied by this inventory.
