# P0-E panel kit and shared Units: evidence

DATE: 2026-09-18
STATUS: Implemented on branch and host-verified on SketchUp 26.1.188, except a same-process Model
switch and the native Extensions menu click; see "Limits".
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft; origin exists, issue not created)

## Scope and commits

Branch `phase-zero-foundation`, source baseline `f358ebf`. The panel's module registry and generated
script lists, the shared UI kit, the panel as one client of `PhComposer::API` with empty Overview and
Export panes, display preferences, the shared Units modules, a development-only synthetic editor and
the browser preview. No runtime, export or feature screen (P0-F and later).

| Commit | Unit |
| --- | --- |
| `fe28acb` | Module registry, manifest generator, DOM double, JavaScript coverage; Units core and its Ruby mirror |
| `ff7a2c7` | Kit: DOM primitives, icons, overlay, record form, request channel, unit field, shared styles |
| `2ff9521` | Ruby panel client, messages, preferences, menu command; page state, Overview and Export panes |
| `8dd8ea2` | Synthetic editor, stand-in host, browser preview and checks |
| `f9ae488` | Kit primitive tests to the coverage minimum |
| `6e35c1a` | Review fixes |
| `4206e19` | Host walkthrough fixes |

## Source dispositions

Frozen paths are relative to `src/ph_navigator_sketchup/`.

| Frozen source | Disposition |
| --- | --- |
| `html/module.js` | Adapted: `PhComposerUI` registry, same ordering and diagnostics |
| `html/{units,unit_tables,unit_numbers,length_expression}.js`, `core/units.rb` | Kept: namespace and attribution only; `units_vectors.json` unchanged |
| `html/{unit_preferences,unit_field,fields}.js` | Adapted: builder names become dimension scopes a screen names; table-layout preferences removed; the field no longer depends on the panel module; the metres-to-millimetres library helper dropped |
| `html/{dom,icons,overlay,record_form}.js`, `html/{base,overlay}.css` | Adapted: `phc-` prefix; command button, `push` and `sync_library` glyphs, material, category-chip and send-dialog styles dropped; the dragging class is generic |
| `html/{request,snapshot,workspace,panel}.js`, `html/sections/{shell,export}.js`, `html/index.html`, `html/shell.css` | Rewritten for the P0-D outcome shape and the panel-as-client design: no feature flags, designPH gate, runtime or task state |
| `shell/{panel,message,protocol,preferences,commands}.rb` | Rewritten as `shell/{panel,panel_messages,preferences,commands}.rb`: no asset server, feature flags, placeholder actions, diagnostics menu or context menu |
| `shell/{action_channel,actions,feature_flags}.rb` | Replaced: the panel calls `PhComposer::API`; feature flags are dropped |
| `html/{table,view_controls,record_edits}.js`, `html/table.css` | Deferred to the first screen with a record table. They are built around the Spaces sticky columns (`hierarchy`, `number`, `name`) and the Library materials table (its action, field list, category and emissivity rules). Generalizing them without a consumer would be design by guess |
| `html/{runtime}.js`, `shell` asset server | P0-F |
| `tools/panel_manifest.js`, `tools/coverage_js.js`, `tests/support/{dom_stub,panel_files,panel_source}.js` | Adapted: paths and registry name; the manifest serves any number of development pages |
| `tools/ui-preview/` | Rewritten: the real panel, a stand-in host for the example parts and four fixtures; one browser check replaces the feature checks |
| JavaScript tests | `units_test.js`, `dom_stub_test.js`, `coverage_js_test.js` kept; `load_order`, `icons`, `request`, `unit_field`, `workspace`, `css_selectors`, `panel_app` adapted or rewritten; `example_editor_test.js` new |

## Units acceptance allocation (A1 to A15)

The predecessor's A1 to A15 are in its `planning/archive/units/ACCEPTANCE.md` at `f358ebf`. Phase 0
proves only what the shared control and the synthetic editor can.

