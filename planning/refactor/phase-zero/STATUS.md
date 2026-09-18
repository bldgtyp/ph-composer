# Phase 0 status

DATE: 2026-09-18
STATUS: In progress
AUTHOR: Ed May, BLDGTYP, with Codex
ISSUE: none (local planning draft; origin exists, issue not created)

## Current handoff

Ed authorized Phase 0 implementation on 2026-09-18. Work runs on branch `phase-zero-foundation`
from `152e796`, one commit per completed unit. P0-A and P0-C are complete. P0-D is implemented on
branch and host-verified: record engine, sessions and revisions, registry and the public API, with a
development example driven by two clients with the panel closed. Next: P0-E. P0-B needs Ed's spike
scheduling. No spike has run.

Open decision for Ed: the wording of the `effect: unknown` warning (`Outcome::UNVERIFIED` in
`shell/outcome.rb`), shown when an abort ran but the unchanged-data check failed or could not run.

| Stage | State | Next action |
| --- | --- | --- |
| P0-A handoff check | Complete | [Evidence](evidence/phase-00-handoff.md); A01 inventory portion satisfied |
| P0-B investigations | Scoped | Execute the four documented procedures once Ed schedules them and a host is available |
| P0-C tooling/bootstrap | Complete | [Evidence](evidence/phase-02-bootstrap.md); A03/A04 provisional until P0-G |
| P0-D records/operations | Implemented on branch | [Evidence](evidence/phase-03-operations.md); A05 to A07 and the A08 action/snapshot portion passed |
| P0-E panel/units | Scoped | Next stage |
| P0-F runtime/export shell | Scoped | Implement C6 after P0-D/P0-E |
| P0-G acceptance | Scoped | Await implementation and investigation dispositions |

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
two open Models. See [evidence/phase-03-operations.md](evidence/phase-03-operations.md). A02 and
A08 (export portion) through A21 remain pending.

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
