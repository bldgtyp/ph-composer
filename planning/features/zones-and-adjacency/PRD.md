# Zones and adjacency: behavior contract

DATE: 2026-09-18
STATUS: Scoped. Interviewed 2026-09-18 in three rounds, 24 decisions recorded below. PLAN.md now binds the Phase 1 delivery sequence after the merged foundation.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## Problem

PH-Composer has to decide what the fundamental unit of building geometry is before face
assignment can say what a boundary condition means. The two established answers pull apart:

- designPH, WUFI-Passive and METr are single-zone. One envelope, nothing inside, no interzonal
  surfaces, no surface matching. Simple to draw and simple to model. It cannot give different
  loads or schedules to different parts of a building, and it cannot feed a multi-zone
  EnergyPlus model.
- honeybee is multi-zone. Its unit is the Room, a closed volume with faces, and interior faces
  between two Rooms must be matched one to one with a Surface boundary condition. That gives
  per-zone loads, complex buildings and EnergyPlus for free, and it is the source of most of the
  geometry bugs in the honeybee ecosystem: failed matching, tolerance drift, and neighbours that
  fall out of sync when one is edited.

Phius's market is increasingly large multifamily and mixed use. A tool that cannot model a
podium, a corridor or a community room as its own zone leaves that market without the tool it
needs. A tool that forces every single-family user to draw closed solids and solve adjacencies
loses the simplicity that made designPH usable.

## Decision

Multi-zone in the data model. Single-zone in the default experience. Adjacency solved on demand,
recorded as an assignment, and made strict only for the consumer that needs it.

- The fundamental unit is the **Zone**: one SketchUp Group, at model root or inside plain wrapper
  groups, never inside another Zone. It maps one to one to a honeybee Room. Components are not
  Zones in the MVP (Q2, Q15).
- A model needs one Zone, made once with Make Zone. A user who never makes a second group never
  meets Building-Segment, Level or adjacency.
- **Spaces** live inside Zones exactly as the predecessor built them: Space group, Volume group,
  Floor Segment faces. Space stays the Phius unit for iCFA and ventilation.
- Interior faces between two Zones are recognized and recorded by an explicit **Solve adjacencies**
  action, not by a live constraint. Editing a Zone marks its adjacencies stale; validation reports
  them; the user re-solves. Nothing moves behind the user's back.
- The METr exporter needs no matched surfaces. The EnergyPlus path needs one-to-one matches and
  closed Zones, and gets a blocking gate the other exporters do not.
- Every floor is drawn. There is no multiplier and no typical-floor abstraction (Q4).

## Vocabulary

honeybee's names are the problem, so this section is exact. The left column is what
PH-Composer says on screen, in code and in this repository. The right column is what it
becomes in the HBJSON export. `context/UBIQUITOUS_LANGUAGE.md` carries the same table.

| PH-Composer term | Meaning here | honeybee object it maps to | Note |
| --- | --- | --- | --- |
| **Zone** | The fundamental geometry unit: one SketchUp Group carrying envelope faces, Spaces, loads and schedules. A building may be one Zone. | `honeybee.room.Room` | honeybee calls this a Room. It is not a room; it is an arbitrary chunk of building, up to the whole building. PH-Composer never uses the word Room for it. |
| **Building-Segment** | A tag on one or more Zones naming the part of the building that becomes one METr model: a residential tower, a commercial podium. Every Zone belongs to exactly one Building-Segment; a model with one Building-Segment never shows the field. | `honeybee_ph` `BldgSegment` on `Room.properties.ph.ph_bldg_segment` | PHX builds one variant per Building-Segment, merges its Zones, and drops the interior faces between them (`PHX/from_HBJSON/create_project.py`, `cleanup.py`). |
| **Space** | A division inside a Zone for iCFA, ventilation airflows and occupancy: one SketchUp group containing Volumes, each holding Floor Segments. | `honeybee_ph` `Space` on `Room.properties.ph.spaces` | Unchanged from the predecessor. |
| **Level** | An optional classifier tag on a Zone, used for query, sort and group. A Space inherits its Zone's Level with no override. | `Room.story` | The predecessor kept Floor level on the Space; this packet moves it to the Zone (Q6). |
| **Adjacency** | A reciprocal pairing of two path-qualified face endpoints in different Zones, with Zone UUIDs, face persistent ids and solved world-geometry stamps. | `Surface` boundary condition naming the paired face and its Room, only while current | The predecessor had no equivalent. |
| **Interior face** | A face of a Zone whose other side is another Zone, whether or not its adjacency has been solved. | `Surface` when solved, or `Adiabatic` when the user marks it **To neighbour** | Distinct from an envelope face whose boundary condition is Outdoors or Ground. |
| **Closed Zone** | A Zone whose group is a manifold solid. | Required by EnergyPlus; not required by honeybee itself or by METr | `Sketchup::Group#manifold?` |
| **To neighbour** | The on-screen label for the boundary condition a user sets on a face whose other side is not modeled or does not matter: a party wall, a floor over an unmodeled podium. | `Adiabatic` | WUFI and METr vocabulary on screen, honeybee's in the stored value (Q22). |

