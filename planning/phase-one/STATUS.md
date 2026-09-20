# Phase 1 status

DATE: 2026-09-20
STATUS: In progress. P1-A through P1-C complete on the implementation branch; P1-D is authorized, with D1 to D6 implemented and D7 remaining.
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
- P1-D is authorized. Its slices are tracked in [PLAN.md](PLAN.md); D7 remains. See "What D4 left open" in the plan for the two shapes the solver reports rather than cuts.

## Stages

| Stage | State | Completion evidence |
| --- | --- | --- |
| P1-A: geometry contracts and host investigation | Complete | [Contract](CONTRACTS.md); [host evidence](evidence/p1-a-geometry.md); A01 met |
| P1-B: Zone and face authoring core | Complete | [Authoring evidence](evidence/p1-b-authoring.md); A02/A03 and the P1-B portion of A04 met |
| P1-C: adjacency and early HBJSON proof | Complete on branch | [Adjacency/HBJSON evidence](evidence/p1-c-adjacency-hbjson.md); A10 and P1-C portions of A05/A11 met |
| P1-D: complete Phase 1 authoring UI and repairs | In progress | D1 to D6 implemented; the offline portions of A04, A06, A07 and A08 pass and D4's host gate passed. Slice table in [PLAN.md](PLAN.md) |
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
Level, disclosing the rest, reverting in one Undo, and refusing on the complete contract set:
conflicting stamps, mixed parent contexts, an id already back in the Model, and a bounding Edge
shared with geometry nobody stamped. P1-A's host probe already measured the Restore
mechanic itself; the native checks for these two operations wait with the rest of P1-D, and
[`tools/examples/authoring/repair_walkthrough.rb`](../../tools/examples/authoring/repair_walkthrough.rb)
is checked in so that gate can be run as soon as Ed is at the bridge. One step in it needs Ed at
the viewport: how SketchUp copies a Group is the thing being measured, so the walkthrough asks for
a Ctrl-drag copy rather than scripting an assumption about it.

P1-D D4 brings the offline suite to 343 Ruby tests with 1,444 assertions, green on both Rubies with
`make ci` and Ruby coverage at 96.0%. The pure overlap geometry is covered case by case: full,
partial, contained, disjoint, off-plane, both sliver thresholds independently, a sliver left behind
by an otherwise acceptable cut, same-normal overlapping Zones, a holed Face, concave outlines, and
winding independence. The solver is covered for whole-scope pairing, the Q18 refusal naming both
Zones, a retry that includes them, an unscoped neighbour still being read, and each reported case.
The cut
is implemented: a partial overlap is cut on both sides and paired on the shared pieces only, with
the remainder keeping its own classification, payloads following every piece, the piece holding the
native persistent id keeping its Face id, a region covering a whole Face needing no cut at all, and
a failure on the second side leaving neither Face cut. A bounded review found and the slice fixed
three things: Q17's area floor was applied to the summed remainder rather than per Face the host
will make, so a cut leaving two under-floor pieces could pass; Q19 was decided after the size of
the shared region, so a same-normal sliver was reported as an ordinary skip; and a Face still
holding a Surface pair could be cut, stripping that pair and leaving its counterpart naming a Face
that was gone. A Face meeting more than one neighbour, a
concave outline and a holed Face stay reported rather than cut; see "What D4 left open" in
[PLAN.md](PLAN.md). The offline stub models a Face split to make the record consequences testable
and is not evidence about SketchUp; the host gate is outstanding.

P1-D D5 brings the offline suite to 370 Ruby tests with 1,530 assertions, green on both Ruby 3.2.2
and the 2.7.2 compatibility floor, with `make ci` green and Ruby coverage at 96.2%. It adds the
shared Colour-by service as a fourth contribution seam: `FeatureScope#colour_mode`, a per-Model
service held as generic session feature state, one `Sketchup::Overlay` drawing a cache batched one
call per legend row, the viewport HUD legend, and the native Colour by menu built from whatever
modes are registered. Face assignment registers face type and boundary condition in honeybee's own
hues; Zones registers Zone, Building-Segment and Level on the shared categorical ramp. The offline
checks cover an outside feature registering a mode with no branch in the shared renderer, a mode
missing its colour function refusing the whole batch, the unclassified and incomplete states, a
Zone mode reaching a Group nested inside the Zone, hidden geometry and hidden tags leaving the
drawing, per-colour batching, the overlay's whole lifecycle including model detach, a committed
change rebuilding once a revision, a tag rebuilding without one, and a mode turning on without a
record write or an Undo entry. A bounded independent review found and the slice fixed three
things: the overlay teardown read `overlays` off a Model that had already closed, where the real
close path reaches feature state after the Model is gone; the new tag observer was attached and
never removed, so a reload cycle would stack observers and rebuild once per copy; and a mode's
projection raising propagated out of the host observer, which would have skipped every subscriber
registered after Colour-by. The review also found that no fixture used a non-identity
transformation, so the world-space composition the whole overlay rests on was unverified; it is
covered now by a translated Zone holding a translated nested Group. No host gate ran; its
questions and the three unmeasured assumptions behind them are in "What D5 left open" in
[PLAN.md](PLAN.md), and
[`colour_by_walkthrough.rb`](../../tools/examples/authoring/colour_by_walkthrough.rb) asks each one.

