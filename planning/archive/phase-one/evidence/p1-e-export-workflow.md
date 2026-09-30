# P1-E/F: HBJSON/report workflow and integrated acceptance

DATE: 2026-09-30
STATUS: Complete on the implementation branch for the named current-host Phase 1 scope.
ISSUE: none (local implementation packet)

## Accepted scope and build

Ed authorized P1-E on 2026-09-29: HBJSON/report always selected, blocking findings write no canonical
pair and remain visible, export never implicitly saves the SKP, and METr stays deferred. P1-D was
already complete at `f1d3771`. This implementation is `314e576` on
`codex/phase-one-geometry-contracts`. It is neither merged nor released.

Final RBZ SHA256: `bf65a88382405c2f0517bdf0b8a2bc6137ef918e60506dedf56400d0c95543b0`.
The package contains 167 files, 7,069,247 compressed bytes and 21,835,695 installed bytes,
below the 22,000,000 target and 24,000,000 ceiling. The manifest pins all eight HBJSON wheels,
source URLs, exact versions and hashes. The extension LICENSE and upstream notices/texts ship.
Source license discrepancies remain recorded for the separate public-distribution gate; this
acceptance does not reinterpret them as a new license grant.

## Implementation and independent review

The per-Model task performs bounded collection, lazy runtime translation, exact HBJSON reload,
privacy checks and coordinated pair commit. Preflight is a feature-owned query declaration with
explicit repair actions. The panel runs only selected repairs and repeats preflight afterward.
Task status carries counts and diagnostics without canonical HBJSON bytes, including blocked runs
with partial translated output. Files and their embedded result retain the exact canonical bytes.

One stronger independent reviewer reviewed the coherent P1-E diff using the architecture and UI
rubrics, deterministic checks and coverage. Four confirmed findings were corrected and the same
reviewer closed them: stale Surface blocking versus required omission, absent post-Solve preflight,
full HBJSON in polling, and missing distinct Face/Attached-zone diagnostics. Native acceptance then
exposed the navigation-generation issue below. The same reviewer examined that correction and
found no confirmed mutation-masking defect. No equivalent second review was added.

The native Export checkbox initially inherited a stacked grid layout; its narrowly scoped layout
was corrected and inspected again. Preview tooling now answers the current preflight/latest
protocol and gives its two synthetic Zones distinct occurrence paths.

## Native host and fixture boundary

Installed SketchUp **26.1.188**, embedded Ruby **3.2.2**, on this macOS system. Fresh-process
installed builds were used after implementation and after the navigation correction. The final
integrated run used PID 55699 with the same final shipping source and wheel payload. A final normal
restart at PID 57338 reopened the saved fixture clean at the root edit path; the tools-only
composition was absent and normal missing-Assembly refusal remained intact.

All Models and artifacts are synthetic and gitignored under `_private/host/`:
`p1e-workflow-two-zones.skp`, `p1f-integrated.skp`, and `p1e-*-evidence.json`/artifact pairs.
The integration fixture was authored in a fresh blank Model through the public Make Zone,
Classify and Solve operations, then placed in a wrapper and solved again using its new occurrence
paths. It contains 2 Zones, 12 assigned Faces and one current reciprocal Surface pair.

The ordinary installed build reports 12 missing authored Assemblies before destination selection.
A programmatic run through the real runtime likewise refuses both Rooms and writes no pair.
For successful native acceptance only, a copy of the runtime tree under `_private/host/` used an
explicit lazy synthetic construction provider. Its manifest was rebuilt for that private tree,
and development-only Ruby composition supplied that asset server and removed only missing-Assembly
preflight findings. No Assembly record, shipping switch, provider address or fallback was added.
The same fixture geometry, records, task, panel, privacy/report and artifact code ran unchanged.
Tools-only latency injection made pending Model-switch/close states observable; it is not shipping
behavior. The final host restart removed all of these in-process development compositions.

## A11 to A14 and A16 results

