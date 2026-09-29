# Phase 1 delivery plan

DATE: 2026-09-25
STATUS: P1-A through P1-C complete on the implementation branch. P1-D is authorized and in progress; D1 to D4 are implemented.
ISSUE: none (local planning draft)

## Outcome and scope

Draw two adjacent boxes in SketchUp, make them Zones, classify their faces, solve their shared
boundary and export a canonical HBJSON/report pair. Reload the exact HBJSON in the pinned
honeybee stack and check it against hand-calculated geometry.

Ed deferred METr exporter development and import acceptance on 2026-09-20 until feature
development is further along. Its return milestone is unscheduled. Phase 1 requires no PHX
integration, METr artifact handling or no-Spaces consumer workaround.

The construction used for this proof is deterministic and development-only. A normal packaged
build refuses missing authored constructions. This phase is an engineering milestone; real
assemblies arrive in Phase 2, Spaces in Phase 3 and mechanical systems in Phase 4. No iCFA or
Vn50 is inferred from Zone geometry to fill the temporary gap.

The first end-to-end proof uses whole-face adjacency and a small authoring UI. Phase 1 closes
only after partial overlaps, repair/reference lifecycle, Colour-by and the export failure paths
meet the owning PRDs. The implementation may overlap feature owners in this order without
calling their packets complete prematurely.

## What Phase 0 actually supplies

Paths below are relative to `src/ph_composer/` unless stated otherwise. This is a planning
baseline at `f1e9a98`, not a substitute for the durable contracts in `context/`.

| Existing implementation | Reuse | Phase 1 work still required |
| --- | --- | --- |
| `shell/api.rb`, `dispatch.rb`, registry and declarations | Discovery, schema validation, session targeting, preview/invoke/outcome, stale and duplicate-request handling | Geometry-aware proposals, preconditions and rollback verification; retain record-only compatibility |
| `core/records/engine.rb`, `change_set.rb`, `dictionary_store.rb` | Record validation, metadata, extension/reference rules, injectable record stores and Model-level definition storage | Entity-owned Zone/face stores and occurrence resolution; deletion/retirement and geometry edits are not existing ChangeSet capabilities |
| `session/model_session.rb`, `host_observers.rb` | Per-Model state, events, revision and lifecycle | Feature reconciliation, endpoint/geometry stamps, copy ambiguity and cache invalidation |
| `html/` panel sections, request channel, forms and units | One client of the public operations | First model tree/table, table drafts/preferences deferred by P0-E, feature navigation and viewport tool state |
| `export/collection.rb`, record reader, privacy, report and artifact pair | Contributor declarations, allowlist and recoverable pair primitives | Bounded geometry collection, coherent snapshot guard, cancellable task/run coordinator and optional-artifact recovery |
| Python section coordinator and exporter registry | Typed dependencies, result accounting and HBJSON-only exporter isolation; P1-C adds Zone/face sections and early honeybee model assembly | P1-E completes the user export workflow and shipped runtime composition; METr remains deferred |
| Runtime host, server and manifest | Separate token-origin runtime page, lazy boot and integrity checks | HBJSON translation wheel set, loader and real translation requests; refresh manifest and measured footprint; PHX payload deferred |

The [foundation example](../../tools/examples/foundation/README.md) is the entrypoint pattern.
The [P0-E](../archive/phase-zero/evidence/phase-04-panel-units.md) and
[P0-F](../archive/phase-zero/evidence/phase-05-runtime.md) records identify deferred work.
Do not port an entire predecessor subsystem merely because its name appears in the target layout.

## Ownership and dependency direction

- Zones owns Zone identity, hierarchy, occurrence resolution and adjacency proposal/apply/retire.
  Pure SI overlap calculations stay separate from SketchUp geometry access.
- Face assignment owns classified-face values, Attached zones, field-level edit intent and the
  Colour-by contribution contract. It composes Zones' pair-retirement proposal in the same
  operation when a Surface condition changes. Zones must not depend on the face editor.