| ID | Phase 0 result | Evidence, or later owner |
| --- | --- | --- |
| A1 | Physical equivalence: `0.5 ft` stores 152.4 mm and 0.1524 m; `4 ft` in an SI field and `50` in an IP draft store 1219.2 and 1270 mm | `units_test.js`, `example_editor_test.js`; host: 50 in stored 1270 mm |
| A2 | Deferred | Assembly Builder and Window Types dimensions |
| A3 | Deferred | Each feature's screen coverage |
| A4 | Input failures keep text, mark `aria-invalid`, name the problem and send nothing: unsupported unit, wrong quantity, malformed, division by zero, nonfinite, negative, zero, range | `units_test.js`, `unit_field_test.js`, `example_editor_test.js`; host: `2 kg` kept with "Expected a length; kg is a mass unit.", Escape restored 1200 |
| A5 | Mixed arithmetic: `1 ft + 2 in` is 355.6 mm, `100 + 2 in` is 150.8 mm in a mm field, `2 ft * 3 ft` refused | `units_test.js` |
| A6 | A draft keeps its text and starting unit through a switch and commits in it; an invalid draft and its message survive a switch | `unit_field_test.js`, `example_editor_test.js`, `preview_checks.cjs`; host: `50` typed in IP, switched to SI with focus kept, Enter stored 1270 mm |
| A7 | Precision: stored values never change on switches, focus or blur; the vectors round-trip | `units_test.js`, `units_test.rb`, `example_editor_test.js` (switch and blur send nothing) |
| A8 | Architectural formatting: carries, sixteenths, decimal seed when not exact at 1/16 | `units_test.js`, `unit_field_test.js`; host: `4' 2"` and `3'` in ft-in |
| A9 | Known-value vectors for every quantity, shared by Ruby and JavaScript | `units_vectors.json` in both suites |
| A10 | Host independence: switching wrote no `UnitsOptions` | Host: LengthUnit 4, LengthFormat 0 before and after |
| A11 | A switch leaves the Model unmodified with the revision unchanged; a panel edit is one Undo step | Host: unmodified, revision 1 before and after IP; Undo restored 1231.9, Redo 1270, one revision each |
| A12 | Restart restores the preference and the scope's format; a stale or other-Model edit is refused | Host: fresh process read IP and ft-in; `panel_test.rb` (stale revision, `session.inactive`). Same-process document switching not host-run (see "Limits") |
| A13 | Deferred | Validation and export; the empty Export writes nothing |
| A14 | Deferred | Feature workflows (reviews, placement) |
| A15 | Accessibility and no-op switch: labelled IP/SI buttons in a "Display units" group, choosing the current system sends nothing, the dimension chooser marks its choice with `aria-pressed`. Large-table repaint stays with Spaces | `panel_app_test.js`, `unit_field_test.js` |

## Required checks (phase-04 plan)

| Check | Result |
| --- | --- |
| Missing or cyclic modules fail with diagnostics | `load_order_test.js` |
| Close and reopen, late responses and Model switches never repaint another Model | `panel_test.rb` (closed page ignored, `session.inactive` with the page brought up to date), `panel_app_test.js` (result and notice for another session not painted), `example_editor_test.js` (a Model switch during a draft sends nothing) |
| Normal panel minimal; development controls excluded from shipping | Overview and Export are empty; the editor ships nowhere (`example_foundation_test.rb` checks the page names no example file; the RBZ refuses `examples`) |
| Switching or repainting never writes a rounded value back | `example_editor_test.js`, host switch and blur |
| Notices, accessible labels, focus, Escape, Save and Cancel | `workspace_test.js`, `panel_app_test.js`, `preview_checks.cjs`; host: form opened with focus in its first field, `3 ft` created 914.4 mm and the form closed |
| Failed operations give persistent warnings; a programmatic failure does not open the panel | `panel_app_test.js`, `panel_test.rb`; host: a change made elsewhere during a draft refused it with a persistent warning, the other change standing |
| Manifest refreshed after shipped assets change | `make ci` runs `panel-manifest-check` |

## Host evidence

SketchUp 26.1.188 on macOS, Ruby 3.2.2, fresh processes through the bridge on a copy of the stock
Simple template (SHA-256 `2ae1418d…57121063`), with the RBZ built from each commit under test.
Captures are in ignored `_private/host/p0e/`. The page reported its state through a development-only
callback added by the scratch driver; Ruby read records, revision and `UnitsOptions` independently.
The editor and the example feature were loaded through `tools/examples/foundation/load.rb`.

1. Opening the panel showed the empty Overview with the file name and "PH-Composer 0.1.0-dev ·
   Editing: Model"; Export showed its empty pane. No page error.