| Gate/case | Verified outcome |
| --- | --- |
| A11 fixture isolation | Normal preflight blocks missing Assemblies; direct normal runtime refuses canonical output. No canonical files. RBZ inventory excludes tools, private fixtures and synthetic provider. Authored unavailable Assembly IDs still refuse. |
| Native destination cancel | Native Save dialog Cancel returns cancelled, starts no task/runtime and writes nothing. |
| Clean native export | Development composition creates 2 Rooms, 12 Faces, one actual reciprocal Surface pair. Both files agree exactly with the report's embedded result. |
| Stale Surface, skip Solve | Moving the east Zone 1 mm exports 10 Faces, zero Surface pairs, and reports both omitted Faces with their owning Zones, reasons and 12 m² areas. No dangling Surface reference. |
| Retired Surface | Explicit Solve retires the stale endpoints. Their unassigned boundaries produce the same 2 omissions and 10 emitted Faces, with truthful reasons. No condition is guessed and export performs no repair. |
| Collection/translation cancellation | Queued cancellation is covered offline; native cancellation after the task enters translating writes no pair and stops its runtime. |
| Content mutation | A native committed Model attribute change during translation returns `export.model_changed`, releases the runtime and writes no pair. Undo/Redo invalidation also has focused coverage. |
| Camera/selection/edit context | Camera and selection changes plus entering a Zone edit context during translation complete with 2 Rooms/12 Faces/one pair. Navigation may dirty native view state; export does not save it. |
| Runtime window close | Closing the actual runtime HtmlDialog terminates the task with `runtime.closed`, releases resources and writes no pair. |
| Panel/client loss | Closing the actual panel during translation does not cancel the task. Reopening Export retrieves its completed result and diagnostics. |
| Two Models | With a tools-only delayed runtime start, a second Model is opened while the old task is confirmed pending in translating. The old task then completes against its own Model; the new Model remains unmodified. Cross-session status refuses `task.expired`. |
| Model close | Native close of the synthetic Model while its task is pending invalidates its session, releases all runtimes and writes no files. Latency injection delayed runtime start to make this state reachable. |
| Polling/retention/timeout | Polling/status/latest return detached outcomes without repeating writes. One active task per Model; latest 20 terminal tasks retained for at most 30 minutes. Limit and monotonic expiry have focused tests. A lost reply or timeout itself does not cancel; panel-loss and later retrieval exercise this ownership boundary. |
| Canonical fault/recovery | The complete offline failure matrix passes. A real-host injected failure after HBJSON rename restores the exact prior pair. A staged interrupted commit survives host restart; the next task restores the prior pair and removes its journal before normal translation refuses. The old task handle expires rather than claiming success. |
| Privacy/accounting | The integration fixture retains a synthetic local metadata sentinel in the SKP, but neither canonical file contains it. The report records its omission. Stale/retired rows reconcile with canonical omitted count and area; report embeds exact HBJSON bytes. Allowlists, escaping, unknown/required extension refusal and shared failure accounting pass the required suites. |
| P1-F integration | Fresh public authoring and Solve, native Zone edit Undo/Redo, export at edit-path depth 2, two-Model task behavior, and saved-file close/reopen pass. Reopen creates a new session with the same Zone IDs, edited name and local metadata. Export preserves the saved SKP hash and content generation. |

The integrated export took 2,425 ms and produced 2 Rooms, 12 Faces, one pair, zero geometry omissions,
and one local-metadata finding. The ordinary geometry cursor traversed 1,964 entities in 22 slices,
48.642 ms total, with a largest observed slice of 8.272 ms. The 8 ms budget is checked between
indivisible native Face captures; it is not a hard real-time ceiling. Contributor callbacks also
remain indivisible and are not claimed to scale to every future feature.

## Native navigation correction

SketchUp emits `transaction_committed` at the new path immediately before `active_path_changed`
when entering or leaving a context. Counting that callback as content cancelled an otherwise
valid export. The session now recognizes a commit whose path differs from its cached path as
navigation while retaining the existing whole-Model revision behavior. Measured combined edit
and path-switch ordering commits the preceding content at the old path, reports the path change,
then commits at the new path. Those content commits still advance export generation. Own public
mutations and Undo/Redo remain independently counted. Focused ordering tests and the fresh installed
native repeat pass; no unmeasured host-version claim follows.

## Final deterministic/runtime gates

- `make ci` on Ruby **3.2.2** and **2.7.2**: 605 Ruby tests / 2,742 assertions, 184 JavaScript tests,
  96 Python tests and 9 hostkit tests / 30 assertions; zero failures/errors/skips. Lint, types,
  unchanged fixture goldens, manifests/pins and RBZ checks pass.
- Coverage: Ruby **96.4%**, JavaScript **97.7%**, Python **94.00%**, all above repository floors.
- Real-panel browser checks pass at four sizes, including the updated Export and authoring fixtures.
- Chromium **88** real runtime: isolated origin, one boot for two probes, no translation-stack import
  on probe, cold boot **2,230 ms**, warm **1.7/0.5 ms**, Python **3.11.3**.
- Exact eight-wheel native/Pyodide synthetic translation comparison passes. Comparison normalizes
  only upstream-created PH default UUIDs and unordered global construction definitions; authored
  identities, actual references and values are compared directly. Exported bytes are not rewritten.
- Actual HtmlDialog translation, cancellation, close and teardown pass in SketchUp. A browser pass
  alone was not used as native acceptance.

Logs are local scratch: `/tmp/phc-p1e-ci-final.log`, `/tmp/phc-p1e-ci-27.log`,
`/tmp/phc-p1e-coverage-final.log`, `/tmp/phc-p1e-ui-browser.log` and
`/tmp/phc-p1e-browser-final.json`. They supplement this source-controlled summary, not its authority.

## Remaining boundaries

Phase 1's named current-host acceptance is complete on branch. Assembly authoring/provider
integration, further feature-owned building validation and the deferred METr milestone stay with
their owning later plans. The normal build has no construction fallback and cannot yet produce
an authored production building through the Phase 1 fixture route. SketchUp 2023 host proof,
Windows support, public distribution/license-resolution gates, merge/release and certification
claims are separate and remain unclaimed.
