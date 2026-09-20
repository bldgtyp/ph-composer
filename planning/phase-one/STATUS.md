# Phase 1 status

DATE: 2026-09-20
STATUS: In progress. P1-A through P1-C complete on the implementation branch; P1-D is authorized, with D1, D2 and D3 implemented.
ISSUE: none (local implementation packet)

## Current handoff

Phase 0 is complete and merged at `f1e9a98` through PR #1. The four investigations passed with
recorded conditions. P1-B installs the first building features: entity-owned Zones and Face
assignments, registered public operations and the minimal Overview authoring UI. P1-C adds
whole-wall adjacency, a shared detached geometry snapshot, registered Zone/face contributors and
the first typed Honeybee model sections. Export still refuses after destination selection without
writing anything; the user workflow and shipped translation wheels remain P1-E.
P1-A completed on 2026-09-20 under Ed's implementation instruction. It produced the
[geometry/persistence contract](CONTRACTS.md), a reusable native probe and
[current-host evidence](evidence/p1-a-geometry.md). P1-B completed on 2026-09-20 with
[authoring evidence](evidence/p1-b-authoring.md) and a checked-in public-operation walkthrough.

The [plan](PLAN.md) starts with the geometry/storage contract and native evidence needed by
Make Zone and Solve adjacencies. The small two-Zone HBJSON proof now passes. P1-D completes the
remaining authoring behavior; the early proof does not close a feature packet.

METr exporter implementation and consumer acceptance are deferred by Ed on 2026-09-20.
Phase 1 now closes on HBJSON/report; the later METr milestone is unscheduled.

## Entry gates

- Review the remaining recommendations in [DECISIONS.md](DECISIONS.md). Ed has deferred METr
  development and its floor-area/import questions. P1-E still owns the shipped HBJSON wheel set.
- Create/link the implementation issue during authorized issue intake. The configured remote is
  `bldgtyp/ph-composer`; P1-A created no external issue or PR.
- P1-D is authorized. Its slices are tracked in [PLAN.md](PLAN.md); D4 to D7 remain.

## Stages

| Stage | State | Completion evidence |
| --- | --- | --- |
| P1-A: geometry contracts and host investigation | Complete | [Contract](CONTRACTS.md); [host evidence](evidence/p1-a-geometry.md); A01 met |
| P1-B: Zone and face authoring core | Complete | [Authoring evidence](evidence/p1-b-authoring.md); A02/A03 and the P1-B portion of A04 met |
| P1-C: adjacency and early HBJSON proof | Complete on branch | [Adjacency/HBJSON evidence](evidence/p1-c-adjacency-hbjson.md); A10 and P1-C portions of A05/A11 met |
| P1-D: complete Phase 1 authoring UI and repairs | In progress | D1, D2 and D3 implemented; the offline portions of A04, A06 and A07 pass. Slice table in [PLAN.md](PLAN.md) |
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

The P1-A native probe passed on SketchUp 26.1.188 with Ruby 3.2.2. Grouping, split, explode/limited
Restore, closure, holes, scaled/mirrored nesting, native Undo/Redo and fresh-process reopen passed.
The measured point-merge boundary was 0.0254 mm; plane-offset and normal-angle criteria remain a
P1-C solver gate. Syntax, link and documentation checks passed. The full offline suite passed on
Ruby 3.2.2 and the Ruby 2.7.2 compatibility floor: 229 Ruby tests with 1,056 assertions, 112
JavaScript tests, 77 Python tests and 9 hostkit tests. The P1-B gates now pass with 248 Ruby tests
and 1,123 assertions, 116 JavaScript tests, 77 Python tests and 9 hostkit tests with 30 assertions.
Coverage is 95.4% Ruby, 97.7% JavaScript and 100% Python. The runtime browser check and fresh-process
SketchUp 26.1.188 save/reopen plus native Undo/Redo passed. The Playwright preview check skipped
because its external scratch dependency was unavailable; focused panel tests and live-host visual
acceptance covered the P1-B UI. SketchUp 2023, Windows and public distribution remain separate gates.