- Export owns run state, validation aggregation and canonical artifact handling. The same packet
  retains ownership of the deferred METr exporter.
  Features own their extraction, findings and Python sections. Export orchestration names no feature.
- Shared code owns only contracts several features need. Registration in Ruby/Python composition
  roots is permitted. Feature-specific branches in shell/session/export/UI-kit internals are not.

Resolve the Zone/face schema dependency in P1-A: Zones owns pair endpoints and reciprocal state;
face assignment owns type, boundary intent and construction reference. Define how a split or
retirement preserves the face fields through a declared operation participant, without requiring
Zones to call face editor internals. The same participant contract must work from a script.

## P1-A: geometry contracts and host investigation

**State:** Complete 2026-09-20. See [contract design](CONTRACTS.md) and
[native evidence](evidence/p1-a-geometry.md). No building feature was implemented.

**Depends on:** explicit implementation authorization, received 2026-09-20. No building feature
is assumed present.

Before dependent implementation, add a bounded contract design to the Zones plan with:

1. Versioned Zone, face-assignment, Attached-zone and adjacency endpoint schemas. Name the entity
   dictionary owner, durable id, occurrence path, reference targets, SI fields, metadata rules
   and how copied/split records are distinguished. Zone and adjacency storage must remain on
   their owning entities as the PRD requires; a Model-level adjacency table is not a shortcut.
2. A generic operation proposal extension for geometry plus record create/update/delete. Define
   store deletion, reference-usage checks, deleted affected-result entries and before-images for
   rollback/Undo. Attached-zone delete-with-replacement must commit reassignment and deletion
   together. State the immutable
   preview, revision/edit-path preconditions, explicit mutation scope, temporary identities for
   newly created entities, validation order and one transaction owner. Record-only clients retain
   their behavior. Reads and preview perform no repair or geometry mutation.
3. Commit-time resolution and failure verification covering both topology and attributes. Refusal
   writes nothing; failed application aborts the whole operation. If unchanged state cannot be
   verified, preserve the existing `effect: unknown` outcome rather than claiming rollback.
4. Feature-owned reconciliation and export geometry access through declared contracts. Collection
   today exposes records, so specify how one bounded snapshot supplies world geometry and stable
   references without rescanning the Model per contributor.

Run a synthetic host investigation for coplanar split/identity/dictionary behavior, Make Zone
grouping, explode/limited restore and closure. Include wrappers, scale/mirror, holes, tolerance
boundaries, native Undo/Redo and save/reopen. Record measured tolerances before implementing the
solver. The Phase 0 edge spike is evidence about edges; it does not prove face-split semantics.

**Exit:** met on the proving host. The contract binds entity schemas, occurrence resolution,
compound proposals, rollback evidence and the shared export snapshot. Group/split/explode/Restore,
holes, closure, nested scale/mirror, Undo/Redo, 0.001 in native tolerance and save/reopen were
measured. SketchUp 2023 and Windows remain support gates. This stage adds no plugin framework or
external agent adapter.

## P1-B: Zone and face authoring core

**State:** Complete 2026-09-20. See [acceptance evidence](evidence/p1-b-authoring.md).

**Depends on:** P1-A. Owners: Zones, face assignment.

Implement the approved entity stores and operation support, then Make Zone, Zone details and
focused queries. Register schemas and actions through feature `install` entrypoints. Add face
reads/classification with explicit occurrence references, Zone stamps and keep/set/clear intent.
The initial UI supplies Make Zone and the minimum face type/boundary controls for the proof;
scripts can perform the same operations with the panel closed.

Check explicit model/revision targeting, copy identity, metadata preservation, wrong hierarchy,
native Undo/Redo and save/reopen before layering adjacency onto these records. Ground depth and
world-normal suggestions use SI geometry; UI units only affect display/input.

**Exit:** two authored Zones and their faces survive reopen; UI and script reads agree. No
construction or thermal-performance claim is made. The public-operation walkthrough is checked in.

## P1-C: adjacency and early HBJSON proof