Two honeybee names PH-Composer does not use on screen:

- **honeybee's `Room.zone`** is a free-text classifier grouping Rooms into what honeybee calls a
  zone. PH-Composer does not expose it and leaves it unset on export, so it defaults to the
  Room identifier (Q7).
- **honeybee's Room** appears only in the export report's audit surface and in code that talks
  to honeybee. A panel label, a validation message and a tooltip say Zone.

## Model hierarchy

```
Model
  Zone (Group, one honeybee Room)                    required; at root or under plain wrapper groups
    envelope faces and interior faces                 classified by face assignment
    Space (group, one honeybee-ph Space)              zero or more
      Volume (group, protected)                        one or more
        Floor Segment (face, iCFA)                     one or more
    window units (components glued to envelope faces)
```

Rules the hierarchy fixes:

- A face is classified in the context of the Zone group that owns it. A face at model root, or
  in a group that is not a Zone, is not an envelope face and validation says so.
- A Zone is identified by PH-Composer's durable UUID in its own dictionary, never by
  `entityID`, and read through its occurrence path. Only Groups are Zones in the MVP; a component
  instance marked as a Zone is a finding (Q2). A Zone inside another Zone is a finding (Q15).
- Every face classified inside a Zone, and every Space group, also carries a small stamp naming
  its Zone id, Building-Segment and Level. These support the limited Restore Zone repair below,
  not reconstruction of the complete Zone record (Q14).
- Spaces cannot span Zones. A Space group directly under the model root is a finding.
- Window units glue to the Zone's Outdoors faces. A window on an interior face is a blocking
  finding (Q12), owned by the window-types packet's "Unit on a Surface face" row. A window unit
  carries no Zone stamp: its Zone is the group that contains it (window-types Q25).

## Behaviors

### Creating and recognizing Zones

- **Make Zone** turns the selected group into a Zone, or wraps the selected loose geometry in a
  new group and marks it. It writes the Zone record and a default name ("Zone 1", "Zone 2"). It
  does not require closure. Entry points: a toolbar button, a right-click item on a selected
  group, and an inline offer from the classification tool when the user clicks a face outside any
  Zone (Q23).
- A Zone is required. A model with no Zone shows one call to action on the Overview and cannot
  export (Q3).
- Predecessor models are not recognized and there is no migration (Q11).
- **Exploding a Zone group** is detected from surviving stamped faces and Spaces whose Zone is
  gone. Native Undo is the full recovery route while the explode remains in the Undo history;
  immediately after explode it is one Undo step. Do not promise one-step recovery after later edits.
- **Restore Zone** is a limited, explicit repair (Q14). Its non-mutating preview lists surviving
  stamped members and necessary bounding edges in one parent entities context, the recovered Zone
  id, Building-Segment and Level, and what cannot be recovered. It does not infer membership from
  proximity or sweep up unstamped faces, windows or other groups. Refuse ambiguous or conflicting
  stamps, a Zone id already in use, mixed parent contexts, or geometry that cannot be regrouped
  without affecting unstamped contents. Nothing is written on refusal.
- Restore retains each surviving member's fields, `user_data` and structured extension payloads,
  including unavailable-extension data. It creates the Zone with the recovered fields and a new
  default name. The former Zone name, Zone metadata, extension payloads and other unstamped fields
  are unavailable, not recovered or silently represented as preserved. The preview discloses this
  loss and requires acceptance of the limited repair. References needing new paths are handled
  by the endpoint rules below. The repair is one atomic Undo step.
