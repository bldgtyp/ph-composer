# Validation and export: status

DATE: 2026-09-30
STATUS: In progress. Phase 1 HBJSON/report scope merged to main through PR #3 and PR #6 and accepted in
the archived Phase 1 packet. Later feature scope remains.
AUTHOR: Ed May, BLDGTYP, with Codex review
ISSUE: none (local planning draft)

## State

P1-E implements preflight, explicit repairs, per-Model asynchronous tasks, bounded collection,
pinned lazy translation, cancellation, result retention and coordinated HBJSON/report replacement
and recovery. Blocking findings remain visible and write no canonical pair. Export does not save
or modify the SKP. [P1-E/F evidence](../../archive/phase-one/evidence/p1-e-export-workflow.md) records the
exact implementation, package, native cases and independent-review corrections.

## Remaining scope and delivery boundaries

The normal build requires authored Assemblies; it safely refuses when none are available.
Successful Phase 1 translation acceptance uses an explicit tools-only synthetic provider, excluded
from shipping composition. Assemblies/materials authoring and later building validation belong to
their feature stages. METr export, consumer import and floor-area policy remain deferred and
unscheduled. SketchUp 2023/Windows host proof, public-distribution license review, merge and
release are separate gates. No implementation issue was requested or created.

## Verification

Both Ruby 3.2.2 and 2.7.2 full offline gates pass, with coverage, real-panel browser checks,
pinned native/Pyodide comparison, package inventory and fresh SketchUp 26.1.188 acceptance.
Native cases cover missing-construction refusal, successful exact HBJSON/report, warnings,
cancellation, mutation refusal, navigation tolerance, fault/restart recovery, panel/runtime/Model
loss, two Models, nested edit paths, Undo/Redo and reopen. See the evidence for fixture limits.

## Ledger

| Date | Event |
| --- | --- |
| 2026-09-18 | Initial scoping packet drafted during the whole-project review. |
| 2026-09-18 | D2 confirmed: keep a valid HBJSON/report pair when optional METr export fails, report the failure and preserve any prior METr file. |
| 2026-09-20 | Post-Phase-0 refresh: added PLAN.md, removed completed foundation blockers and linked the shared Phase 1 stages and decisions. Planning only; feature implementation remains pending. |
| 2026-09-20 | Ed deferred METr exporter development and consumer acceptance until further feature development. Phase 1 closes on canonical HBJSON/report; return milestone unscheduled. |
| 2026-09-20 | P1-C development proof complete on the implementation branch: registered Zone/face sections produced and reloaded exact HBJSON in the pinned native Honeybee stack; P1-E user workflow and Pyodide wheels remain pending. |
| 2026-09-29 | Ed authorized P1-E: HBJSON/report always selected, blockers write no pair and remain visible, no implicit SKP save, METr deferred. |
| 2026-09-30 | P1-E implementation and P1-F current-host integrated acceptance complete on branch; independent review and final gates pass. Normal composition requires authored Assemblies. |
