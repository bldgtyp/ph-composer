# Phase 0 status

DATE: 2026-09-18
STATUS: In progress
AUTHOR: Ed May, BLDGTYP, with Codex
ISSUE: none (local planning draft; origin exists, issue not created)

## Current handoff

Ed authorized Phase 0 implementation on 2026-09-18. Work runs on branch `phase-zero-foundation`
from `152e796`, one commit per completed unit. P0-A and P0-C are complete. P0-D is implemented on
branch and host-verified: record engine, sessions and revisions, registry and the public API, with a
development example driven by two clients with the panel closed. P0-E is implemented on branch and
host-verified: the panel as one API client with empty Overview and Export, its UI kit, display
preferences and shared Units, with a development-only synthetic editor. P0-F is implemented on
branch and host-verified: the pinned Pyodide payload and loopback server, the typed translation
package with C6 ordering, export contributors with the privacy guard, report and artifact pair, the
empty Export, and the runtime page with its development probe. P0-G ran as the foundation
milestone at Ed's choice: the offline gate and the fresh-process host gate passed at `0e71b2e`, and
A01 to A15, A20 and A21 are met. Phase 0 stays open: P0-B needs Ed's spike scheduling, and no spike
has run.

Open decisions for Ed:

- The wording of the `effect: unknown` warning (`Outcome::UNVERIFIED` in `shell/outcome.rb`), shown
  when an abort ran but the unchanged-data check failed or could not run.
- The six muted "Planned" tabs the UI baseline keeps. They name features in the shell page and are
  hidden below 600 px; the review recommends dropping them until tab registration lands.
- The Pyodide notice: the repository license file says MPL-2.0 and the release's `package.json`
  says Apache-2.0. Both are recorded; the licensing gate settles the shipped notice. The RBZ also
  lacks the extension's own LICENSE.
- Where Phase 1 Export hosts Pyodide: its own window, as now, or the panel on the token origin.

| Stage | State | Next action |
| --- | --- | --- |
| P0-A handoff check | Complete | [Evidence](evidence/phase-00-handoff.md); A01 inventory portion satisfied |
| P0-B investigations | In progress | Ed authorized P0-B 2026-09-18. B1 complete: [spike-phx](evidence/spike-phx.md). B2 complete: [spike-overlay](evidence/spike-overlay.md). B3 complete: [spike-window](evidence/spike-window.md). B4 next |
| P0-C tooling/bootstrap | Complete | [Evidence](evidence/phase-02-bootstrap.md); A03/A04 provisional until P0-G |
| P0-D records/operations | Implemented on branch | [Evidence](evidence/phase-03-operations.md); A05 to A07 and the A08 action/snapshot portion passed |
| P0-E panel/units | Implemented on branch | [Evidence](evidence/phase-04-panel-units.md); A10 and the A11 stage portion passed |
| P0-F runtime/export shell | Implemented on branch | [Evidence](evidence/phase-05-runtime.md); A12 to A14 and the A08 export portion passed; A15 passed with the destination dialog scripted, native step at P0-G |
| P0-G acceptance | Implemented on branch | [Evidence](evidence/phase-06-acceptance.md); foundation milestone met (A01 to A15, A20, A21); A16 to A19 await P0-B |

The existing roadmap spike statuses remain authoritative until execution is scheduled. Scoping
their work here does not turn a deferred spike into an authorized task.

## Verification

Reviewed ROADMAP, foundation scope, Units packet, decision register and applicable architectural
authorities. Verified predecessor SHA resolution, the configured remote and PHX #157's open status.
Reviewed this packet for scope/dependency consistency and checked local Markdown link targets.
Reviewed the detailed plans against accepted decisions and the architecture rubric. Source inventory
was checked against the frozen tree. Local links and whitespace checks passed.

P0-A (2026-09-18): the frozen SHA resolves; every listed path exists except one misnamed test;
JavaScript, Ruby and Python references out of the listed files were followed and each real coupling
dispositioned. See [evidence/phase-00-handoff.md](evidence/phase-00-handoff.md). Paper verification
only. A01's inventory portion is satisfied.

P0-C (2026-09-18): `make ci` exits 0 on Ruby 2.7.2 and 3.2.2 and prints the checks still pending
(JavaScript suite and panel manifest, P0-E; runtime checks and footprint gate, P0-F). The empty
extension loaded with identity `ph_composer` 0.1.0-dev and no features in a fresh SketchUp
26.1.188 process through the bridge. See [evidence/phase-02-bootstrap.md](evidence/phase-02-bootstrap.md).
A03/A04 are provisional.

P0-D (2026-09-18): `make ci` exits 0 on both Rubies (135 Ruby runs); Ruby coverage 96.1%. One
independent high-assurance review found three reproduced defects and five smaller issues, all fixed
with regression tests. Host runs on 26.1.188 covered the walkthrough, native Undo/Redo, an injected
write failure with verified rollback, save and fresh-process reopen (identical record digest) and
two open Models. See [evidence/phase-03-operations.md](evidence/phase-03-operations.md).

P0-E (2026-09-18): `make ci` exits 0 on both Rubies (167 Ruby runs, 103 JavaScript tests); coverage
Ruby 96.6%, JavaScript 97.3%; browser checks pass. One independent high-assurance review reproduced
two high and three medium defects, all fixed with regression tests; the host walkthrough found one
more, fixed. Host runs on 26.1.188 covered the empty panel, unit switches that leave the Model
untouched, a draft through a switch, Undo/Redo of a panel edit, invalid input, the New part form, a
refused edit, restart restoration and a narrow panel. See
[evidence/phase-04-panel-units.md](evidence/phase-04-panel-units.md).