- An entirely unclassified Zone with no Spaces has no recovery stamp. The extension cannot promise
  detection after reopening or offer Restore Zone for it; use native Undo or Make Zone manually.
  A session observation may explain the loss but is not durable recovery data.
- **Deleting a Zone group** is distinct from exploding it. If no contents survive, there is nothing
  to regroup and Restore Zone is unavailable. Surviving neighbours report unresolved references;
  use native Undo if available or re-solve them. Offer Restore only for eligible surviving contents.

### Building-Segments and Levels

- Building-Segment and Level are fields on the Zone. A model with one Zone shows neither until the user
  opens the Zone's details.
- A model has one implicit Building-Segment named after the Model file until the user names a second;
  the field is never shown before then (Q5). Building-Segment names become the METr model's name.
- Level is an optional free-text classifier for query, sort and group. The Spaces table's Level
  rail reads the Zone's Level; a Space has no Level of its own (Q6).

### Interior faces

- In a single-Zone model an unclassified face is ignored completely: no finding, no prompt.
  designPH users do not draw partitions and PH-Composer does not ask them to (Q8).
- In a multi-Zone model, a face whose plane and extent coincide with a face of another Zone is a
  candidate interior face. Solve adjacencies confirms it. Until then it is unclassified.
- The user can mark a face **To neighbour** without solving. That is the escape hatch for a Zone
  whose neighbour is not modeled, and it is what a party wall to an unmodeled building is. It is
  stored as honeybee `Adiabatic` (Q10, Q22).
- Interior windows are refused in this packet: a window unit must sit on an Outdoors face. The
  window placement packet may reopen it (Q12).

### Solve adjacencies

One action, one Undo step, run on demand and offered again by validation whenever an adjacency
is stale. It also runs as an opt-out step in the export dialog, "Solve N stale adjacencies before
export", checked by default, as its own Undo step before the artifact is written. It never runs
from an observer (Q9). Scope: the selected Zones if any are selected, otherwise all Zones (Q18).

Resolve that scope once into explicit Zone occurrence references. All Zones may be read to identify
candidates and existing counterparts, but only the resolved mutation set may be changed. If making
or retiring a pair requires a surviving endpoint outside that set, refuse the whole operation with
both Zone references and offer retry with both included. Never silently expand selection scope.
A confirmed deleted endpoint requires no write; an ambiguous endpoint is a refusal, not a deletion.
Export preflight uses an explicit all-Zone scope independent of viewport selection.

The operation first prepares a non-mutating proposal, including old pairs to retire, splits,
skips and affected references. Revalidate model/session, geometry revision and edit context at
commit. Apply the proposal atomically in one transaction: a runtime failure aborts every split and
record change. Expected geometric skips are reported proposal outcomes, not partially failed
transactions. An unchanged solve creates no write or Undo entry.
All candidate, sliver and overlap decisions below are settled in the proposal before its geometry
and record writes begin. A failed native split aborts the transaction rather than becoming a skip.

1. Collect every face of every Zone with its world plane and world outline, read once through
   the occurrence path with transforms accumulated exactly once.
2. Pair faces across Zones whose planes coincide within SketchUp's tolerance with opposite
   normals and whose outlines overlap in the shared plane.
3. Plan splits and reject any that would create a face narrower than 10 mm or smaller than
   0.01 m² before changing geometry (Q17). Where an accepted overlap is a proper subset of a face,
   draw the overlap outline onto that face inside its Zone group. The intended native split and
   attribute behavior must pass the host gate below; the solver computes the 2D clip. Repeat on
   the other side.
4. Retire superseded or invalid old pairs on both surviving endpoints, then record one Adjacency
   per matched pair using the endpoint contract below, overlap area in m² and world-geometry stamps.
5. Record no new adjacency for a skipped split and report it, naming both Zones. A skipped match
   does not preserve an invalid old pair as current.
6. Report coplanar overlapping faces whose normals point the same way as overlapping Zones, a
   modeling error, and pair nothing (Q19).
7. Report faces that overlap more than one neighbour and could not be split cleanly.

