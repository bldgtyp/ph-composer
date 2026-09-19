# P0-A handoff check: evidence

DATE: 2026-09-18
STATUS: Complete. Paper verification only; no runtime behavior is proved here.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft; origin exists, issue not created)

## Scope and checkout

| Item | Value |
| --- | --- |
| Authorization | Ed authorized Phase 0 implementation on 2026-09-18, one commit per unit of work |
| Target branch | `phase-zero-foundation`, created from `main` at `152e796` (Phase 0 planning packet) |
| Dirty work | None. Ed's planning edits were already committed in `152e796`; nothing to preserve or isolate |
| Stage range executed | P0-A only. P0-B needs a running host and explicit spike scheduling; not started |
| Frozen baseline | `f358ebf51532046da1fa16f0ee7462df84e1ddaa`, "window-building UI update and fixes (#93)", 2026-09-17. Resolves as a commit in `../ph-navigator-sketchup` |
| Predecessor HEAD at check | `1fae5d3cac4762fbac9bcae06652532776de945e`. Nothing from it is included; newer fixes need separate disposition |
| Local toolchain seen | macOS system Ruby 2.6.10 (unused); rbenv 2.7.2 and 3.2.2 installed; Node 22.22.2; pnpm and uv present |

The frozen tree was read with `git archive f358ebf | tar -x` into session scratch storage. No
predecessor file was copied into this repository.

## Source closure

Method: a scratch analyzer expanded every inventory brace group, confirmed each path exists at the
SHA, then followed three kinds of reference out of the listed shipping files: `Phn.define`
dependencies (JavaScript), constant references resolved against every `module`, `class` and
constant definition in the tree (Ruby), and `import` statements (Python). String-level coupling
was checked by grepping the listed files for designPH, `phn_`, Space, Assembly, Window, Library and
Aperture terms. The analyzer is not retained; the P0-C shipping-string check is a separate tool.

All 82 listed Ruby, JavaScript and Python shipping paths, the six listed stylesheets and markup
files, the loader and all listed tooling paths exist, except one test (correction 1).

### False positives

| Hit | Why it is not a coupling |
| --- | --- |
| `core/diagnostics.rb`, `shell/panel.rb` → `VERSION` | Defined by the loader `src/ph_navigator_sketchup.rb`, outside the scan root |
| `shell/preferences.rb` → `Builder`, `runtime/http.rb` → `Connection`, `Origin` | Words inside strings and HTTP headers |

### Real couplings and their dispositions

| Listed file | Reaches | Disposition |
| --- | --- | --- |
| `extension.rb` | `Spaces`, `Assemblies`, `Windows`, `OrganizationLibrary` through `FEATURES` and the directory walk | Adapt as planned: explicit empty feature list, no directory walk |
| `shell/{actions,panel,commands}.rb`, `export/workflow_run.rb` | `designph/version_gate.rb` (`VersionGate`) | Drop the gate and every call site. No replacement gate in Phase 0 |
| `shell/commands.rb` | `Spaces.space?`, `Spaces::Attrs::{SPACE,VOLUME}` for context-menu branching | Drop the branch. It is a feature branch inside the shell (EXTENSIBILITY). Menu placement becomes part of an action declaration (CONTRACTS C1); Phase 0 registers no menu entry |
| `shell/panel.rb` | designPH gate snapshot key `designph` | Drop the key from the panel snapshot |
| `export/export_collector.rb` | `DesignPhExtraction`, `DesignPhTables`, `MarshalDecoder`, `BackgroundDecode`, `Normalize` | Redesign as planned. Nothing of the collector body transfers; contributors supply collection |
| `export/export_report.rb` | Fixed labels for Faces, Windows, Thermal bridges, Spaces, Volumes | Adapt: the report renders contributor-declared sections only, with no feature names |
| `core/records/sources.rb` | `organization_library` and designPH adoption provenance | Adapt as planned: neutral manual, derived and library provenance only |
| `html/workspace.js` | `domain_options.js`, assembly/material enum chips | Defer `domain_options.js` to Assemblies. Remove the dependency from the 19-line `workspace.js` |
| `python/.../contract/{__init__,parse,records}.py` | `contract/sections/{assemblies,assembly_records,spaces,window_apertures,windows}.py` | See correction 2 |
| `python/.../result/*.py` | `build.py` (600 lines), `cause_codes.py`, `kinds.py`, `report.py`, `evidence.py` → `resolution.py` | See correction 2 |

