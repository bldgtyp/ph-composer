# Phase 1 status

DATE: 2026-09-30
STATUS: P1-A through P1-F complete on the implementation branch for the named current-host scope.
Independent review, offline gates and fresh SketchUp acceptance pass. Merge and release remain separate.
ISSUE: none (local implementation packet)

## Current completion boundary

P1-E implements the canonical HBJSON/report task, panel workflow and eight pinned translation wheels.
P1-F verifies fresh two-Zone authoring, nested edit paths, native Undo/Redo, two Models, reopen,
restart recovery and task expiry. See [P1-E/F evidence](evidence/p1-e-export-workflow.md) for build,
checks and limits. The normal build requires authored Assemblies and safely refuses without them;
successful translation uses an explicit tools-only synthetic provider. METr, SketchUp 2023 and
Windows host proof, public distribution and certification remain separate gates.

## Completed native references and authoring work

The [2026-09-29 native reference run](evidence/p1-d-native-references.md) verifies cut/paste and
Line-split record survival, safe Solve refusal, exact Undo/Redo and fresh reopen. It exposed and
corrected a pasted Surface endpoint reading current despite its changed paths. The correction
passes both offline Rubies, full CI, coverage and independent review, with fresh installed-host
checks. Explicit Solve now recovers unique authored identities after cut/paste path changes,
with exact native rollback, Undo/Redo and fresh reopen. Copied split-Face UUID recovery now passes through the explicit public action and native Repair menu, with
[exact rollback, Undo/Redo and fresh reopen](evidence/p1-d-split-identity-recovery.md). The [extension-copy correction](evidence/p1-d-extension-copy-safety.md) now refuses unsafe
Face cuts and copied-Zone repair before writes, with supported catalog-reference payloads passing
native rollback, Undo/Redo and reopen. Ed accepted the split identity policy in [P1-Q5](DECISIONS.md#p1-q5-native-split-identity-frontier);
the stored-path/explicit-choice policy is implemented and current-host verified. [Face/Zone extension-reference targets](evidence/p1-d-entity-reference-targets.md) now pass native copy, split, Solve, rollback, Undo/Redo and reopen; independent review and its two resolver corrections pass. The
[clean multi-neighbour continuation](evidence/p1-d-multi-neighbour-adjacency.md) verifies coordinated
partitioning, reciprocal references, rollback, Undo/Redo and fresh reopen. The [atomic Attached-zone continuation](evidence/p1-d-attached-zone-atomic.md) verifies the public action, inline Enter/Escape, references, exact rollback, Undo/Redo and fresh reopen; A07’s named current-host cases pass. The [isolated GPU continuation](evidence/p1-d-gpu-timing.md) completes A08’s named current-host cases. The
[native adjacency boundary continuation](evidence/p1-d-adjacency-boundaries.md) verifies A05's
named current-host cases, including independent plane/angle controls, sliver/same-normal skips
and refusal when A–B would retire an existing B–C pair outside scope. The [Colour-by continuation](evidence/p1-d-colour-by-continuation.md) verifies
native Overlays-panel toggles, foreground occlusion, alpha and orbit; feature timing passes the
prior screening budget at 1,032 triangles. The
[hatch and invalidation correction](evidence/p1-d-hatch-and-invalidation.md) verifies the PRD hatch and immediate public-action cache updates, with a 91.969 ms hatch-generation median
at 1,892 triangles. Isolated GPU execution at 1,032 triangles adds 0.683 ms p95 on this host. The
[keyboard/context continuation](evidence/p1-d-keyboard-context.md) verifies layered Escape, quantity save/Undo/Redo and native-menu Classify state, with two
keyboard/lifecycle corrections fresh-host verified. Tree navigation, stable focus/drafts and
held-button Model/edit-context cancellation now pass; A09's named current-host cases are verified.

## Broader acceptance continuation

D7 fixes are committed and pushed as `a79ae4d`. The subsequent A05 to A09 host run is recorded
in [the broader acceptance evidence](evidence/p1-d-broader-acceptance.md). It adds transformed
holed adjacency, copy/repair persistence, limited Restore, Attached-zone rollback and replacement,
scene/tag invalidation, model-close cleanup and active-edit-path evidence. It also exposed
ancestor visibility, lost Zone drafts and missing stale-pair retirement; their fixes pass native
checks, `make ci`, coverage and the Ruby 2.7.2 suite. The record distinguishes the completed cases
from the remaining boundaries. The continuation records now complete the named current-host P1-D register.

## D7 gate continuation and corrections

The D7 handoff was executed with native computer use on 2026-09-26. Q1, Q7 and Q5's restart
checks are answered in [the evidence record](evidence/p1-d-overview.md). Six F7 reproduction
attempts stayed clean. F1 to F6 and F8 were corrected and rechecked in a fresh installed
SketchUp 26.1.188 process. Narrow-panel checks also found and corrected sticky headers and
compressed table columns. Native select-editor Enter and exact-reference Undo/Redo pass.
The final installed code passes `make ci`, `make coverage` and the Ruby 2.7.2 suite.

The handoff's restart premise needed correction: Colour by starts Off and remembers the mode
Classify will use, as the owning PRD specifies. A failing tessellation now clears the mode,
removes its overlay and displays a warning without replacing the last successful preference.

At 512 classified Faces, Ruby snapshot construction takes 39 to 47 ms. Discrete panel
interactions were usable. JavaScript paint was observed rather than timed. Rebuilding a full
snapshot on every pointer move is too expensive for hover-to-highlight; keep that feature
deferred until a cheaper path is measured. The existing Overview pane arrangement is retained;
Ed's pending arrangement decision has not been inferred from this verification work.

### Acceptance boundary

The older handoff said a docs pass would close P1-D. `PLAN.md` instead requires A04 to A09 to
have evidence. The named current-host cases now have that evidence, including A06's entity-reference
continuation. A fresh independent review of `4404527` found two resolver defects: proposal aliasing and
uncoded malformed-identity failure. Both are corrected, covered by regressions, and re-reviewed
by the same independent reviewer. Final CI, coverage, Ruby 2.7 and targeted fresh installed-host
checks pass. P1-D is complete on this implementation branch; release and floor-host acceptance
remain separate. P1-E subsequently completed the HBJSON/report workflow; see the current completion boundary above.

The historical [D7-GATE-HANDOFF.md](D7-GATE-HANDOFF.md) is retained as the procedure that was
executed, with its corrected assumptions noted at the top. Use the current evidence and
acceptance register for the next work.

## Current handoff

Phase 0 is complete and merged at `f1e9a98` through PR #1. The four investigations passed with
recorded conditions. P1-B installs the first building features: entity-owned Zones and Face
assignments, registered public operations and the minimal Overview authoring UI. P1-C adds
whole-wall adjacency, a shared detached geometry snapshot, registered Zone/face contributors and
the first typed Honeybee model sections. P1-E completes the user workflow and shipped translation
wheels, with normal composition refusing missing authored Assemblies before destination selection.
P1-A completed on 2026-09-20 under Ed's implementation instruction. It produced the
[geometry/persistence contract](CONTRACTS.md), a reusable native probe and
[current-host evidence](evidence/p1-a-geometry.md). P1-B completed on 2026-09-20 with
[authoring evidence](evidence/p1-b-authoring.md) and a checked-in public-operation walkthrough.

The [plan](PLAN.md) starts with the geometry/storage contract and native evidence needed by
Make Zone and Solve adjacencies. P1-D completes the Phase 1 authoring behavior; P1-E/F complete
the export and integrated current-host acceptance. Later feature scope remains in its owning packets.

METr exporter implementation and consumer acceptance are deferred by Ed on 2026-09-20.
Phase 1 now closes on HBJSON/report; the later METr milestone is unscheduled.

## Remaining delivery boundaries

- [DECISIONS.md](DECISIONS.md) records the accepted Phase 1 choices. METr development and its
  floor-area/import questions remain deferred. The HBJSON wheel set is shipped and verified.
- Create/link the implementation issue during authorized issue intake. The configured remote is
  `bldgtyp/ph-composer`; P1-A created no external issue or PR.
- All six Phase 1 stages are complete on branch. Merge, floor-host/platform proof and public distribution require their own gates.

## Stages

| Stage | State | Completion evidence |
| --- | --- | --- |
| P1-A: geometry contracts and host investigation | Complete | [Contract](CONTRACTS.md); [host evidence](evidence/p1-a-geometry.md); A01 met |
| P1-B: Zone and face authoring core | Complete | [Authoring evidence](evidence/p1-b-authoring.md); A02/A03 and the P1-B portion of A04 met |
| P1-C: adjacency and early HBJSON proof | Complete on branch | [Adjacency/HBJSON evidence](evidence/p1-c-adjacency-hbjson.md); A10 and P1-C portions of A05/A11 met |
| P1-D: complete Phase 1 authoring UI and repairs | Complete on branch | D1 to D7 implemented; the offline portions of A04, A06, A07, A08 and A09 pass. D4 and D6 host gates passed; D7's eight questions are answered and fixes rechecked. A04 to A09 named current-host cases have evidence; the final entity-reference implementation and review corrections pass independent review, final gates and targeted fresh-host checks. Slice table in [PLAN.md](PLAN.md) |
| P1-E: HBJSON/report export workflow | Complete on branch | [Export evidence](evidence/p1-e-export-workflow.md); A11 to A14 pass for the accepted scope |
| P1-F: acceptance and handoff | Complete on branch | [Integrated evidence](evidence/p1-e-export-workflow.md); A16 passes on SketchUp 26.1.188 |

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
and is not evidence about SketchUp. The later [native cut gate](evidence/p1-d-repairs-and-cut.md) supplies that evidence.

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

P1-D D6 brings the offline suite to 414 Ruby tests with 1,675 assertions, green on both Ruby 3.2.2
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

D6's host gate ran on 2026-09-20 with Ed at the mouse, because SketchUp delivers pointer events to
the active tool and the Ruby API synthesizes none. It passed, after eight findings were fixed and
re-verified in the same session. One sweep over forty Faces is one gesture and one native Undo step
named "Undo Classify Faces"; Shift-click takes a whole plane and stops at it; an over-ceiling
gesture refuses whole with its reason in the status bar; Escape cancels; a click inside an open
Zone paints; the palette appears on a right-click over a Face and not over a Zone Group; picking a
native tool deactivates the tool and releases the mode it forced; and Locate resolves and selects.
That also closes D1's two deferred native checks. See
[the Classify tool evidence](evidence/p1-d-classify-tool.md).

Three of the eight findings were defects no offline test could have caught, because the stub was
wrong about the host where it mattered. `PickHelper#path_at` answers relative to the open edit
context, so inside a Zone every Face read as being in no Zone, which is where a user works most of
the time. `OverlaysManager#add` leaves an overlay disabled, so Colour-by reported itself active,
built its cache and drew nothing at all on a real SketchUp; that is a D5 defect that shipped in
that slice and survived its own review, because D5's host gate had not been run. And a fill drawn
exactly on the Face it colours z-fights with it, so both the tool's tint and Colour-by's fills
blinked; every drawn point is now lifted toward the camera. The rest: a refusal reached only the
panel, which is closed while a viewport tool is in use; `Model#active_tool` does not exist on the
host; the context menu tested for a selected Face where a root right-click selects the Group;
`CONSTRAIN_MODIFIER_MASK` is 131072, not 1; and the walkthrough's cleanup missed renamed Zones.
Every one is recorded in [`context/SKETCHUP_HOST_BEHAVIOR.md`](../../context/SKETCHUP_HOST_BEHAVIOR.md).

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

P1-D D7 brings the offline suite to 439 Ruby tests with 1,753 assertions, green on both Ruby 3.2.2
and the 2.7.2 compatibility floor, with `make ci` green, Ruby coverage at 96.5% and JavaScript at
97.9%. It builds the Overview screen the phase has been working towards: the Zone tree with each
Zone's classified Faces beneath it, editable type and boundary chips guarded by the values each row
painted from, Locate on both tiers, Suggest classification from a Zone row, the Colour-by legend
with click-to-select-and-zoom and "Show only this", and the Classify tool's palette with its
Attached zone picker and inline New route.

It added a sixth contribution seam, `view_command`, because the legend forced the question D5 left
open: what channel a client uses for something that changes what the host shows and never the Model.
A view command carries no sequence and no expected revision, needs its own `view` capability, and
opens no operation. Locate, the Colour-by mode switch, the legend's row selection and isolation, and
the Classify palette are the first six.

`table.js`, `table.css` and `view_controls.js` are ported from the predecessor and trimmed to what
this screen uses, which is what makes the Spaces and Assemblies tables a port rather than a rewrite.
Neither names a feature. Two independent reviews ran, one on the seam and one on the screens.

The Face read now carries the state every surface shows a Face by, unclassified, incomplete or
classified, derived where the record is so the table and the overlay cannot disagree.

The D7 host continuation and fixes are recorded in [the Overview evidence](evidence/p1-d-overview.md). Hover-to-highlight, the fourth legend affordance Q18 names,
is deliberately not built: Ed chose on 2026-09-20 to measure its cost rather than ship it unmeasured.