The Adjacency lives on both faces' own dictionaries, each naming the other face and its Zone,
with the geometry stamp. There is no Model-level table (Q20). Solving records Surface on the
matched portion only. An unpaired remainder retains its non-Surface classification (Q21).
A formerly paired portion that becomes unmatched loses the old adjacency and Surface boundary
condition; its boundary condition is absent and it needs classification. Preserve face type,
assembly, metadata and extension payloads. Do not restore an old boundary condition by inference
or silently substitute Outdoors or Adiabatic. Face assignment owns the user's new classification.
Both sides of a retired pair follow this rule unless replaced by a new valid pair in the same
operation. A copied dictionary on a split face is not proof of a valid adjacency.

What it never does: move geometry, change a face's plane, edit a Zone the user did not include,
or run from an observer. `intersect_with` is not used for the coplanar case because it skips
coplanar geometry; it may be used later for non-coplanar intersections if a feature needs them.

### Staleness

- An Adjacency is current only when both endpoint references resolve uniquely, both reciprocal
  records agree, and both world planes, normals and outlines still match the solved geometry.
  Reconciliation checks wrapper transforms and endpoint changes as well as edits inside a Zone.
  It reports stale or unresolved pairs without solving or assigning a replacement condition.
- Solve adjacencies repairs the relationship or retires it; retirement can leave faces needing
  classification. Validation distinguishes these outcomes and names each surviving affected face.
- Staleness alone is warning-only on the HBJSON and METr paths. It blocks the EnergyPlus path.
- PHX's existing behavior decides what METr sees: a Surface face whose neighbour is in the same
  Building-Segment is omitted; a Surface face whose neighbour is in another Building-Segment, and a To neighbour
  face, both export as a to-neighbour surface (Q10). The Surface mapping requires a current
  reciprocal pair; an explicitly assigned To neighbour face needs no adjacency.
  A stale or unresolved Surface reference, including one naming a deleted target, is never passed
  to PHX as a valid Surface. Translation omits each affected face with a finding naming its area,
  Zone and reason. A retired face with no boundary condition is likewise a reported omission until
  classified. These states alone do not block HBJSON or METr; independent blocking findings still
  apply. A usable remaining model is required by translation and conformance checks.
- Whether preflight repair is run or skipped, exported Surface references must target faces and
  Rooms actually emitted in the same HBJSON. If one endpoint cannot be emitted, omit its paired
  counterpart with a reference finding rather than emit a dangling Surface. Export is read-only;
  omission does not remove records from the SKP. The report accounts for every omission.

### Endpoint identity and persistence

Each persisted endpoint contains the owning Zone UUID, its root-to-Zone occurrence path, and the
face's persistent id plus any remaining path within the Zone. Reuse the foundation's reference
types and schema versioning; PLAN.md selects their exact serialized representation. Both face
records name the same two endpoints. Geometry stamps check freshness and never identify a target.

- Preserve Zone UUIDs for the same logical Zone when the foundation can establish continuity.
  Path or persistent-id changes invalidate the old adjacency reference until an explicit solve
  creates a new pair. Never recover a face reference by name, proximity or coincident geometry.
- **A copied Zone is shared storage, and Make Unique comes first (Q25).** Measured on 26.1.188,
  2026-09-20: copying a Group makes both Groups instances of one definition sharing every Face,
  while each keeps its own Zone record. So a plain copy is ambiguous and shared at once, and
  identity repair refuses it, because giving the copy new Face ids would rewrite the original's.
  The Zones read reports shared storage ahead of the ambiguity, since that is what blocks every
  repair and names the fix. The user makes the copy unique with SketchUp's own Make Unique, and
  identity repair is then available on an occurrence that genuinely has its own members.
  PH-Composer does not make a Group unique on the user's behalf inside a repair: that is a native
  edit with its own consequences for every other instance, and hiding it inside an identity repair
  would change more of the Model than the repair names. Ed confirmed this on 2026-09-20.
- Duplicate Zone UUIDs are ambiguous, not aliases. Refuse pair mutation involving them and report
  them. An explicit identity repair identifies the copied Zone occurrence, assigns it a fresh
  foundation UUID, updates its member stamps and retires copied adjacency data without rewriting
  the original Zone's pairs. Preserve copied metadata and extension payloads; unresolved extension
  references are reported, not guessed. Refuse if the original cannot be identified or shared
  storage prevents an independent repair; the user must resolve the ambiguity or make it unique.