### Corrections to the inventory

1. `tests/snapshot_test.js` does not exist at the SHA. The JavaScript snapshot test is
   `tests/snapshot_reader_test.js`, already listed; the Ruby `tests/snapshot_test.rb` exists and
   belongs to the conceptual shell group.
2. The Python translation shell cannot be transplanted by stripping. `contract/` imports the
   feature sections, and `result/` imports `build.py` and the feature-shaped `kinds`, `report`,
   `evidence` and `cause_codes` modules. Disposition changes from Adapt to **pattern reference**:
   P0-F writes `ph_composer_translation/contract/{coerce,parse}.py` and a `result/` skeleton fresh,
   following the predecessor's typed-record and failure-policy patterns. Only
   `contract/coerce.py` (standard library only) is a candidate for a near-verbatim port.
3. `features/spaces/{pending_work,reconciler,undo_ledger}.rb` contain nothing generic to extract.
   Their state is Space- and Volume-keyed (`@space_jobs`, `Spaces.find_volume!`). The generic
   primitives already sit in `session/`: `CoalescedTimer` and `ModelSession#feature_state` with
   `settle` and `detach`. The C3 dirty flag, suppression depth and settle-before-read behavior are
   new session code informed by `reconciler.rb`, not a port. All three files stay deferred with
   Spaces.

`SOURCE_INVENTORY.md` carries these corrections.

## Entrypoints without an HtmlDialog

The predecessor's action boundary does not satisfy C2 as written. Four refinements are recorded
in CONTRACTS; none changes accepted product behavior.

| Predecessor evidence | Conflict with C2/C3 | Refinement |
| --- | --- | --- |
| `Actions.run(name, params, model: Sketchup.active_model)` | The target defaults to the active Model; C2 requires explicit context and no selection fallback | `API.invoke` and `API.query` take a required `context:`. The session is resolved from its id; only the panel client picks its own session |
| `Actions.run` calls `show_error(model, ...)` inside the business boundary | UI side effect inside dispatch; C2 requires the panel-closed path to return a structured outcome | Dispatch returns an outcome and shows nothing. The calling client presents the message: the panel as a persistent warning, a script by reading it |
| `Actions::Outcome#to_h` merges `detail` and the handler's Hash into the top level | Handler keys can collide with envelope keys; C2 names `effect`, affected references, revision and findings | Result fields are nested and named; nothing is flattened |
| `ModelOperation.perform` aborts on exception and returns | C3 requires verifying unchanged data after abort before claiming rollback | The operation boundary captures a pre-image of declared targets and compares after abort. A mismatch or failed comparison reports `effect: unknown` |

The remaining entrypoint pieces work without a dialog: `ModelSession` holds no panel reference,
`ModelOperation` needs only a Model, and `Sessions` keys by Model and notifies subscribers. The
session's existing `generation` counter is the base for the C3 revision. The panel-only coupling sits in
`shell/action_channel.rb`, which remains the panel's transport and becomes one API client.

## Contract fixture map

Fixture files land in P0-C/D when a harness can load them, under `tests/fixtures/foundation/`.
Status, codes and bounds are pinned in CONTRACTS ("Outcome vocabulary" under C2 and "Pinned bounds"
under C4). Case lists in the P0-D, P0-E and P0-F plans map onto these fixtures.