D6's two measurements ran on SketchUp 26.1.188 on 2026-09-20, before any of D6 was built, because
both of them decide how it is built. The gesture ceiling was re-measured on the host it will run
on and holds as a bound on blast radius, with the over-limit refusal costing 3.6 ms; it cannot
bound elapsed time, which depends on the Model as much as the gesture. Occurrence resolution costs
O(targets x Model Faces) and is about half of a gesture's total. `face_assignment.list` is
separately quadratic in Face count, which nothing had measured and which D7's table depends on.
Ed took the recommendation, and `Zones::Index` implements it: one lazily-built walk of a Model,
reused for the length of a read phase and passed as an optional keyword, so a call that does not
ask for one is unchanged. Re-measured on the same host and fixture, the 250-target gesture fell
from 10,368 ms to 182 ms, the 50-target gesture from 3,352 ms to 164 ms, and the Face read from
12,764 ms to 205 ms. The ceiling stays at 250. No mutating step takes an index; the offline suite
pins the property that the Model is walked a fixed number of times however many Faces a gesture
names. See [the gesture cost evidence](evidence/p1-d-gesture-cost.md).

P1-D D6 brings the offline suite to 412 Ruby tests with 1,658 assertions, green on both Ruby 3.2.2
and the 2.7.2 compatibility floor, with `make ci` green and Ruby coverage at 96.4%. It adds the
Classify tool, the shared `core/` pick and drag primitives Spaces' Mark floor will reuse, Locate,
and a fifth contribution seam. The tool calls D1's operation through the public interface with its
own caller handle and sequence numbers and opens no Model operation itself, so an abandoned gesture
writes nothing and one completed gesture is one Undo step. A pointer move costs no Model walk:
`Occurrences.occurrence_for_path` builds the occurrence from the picked instance path.

The seam was not planned and was added because the palette could not be built without breaking a
contract. It began as a table in `shell/commands.rb`, which named a feature and put honeybee's
glossary words in a second place; `context/EXTENSIBILITY.md` requires that nothing in `shell/` or
`session/` name a feature. A feature now declares `menu_item` as it declares a Colour-by mode, and
`shell/` builds the Extensions submenu and the viewport context menu from whatever is registered.

The offline checks cover a click, a drag and a Shift-click as one gesture and one Undo step each,
the flood stopping at the plane, every cancel route writing nothing, a drag across empty space
painting both ends of it rather than refusing, a press whose release never arrives collecting
nothing afterwards, the over-ceiling refusal, the palette frozen at button-down and surviving the
tool, Q12 forcing a mode on without remembering it and releasing only the mode it forced, a Face
inside a nested Zone belonging to the inner Zone, a picked path composing the same world transform
and the same shared-storage answer as a walk, Locate skipping a reference the Model no longer has,
an outside feature reaching the native menus through the new seam with no line in `shell/`, and
the palette offered on a right-click only where a Face is under the cursor, by the selection with
no tool running and by the tool's own `getMenu` while one is.

A bounded independent review found and the slice fixed six things. A Face inside a Zone nested in
another Zone was attributed to the outer Zone, which the resolver accepts because it descends a
Group without checking for a Zone record, so the gesture would have stamped that Face with the
wrong Zone. A press whose release the host never delivered left the tool collecting, so ordinary
hovers piled into the pending gesture and the next release wrote them. A drag across empty space,
which is any Zone with a window opening or a gable, refused the whole gesture and told the user
something untrue about a Face they never pointed at. Stopping the tool turned off a Colour-by mode
the user had chosen while it was running. A failing hover noticed once per pointer move rather than
once. And `shell/commands.rb` named a feature and carried its words, which is the contract
violation the new seam removes. The review also found the Shift flood unbounded by the gesture
ceiling, now stopped one past it.

No host gate ran. The gesture is the part of it no script can perform, so
[`classify_tool_walkthrough.rb`](../../tools/examples/authoring/classify_tool_walkthrough.rb) arms
the tool and asks Ed to drag; its nine questions and the four unmeasured assumptions behind them
are in "What D6 left open" in [PLAN.md](PLAN.md). D1's two deferred native checks, one drag over
forty Faces in one Undo and a gesture of 251 refusing in the viewport, are in the same walkthrough.

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
| 2026-09-20 | P1-D D4 part one: pure overlap geometry with remainder thresholds, whole-scope Solve, the Q18 out-of-scope refusal and a finding for every case the solver will not pair. The geometry cut remains. |
| 2026-09-20 | P1-D D4 part two: partial overlaps are cut on both sides and paired on the shared region only, under the split rules, in one aborting step. |
| 2026-09-20 | P1-D: `Zones::Index` gives each read phase one walk of the Model instead of about two per target. The 250-target gesture went from 10.4 s to 182 ms and the Face read from 12.8 s to 205 ms, both re-measured on the host. |
| 2026-09-20 | P1-D D6's two measurements ran on the host: the gesture ceiling holds as a blast-radius bound, the cost is O(targets x Model Faces) in occurrence resolution, and the Face read turned out to be quadratic on its own. No code changed; the fix is Ed's call. |
| 2026-09-20 | P1-D D5: the shared Colour-by seam, its overlay, HUD and cache invalidation, with face-assignment and Zone modes registered through the public call. |
| 2026-09-20 | P1-D D6: the Classify tool, the shared pick and drag primitives, Locate, Q12 forcing, and the `menu_item` seam a feature reaches the native menus through. |
| 2026-09-20 | The Ground suggestion was corrected to honeybee's rule after the host gate showed it setting five of a plain box's six Faces to Ground. |