- A native split or merge invalidates affected pairs, even when dictionaries were copied. The
  explicit solver reacquires resulting face references and establishes only valid reciprocal
  pairs. Classifications other than Surface and surviving payloads are preserved; conflicting
  payloads that cannot be retained must be reported and resolved before a plugin-owned edit.
- Restore Zone preserves an unambiguous recovered Zone UUID, but new paths do not make old pairs
  current. Report them unresolved and require an explicit solve. Undo/Redo restores the matching
  geometry and record state together; save/reopen must not turn unresolved pairs into current ones.

### Closure

- **Closed** is a Zone-level finding computed with `manifold?` on the deferred pass. An open
  Zone is disclosed in the Zones table and the Export report.
- Closure blocks the EnergyPlus exporter only. METr and the HBJSON artifact accept an open Zone
  and say so in the report, because designPH never required closure and neither does honeybee
  (Q10).
- Zone volume is neither shown nor exported as a Phius quantity. Vn50 and iCFA stay Space-derived
  as the predecessor built them; honeybee computes Room volume from the faces itself (Q24).

### Export mapping by consumer

| Consumer | Zones | Interior faces | Closure |
| --- | --- | --- | --- |
| HBJSON artifact | one Room per Zone, `story` from Level, `zone` unset | Surface only for current reciprocal pairs with emitted targets; Adiabatic where marked To neighbour; unresolved or absent conditions are reported omissions | disclosed |
| METr exporter (PHX) | one variant per Building-Segment; Zones merged | intra-Building-Segment Surface omitted; cross-Building-Segment Surface and To neighbour both written as to-neighbour | disclosed |
| EnergyPlus (REVIVE, later) | one Room per Zone | every interior face solved or Adiabatic, blocking | required, blocking |

### Validation rows

Each is one row in the rules table with a severity, per the durable delivery rules.

| Finding | Severity | Repair |
| --- | --- | --- |
| No Zone in the model | blocking for export | Make Zone |
| Face outside any Zone | warning | Move into a Zone or ignore |
| Space outside any Zone | blocking for export | Move into a Zone |
| Zone not closed | info; blocking for EnergyPlus | Fix geometry |
| Candidate interior face unsolved (multi-Zone model only) | warning; blocking for EnergyPlus | Solve adjacencies or mark To neighbour |
| Adjacency stale | warning; blocking for EnergyPlus | Solve adjacencies |
| Adjacency endpoint unresolved or ambiguous | warning; blocking for EnergyPlus | Resolve identity ambiguity, then Solve adjacencies |
| Retired adjacency needs boundary classification | warning; blocking for EnergyPlus | Classify or Solve adjacencies |
| Sliver skipped by the solver | warning | Named with both Zones |
| Overlapping Zones (same-normal coplanar faces) | warning | Named with both Zones |
| Face overlaps more than one neighbour and could not be split | warning | Named with both neighbours |
| Orphaned stamped contents | warning | Native Undo if available, or limited Restore Zone when eligible |
| Zone inside a Zone, or a component marked as a Zone | warning | Regroup |
| Interior window | blocking for export; raised by the window-types packet, listed here for the reader | Move the window to an Outdoors face |

## Contribution ownership

The zones feature owns Zone records, endpoint references, pair validation and pair creation/removal.
Its public queries and operations register through one feature install entrypoint, with explicit
dependencies. Make Zone, Solve adjacencies, Restore Zone and identity repair use the same validated
operations from UI and scripts with the panel closed. Calls carry explicit session and occurrence
references, expected revisions and the affected mutation set. Results return changed references,
findings and the resulting revision, distinguishing refusal, rollback and success.

Pure overlap calculations take explicit SI geometry; the SketchUp adapter reads paths, applies
splits and persists records. Face assignment calls the public pair-removal contract when changing
a Surface condition; it never edits adjacency dictionaries itself. The caller owns one enclosing
transaction for pair removal and classification, with no nested transaction or out-of-scope write.
Preflight invokes the same solve operation before the export snapshot. The feature contributes its
snapshot and findings through the export contributor and translation-section contracts. Shared
shell, session and export orchestration contain no Zone-specific branch.

