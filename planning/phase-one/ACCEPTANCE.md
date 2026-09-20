# Phase 1 acceptance register

DATE: 2026-09-20
STATUS: In progress. P1-A through P1-C have evidence and P1-D D1/D2 met offline portions of A04 and A07; remaining active rows are pending. A15 is deferred outside Phase 1 by Ed.
ISSUE: none (local planning draft)

Record a source-controlled evidence summary per completed stage with commit/build, fixtures,
checks, exact host versions and remaining limits. Keep SKP files and captures in `_private/`.
The owning PRDs supply the detailed cases; this register supplies the closure gates.

| ID | Owner/stage | Required evidence | State |
| --- | --- | --- | --- |
| A01 | Zones / P1-A | Versioned entity records and geometry proposal contract; split/group/explode/tolerance host investigation; no unsupported host premise left implicit | Pass 2026-09-20: [contract](CONTRACTS.md), [evidence](evidence/p1-a-geometry.md) |
| A02 | Zones / P1-B | Make Zone on selected group and loose geometry; wrappers and forbidden hierarchy; independent copy identities; correct occurrence references and SI geometry | Pass for P1-B 2026-09-20: [evidence](evidence/p1-b-authoring.md) |
| A03 | Shared operations / P1-B | Panel-closed discover/read/preview/write/read-back; stale/wrong-model refusal, retry outcome, unknown rollback outcome; geometry plus record creation/update/deletion atomic under injected failure, with truthful rollback results | Pass 2026-09-20: [evidence](evidence/p1-b-authoring.md) |
| A04 | Faces / P1-B/D | Keep/set/clear intent, suggestions, Ground depth, atomic Classify gesture at the accepted target limit and refusal at limit + 1; Auto-classify only unrecorded faces in one Undo step; Reverse face and metadata preservation | Offline portion passes 2026-09-20 in P1-D D1: gesture at the 250 limit and refusal at 251, refusal driven by reciprocal retirement targets, deduplication, all-or-nothing rollback, Auto-classify touching only unrecorded Faces in one step, and Reverse keeping the record. The Classify tool gesture itself (D6) and every native check remain pending, as does the host re-measurement of the limit |
| A05 | Zones / P1-C/D | Whole/partial matches, holes/transforms; measured plane-offset and normal-angle boundaries distinct from point coincidence; sliver and same-normal skips; explicit scope refusal; pair retirement, deleted versus ambiguous endpoints; unchanged solve has no Undo entry | P1-C subset passes 2026-09-20: whole-wall pair, measured tolerances, stale/retire lifecycle and no-op repeat solve. Scope refusal, sliver and same-normal skips and the multiple-neighbour report pass offline 2026-09-20 in P1-D D4, with the shared region and every remainder threshold-checked before any cut. The partial-overlap cut itself is not implemented: it reports and pairs nothing. Split, ambiguity and native cases remain. [Evidence](evidence/p1-c-adjacency-hbjson.md) |
| A06 | Zones / P1-D | Explode/limited Restore, copy/split/cut-paste references; explicit identity repair changes copied UUID/stamps and retires copied pairs while preserving original pairs; ambiguity refuses; disclosed unrecoverable fields; native Undo/Redo and fresh reopen preserve records and reference meaning | Offline portion passes 2026-09-20 in P1-D D3: identity repair reidentifies the copy and its Faces, retires the copied pair, leaves the original pair untouched, preserves payloads with unremapped references disclosed, and refuses a unique identity or shared storage. Restore recovers id, Building-Segment and Level, discloses the rest, reverts in one Undo, and refuses on the complete contract set: conflicting stamps, mixed contexts, an id in use, and a bounding Edge shared with unstamped geometry. Split and cut-paste references belong to D4; native Undo/Redo and fresh reopen remain pending |
| A07 | Faces / P1-D | Attached-zone local creation/edit/replacement/delete rules including delete/reassign failure rollback and Undo; references and unknown extension data preserved or safely refused as the PRD requires | Offline portion passes 2026-09-20 in P1-D D2: create, edit with stale-value refusal, duplicate, absent/dangling/resolved reference states, delete with a replacement record or an explicit boundary condition, refusal on a missing replacement, and one-step Undo. Inline creation and its cancellation arrive with the UI; native checks pending |
| A08 | Faces + Zones / P1-D | Shared Colour-by registration example, Zone modes, HUD/picking/occlusion, cache invalidation, model-switch cleanup, measured scale cost; materials and Undo history unchanged | Pending |
| A09 | UI owners / P1-D | Current-host Overview/tree/table, Auto-classify and Classify review; narrow layout, unit-switch drafts, focus/Escape/Enter, stable rows and active-edit-path behavior | Pending |
| A10 | Contributors / P1-C | Exact HBJSON reloads in pinned honeybee; Zone/face IDs, world geometry and reciprocal Surface targets reconcile; stale/withheld counterparts are accounted omissions | Pass 2026-09-20: exact pinned-stack reload, identifiers, SI geometry, reciprocal targets and blocking stale extraction verified. [Evidence](evidence/p1-c-adjacency-hbjson.md) |
| A11 | Export / P1-C/E | Fixture construction is deterministic, never a stored Assembly or fallback; normal RBZ cannot activate it; dangling construction references still block | P1-C subset passes 2026-09-20: provider is tools-only, absent from RBZ, and normal composition withholds Rooms. P1-E must retain this boundary in the final workflow. [Evidence](evidence/p1-c-adjacency-hbjson.md) |
| A12 | Export / P1-E | Destination cancel, warning/blocking runs, collection/translation cancellation, export-relevant edit refusal, camera/selection tolerance, no implicit SKP save; polling/result retention, timeout without implied cancellation, model close and client/panel loss | Pending |
| A13 | Export / P1-E | Canonical pair replacement/recovery failure matrix; report totals/privacy/escaping agree with result. Optional METr output/recovery deferred | Pending |
| A14 | Runtime / P1-E | Accepted HBJSON translation wheel manifest, sources/notices, installed footprint and real HtmlDialog translation; lazy boot, cancellation and teardown; pinned native/Pyodide comparison | Pending |
| A15 | Deferred METr milestone | Actual import, suffix, floor-area policy and consumer mapping to be re-scoped against available features when work resumes | Deferred; excluded from Phase 1 closure |
| A16 | Integration / P1-F | Both offline Ruby gates, coverage and browser/runtime checks; packaged inventory; fresh-process two-Zone authoring/export with nested edit path, two Models, Undo/Redo and reopen; host restart expires task handles and recovers staged artifacts without claiming an unknown run succeeded | Pending |

## Synthetic reference cases

Start with adjacent 5 x 4 x 3 m and 4 x 4 x 3 m boxes, without windows or Spaces. Expected
external floor and roof area is 36 m2 each, external wall area is 78 m2, and the common wall
is 12 m2 on each Zone. Use one Building-Segment, then separate Building-Segments to check the
HBJSON Building-Segment metadata. METr mapping waits for its deferred milestone. Geometric volume is 108 m3; this is a test oracle, not a Phius Vn50 value.

Add partial overlap, a rotated/scaled wrapper, mirrored placement, a face with a hole and an
unresolved pair as separate fixtures. Compare actual identifiers and reference targets after
save/reopen and HBJSON reload; matching counts alone cannot prove a correct round trip.

The B1 fixture includes a window and authored constructions. Reuse its runtime evidence, but do
not confuse that Python-generated model with proof of Phase 1's SketchUp authoring path.

## Completion boundary

All active rows must pass before Phase 1 closes on HBJSON/report. A15 and optional-METr portions
of the export PRD are deferred and do not block closure. No synthetic Space or derived iCFA is
needed to satisfy a deferred consumer gate.

Later assembly-dependent feature checks remain explicitly assigned to Phase 2 rather than counted
as passing here.