**State:** Complete 2026-09-20 on the implementation branch. See
[acceptance evidence](evidence/p1-c-adjacency-hbjson.md).

**Depends on:** P1-B, the development-fixture decision and accepted runtime pins for real
translation. Owners: Zones and export contributors.

Start with a full shared wall. Before accepting the solver, measure and bind separate plane-offset
and normal-angle criteria for adjacency; P1-A's point-coincidence result does not establish either.
Preview and solve through explicit Zone occurrence references;
record reciprocal endpoints and geometry stamps, and make a second unchanged solve a no-op.
Move a Zone, observe stale state without repair, retire/re-solve and check the references.

Add Zone and face extraction/translation sections with explicit typed dependencies. Construct
Rooms and Faces without a circular section dependency, then resolve Surface references only
among emitted objects. Load the exact HBJSON back into the pinned honeybee stack and verify
identities, boundary conditions, world geometry and complete result accounting.

Use an explicitly selected development composition for the fixture construction. Do not place it
in the SKP or admit it as a default when lookup fails. The package check must demonstrate that the
normal build cannot invoke it. A development script may drive this early export proof through
the shared pipeline before the complete Export UI lands; it does not satisfy the final host gate.

**Exit:** a two-Zone HBJSON proof with reconciled references and no dangling Surface target.
METr conversion and import are deferred; neither is required for this gate.

## P1-D: complete Phase 1 authoring behavior

**State:** In progress, authorized 2026-09-20. Delivered in slices so each lands with its own
focused tests; the stage closes only when A04 to A09 all have evidence.

| Slice | Delivers | State |
| --- | --- | --- |
| D1 | Bounded Classify gesture and its ceiling, Suggest classification for this Zone, Reverse face | Implemented on branch |
| D2 | Attached zone record kind, reference lifecycle and guarded delete with replacement | Implemented on branch |
| D3 | Explicit copied-Zone identity repair and limited Restore Zone | Implemented on branch |
| D4 | Partial-overlap splitting, sliver skips and out-of-scope reciprocal refusal | Implemented on branch |
| D5 | Shared Colour-by registry, overlay, HUD and cache invalidation | Implemented on branch |
| D6 | Classify `Sketchup::Tool`: drag collection, Shift-click, frozen palette intent, Escape and Locate | Implemented on branch |
| D7 | Overview Zone tree, faces table, panel legend and panel palette | Implemented on branch |

D6 is the gesture itself, distinct from D1's operation. A04's atomic-gesture row needs both.

### What D4 left open

The cut is implemented. `Zones::Overlap` settles every candidate, sliver, same-normal,
unsupported-shape and remainder-threshold case in pure SI geometry; the solver applies a whole
scope with the Q18 out-of-scope refusal; and a partial overlap is cut on both sides and paired on
the shared pieces only, in one step, with the split rules from [CONTRACTS.md](CONTRACTS.md)
deciding which piece keeps its Face id.

Two things remain open and are deliberate, not oversights:

- **A Face meeting more than one neighbour is reported, not cut.** It needs one cut per neighbour
  and the solver does one. This is a normal multifamily shape, a wall against two stacked Zones,
  so it should not stay open indefinitely. Revisit it when such a model needs it.
- **A concave outline and a Face with a hole are reported, not cut.** A cut needs both outlines
  convex, because the remainder of a concave Face is a shape the solver will not decompose. Both
  still pair on a full match, which cuts nothing. Windows arrive in Phase 2 and will put holes in
  real walls, so the holed case needs an answer before an assembly-bearing model relies on it.

The [native cut gate](evidence/p1-d-repairs-and-cut.md) records persistent-id survival,
dictionary preservation, the contained-region hole and one-step Undo/Redo. The offline stub
models a Face split so the record consequences can be tested; it is not evidence about SketchUp.