PLAN.md must name the transplanted entrypoints and record schemas and include a small script that
reads two Zone occurrences, previews and applies a solve, then reads back reciprocal references
with the panel closed. Test the same operation and failure outcomes through UI and scripts.
These are contract requirements, not claims that those APIs have been implemented.

## Host assumptions and evidence gates

The solver intends to use planar faces, native edge insertion for splits and `Group#manifold?`
for closure. These do not establish numerical robustness, dictionary survival or recovery behavior.
Before implementation relies on them, record precise API references and fresh-host evidence for
coplanar splitting, new face identity, attribute survival, explode/delete and closure with the
supported Zone hierarchy. Measure the supported tolerance cases, including nested, scaled and
mirrored transforms, holes and near-coincident faces. Inference snapping alone is not proof that
independently authored faces coincide. The old blanket claim that tolerance problems do not arise
is not an implementation premise.

What the predecessor already proved that this packet reuses: reading geometry through
occurrence paths with transforms accumulated once, protecting Volumes across context changes,
the reconciler's deferred idempotent pass, and the rule that repeated components share storage.

## Non-goals

- Live matching that edits a neighbour when the user edits a Zone.
- Automatic Zone creation from loose geometry or from Spaces.
- Multipliers and typical floors. Every floor is drawn; the extension is what-you-see-is-what-
  you-get (Q4).
- Air boundaries. Their own decision later.
- Per-Space loads or schedules. Loads and schedules belong to the Zone, matching honeybee, with
  one exception carried from honeybee-ph: a Space may hold its own fresh-air ventilation flow
  rates, and when present they are used; when absent the Zone's ventilation load applies (Q16).
  This packet defines the ownership; the fields arrive with the loads packet.
- Predecessor model migration (Q11).
- Any change to the Space, Volume and Floor Segment rules the predecessor accepted, other than
  moving them under a Zone and deriving Level.

## Decisions recorded

Interviewed 2026-09-18, three rounds, Ed's answers. Each is cited where it applies above.

| # | Decision | Answer |
| --- | --- | --- |
| Q1 | The word Zone for honeybee's Room | Yes |
| Q2 | What a Zone is | A Group only, for the MVP |
| Q3 | Zone required | Yes; Make Zone is a small ask even for one Zone |
| Q4 | Multipliers and typical floors | No; draw every floor |
| Q5 | Default Building-Segment | One implicit Building-Segment named after the Model, never shown until a second exists |
| Q6 | Level | Optional classifier tag on the Zone; Spaces inherit; no override |
| Q7 | honeybee `Room.zone` on export | Leave unset |
| Q8 | Unclassified faces in a single-Zone model | Ignored completely |
| Q9 | When Solve adjacencies runs | User click, plus an opt-out step in the export dialog; never from an observer |
| Q10 | Closure and the escape hatch | Open Zone blocks EnergyPlus only; To neighbour available on any face; PHX's Building-Segment rule governs METr |
| Q11 | Predecessor models | No recognition, no migration |
| Q12 | Interior windows | Refused in this packet |
| Q13 | Where Zones appear | Overview only until a second Zone exists, then a Zones section atop Spaces with the tree grouped by Zone |
| Q14 | Exploded Zone | Native Undo first; limited Restore Zone from surviving classified-face and Space stamps, with recovery limits disclosed |
| Q15 | Zone nesting | At root or under plain wrapper groups; never inside another Zone |
| Q16 | Loads and schedules | On the Zone, as honeybee; Space fresh-air flow rates override when present, as honeybee-ph |
| Q17 | Slivers | Skip splits under 10 mm or 0.01 m², record nothing, report with both Zones |
| Q18 | Solver scope | Selected Zones if any, else all; refuse required reciprocal writes outside the explicit mutation set; export preflight explicitly targets all Zones |
| Q19 | Same-normal coplanar faces | Report as overlapping Zones, pair nothing |
| Q20 | Adjacency storage | On both faces' dictionaries; no Model-level table |
| Q21 | Unpaired remainder after a split | Keep non-Surface classification; retire invalid Surface pairs and leave the condition absent for user classification |
| Q22 | On-screen label for Adiabatic | "To neighbour", tooltip names honeybee Adiabatic |
| Q23 | Make Zone entry points | Toolbar, right-click on a group, and inline from the classification tool; names "Zone 1", "Zone 2" |
| Q24 | Zone volume | Not shown, not exported; Vn50 and iCFA stay Space-derived |
| Q25 | A copied Zone | Shared storage; repair refuses until the user runs SketchUp's Make Unique. PH-Composer never makes a Group unique inside a repair |

