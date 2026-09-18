# Zones and adjacency: behavior contract

DATE: 2026-09-18
STATUS: Scoped. Interviewed 2026-09-18 in three rounds, 24 decisions recorded below. PLAN.md follows the foundation transplant.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (no remote)

## Problem

PassiveBuilder has to decide what the fundamental unit of building geometry is before face
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
PassiveBuilder says on screen, in code and in this repository. The right column is what it
becomes in the HBJSON export. `context/UBIQUITOUS_LANGUAGE.md` carries the same table.

| PassiveBuilder term | Meaning here | honeybee object it maps to | Note |
| --- | --- | --- | --- |
| **Zone** | The fundamental geometry unit: one SketchUp Group carrying envelope faces, Spaces, loads and schedules. A building may be one Zone. | `honeybee.room.Room` | honeybee calls this a Room. It is not a room; it is an arbitrary chunk of building, up to the whole building. PassiveBuilder never uses the word Room for it. |
| **Building-Segment** | A tag on one or more Zones naming the part of the building that becomes one METr model: a residential tower, a commercial podium. Every Zone belongs to exactly one Building-Segment; a model with one Building-Segment never shows the field. | `honeybee_ph` `BldgSegment` on `Room.properties.ph.ph_bldg_segment` | PHX builds one variant per Building-Segment, merges its Zones, and drops the interior faces between them (`PHX/from_HBJSON/create_project.py`, `cleanup.py`). |
| **Space** | A division inside a Zone for iCFA, ventilation airflows and occupancy: one SketchUp group containing Volumes, each holding Floor Segments. | `honeybee_ph` `Space` on `Room.properties.ph.spaces` | Unchanged from the predecessor. |
| **Level** | An optional classifier tag on a Zone, used for query, sort and group. A Space inherits its Zone's Level with no override. | `Room.story` | The predecessor kept Floor level on the Space; this packet moves it to the Zone (Q6). |
| **Adjacency** | A recorded pairing of one face in Zone A with one face in Zone B: same plane, opposite normals, overlapping, stored with both persistent ids and a stamp of the geometry it was solved against. | `Surface` boundary condition naming the paired face and its Room | The predecessor had no equivalent. |
| **Interior face** | A face of a Zone whose other side is another Zone, whether or not its adjacency has been solved. | `Surface` when solved, or `Adiabatic` when the user marks it **To neighbour** | Distinct from an envelope face whose boundary condition is Outdoors or Ground. |
| **Closed Zone** | A Zone whose group is a manifold solid. | Required by EnergyPlus; not required by honeybee itself or by METr | `Sketchup::Group#manifold?` |
| **To neighbour** | The on-screen label for the boundary condition a user sets on a face whose other side is not modeled or does not matter: a party wall, a floor over an unmodeled podium. | `Adiabatic` | WUFI and METr vocabulary on screen, honeybee's in the stored value (Q22). |

Two honeybee names PassiveBuilder does not use on screen:

- **honeybee's `Room.zone`** is a free-text classifier grouping Rooms into what honeybee calls a
  zone. PassiveBuilder does not expose it and leaves it unset on export, so it defaults to the
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
- A Zone is identified by PassiveBuilder's durable UUID in its own dictionary, never by
  `entityID`, and read through its occurrence path. Only Groups are Zones in the MVP; a component
  instance marked as a Zone is a finding (Q2). A Zone inside another Zone is a finding (Q15).
- Every face classified inside a Zone, and every Space group, also carries a small stamp naming
  its Zone id, Building-Segment and Level, so a Zone can be rebuilt after its group is exploded (Q14).
- Spaces cannot span Zones. A Space group directly under the model root is a finding.
- Window units glue to the Zone's Outdoors faces. A window on an interior face is a blocking
  finding in this packet (Q12).

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
- **Exploding a Zone group** cannot be intercepted; SketchUp has no pre-explode hook and locking
  the group would also block editing inside it. What survives is every face's own dictionary and
  the Zone stamp on each face and Space. The deferred pass detects classified faces and Spaces
  whose Zone is gone and shows one finding whose text says first that one native Undo restores
  everything, and offers **Restore Zone**, which regroups them and rewrites the Zone record from
  the stamp (Q14).
- Deleting a Zone group leaves its contents to normal SketchUp behavior; the same finding and
  repair apply.

### Building-Segments and Levels

- Building-Segment and Level are fields on the Zone. A model with one Zone shows neither until the user
  opens the Zone's details.
- A model has one implicit Building-Segment named after the Model file until the user names a second;
  the field is never shown before then (Q5). Building-Segment names become the METr model's name.
- Level is an optional free-text classifier for query, sort and group. The Spaces table's Level
  rail reads the Zone's Level; a Space has no Level of its own (Q6).

### Interior faces

- In a single-Zone model an unclassified face is ignored completely: no finding, no prompt.
  designPH users do not draw partitions and PassiveBuilder does not ask them to (Q8).
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

1. Collect every face of every Zone with its world plane and world outline, read once through
   the occurrence path with transforms accumulated exactly once.
2. Pair faces across Zones whose planes coincide within SketchUp's tolerance with opposite
   normals and whose outlines overlap in the shared plane.
3. Where the overlap is a proper subset of either face, draw the overlap outline onto that face
   inside its Zone group. SketchUp splits the face along edges that lie on it, so the split is
   native; the solver only computes the 2D clip. Repeat on the other side.
4. Record one Adjacency per matched pair: both persistent ids, both Zone ids, the overlap area
   and a stamp of both outlines.
5. Skip any split that would create a face narrower than 10 mm or smaller than 0.01 m². Record
   no adjacency for it and report it, naming both Zones (Q17).