2. IP: Model unmodified, revision 1, LengthUnit 4 and LengthFormat 0 unchanged, `unit_system` stored.
3. Two parts created through the API; the reopened panel ran the editor and showed them in IP.
4. `50` typed into Head in IP, switched to SI: text and focus kept. Enter stored 1270 mm, revision 3.
5. Undo restored 1231.9 (revision 4) and the panel repainted; Redo restored 1270 (revision 5).
6. `2 kg`: text kept, invalid, message shown, nothing written; Escape restored 1200.
7. New part with `3 ft`: 914.4 mm created, form closed.
8. A draft on Sill, then another client set Sill to 1500: Enter was refused with a persistent
   warning, 1500 stood, and the field showed 1500.
9. IP with the scope's format set to feet and inches; saved; SketchUp quit and relaunched: IP and
   ft-in restored, Model unmodified, three parts intact, fields in ft-in.
10. At 360 by 520 the Export tab had scrolled out of view behind the planned tabs; fixed in
    `4206e19` and re-captured: Overview and Export visible, Export current, no page scroll.

## Review

One independent high-assurance review (Opus, single agent) of `7e6e417..f9ae488` against the
architecture and UI-polish rubrics. It reproduced two high and three medium defects; all are fixed
with regression tests in `6e35c1a`, and its browser repros pass:

1. High: a blur caused by a repaint or a Model switch committed a half-typed draft, once into the
   other Model. Blur commits only while the input is in the page; a disposed field never commits.
2. Medium: a snapshot failing after a write left the waiting form locked. The result always follows,
   and a snapshot section that raises reports its own failed outcome (a P0-D gap).
3. Medium: one throwing section hid the refusal warning. Sections render last, each isolated.
4. Medium: the panel followed a new Model only on macOS activation. A new session and a
   `session.inactive` refusal now refresh the page.
5. Medium/low: planned tabs hardcoded in the shell page crowd a narrow panel. Kept per the UI
   baseline; a narrow panel now drops them (`4206e19`). Tab registration arrives with the first
   feature screen.
6. Low: Escape was held by an untouched unit field; low: a comment described scope declarations
   that do not exist; low: a missing development script blocked the first snapshot; low: a failed
   preference save had no request id. All fixed.

The host walkthrough found one more: the editor let a snapshot mid-draft update the value a draft
expected, so a draft could overwrite a change made elsewhere. Fixed in `4206e19` and host-verified.

## Gate results

| Command | Result |
| --- | --- |
| `make ci` (Ruby 3.2.2) | exit 0: rubocop 80 files no offences; eslint and ruff clean; Ruby 167 runs, 689 assertions; JavaScript 103 tests; pytest 13; manifest 17 modules, 2 pages; hostkit 4 runs, 16 pytest; mypy clean; RBZ 62 files verified |
| Ruby 2.7.2 suite | 167 runs, 0 failures |
| `make coverage` | Ruby 96.6% of 1,635 lines (minimum 93); JavaScript 97.3% of 1,628 lines (minimum 94) |
| `make ui-checks` | Pass in Chrome: four viewports, draft through a switch, invalid entry, form Escape, refused edit, empty and Export panes |

## Limits

- Same-process Model switching was not host-run. `Sketchup.file_new` from the bridge did not change
  the active Model while SketchUp was in the background (as in P0-D), and bringing SketchUp forward
  over other work is not allowed. The switch is covered offline; the predecessor's A12 hit the same
  limit.
- The Extensions > PH-Composer > Open PH-Composer menu item is covered offline; the host run opened
  the panel through the same call, not a native menu click.
- With no Model open, the panel keeps the last Model's snapshot until a Model is active again.
- A refusal message from the record engine names the record id and field key ("Example part
  exp_… has changed since it was read (length_mm)"). The panel shows engine messages verbatim;
  the wording belongs to the P0-D engine and is a follow-up.
- Chromium 88 is checked by eslint only; no SketchUp 2023 host run.
- The predecessor extension and designPH were installed in the same host process.

## Acceptance

- A10 applicable Units checks: passed offline and on the host, with A2, A3, A13 and A14 deferred to
  named owners above.
- A11 empty panel lifecycle, accessible controls, warnings and current-asset native captures: passed
  on the host for this stage; P0-G re-runs the lifecycle at final acceptance.

Next stage: P0-F, runtime and export shell.