## Acceptance shape

Delivery update, 2026-09-20: D12 defers METr exporter development and consumer acceptance.
The HBJSON and authoring checks below remain Phase 1 work as allocated in PLAN.md; METr-specific
checks wait for the exporter's separately scheduled milestone. Existing consumer mappings remain
requirements for that future work.

The 2026-09-18 architecture-review corrections were authorized after the interview. Q14, Q18 and
Q21 above include those clarifications; consumer-specific blocking remains Q10's policy.

Offline: fixtures for a single-Zone box, two Zones sharing a full wall, two Zones sharing a
partial wall that needs a split on both sides, a Zone nested in a rotated group, a repeated Zone
component, and a podium under a tower in two Building-Segments. Each proves the classification, the solver
output, the staleness detection after an edit, and the export mapping row by row.

Extend those fixtures with the following contract checks:

- Solve, separate completely, re-solve; repeat with partial overlap and a deleted neighbour.
  Verify reciprocal retirement, retained non-adjacency fields and metadata, and absence of inferred
  replacement conditions. Export with preflight enabled and disabled and reconcile every omitted
  face and area; no emitted Surface may reference an omitted face or Room.
- Select only A from an A-B pair; select A-B with an existing B-C pair; reclassify one endpoint.
  Verify refusal outside the mutation set and no writes. Inject failure after the first proposed
  endpoint write and verify full rollback, including geometry and one-step Undo behavior on success.
- Move through wrappers, cut/paste, duplicate, split and restore paired Zones. Assert actual
  endpoint references and UUID uniqueness, not record counts. Ambiguity is never resolved through
  geometry matching. Include unavailable extension data and unsupported schema preservation.
- Explode an unclassified Zone and a named Zone with metadata; test conflicting survivor stamps,
  mixed contexts and deletion with no survivors. Verify limited-repair eligibility, disclosed lost
  Zone fields, retained member payloads and rejection without mutation when membership is unsafe.
- Run the representative public-operation script with the panel closed and compare UI outcomes,
  including wrong sessions, stale revisions and read-back of successful writes.

Host gate, fresh process: draw two Zones against each other by hand with inference, solve, edit
one, see the stale finding, re-solve, Undo once and see both the split and the records revert,
explode one Zone and recover it with Restore Zone, save, reopen, export HBJSON and the METr
model, and confirm PHX omitted the intra-Building-Segment faces and wrote the cross-Building-Segment one as a
to-neighbour surface.

Extend the fresh-process gate to the lifecycle cases above, with native Undo/Redo and save/reopen.
Record exact host and runtime versions and the split/attribute/tolerance evidence required above.
Offline checks cannot establish native identity or payload survival. No such evidence exists here yet.

## Prior art and evidence

- Predecessor Space hierarchy and reconciler: `../../ph-navigator-sketchup/planning/archive/`
  B1 and B2 acceptance evidence; `context/TECH_STACK.md` here for the carried rules.
- honeybee Room, `zone`, `story`: `honeybee-core/honeybee/room.py`.
- honeybee-ph BldgSegment and Space: `honeybee_ph/honeybee_ph/bldg_segment.py`, `space.py`.
- PHX grouping by Building-Segment and interior-face handling:
  `PHX/PHX/from_HBJSON/create_project.py` (`sort_hb_rooms_by_bldg_segment`) and
  `PHX/PHX/from_HBJSON/cleanup.py` (`merge_rooms`, `_get_thermal_envelope_faces`).
  Local source inspected 2026-09-18: `_get_thermal_envelope_faces` omits Surface faces by referenced
  Room membership in the merge set, without testing contact. This is source evidence, not a
  pinned-runtime test; the translation gate must exclude stale references before calling PHX.
- honeybee-grasshopper-core Solve Adjacency and Intersect Solids components, as the reference for
  what a matched model must satisfy, not for how to build one in SketchUp.