D6's occurrence-resolution cost was measured on the proving host and then fixed: see
[P1-D gesture cost](evidence/p1-d-gesture-cost.md). Resolution was O(targets x Model Faces),
because `resolve_face` walked the whole Model through `resolve_zone` and again through
`faces_with_id`, about twice per target, and `retire_pairs` resolved each counterpart the same
way. `Zones::Index` is one lazily-built walk reused for the length of a read phase, threaded as an
optional `index:` keyword; a call that does not pass one behaves exactly as before. Four read
phases opt in: the Face read, a gesture's target resolution, Auto-classify, and the
resolve-everything-first half of `ClassifyStep#apply`. **No mutating step may be given one**, and
none is: a step that cuts geometry has to see what it just did.

Measured on the same host and fixture, a 250-target gesture at 2,004 Faces fell from 10,368 ms to
182 ms, and the curve went flat in target count. The Face read had the same defect by another
route, through `Adjacency.state` resolving every Surface Face's counterpart, so the same patch
took it from 12,764 ms to 205 ms; that is the read D7's faces table is built on. The ceiling stays
at 250 and keeps its own job, which is bounding what one gesture can change; its refusal still
costs 3.6 ms, before anything is resolved.

### What D7 left open

The Overview screen is built on the predecessor's record table rather than on a list of cards:
`table.js`, `table.css` and `view_controls.js` are ported and trimmed to what this screen uses. The
columns, rules and controls that named Spaces' own data went back; they return when a screen needs
them. Neither module names a feature, which is what makes the Spaces and Assemblies tables a port
rather than a rewrite.

