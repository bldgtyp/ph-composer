# Pipeline and UI review

DATE: 2026-09-30
STATUS: Review only; corrections proposed, no implementation authorized by this note.
ISSUE: none (local planning draft)
BASE: origin/main
HEAD: 99b6fc7b1dc6c80129c7467ebb5851c6cedb7c0c (PR #3)

## Findings

### P2: Row selection silently destroys a Zone details draft

**Confirmed by reproduction.** `html/sections/overview.js:357-376` disposes the current
Zone editor whenever the selected row is a Face, absent, or another Zone. The editor tracks
`dirty` at lines 421 and 452, but selection at line 326 never consults it. The form has Save
but no whole-form Cancel. There is no Overview navigation guard.

Select a Zone, type a new Name, select one of its Face rows, then select the Zone again.
The field returns to its stored name and no write was sent. This loses user-entered text,
Building-Segment, Level, and Ground depth drafts. Native unit refresh preservation tests
cover another route and do not cover this one. Filtering a selected Zone out takes the same
disposal route.

The UI polish skill's progressive-disclosure rule requires a surface owning an active draft
and Save/Cancel to remain visible until the draft ends. The relevant correction is draft
ownership, not more component fragmentation. Prefer a whole-form Cancel and a guard against
selection/filter/tab changes that hide a dirty or pending editor. Alternatively retain
per-occurrence drafts and keep the active editor visible until Save/Cancel. Model switches
must still withdraw the old session's editor safely.

Verify name and quantity drafts across Face/other-Zone selection, filtering, tabs, refusal,
Save and Cancel; verify a pending request cannot lose its controls. Preserve unit-switch,
stale-value and exact Undo/Redo behavior in the existing tests and native acceptance.

Reproduction was run from the repository root with the existing DOM/test helpers, without
creating or changing a test file:

```javascript
// node; require('module').createRequire points at tests/overview_panel_test.js
const fs = require('fs'), vm = require('vm'), path = require('path');
const req = require('module').createRequire(path.resolve('tests/overview_panel_test.js'));
const context = { require: req, console, setTimeout, clearTimeout };
vm.createContext(context);
const helpers = fs.readFileSync('tests/overview_panel_test.js', 'utf8').split('\ntest(')[0];
vm.runInContext(helpers + `
var p = page(); p.panel.receive({ type: 'panel.snapshot', payload: snapshot() });
var section = p.query("[data-section='ph_composer.overview']");
section.querySelector('.row-target').listeners.click({});
var name = byLabel(section, 'Zone name');
name.value = 'Unsaved review draft'; name.listeners.input({});
section.querySelectorAll('.row-target')[1].listeners.click({});
console.log('editor present:', !!byLabel(section, 'Zone name'));
section.querySelector('.row-target').listeners.click({});
console.log('name:', byLabel(section, 'Zone name').value);
console.log('writes:', p.sent.filter(m => m.type === 'action.invoke').length);
`, context);
```

Observed output: `editor present: false`, `name: Zone 1`, `writes: 0`.

### P2: The shared export snapshot owns Zone policy

**Directly evidenced architecture violation.** `export/geometry_snapshot.rb:114-122`
implements `zone_owner`, reads `Zones::ZONE_DICTIONARY`, and enforces the rule that a Face
must have one owning Zone. Its single downstream caller is
`features/face_assignment/export.rb:116`; the rest of the shared snapshot offers generic
record, occurrence and descendant reads.

`AGENTS.md` and `context/EXTENSIBILITY.md` require shared export orchestration to name no
feature. This method makes another contributor learn Zone identity and containment rules
inside otherwise neutral export infrastructure. The two feature contributors already own
their projection policy; putting this one policy in export is inconsistent with that seam.

Move the ownership query to the Zones public snapshot projection, or the FaceAssignment
projection with an explicit declared Zones dependency. Keep path-prefix and detached
snapshot traversal primitives generic. Do not introduce a callback registry solely to
relocate this one cohesive check. If several feature projections later require generic
ancestor lookup, add a neutral helper taking explicit entries or a declared dictionary.

Verify the two-Zone extraction golden, nested/wrong-Zone refusals, shared occurrences,
and an outside contributor using only the neutral snapshot interface. Coordinate with the
model review's cross-feature dependency finding rather than duplicating its proposed fix.

### P2: Opaque canonical HBJSON bypasses the advertised metadata-key guard

**Confirmed guard limitation; no current-model data leak established.**
`export/privacy.rb:60-83` validates the contributor-declared `canonical_model.hbjson` as a
scalar string. `export/artifact_hygiene.rb:13-22` traverses the result's structured keys,
but does not parse that string. A JSON string containing `username` or `extension_data`
therefore passes the key prohibition at line 8. The raw-text path regular expressions
still catch many ordinary absolute paths; this is specifically a structured-key bypass.

Minimal reproduction, run with `rbenv exec ruby -Itests -r test_helper -`:

```ruby
result = {
  "schema_version" => 1, "run_id" => "review", "state" => "complete",
  "summary" => { "objects" => 1, "unavailable" => 0, "findings" => 0, "publishable" => true },
  "sections" => [], "findings" => [], "failure" => nil,
  "canonical_model" => {
    "hbjson" => JSON.generate("type" => "Model", "username" => "private-user",
                              "extension_data" => { "secret" => "payload" }),
    "rooms" => 1, "faces" => 1, "surface_pairs" => 0, "omitted" => 0
  }
}
puts PhComposer::Export::Privacy.validate!(result) # true
```

The current Ruby record reader strips source metadata before translation, and the built-in
translator explicitly writes derived `room.user_data["ph_composer"]` for Level and
Building-Segment (`python/ph_composer_translation/model_sections.py:233`). Consequently,
blindly running the existing prohibited-key list over parsed HBJSON would reject valid
current output. The defect is the gap between the advertised artifact guard and its actual
coverage, not proof that current records leak their `user_data`.

Choose one explicit boundary before treating arbitrary contributor output as protected:

- Keep the exact serialized HBJSON bytes, parse a copy for validation, and apply an
  HBJSON-specific metadata policy that permits the known derived PH-Composer metadata while
  refusing source envelopes and undeclared metadata. Parsing must not rewrite the artifact.
- Treat canonical bytes as trusted translator output, restrict who may supply that field,
  and enforce metadata policy on typed translation inputs/output objects before serialization.
  Document that the Ruby report allowlist alone cannot validate opaque HBJSON contents.

The first option gives the artifact boundary stronger independent enforcement; the second
has less duplicated HBJSON schema knowledge but depends more on contributor validation.
Neither requires changing languages or abandoning exact-byte conformance. Verify current
derived metadata survives, unauthorized nested metadata refuses, escaped path spellings are
handled according to the chosen policy, and the HBJSON and embedded report bytes remain exact.

## Foundation assessment and focused corrections

The generic Python coordinator names no feature, orders explicit typed dependencies, and
keeps record findings separate from unreadable contracts. Ruby collection executes declared
contributors against one detached snapshot. Runtime startup is explicit, per task and per
Model session; the panel never loads Pyodide. Exporters take only HBJSON and copied options.
These are useful foundations; there is no evidence here for a language migration.

Keep Ruby for host access and model operations, JavaScript for presentation, and Python for
Honeybee construction and downstream conversion. Moving Honeybee translation to Ruby or JS
would add a second model/schema implementation. A system-Python subprocess would introduce
installation and process-lifecycle requirements absent from the current product boundary.
Revisit execution placement only if measured Pyodide limits or a supported packaging need
justify it. METr is deferred; `EXPORTERS = ()` is declared future composition, not an
unused shipping integration falsely presented as complete.

The existing review metrics identify cohesive but demanding operations: Workflow#start
has cyclomatic complexity 17; Task#received 13; artifact recovery 15; hatch clipping 11.
Measurements are from the root review's deterministic RuboCop advisory file
`/tmp/ph-composer-pr3-review-metrics.json`. These are prioritization signals, not defects.
Prefer these bounded changes when the relevant behavior next changes:

- Make export task stages and permitted transitions explicit, retaining one owner for
  coherence, cancellation, runtime teardown and canonical commit. Avoid a generic state-machine
  library for the present stages.
- Keep artifact recovery local and readable; its backup/commit/cleanup fault matrix is more
  valuable than distributing it across helpers merely to reduce its method score.
- Hatch clipping and zero-length-extremum checks repeat edge-intersection arithmetic. A small
  pure helper returning numeric intersections could reduce divergence; preserve the measured
  allocation/performance limits and exact holed/concave mesh acceptance before changing it.
- Do not delete shared UI/public seam code simply because a shipping feature does not yet use
  every route. Distinguish documented contributor primitives and intentional deferred exporter
  composition from accidental dead code. No confirmed removal candidate was established here.

## Verification and review coverage

Focused checks passed on the reviewed HEAD:

- Python `test_model_sections.py`, `test_entry.py`, `test_exporters.py`: 25 tests.
- Ruby `export_tasks_test`, `artifact_pair_test`, `export_test`, `phase_one_export_test`:
  42 tests, 240 assertions, no failures/errors/skips.
- JavaScript `runtime_page_test.js`: 10 tests. The attempted `export_panel_test.js` path did
  not exist; Export panel tests actually live in `panel_app_test.js`, covered by the root's
  fresh full gate, not claimed as part of this focused invocation.
- Root reviewer reports fresh `make ci`: 605 Ruby, 184 JS and 96 Python tests passed.

Source review traced Ruby collection/preflight/task/pair/report/privacy, loopback runtime
and page boot/translation, Python contracts/coordinator/sections/conformance/exporters,
Overview/Classify/Colour-by presentation, shared table/request/module/forms/overlays/unit
draft mechanics, Classify gesture cancellation, Colour-by cache/visibility/tessellation,
and vendor/RBZ composition. This was a bounded source review, not an assertion that every
line or every future contributor route has been exercised. Runtime asset server and parts
of the RBZ builder predate PR #3; no new defect is claimed merely from their existing design.

No host automation or fresh host session was run by this reviewer. Current acceptance
evidence remains with `planning/phase-one/ACCEPTANCE.md` and its linked evidence. Offline
tests and these reproductions do not establish SketchUp 2023, Windows, public distribution,
or METr acceptance. The notes do not advance any delivery or acceptance status.