6. Report coplanar overlapping faces whose normals point the same way as overlapping Zones, a
   modeling error, and pair nothing (Q19).
7. Report faces that overlap more than one neighbour and could not be split cleanly.

The Adjacency lives on both faces' own dictionaries, each naming the other face and its Zone,
with the geometry stamp. There is no Model-level table (Q20). Solving records Surface on the
matched portion only; the unpaired remainder keeps whatever classification it had, and assigning
Outdoors, Ground or an assembly is the face assignment packet's job (Q21).

What it never does: move geometry, change a face's plane, edit a Zone the user did not include,
or run from an observer. `intersect_with` is not used for the coplanar case because it skips
coplanar geometry; it may be used later for non-coplanar intersections if a feature needs them.

### Staleness

- An Adjacency is current when both faces still exist, still lie on the recorded plane and still
  have the recorded outlines. The reconciler checks this on the deferred pass after a Zone
  changes and marks the affected Adjacencies stale.
- A stale Adjacency is a finding with one repair: Solve adjacencies. Validation lists the count.
- A stale Adjacency blocks nothing on the HBJSON or METr paths. It blocks the EnergyPlus path.
- PHX's existing behavior decides what METr sees: a Surface face whose neighbour is in the same
  Building-Segment is omitted; a Surface face whose neighbour is in another Building-Segment, and a To neighbour
  face, both export as a to-neighbour surface (Q10). So an unsolved cross-Building-Segment face is a
  classification gap the user closes by solving or by marking To neighbour, and once classified
  either way its staleness no longer matters to METr.

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
| HBJSON artifact | one Room per Zone, `story` from Level, `zone` unset | Surface where solved, Adiabatic where marked To neighbour, otherwise a reported omission | disclosed |
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
| Sliver skipped by the solver | warning | Named with both Zones |
| Overlapping Zones (same-normal coplanar faces) | warning | Named with both Zones |
| Face overlaps more than one neighbour and could not be split | warning | Named with both neighbours |
| Zone group exploded or deleted with classified contents | warning | Undo, or Restore Zone |
| Zone inside a Zone, or a component marked as a Zone | warning | Regroup |
| Interior window | blocking for export | Move the window to an Outdoors face |

## Why SketchUp makes this tractable

Three host facts, all measured in the predecessor or in SketchUp's own documentation:

- Faces are planar by construction and the inference engine snaps to existing geometry, so two
  Zones drawn against each other share a plane exactly. The internal tolerance is a thousandth
  of an inch and is not user-configurable. The tolerance and mesh problems that make adjacency
  hard in Rhino do not arise.
- Adding edges that lie on a face, inside that face's entities context, splits the face. The
  solver computes the overlap polygon and draws it; SketchUp performs the split.
- `Group#manifold?` answers closure directly.

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
| Q14 | Exploded Zone | Detect on the deferred pass; say Undo first; offer Restore Zone from a stamp on every face and Space |
| Q15 | Zone nesting | At root or under plain wrapper groups; never inside another Zone |
| Q16 | Loads and schedules | On the Zone, as honeybee; Space fresh-air flow rates override when present, as honeybee-ph |
| Q17 | Slivers | Skip splits under 10 mm or 0.01 m², record nothing, report with both Zones |
| Q18 | Solver scope | Selected Zones if any, else all |
| Q19 | Same-normal coplanar faces | Report as overlapping Zones, pair nothing |
| Q20 | Adjacency storage | On both faces' dictionaries; no Model-level table |
| Q21 | Unpaired remainder after a split | Untouched; classification is the face assignment packet's job |
| Q22 | On-screen label for Adiabatic | "To neighbour", tooltip names honeybee Adiabatic |
| Q23 | Make Zone entry points | Toolbar, right-click on a group, and inline from the classification tool; names "Zone 1", "Zone 2" |
| Q24 | Zone volume | Not shown, not exported; Vn50 and iCFA stay Space-derived |

## Acceptance shape

Offline: fixtures for a single-Zone box, two Zones sharing a full wall, two Zones sharing a
partial wall that needs a split on both sides, a Zone nested in a rotated group, a repeated Zone
component, and a podium under a tower in two Building-Segments. Each proves the classification, the solver
output, the staleness detection after an edit, and the export mapping row by row.

Host gate, fresh process: draw two Zones against each other by hand with inference, solve, edit
one, see the stale finding, re-solve, Undo once and see both the split and the records revert,
explode one Zone and recover it with Restore Zone, save, reopen, export HBJSON and the METr
model, and confirm PHX omitted the intra-Building-Segment faces and wrote the cross-Building-Segment one as a
to-neighbour surface.

## Prior art and evidence

- Predecessor Space hierarchy and reconciler: `../../ph-navigator-sketchup/planning/archive/`
  B1 and B2 acceptance evidence; `context/TECH_STACK.md` here for the carried rules.
- honeybee Room, `zone`, `story`: `honeybee-core/honeybee/room.py`.
- honeybee-ph BldgSegment and Space: `honeybee_ph/honeybee_ph/bldg_segment.py`, `space.py`.
- PHX grouping by Building-Segment and interior-face handling:
  `PHX/PHX/from_HBJSON/create_project.py` (`sort_hb_rooms_by_bldg_segment`) and
  `PHX/PHX/from_HBJSON/cleanup.py` (`merge_rooms`, `_get_thermal_envelope_faces`).
- honeybee-grasshopper-core Solve Adjacency and Intersect Solids components, as the reference for
  what a matched model must satisfy, not for how to build one in SketchUp.