| Clause | Fixture | Shape | Test cases |
| --- | --- | --- | --- |
| C1 | `registration/*.json` | Feature declarations: valid, duplicate id, missing dependency, cycle, wrong contract major, malformed schema | Each invalid set fails in staging with one `registration.*` diagnostic naming owner and dependency; nothing publishes; repeated install adds no duplicate observer |
| C2 | `discover.json` | Expected discovery document for the example feature | Versions, session handles, declarations listed by id; full schema fetched separately |
| C2 | `query_records/*.json` | Record-query params and expected pages over 0, 1, 100, 101 and 501 records | Default 100; 500 accepted; 0, 501 and non-integers refused as `query.limit_invalid`; cursor after a revision change refused as `query.cursor_expired`; stable id order |
| C2/C3 | `invoke_update/*.json` | Length update: success, no-op, stale revision, wrong session, unknown field, invalid value, missing target | Outcomes pinned by status, code and effect; no-op adds no Undo entry; stale and wrong session write nothing |
| C3 | `batch_rollback.json` | Three-target batch with injected failure on the last target | All targets and references restored; `effect: rolled_back` only after verification; suppression depth back to zero |
| C4 | `retry/*.json` | Same sequence and payload, same sequence changed payload, pending, expired, lower sequence | Retained outcome returned without a transaction; `request.sequence_conflict`; `pending`; `request.outcome_unavailable`; expiry never makes a sequence writable |
| C5 | `records/*.json` | Records with absent `user_data`, known extension, unknown `local_only`, unknown `required`, newer schema, legacy envelope without relevance | Ordinary edit preserves payloads byte-for-byte as JSON values; duplicate remaps internal references and keeps external ones; unknown-rule copy refused whole; failed migration keeps originals |
| C6 | `sections/*.json` | Synthetic A, B (requires A), C (independent); missing A, A↔B cycle, malformed section, one bad A record | Structural failures before translation; bad A record gives an object finding on A and a `dependency.unavailable` finding on the B consumer; C translates |
| C6 | `export_empty.json` | Destination listing before and after, including a pre-existing file | Cancel and accept both return with no file change and no runtime start |

## Design trace: the synthetic feature end to end

The example is `example.foundation` with one record kind `example.part`: a label, `length_mm`, a
reference to a shared `example.definition` and namespaced metadata. Paths are relative to
`src/ph_composer/` unless marked.

| Step | Owner and files | Notes |
| --- | --- | --- |
| Registration | `shell/registry.rb` (staging and publish), `extension.rb` (empty `FEATURES`) | The example's `install(registry)` lives in `tools/examples/foundation/example_foundation.rb`. The development entry `tools/examples/foundation/load.rb` calls the same public install path. `extension.rb` does not change |
| Record kind | `core/records/{identity,schema}.rb`, new `core/records/engine.rb` and `core/records/extension_data.rb` | Kind declares fields in SI, reference fields and a persistence adapter. The adapter proposes edits; the engine writes dictionaries |
| Discovery and query | New `shell/api.rb`, `shell/operation_context.rb` | `discover`, `query`, `invoke`, `outcome`. Schemas come from the declarations; no second catalog |
| Atomic write | `core/model_operation.rb` (pre-image and verification added), `session/model_session.rb` (revision, dirty flag, suppression depth) | Validation completes before `start_operation`. One operation, one Undo step |
| Retry | New `session/caller_handles.rb`, `session/outcome_store.rb` | Handle registration, sequence tracking and retained outcomes per session |
| Snapshot and read-back | `shell/panel.rb` snapshot assembly from registered snapshot sections | The panel receives the snapshot after the authoritative revision; the script reads back through `query` |
| Duplicate | `core/records/engine.rb` copy with declared reference remapping and extension copy rules | Refusal when a required copy rule is unavailable |
| Export contribution | `export/contributors.rb` (privacy allowlist composition), `export/workflow_run.rb` | The example contributes one declared field and one `local_only` omission finding |
| Synthetic client | `tools/examples/foundation/walkthrough.rb` | The panel-closed script: discover, query, update, stale refusal from a second handle, retry, duplicate |

Only the example's own files and the development entry change to add the feature. The shell,
session, export orchestration and UI kit name no feature. This is a design trace; extensibility
is not verified until P0-D and P0-F run the walkthrough.

## Findings

1. No conflict with accepted product behavior, licensing or scope. Nothing escalates to Ed.
2. The four entrypoint refinements, the outcome vocabulary and the pinned bounds are recorded in
   CONTRACTS as implementation-level refinements.
3. `effect: unknown` is a fourth effect value. C2 already forbids claiming a rollback that was not
   verified; the value names that case instead of leaving it unrepresentable.
4. Whether an agent-initiated failure also raises a notice inside SketchUp belongs to the future
   adapter packet. Phase 0's synthetic client receives the structured outcome only.
5. Python: the frozen tree pins `requires-python ==3.11.*` to match Pyodide 0.24.1. That is
   independent of the 3.10 rule for Ladybug-path venvs in other PH-Tools repositories.

## Acceptance and next stage

A01 inventory portion: satisfied for the shipping and tooling groups by the closure above. The
conceptual Ruby test groups resolve during P0-C when each test is rewritten for the synthetic
feature. No other acceptance row changes.

Authorized next stage: **P0-C, tooling and empty extension.** P0-B stays pending until Ed
schedules the spikes and a host is available.