P0-F (2026-09-18): `make ci` exits 0 on both Rubies (220 Ruby runs, 112 JavaScript tests, 77 Python
tests); coverage Ruby 96.6%, JavaScript 97.5%, Python 100%; the Chromium 88 runtime check and the
browser checks pass. One independent high-assurance review reproduced eight findings, none high,
all fixed with tests; the host run found one more (a favicon request), fixed. Host runs on 26.1.188
covered panel-ready time, Export cancel and accept with no file written and no runtime started, the
runtime probe (cold boot about 1.3 s), teardown, cancel during boot, close and reopen, and a
tampered install. See [evidence/phase-05-runtime.md](evidence/phase-05-runtime.md).

P0-G (2026-09-18), foundation milestone: `make ci` exits 0 on both Rubies at `0e71b2e`, coverage
and browser checks pass, and the RBZ inventory holds no development or private path. A fresh
26.1.188 process loaded the candidate without the synthetic feature. Host steps covered the
panel-closed walkthrough, native Undo/Redo, native Export cancel and accept with nothing written, save and fresh-process reopen, two
Models, old handles after close and reopen, drafts through a unit switch, a native same-process
Model switch and the runtime probe. Two new host facts: `open_file` activation fires no
`onActivateModel`, and the save dialog ignored the Model's folder. See
[evidence/phase-06-acceptance.md](evidence/phase-06-acceptance.md). A16 to A19 remain open.

## Ledger

| Date | Event |
| --- | --- |
| 2026-09-18 | Drafted readiness review and seven-stage sequence. Recorded unresolved Units scope, public contracts and remote/home discrepancy without treating recommendations as decisions |
| 2026-09-18 | Ed confirmed Units inheritance and scope split. Remaining foundation decisions stay open |
| 2026-09-18 | Ed confirmed the frozen predecessor baseline `f358ebf51532046da1fa16f0ee7462df84e1ddaa`; newer fixes require separate review before inclusion |
| 2026-09-18 | Ed confirmed no files from the empty Export workflow. Separate synthetic probes verify runtime and artifact handling; user-facing exports remain Phase 1 |
| 2026-09-18 | Ed confirmed shared programming contracts and synthetic-client acceptance in Phase 0. The user-facing adapter requires a separate delivery packet; its milestone remains unscheduled |
| 2026-09-18 | Ed confirmed authored-object copying and metadata/reference behavior; recorded in EXTENSIBILITY. Unknown-version editing and migration failure policies remain open |
| 2026-09-18 | Ed confirmed unknown-payload preservation, safe unrelated edits, dependent-operation refusal without partial copies, migration rollback and correctness-based export blocking. Remaining API details belong to contract design |
| 2026-09-18 | Ed confirmed explicit typed translation dependencies and failure reporting. Registration details and failure propagation remain bounded design work |
| 2026-09-18 | Ed confirmed all-or-nothing ordinary edits/batches, one native Undo step, stale refusal and clear failure warnings confirming no change. Recorded in TECH_STACK and AGENT_INTERFACE |
| 2026-09-18 | Ed confirmed `bldgtyp/ph-composer` as the development home. Updated D8 and related documents; the repository-home discrepancy is resolved. Any future move requires an explicit decision |
| 2026-09-18 | Prepared detailed contract design, source inventory, seven execution-stage plans and acceptance register. Documentation-only consistency review; implementation remains unauthorized |
| 2026-09-18 | Ed authorized Phase 0 implementation. Branch `phase-zero-foundation` created from `152e796` |
| 2026-09-18 | P0-A Complete. Closure verified at `f358ebf`; Python shell reclassified as pattern reference; Spaces session candidates stay deferred; outcome vocabulary, rollback verification and bounds pinned in CONTRACTS |
| 2026-09-18 | P0-C Complete. Empty extension, offline harness, RBZ shipping checks, lint/CI gate and host bridge in `db00b48`..`12ebc3c`; one bounded review, findings fixed; host load verified on SketchUp 26.1.188 |
| 2026-09-18 | P0-D Implemented on branch, `4c6cd19`..`689e464`. High-assurance review findings fixed; host evidence on 26.1.188 including two new measured host facts (synchronous commit callback, abort reported as Undo) |
| 2026-09-18 | P0-E Implemented on branch, `fe28acb`..`4206e19`. Table, inventory controls and cell drafts deferred to the first table screen; review and host findings fixed; `session.inactive` added to CONTRACTS |
| 2026-09-18 | P0-F Implemented on branch, `87d0326`..`f74e16f`. Runtime page kept apart from the panel; `TaskRunner` and the export run's guard, reporter and workflow deferred; export and runtime codes added to CONTRACTS; review and host findings fixed |
| 2026-09-18 | P0-G Implemented on branch as the foundation milestone (Ed chose it over waiting for P0-B). Gates passed at `0e71b2e`; two host facts added; A16 to A19 open |
| 2026-09-18 | Ed authorized P0-B. B1 Complete: PHX 1.57.1 in Pyodide 0.24.1 matches native byte for byte; route viable without dependency resolution, honeybee-ph pin to 1.33.65, Spaces question for Export |
| 2026-09-18 | B2 Complete: filled overlays pass the frozen criteria (1,000 triangles: added p95 8.7 ms, no stall); outline-only fallback not needed |
| 2026-09-18 | B3 Complete: flat cutting component holds; the cut is rendered, not topological; glue survives splits and explodes stale; `no_scale_mask` is UI-only |
