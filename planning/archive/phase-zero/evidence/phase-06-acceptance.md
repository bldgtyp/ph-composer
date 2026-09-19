# P0-G integrated acceptance: evidence

DATE: 2026-09-18
STATUS: Implemented on branch and host-verified on SketchUp 26.1.188 as the foundation milestone. Ed
chose to run P0-G before P0-B. P0-B then ran the same day, and A16 to A19 passed (see "Spike
outcomes"), so every row A01 to A21 is met.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft; origin exists, issue not created)

## Scope

Branch `phase-zero-foundation`. Tested source commit `0e71b2e`. Later commits, through P0-B, touch planning, context, docs and
the development-only `tools/spikes/`. Shipped source, tests and the Makefile are unchanged:
`git diff --stat 0e71b2e..HEAD -- src tests Makefile` is empty at closure. With no shipped code
changed, there is no new code review. The five coherent-slice reviews of P0-C through P0-F stand,
with every finding resolved in their evidence files.

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

## Fresh-process host gate

SketchUp 26.1.188, macOS 26 (Darwin 25.6.0), Ruby 3.2.2. The candidate `dist/ph_composer.rbz`
(`dce9b17b…`, built from `0e71b2e`) was installed with `make install`. All 94 installed files were
byte-compared with the archive, with no difference. The development bridge was installed beside it.
The same Plugins folder also loads the predecessor, its own bridge and designPH, as in P0-C to P0-F.
Models were copies of the stock Simple template (SHA-256 `7987cc22…7452f4`): `run-a.skp` in the
session scratch folder, and `run-b.skp`, later saved into the ignored `_private/host/`. No user
Model was open at any point. Driven through the bridge; Ed operated the native controls marked
"Ed".

1. **Normal build, synthetic feature absent.** In the fresh process, before any development file
   loaded: identity `ph_composer` 0.1.0-dev, loaded, `FEATURES` empty. `API.discover` listed one
   feature (`ph_composer.records`), one query, no actions, no record kinds and no snapshot sections,
   and `ExampleFoundation` was undefined. The installed manifest's SHA-256 matched the tree's
   (`3003bfaf…`).
2. **Panel closed, synthetic feature.** After `load.rb`, `ExampleWalkthrough.run` passed all eight
   steps with the panel closed: create, read, update, read back, stale second client refused with
   `revision.stale` and no write, retry, duplicate and summary (revisions 2 to 4).
3. **Values, metadata and references.** After the duplicate, four parts and one definition. Each
   copy kept its `user_data` (`example_org`) and its `example.foundation.review` extension, status
   `understood`. Each copied Sill's `checked_against` names the copied Head, and each original
   names the original: the reference was remapped inside the duplicated set.
4. **Native Undo and Redo (Ed).** The Edit menu offered "Undo Duplicate Example Parts" as one step.
   Undo returned the parts from 4 to 2 (revision 5). Redo restored the four with the same record
   digest as before, `518340fd…` (revision 6). An observer logged each digest after the host settled.
5. **Empty Export, native dialog (Ed).** The panel's Export button opened SketchUp's save dialog
   titled "Export HBJSON", proposing `run-a.hbjson`. Cancel answered "Export cancelled. Nothing was
   written." (`export.cancelled`, effect `none`). Save, twice, answered `export.unavailable` with
   effect `none`. The Model's folder, which held a previous `run-a.hbjson` and report, was byte-
   and time-identical afterwards. `~/Documents`, where the dialog opened, gained no file. Because of that, the accepted destination
   was not the folder holding the previous files; the workflow never reads the destination. No
   runtime host, asset server or extra thread existed.
6. **Save and fresh-process reopen.** Saved through the bridge, quit, relaunched: the same digest
   `518340fd…`, a new session id, revision 1, the Model unmodified.
7. **Two Models.** `run-b.skp` opened beside `run-a.skp`: two sessions. A write to B through B's
   handle left A's digest unchanged. A write to A through A's handle while B was the active Model
   changed A only. A's handle with an old revision was refused `revision.stale`. In B, a group was
   opened as the edit context (active path depth 1). A record write succeeded there and left the
   edit context open. B's revision had advanced to 10, since the geometry setup commits count.
8. **Old handles.** `Model#close` on A while B was active raised "Only the active model can be
   closed", a known host fact. After activating A and closing it, A's old handle was refused
   `session.unknown`. `Sketchup.open_file` then reopened A with a new session id and the saved
   values, and the old handle was still refused. The closed session was garbage-collected once the
   bridge's own locals were cleared: the bridge keeps one binding across evals, and a scratch local
   had been holding it. That note is now in DEVELOPMENT.
9. **Panel, units and drafts.** With the panel open on A, a typed draft of 1234 in the first Head
   length survived SI to IP unchanged and kept focus, while the other fields re-rendered in inches.
   The Model stayed unmodified. The IP preference survived a panel close and reopen.
10. **Same-process Model switch.** Switching to B through `open_file` moved the panel to B, dropped
    the draft with "The panel now shows a different Model. Nothing was written." and showed B's edit
    path ("Editing: Group1#1"). Neither Model changed; the path by which this activation reached the
    panel was not identified. Switching back through `open_file`, and two later instrumented
    switches, fired no `onActivateModel`, to the session's subscriber or to a fresh `AppObserver`,
    so the panel stayed on B. Native window
    clicks (Ed) fired it every time, and the panel followed A, B, A, B, with the right parts and
    footer. This is a new host fact.
11. **Export from a normal folder (Ed).** With B saved in `_private/host/`, the save dialog again
    opened in `~/Documents`, not the Model's folder. Cancel wrote nothing, and `_private/host/` was
    unchanged. This is a new host fact; see Limits.
12. **Runtime probe.** PASS: one boot for two requests, Python 3.11.3, no stack module, cold 1,289 ms
    (Pyodide 1,062, translation 137), warm 0.3 to 0.5 ms, worst pump 13.0 ms (ceiling 50),
    17 requests, none refused. Teardown: timer, acceptor, socket and dialog went from 1 to 0 and the
    window closed. Cancel during boot, with one client mid-transfer: all resources 0. Afterwards no
    running runtime host or asset server, 3 threads, and the only loopback listeners belonged to
    the two development bridges.
13. **Panel close and reopen.** Closing left two sessions, no runtime and 3 threads. Reopening
    showed A with the IP preference.
14. SketchUp quit cleanly through the bridge.

Not exercised on the host in P0-G: modal-tool conflict (not implemented; P0-D records it for the
first geometry feature), nested-path Undo (Model-level records only) and a failure warning from a
refused panel edit. The refused-edit warning passed in P0-E on the host and in `make ui-checks`
here.

## Limits

- **The save dialog ignores the Model's folder.** `UI.savepanel` receives the Model's folder
  (`Export::Workflow.start`) yet opened in `~/Documents`, for a Model under `/private/tmp` and for
  one under the user's Dropbox. The cause is unverified. Phase 1 Export must find a form that
  starts in the Model's folder, or accept this, before it writes artifacts.
- The RBZ lacks the extension's own `LICENSE` (see the offline gate).
- Scratch host drivers (`g_host.rb`, `g_multi.rb`, `g_js.rb`) stayed in the session scratch folder;
  the committed probes are `tools/hostkit/runtime_probe.rb` and the example walkthrough.
- No SketchUp 2023 host run and no Windows run.

## Acceptance matrix

| ID | Result | Evidence |
| --- | --- | --- |
| A01 | Passed | Inventory: [P0-A](phase-00-handoff.md). Dispositions per stage: [P0-C](phase-02-bootstrap.md), [P0-D](phase-03-operations.md), [P0-E](phase-04-panel-units.md), [P0-F](phase-05-runtime.md) |
| A02 | Passed | Offline gate above: both Rubies, Chromium 88 runtime check, mypy |
| A03 | Passed, with one finding | RBZ inventory above; the extension's own LICENSE is not in the RBZ, carried to the licensing gate |
| A04 | Passed | Deny check in `make ci`; host step 1 |
| A05 | Passed | [P0-D](phase-03-operations.md); host steps 3 and 6 |
| A06 | Passed | [P0-D](phase-03-operations.md); host steps 2, 4 and 7 at `0e71b2e` |
| A07 | Passed | [P0-D](phase-03-operations.md); host step 2 |
| A08 | Passed | [P0-D](phase-03-operations.md), [P0-F](phase-05-runtime.md) |
| A09 | Passed | Host steps 4, 6, 7, 8, 10 and 13. Modal-tool conflict and nested-path Undo belong to the first geometry feature |
| A10 | Passed | [P0-E](phase-04-panel-units.md); host step 9 |
| A11 | Passed | [P0-E](phase-04-panel-units.md); host steps 9, 10 and 13, including the same-process switch |
| A12 | Passed | [P0-F](phase-05-runtime.md); offline gate; host step 12 |
| A13 | Passed | [P0-F](phase-05-runtime.md) |
| A14 | Passed | [P0-F](phase-05-runtime.md) |
| A15 | Passed | Host steps 5 and 11, native dialog |
| A16 | Passed in P0-B | [B1](spike-phx.md) |
| A17 | Passed in P0-B | [B2](spike-overlay.md) |
| A18 | Passed in P0-B | [B3](spike-window.md) |
| A19 | Passed in P0-B | [B4](spike-edge.md) |
| A20 | Passed | Coverage and metrics above; five slice reviews (P0-C to P0-F), every finding resolved; no new code in P0-G |
| A21 | Passed | DEVELOPMENT, the example README and CONTRACTS match the code at `0e71b2e`; P0-B recorded each spike's disposition in its owning packet |

The foundation milestone (A01 to A15, A20, A21) was met at P0-G. With P0-B, A16 to A19 are met too.

## Spike outcomes

P0-B ran after this gate, on 2026-09-18. Each result is recorded in its owning packet:

| Spike | Result | Owning packets |
| --- | --- | --- |
| [B1 PHX in Pyodide](spike-phx.md) | Route viable. PHX 1.57.1 matches native byte for byte in Pyodide 0.24.1. Nine wheels (2.04 MB) installed without dependency resolution while PHX#157 is open; honeybee-ph pin to 1.33.65 | Validation and export: also decide how a model without Spaces supplies METr floor area |
| [B2 overlay fill](spike-overlay.md) | Pass. 1,000 triangles add 8.7 ms p95 (limit 16) and no stall; occlusion and picking correct | Face assignment (Colour-by filled modes), Spaces (volume preview) |
| [B3 window component](spike-window.md) | The flat cutting component holds, with five plan consequences: panes face out, net area from outlines, glue verified geometrically, `no_scale_mask` is UI-only, type edits re-validate | Window types |
| [B4 edge identity](spike-edge.md) | Dictionaries survive every tested operation and copy onto new edges; a registry scan separates the outcomes | Thermal bridges, ERV ducting, hot water piping |

No fallback was triggered. The PHX route holds, so Phase 1's success boundary is unchanged.

## Phase 1 handoff

- **Contracts available** (CONTRACTS C1 to C6, as implemented in P0-D to P0-F): feature registration
  in one `install`, record kinds and extensions, queries and actions through `PhComposer::API`
  with the outcome vocabulary, one native Undo step per change, stale refusal and retries without
  duplicate writes, snapshot sections and panel sections, display preferences and shared Units,
  export contributors with the privacy guard, report and artifact pair, typed translation sections
  with C6 ordering, Python exporter registration, and the pinned Pyodide runtime with its page and
  host.
- **Not implemented:** every user feature. Zones and adjacency, face assignment and validation and
  export (Phase 1) start from these contracts. Also not implemented: the export run's change guard,
  reporter and workflow; the background task runner; any exporter or real translation section; and
  the table, inventory controls and cell drafts.
- **Runtime versions:** SketchUp 26.1.188 host-verified; Ruby 3.2.2 (host) and 2.7.2 (floor, offline);
  Chromium 88 for panel and runtime JavaScript; Pyodide 0.24.1 with CPython 3.11.3, no wheels.
- **Open before or during Phase 1:**
  - the four P0-B spikes, with the PHX route (B1) gating the METr exporter;
  - where Phase 1 Export hosts Pyodide (its own window or the panel on the token origin);
  - the save dialog's starting folder;
  - where the HBJSON itself is guarded;
  - the Pyodide notice and the RBZ LICENSE;
  - Ed's decisions on the `effect: unknown` wording and the six Planned tabs;
  - the validation-and-export interview (PRD drafted, not interviewed).
- **Later gates:** SketchUp 2023 native proof, Windows, public packaging and distribution, METr
  opening a real export, and the external-agent adapter packet.

## PR review (PR #1)

An independent review of PR #1 at `bb00db9` reproduced five P2 findings. The review ran against
CODING_STANDARDS, EXTENSIBILITY, the architecture rubric and CONTRACTS. All five were accepted and
fixed in `0c3144d`, each with a regression test that failed before its fix:

| Finding | Fix | Regression |
| --- | --- | --- |
| Discovery and descriptions returned live schemas; editing one changed write validation | Detached copies from `discover` and `describe` | `test_discovery_and_descriptions_are_detached_from_what_validation_uses` |
| Returned outcomes shared the retained object, so a caller could change what a retry returned (C4) | The store keeps its own copy; every read returns a detached one | `test_a_retained_outcome_is_isolated_from_every_returned_copy` |
| A current-version extension envelope counted as understood without the installed validator or reference check; invalid data copied and exported | New status `invalid` and code `extension.invalid`: kept for unrelated edits, replaceable with valid data, refused for copy, migration and export | three engine tests and `test_an_exported_extension_failing_its_installed_validator_blocks_the_export` |
| A forged cursor raised out of `API.query`; unexpected query and preview failures relied on a panel-only rescue | The cursor position must be a string id (`params.invalid`); query and preview answer unexpected failures as `failed` / `operation.failed` for every client | `test_a_malformed_cursor_is_refused_as_an_outcome`, `test_an_unexpected_query_or_preview_failure_is_a_failed_outcome` |
| Rollback recovery left the journal stage after a process was lost while marking the journal committed, so the next commit failed with `EEXIST` | Rollback also clears the journal stage, before the journal | `test_next_commit_recovers_a_process_lost_while_marking_the_journal_committed` |

In the discovery regression, before the fix, the test's edit to the "detached" schema also broke a
later test through the shared part kind. That confirmed the finding.

**Gate at `0c3144d`:**
- `make ci` exits 0 on Ruby 3.2.2 and 2.7.2: 229 Ruby runs, 1,056 assertions, 112 JavaScript
  tests, 77 Python tests.
- `make coverage`: Ruby 96.5%, JavaScript 97.5%, Python 100%.

**Host smoke on SketchUp 26.1.188, fresh process, RBZ built from `0c3144d`:**
- the shipping build loads without the example feature;
- `ExampleWalkthrough.run` passes all eight steps;
- a described schema edited by the caller reads back unchanged;
- a forged cursor is refused as `params.invalid`.

The earlier host steps covered behaviour these fixes do not touch, and were not rerun.
