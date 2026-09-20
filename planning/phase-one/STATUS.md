# Phase 1 status

DATE: 2026-09-20
STATUS: In progress. P1-A complete; P1-B is next and not authorized.
ISSUE: none (local implementation packet)

## Current handoff

Phase 0 is complete and merged at `f1e9a98` through PR #1. The four investigations passed with
recorded conditions. The shipping composition has no building features or Python translation
sections/exporters; Export still refuses after destination selection without writing anything.
P1-A completed on 2026-09-20 under Ed's implementation instruction. It produced the
[geometry/persistence contract](CONTRACTS.md), a reusable native probe and
[current-host evidence](evidence/p1-a-geometry.md). No building feature is implemented yet.

The [plan](PLAN.md) starts with the geometry/storage contract and native evidence needed by
Make Zone and Solve adjacencies. It then delivers a small two-Zone export proof before completing
the remaining Phase 1 behavior. A successful early proof alone does not close a feature packet.

METr exporter implementation and consumer acceptance are deferred by Ed on 2026-09-20.
Phase 1 now closes on HBJSON/report; the later METr milestone is unscheduled.

## Entry gates

- Review the remaining recommendations in [DECISIONS.md](DECISIONS.md). Ed has deferred METr
  development and its floor-area/import questions. HBJSON translation pins and fixture isolation
  remain active planning gates.
- Create/link the implementation issue during authorized issue intake. The configured remote is
  `bldgtyp/ph-composer`; P1-A created no external issue or PR.
- Obtain implementation scope for P1-B. The completed instruction covered the first Phase 1 step.

## Stages

| Stage | State | Completion evidence |
| --- | --- | --- |
| P1-A: geometry contracts and host investigation | Complete | [Contract](CONTRACTS.md); [host evidence](evidence/p1-a-geometry.md); A01 met |
| P1-B: Zone and face authoring core | Scoped | Pending |
| P1-C: adjacency and early HBJSON proof | Scoped | Pending |
| P1-D: complete Phase 1 authoring UI and repairs | Scoped | Pending |
| P1-E: HBJSON/report export workflow | Scoped | Pending; remaining canonical-export choices open |
| P1-F: acceptance and handoff | Scoped | Pending |

## Verification

P1-A checked the merged registration, record storage, dispatcher, transaction and export code.
The contract preserves record-only actions and allocates entity stores, delete, geometry steps,
participants and scoped rollback fingerprints to later implementation.

A bounded independent planning review identified missing allocation for record deletion, explicit
identity repair, Auto-classify, gesture bounds and export task retention/lifecycle. These were
checked against the PRDs/current code and added to the plans and acceptance register. Local link
and whitespace checks passed. No code, runtime or host gate was run for these documentation edits.

The native probe passed on SketchUp 26.1.188 with Ruby 3.2.2. Grouping, split, explode/limited
Restore, closure, holes, scaled/mirrored nesting, native Undo/Redo and fresh-process reopen passed.
The measured point-merge boundary was 0.0254 mm; plane-offset and normal-angle criteria remain a
P1-C solver gate. Syntax, link and documentation checks passed. The full offline suite passed on
Ruby 3.2.2 and the Ruby 2.7.2 compatibility floor: 229 Ruby tests with 1,056 assertions, 112
JavaScript tests, 77 Python tests and 9 hostkit tests. Coverage passed at 96.7% Ruby, 97.5%
JavaScript and 100% Python. The independent architecture review's two findings were resolved in
the final documents. SketchUp 2023, Windows and public distribution remain separate gates.

## Ledger

| Date | Event |
| --- | --- |
| 2026-09-20 | Post-merge planning refresh. Added staged delivery and feature plans, recorded foundation gaps and carried B1/B2 consequences into Phase 1. At this checkpoint, implementation remained unauthorized. |
| 2026-09-20 | Ed deferred METr exporter development and consumer acceptance until further feature development. Phase 1 closes on canonical HBJSON/report; return milestone unscheduled. |
| 2026-09-20 | P1-A complete: entity schemas and compound-operation/export snapshot contracts bound; native geometry probe passed on SketchUp 26.1.188. No Zone/face feature code landed. |