P1-D D1 and D2 pass 279 Ruby tests with 1,238 assertions on both Ruby 3.2.2 and the 2.7.2
compatibility floor, with `make ci` green and Ruby coverage at 95.7%. The offline checks cover the
gesture ceiling at exactly 250 and the refusal at 251, refusal driven by reciprocal targets,
occurrence deduplication, a host write
failure part-way through a gesture rolling every Face back, both endpoints of one pair classified
in a single gesture, Suggest classification leaving existing records alone, Reverse face keeping
the record while the pair reads stale, and the Attached zone reference states and guarded delete.
No host gate ran for these slices. Ed accepted deferring them to D6, when there is a real gesture
to perform; the ceiling's own host re-measurement belongs to the same slice.

P1-D D3 brings the offline suite to 295 Ruby tests with 1,304 assertions, green on both Rubies with
`make ci` and Ruby coverage at 95.8%. It covers identity repair giving a copied occurrence and every
one of its Faces a fresh id while the Zone it came from and that Zone's pairs stay byte-identical,
the copied pair retiring, copied `user_data` and extension payloads surviving with the unremapped
references disclosed, refusal when the identity is already unique or the copy sits in shared
component storage, and Restore regrouping stamped members, recovering only id, Building-Segment and
Level, disclosing the rest, reverting in one Undo, and refusing conflicting stamps, mixed parent
contexts and an id already back in the Model. P1-A's host probe already measured the Restore
mechanic itself; the native checks for these two operations wait with the rest of P1-D, and
[`tools/examples/authoring/repair_walkthrough.rb`](../../tools/examples/authoring/repair_walkthrough.rb)
is checked in so that gate can be run as soon as Ed is at the bridge. One step in it needs Ed at
the viewport: how SketchUp copies a Group is the thing being measured, so the walkthrough asks for
a Ctrl-drag copy rather than scripting an assumption about it.

P1-C passes 260 Ruby tests with 1,175 assertions, 116 JavaScript tests and 84 Python tests.
Coverage is 95.6% Ruby, 97.7% JavaScript and 97.5% Python. The pinned development composition
reloaded the exact two-Zone HBJSON with reconciled identifiers, one reciprocal Surface pair and
hand-checked areas and volume. SketchUp 26.1.188 verified the measured plane and angle boundaries,
stale state, explicit retirement, no-op repeat solve, native Undo/Redo and fresh-process reopen.
See the [P1-C evidence](evidence/p1-c-adjacency-hbjson.md). The signed P1-C commit and full
post-commit CI close this branch slice; merge remains pending.

## Ledger

| Date | Event |
| --- | --- |
| 2026-09-20 | Post-merge planning refresh. Added staged delivery and feature plans, recorded foundation gaps and carried B1/B2 consequences into Phase 1. At this checkpoint, implementation remained unauthorized. |
| 2026-09-20 | Ed deferred METr exporter development and consumer acceptance until further feature development. Phase 1 closes on canonical HBJSON/report; return milestone unscheduled. |
| 2026-09-20 | P1-A complete: entity schemas and compound-operation/export snapshot contracts bound; native geometry probe passed on SketchUp 26.1.188. No Zone/face feature code landed. |
| 2026-09-20 | P1-B complete: compound proposals, entity stores, Zone/Face public operations, minimal Overview UI and public walkthrough landed; current-host Undo/Redo and reopen passed. |
| 2026-09-20 | P1-C complete on the implementation branch: whole-wall adjacency and stale/retire lifecycle passed in SketchUp; registered Zone/face sections produced and reloaded the exact pinned-stack HBJSON. |
| 2026-09-20 | P1-D D1: Classify became a bounded, deduplicated, all-or-nothing gesture; Zones' retire_pair participant became the plan-returning retire_pairs; Suggest classification and Reverse face landed. |
| 2026-09-20 | P1-D D2: the Attached zone record kind, its reference lifecycle on a Face, and delete with an explicit replacement landed. |
| 2026-09-20 | P1-D D3: explicit copied-Zone identity repair and limited Restore Zone landed, with the restore offer and its disclosed losses on the Zones read. |