The slice added a sixth contribution seam, `view_command`, because the panel legend forced the
question D5 left open. Turning a Colour-by mode on, Locate, showing one legend row on its own and
setting a Classify chip all change what the host shows and never the Model. A query cannot carry
them (`context/AGENT_INTERFACE.md`: a read never changes the camera or the selection) and an action
cannot either (an action's contract is a named native operation there is nothing here to undo). The
contract is in [`context/EXTENSIBILITY.md`](../../context/EXTENSIBILITY.md) under "View commands",
and it closes both D5's write channel and D6's missing route for Locate.

Four things are deliberately not in this slice:

- **Hover-to-highlight is not built.** Q18 names four legend affordances and this is the fourth. It
  would send one command per pointer move and rebuild the drawing each time, and whether that reads
  or stutters is a question only a host can answer. Ed chose on 2026-09-20 to measure it rather than
  ship it unmeasured, which is the D5 lesson applied before the fact rather than after.
- **The assembly column and the assembly picker are Phase 2's**, with the assemblies that own the
  display colour they would read. The faces table has no assembly cell meanwhile.
- **The table's layout is not remembered.** Column widths live for as long as the panel shows that
  Model. The preference store has no table registration yet; it arrives with the screen that needs a
  saved layout, which is Spaces.
- **Select all faces of this type in Zone** is still the PRD's right-click selection command and
  still not built. D6 recorded it and nothing here changes that.

Two narrowings worth recording. The view controls order and filter **Zones**, because a Zone is what
the tree is built from; a Zone's Faces follow it in their own order, and filtering reads a Zone's
Faces so a search for "Ground" keeps the Zone that has one. And an unclassified Face is not a row,
as the PRD says: its Zone's row carries the count and the Suggest classification action, which is
also the first panel route to that operation.

The eight D7 host questions are answered in [the Overview evidence](evidence/p1-d-overview.md),
including the current-host fixes and 512-Face measurement. The table's discrete interactions
were usable; Ruby snapshot construction alone took 39 to 47 ms. Hover-to-highlight still needs
a cheaper measured path. This closes the handoff's questions, with broader acceptance cases
remaining in [ACCEPTANCE.md](ACCEPTANCE.md).

### What D6 left open

The tool is implemented and calls D1's operation through the public interface like any other
client, with its own caller handle and sequence numbers. It opens no Model operation itself, so an
abandoned gesture writes nothing and leaves no Undo entry, and one completed gesture is one invoke
and therefore one Undo step however many Faces the pointer crossed. A pointer move costs no Model
walk: `Zones::Occurrences.occurrence_for_path` builds the occurrence from the picked instance path,
which is what makes hover affordable after what D6's own measurement found a walk to cost.

The slice added a fifth contribution seam, `menu_item`, because it had to. The palette began as a
table inside `shell/commands.rb`, which named a feature and carried honeybee's words in a second
place; `context/EXTENSIBILITY.md` states that nothing in `shell/` or `session/` names a feature,
and that invariant is what the contributor argument rests on. A feature now declares its native
menu items the way it declares its Colour-by modes, and `shell/` groups them without reading one.

Four things are deliberately not in this slice:

- **The panel palette is D7's.** Built there. The chips, the Attached zone picker and its inline
  "New attached zone" route are in the panel; the assembly picker waits on Phase 2's assemblies. The
  native Classify menu stays, and both reach the same tool through the same calls.
- **Locate has no user route yet, and is not registered.** Closed in D7. It is a view command,
  `ph_composer.face_assignment.locate`, reached from the faces table and from any client with `view`
  access. Registering it as an action would have manufactured an Undo entry for a read, which is why
  it waited for a seam that is neither a query nor an action.
- **No toolbar button and no cursor change.** The UI polish skill's drawing-tool state rule asks for
  a pressed button, a changed icon and a changed cursor together; the repository ships no image
  assets at all, and adding the first is a decision of its own. The menu check mark carries the
  state meanwhile. PRD line 118 names the toolbar button; it stays owed.
- **Select all faces of this type in Zone** is the PRD's right-click selection command, not a paint
  gesture, and is not built.

Two narrowings worth recording rather than leaving the PRD sentence unqualified. Shift-click floods
"every connected coplanar Face in the same container", where the PRD says "in the same Zone": the
two differ only when a Zone holds nested plain Groups, and crossing that boundary would need the
flood to compose transforms per container. And the flood stops one past the gesture ceiling, for
the same reason the drag set does, so a wall of thousands of pieces refuses rather than capturing
the lot and then refusing.

The host gate passed on 2026-09-20 with Ed at the mouse, and closed D1's two deferred native checks
with it. It cost eight findings, three of them defects the offline suite could not have caught: the
pick is relative to the open edit context, an added overlay is disabled until something enables it,
and a fill drawn on the Face it colours z-fights with it. The second of those is a D5 defect that
meant Colour-by had never drawn on a real host. See
[the Classify tool evidence](evidence/p1-d-classify-tool.md) and the new rows in
[`context/SKETCHUP_HOST_BEHAVIOR.md`](../../context/SKETCHUP_HOST_BEHAVIOR.md).

Two host behaviours were measured and deliberately not worked around. A custom tool does not
receive double-click-to-enter-group, which belongs to the Select tool as it does for every native
drawing tool; the tool reaches geometry inside a Zone through the picked path instead. And Escape
unwinds one layer per press, the tool first and the edit context second, which is the rule the UI
polish skill sets.

A release outside the viewport and a Model switch during an active gesture were not driven. The
tool defends against both and neither is host-verified.

### What D5 left open

The seam, the service and the two features' modes are implemented. A feature declares a mode with
`colour_mode` in its own `install`, hands over a pure projection of its own entities, and reaches
the overlay, the HUD and the cache without a line in the shared renderer; `colour_by/` is a
foundation directory that names no feature. The contract is written up in
[`context/EXTENSIBILITY.md`](../../context/EXTENSIBILITY.md) under "Colour-by modes".

Three things are deliberately not in this slice:

- **The panel legend is D7's.** Built there, with click-to-select-and-zoom and "Show only this".
  Hover highlight is the one affordance of Q18 still owed; see "What D7 left open". D5 ships the
  viewport HUD, which is what a QA screenshot carries and needs no panel.
- **Forced on while the Classify tool is active is D6's,** since the tool it follows lands there.
  The mode the user last chose is already remembered (`Preferences.colour_by_mode`), which is the
  half of Q12 that does not need the tool. D6 implements the other half: the tool turns a mode on
  without remembering it, and turns off only the mode it turned on, and only while that is still
  the active one.
- **The assembly mode waits for Phase 2 assemblies,** which own the display colour it would read.

Two decisions D7 will build on, recorded here so it does not have to guess:

- **The legend counts an entity the drawing omits.** A Face that is hidden, or on a hidden tag,
  is still a row's count while nothing is painted for it, so the legend keeps telling the truth
  about the Model rather than about the viewport. Q18's "click a row to select and zoom" therefore
  has to decide what it does with an invisible entity. D7 decided: the row selects it anyway.
  SketchUp shows a selection where it can, and a count the user can reach nothing from would be
  worse than one that reaches something hidden.
- **Turning a mode on is not a registered action,** because it writes no record and opens no
  operation. D7 settled what it is instead: a view command, `ph_composer.colour_by.activate`, so
  the native menu, the panel and any client with `view` access all reach the same switch.

Part of D5's host gate ran on 2026-09-20 alongside D6's, on the same host, and it cost two defects:
`OverlaysManager#add` leaves an overlay disabled, so a mode turned on drew nothing at all on a real
SketchUp, and a fill drawn exactly on the Face it colours z-fights with that Face, so it blinked
rather than reading. Colour-by had therefore never drawn on a host until D6's gate. Both are fixed
and re-verified: the HUD is legible, the unclassified outlines and the classified fills both draw,
and the overlay arrives and leaves with its mode
([evidence](evidence/p1-d-classify-tool.md)). The lesson is the slice's, not the defects': D5 was
reviewed, tested and recorded as implemented with its host gate unrun, and the gate was where both
defects lived.

The 2026-09-26 [continuation](evidence/p1-d-broader-acceptance.md) verifies holed and concave
`Face#mesh`, direct tag changes, scene tag visibility, native picking, ancestor visibility,
Model-switch/close cleanup and Ruby rebuild cost. Scene tag visibility reaches the existing
layer invalidation path on this host. The walkthrough's hole helper and the renderer's hidden
ancestor handling were corrected. The [2026-09-29 continuation](evidence/p1-d-colour-by-continuation.md)
verifies native Overlays-panel off/on, foreground occlusion, alpha and native orbit, and measures
feature redraw/cadence at 1,032 triangles. Isolated GPU timing remains open. Unclassified still
uses a stippled outline rather than the PRD's hatch; that visual acceptance is not closed by this run.

**Depends on:** P1-C. Owners: Zones and face assignment.

Finish partial-overlap splitting, sliver skips, out-of-scope reciprocal-write refusal, retirement,
explicit copied-Zone identity repair and limited Restore Zone. Identity repair allocates a new UUID,
updates copied member stamps and retires copied pairs without changing the original Zone's pairs.
Refuse ambiguous originals or shared storage that prevents independent repair. Preserve every non-adjacency field and structured
payload under the accepted extension policy. An ambiguous endpoint is never treated as deleted.

Complete the Classify gesture, the named Suggest classification for this Zone action, Reverse
face and local Attached-zone editing/reference
lifecycle. Deliver the Overview Zone tree/faces table and the shared Colour-by registry/HUD;
Zones registers its modes there. Port only the table/draft/preferences components this first
screen uses. Apply the local UI skill and accepted UI baseline when designing the screens.

Propose a ceiling of 1,000 affected face occurrences per Classify gesture, including reciprocal
retirement targets. Deduplicate before counting, refuse the entire gesture at 1,001 and retain
no partial paint. Confirm or revise the limit with measured P1-D host behavior before Classify
implementation closes; test the exact accepted limit and one above it. Auto-classify is a separate
named batch, touches only faces without records and creates one Undo step.

The [B2 overlay evidence](../archive/phase-zero/evidence/spike-overlay.md) permits filled modes
on the proving host. Feature work must invalidate cached geometry after edits, Undo/Redo and model
switches, and measure cost at and beyond 10,000 triangles. B2 did not test that lifecycle.

**Exit:** owning PRD cases pass for the Phase 1 scope, including UI cancellation and atomic gesture
completion. Assembly assignment/pickers/colours remain Phase 2; future Spaces/window cases stay
with their owners. Neither the library provider nor Spaces becomes a Phase 1 prerequisite.

### Native reference continuation

The [2026-09-29 native checks](evidence/p1-d-native-references.md) establish cut/paste and native
Line-split dictionary survival, safe Solve refusal, exact Undo/Redo and fresh reopen. A read-state
defect that reported a pasted endpoint current is corrected by validating full local and reciprocal
references before geometry. Explicit Solve now recovers cut/paste paths using unique authored
identities, full reciprocal-envelope agreement and the normal mutable resolver on actual paths.
Native rollback, Undo/Redo and fresh reopen pass. Native split identity repair remains incomplete:
a Face split copies one authored UUID onto both pieces, and Solve safely refuses that ambiguity.
Copied-Zone identity repair does not repair a split inside an otherwise unique Zone. Define and
verify that recovery before claiming these PRD cases fully complete. The
[extension-copy continuation](evidence/p1-d-extension-copy-safety.md) corrects warning-only
carriage of unknown data during identity-changing copies: unsafe payloads now refuse before any
write, while supported catalog-reference payloads follow their declared rules. Face and Zone UUID
reference targets are not yet registrable. The paired native split is also a one-to-many overlap,
which the current solver reports. Resolve these explicit identity/reference and solver boundaries
before closing A06; do not choose an ambiguous endpoint by geometry.

## P1-E: HBJSON/report export workflow

**Depends on:** P1-C, final authoring behavior for integrated acceptance, and the HBJSON/report interview choices.

Implement preflight, explicit all-Zone solve, destination-first run, bounded collection,
export-relevant snapshot coherence, runtime translation/conformance, cancellation and progress.
Define bounded task/result retention, polling, timeout semantics and model-close/host-restart
outcomes before implementing the run. A timeout is not cancellation, and a restarted host must
not report success for an expired task handle; artifact recovery determines persisted file state.
Selection/camera changes must not cancel an export; export-relevant edits must. The foundation's
whole-Model revision alone is not proof of that distinction. Compose feature findings once.

Keep the existing separate runtime page unless a reviewed need justifies moving it. Select and
pin the wheels needed by HBJSON translation, using B1 as compatibility evidence without treating
its PHX-specific nine-wheel set as a Phase 1 requirement. Review the honeybee-ph version for this
translation path. Retain Pyodide 0.24.1; record sources, hashes/licenses and actual installed size
against the existing 22 MB target and 24 MB ceiling. Resolve the carried Pyodide notice ambiguity
and include the extension LICENSE before distribution.

Complete the canonical pair workflow around the existing artifact primitives, including
replacement/recovery and report accounting. Preserve the HBJSON-only exporter seam; do not
implement optional METr output or its multi-artifact recovery in this phase.

**Exit:** the actual SketchUp export workflow produces a coherent HBJSON/report pair, the exact
HBJSON reloads in the pinned stack, and all canonical-pair failure paths pass. METr work resumes
only when separately scheduled after further feature development.

## P1-F: acceptance and handoff

Run the [acceptance register](ACCEPTANCE.md), record exact commits/builds and host/runtime
versions, update the owning feature statuses and route Phase 2 work. Keep the development-only
construction limitation visible. Do not claim a released or certifiable model authoring product.

## Verification profile and review

Use high assurance for entity persistence, geometry transactions and conversion. During editing,
run focused tests; at coherent gates run the affected checks, coverage/available complexity
measurements and one risk-appropriate review using the architecture rubric. Do not stack
equivalent reviews. Refresh the manifest for changed shipped assets before the final gate.

The phase gate includes `make ci` on both supported offline Rubies, coverage and browser checks,
runtime browser checks with the new wheels, RBZ inventory/fixture exclusion, then fresh-process
native acceptance. Follow `docs/DEVELOPMENT.md` and machine host procedures at execution time.
Reuse unchanged evidence rather than rerunning Phase 0 wholesale. Public support for SketchUp
2023 and Windows remains pending its own host evidence.
