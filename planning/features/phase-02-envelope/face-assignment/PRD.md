# Face assignment: behavior contract

DATE: 2026-09-30
STATUS: In progress. Interviewed 2026-09-18 in two rounds, 22 decisions recorded below. Phase 1 scope merged to main. Amended 2026-09-30 for the Phase 2 assembly-assignment scope. [PLAN.md](PLAN.md) allocates delivery.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/14

## Amendments for Phase 2

Proposed 2026-09-30. They apply to the assembly-assignment scope that Phase 2 delivers. Rows that
restate what the merged code does are facts. Rows that cite a D2 decision are proposals and govern
only once Ed confirms them; until then the body stands. The reasons are in the Phase 2
[DECISIONS](../DECISIONS.md), and the names in [CONTRACTS](../CONTRACTS.md).

| Body text | Reads as |
| --- | --- |
| "This feature" as the owner of Face records and operations | The `zones` feature in code. This packet owns the behavior |
| Reassign, which "opens its own `ModelOperation.perform` when called alone and joins the caller's" | The `assign_assembly` action, and a reference retargeter Zones registers for the Assembly kind, which the assemblies delete reaches through the foundation. No handler opens an operation; dispatch does |
| "The Classify tool with only an assembly chosen is the paint route. The faces table is the table route" | Selecting Faces and choosing an Assembly, from the selection panel or the right-click menu, is the primary route under the geometry-first rule. The table and paint routes stay (D2-2, confirmed 2026-09-30) |
| The assembly picker, Colour-by mode, hint fill and mismatch finding "read assemblies through that feature's assembly read" | As written. Zones requires assemblies and reads the registered Assembly read (D2-1, revised by Ed 2026-10-01) |
| "This feature declares that read as a dependency when window-types lands" for net opaque area | Windows owns and presents net area. The faces table and assembly usage keep gross area and say so (D2-10, confirmed 2026-09-30) |
| A gesture ceiling to be set by PLAN.md | 250 Face occurrences, as Phase 1 measured and set |
| "Select all faces of this type in Zone" and a toolbar button | Still unbuilt. Neither is in Phase 2 |

## Problem

designPH owned envelope classification in the predecessor: which faces are the thermal envelope,
what each one is, what is on the other side, and which construction it carries. PH-Composer
has to do this itself, and it is the first thing a user does in every model. Everything downstream
reads it: assembly usage, window placement, thermal bridges, iCFA, the HBJSON Room faces and the
METr envelope.

The zones-and-adjacency packet settled the container: a face is classified in the context of the
Zone group that owns it, interior faces between Zones are found by Solve adjacencies, and the
unpaired remainder of any face is this packet's job. This packet settles the face record, the
tool that writes it, what the model shows, and what validation and export do with it.

## The domain model this packet rests on

Confirmed by Ed 2026-09-18 (Q1): the authored model is a set of honeybee-shaped Ruby records in
the SKP, translated to honeybee objects at export. PH-Composer does not run honeybee live and
does not invent its own vocabulary where honeybee has one. A face record therefore uses
honeybee's face types and boundary conditions by their honeybee names as stored values, and adds
only what authoring needs: identity, the Zone stamp, and the states a partial model has that a
simulation-ready one does not. The reasoning is in the founding brief's decisions table.

## Decision

- One **face record** per classified face, in PH-Composer's own dictionary on the face,
  carrying face type, boundary condition, assembly id and the Zone stamp. A face without a
  record is unclassified and, in a single-Zone model, ignored.
- One **Classify tool** in the viewport, modal like SketchUp's Paint Bucket: pick a face type and
  boundary condition in the panel, click or drag over faces to apply. The same tool assigns an
  assembly, and an assembly's own type and exterior condition fill an untyped face's type and
  boundary condition (Q7). It never changes geometry.
- Five boundary conditions on screen: Outdoors, Ground, To neighbour, **Attached zone** (a named
  unconditioned space with a temperature reduction factor, honeybee-ph's `PhAdditionalZone`), and
  Surface, which only Solve adjacencies sets (Q2).
- **Suggestions, never assumptions.** The tool proposes a face type from the face normal and a
  boundary condition from position, using honeybee's own thresholds, and shows the proposal on
  hover. Nothing is written until the user clicks.
- **Colour by classification** through one shared **Colour-by** component: a `Sketchup::Overlay`,
  a legend in the panel, and a heads-up legend drawn in the viewport while a mode is active. Any
  feature registers a mode. Overlay only; SketchUp materials are never written (Q15, Q16).
- Validation reports unclassified faces only in a multi-Zone model or when the user asks;
  every opaque face emitted to HBJSON requires a valid authored assembly. Missing references and
  omitted adjacency states follow the explicit validation and export matrix below.

## Vocabulary

Carried from `context/UBIQUITOUS_LANGUAGE.md`; new terms this packet adds are marked.

| Term | Meaning | Stored value | Shown as |
| --- | --- | --- | --- |
| Envelope face | A face with a face record whose boundary condition is Outdoors or Ground | | |
| Face type | honeybee face type | `Wall`, `RoofCeiling`, `Floor`, `AirBoundary` | Wall, Roof (tooltip: also ceilings between Zones), Floor, Air boundary |
| Boundary condition | What is on the other side | `Outdoors`, `Ground`, `Adiabatic`, `Surface`, honeybee-ph `PhAdditionalZone` | Outdoors, Ground, To neighbour, Surface, Attached zone |
| Attached zone (new) | A named unconditioned space outside the envelope (garage, attic, crawlspace) with one temperature reduction factor; a Library record kind, assigned to faces as a boundary condition | `PhAdditionalZone` with `zone_name`, `zone_type`, `temperature_reduction_factor` | Attached zone |
| Colour-by (new) | The shared component: one overlay, one panel legend, one viewport HUD legend, and a registry of modes any feature adds. A mode names an entity kind, a colour function and a label, and may supply derived geometry. Readouts register separately | | Colour by |
| Face record (new) | The classification record on one face: type, boundary condition, assembly id, Zone stamp, timestamps | | |
| Classify tool (new) | The modal viewport tool that writes face records | | Classify |
| Suggested classification (new) | The type and boundary condition the tool proposes for a hovered face from its normal and position; shown, never written without a click | | |
| Unclassified face (new) | A face inside a Zone with no face record | | shown only in the overlay's legend as a count |
| Incomplete face (new) | A face record missing a required type, boundary reference or assembly, or naming an invalid or unavailable referenced record; export severity follows the consumer matrix | | amber in the overlay and in the faces table |
| Classification overlay (new) | The Colour-by overlay in its three face modes: type, boundary condition, assembly | | |
| Faces table (new) | The panel inventory of face records for the current Zone or the whole model, with Locate | | |

`AirBoundary` is in the stored vocabulary because honeybee has it and the translation must round
trip it, but the tool does not offer it in this packet. See the decisions.

## The face record

```
face_type            "Wall" | "RoofCeiling" | "Floor" | "AirBoundary"
boundary_condition   "Outdoors" | "Ground" | "Adiabatic" | "Surface" | "AttachedZone", or absent after pair retirement
attached_zone_id     Attached zone record id; allowed only for "AttachedZone"; absence is an incomplete authoring state
assembly_id          record id of a model-library assembly, or absent
adjacency            present only when boundary_condition is "Surface"; written by Solve adjacencies
zone_id, segment, level   the Zone stamp, per the zones packet
schema_version, created_at, updated_at

No `source` field: nothing reads it (Q14).
```

Rules:

- The record lives on the face's own attribute dictionary. Supported explode, cut/paste and
  Restore Zone paths must preserve surviving payloads, subject to the zones packet's host gate;
  preserved payloads do not imply that adjacency references remain current.
- A face inside a repeated component shares its record across occurrences, as the zones packet
  and the predecessor's window reader already require. Independent classification requires
  explicit uniqueness, which PH-Composer never applies.
- Splitting must retain non-Surface classifications and surviving metadata. Copied adjacency data
  is invalid until explicitly re-solved under the zones packet's endpoint rules. Native dictionary
  survival and new face identity require host evidence; a copied dictionary is not a valid pair.
- A merge checks area-dependent assembly usage and invalidates affected pairs. Plugin-owned edits
  preserve payloads or refuse unresolved conflicts; native merge survival requires host evidence.
- `Surface` is never set by the tool. It is written by Solve adjacencies and cleared only when the
  boundary condition changes away from Surface, through the zones feature's public pair-removal contract. The operation's
  preview includes both surviving endpoints in its explicit mutation set; without that scope it
  refuses without writing. One caller-owned transaction removes the pair and applies the requested
  classification. The other endpoint retains its type, assembly and payloads but has no boundary
  condition until classified or re-solved. Retired faces remain visible with a needs-classification
  finding; they are not treated as untouched unclassified faces in a single-Zone model.
- Type-only and assembly-only edits preserve the boundary condition and reciprocal pair. A no-op
  writes nothing and creates no Undo entry. An explicit Reverse face geometry repair is separate;
  it must trigger the zones packet's geometry-staleness checks even though it preserves the record.
- Deleting an assembly that faces use requires a replacement, per the predecessor's accepted rule;
  a record naming a missing assembly is an incomplete face, never a silent drop.

## Behaviors

### The Classify tool

- Activated from the toolbar, the panel, or a right-click on a face. It is a `Sketchup::Tool`:
  the toolbar button is pressed, the cursor changes, Escape or a second click ends it, and it
  follows the drawing-tool state rule in the UI polish skill.
- The panel shows the tool's palette while it is active: face type chips (Wall, Roof, Floor),
  boundary condition chips (Outdoors, Ground, To neighbour, Attached zone with a picker and a
  "New attached zone" route; Surface shown disabled with "set by Solve adjacencies"), and an
  assembly picker that reads the model library with matching types listed first. A row with
  nothing selected means keep what the face has, so the tool can set only the assembly on
  already-typed faces, or only the boundary condition (Q10, Q21).
- Hovering a face shows the suggestion as a tooltip and a tinted preview: the type from the
  normal with honeybee's thresholds (roof at 60 degrees from up, floor at 130; Q6), and Ground
  when every vertex of the face is at or below the Zone's ground depth, a per-Zone field
  defaulting to the model's z=0 (Q4), else Outdoors.

  Corrected 2026-09-20. This read "the face's lowest point is at or below", which made every wall
  standing on grade a Ground suggestion, since such a wall starts exactly at the depth: on the
  host, Suggest classification set five of a plain box's six Faces to Ground when only the floor
  belonged there. honeybee's `get_bc_from_position`, which this packet cites as its source,
  returns Outdoors as soon as one vertex is above the depth. A wall on grade is Outdoors; only a
  Face lying wholly at or below grade is Ground. A basement wall becomes Ground by raising its
  Zone's ground depth above the wall, which is what the per-Zone field is for.

- Painting an assembly onto a face with no type fills the type from the assembly's `type` and the
  boundary condition from its `exterior_condition`. Both hold the palette's own words (assemblies
  Q2), so the fill is a copy: Attached zone leaves the zone to choose, and a blank hint fills
  nothing. A mismatch on an already-typed face is an info finding, never a refusal (Q7).
- All routes use explicit keep/set intent per field. Explicit palette values take precedence;
  keep preserves an authored value, and only an absent value eligible under Q7 receives an assembly
  hint. Assembly-only painting does not adopt geometric hover suggestions or overwrite an existing
  boundary condition. Auto-classify explicitly proposes geometric values instead. The preview shows
  the resolved patch, including missing references; application uses exactly that proposal.
- Click applies to one face. Click-drag paints every face the cursor crosses. Shift-click applies
  to all connected coplanar faces in the same Zone. Double-click keeps SketchUp's native meaning
  and is not overridden (Q9). A right-click item, **Select all faces of this type in Zone**,
  selects every face whose suggested type matches, so one click on the palette then classifies
  them; it is a selection command, not a paint gesture.
- A click on a face outside any Zone offers Make Zone inline, per the zones packet, and applies
  nothing until a Zone exists.
- Every application is one named Model operation, so one Undo reverts one gesture, including a
  drag over forty faces.

During click-drag, collect a deduplicated, bounded set of occurrence references and preview the
resolved changes without writing. Mouse-up completes the gesture; click and Shift-click use the
same completion boundary. Freeze palette intent for that gesture. Escape, tool deactivation or a
model/edit-context change cancels the pending gesture without writes. Escape first dismisses an
open bubble/dialog, then ends the tool and cancels its pending gesture, then clears selection.
Report a target-limit refusal instead of silently painting only part of the gesture; PLAN.md sets
and tests the bound.

Resolve Make Zone, inline creation and reciprocal-scope choices before opening a write transaction.
A target outside a Zone refuses the entire pending classification; Make Zone is its own explicit
action and the user then retries classification. If any target or precondition is invalid at
commit, refuse the entire batch. A failure during application rolls back every changed face and
paired endpoint. No transaction remains open while awaiting a dialog or further pointer input.

### Auto-classify a Zone

One action on the Zone row: **Suggest classification for this Zone**. It walks the Zone's faces
once, writes the suggested type and boundary condition to every face that has no record, sets no
assembly, and reports the counts. It is one Undo step and it never overwrites an existing record.
A single-family user can draw a box, make it a Zone, run this, and go straight to assigning
assemblies.

### Assigning assemblies

- The Classify tool with only an assembly chosen is the paint route. The faces table is the
  table route: select rows, choose an assembly, apply.
- Assembly usage, carried from the predecessor, now reads face records instead of designPH
  tables: the set of faces naming each assembly, measured by a scan and reported as of scan time.
  The Assemblies inventory's usage column and the delete-requires-replacement rule are unchanged.
- An assembly's `exterior` and `type` fields, which the predecessor's Assembly Builder already
  carries, are hints for the picker (walls first for a Wall face) and never a constraint.

### Operations other features use

Face records belong to this feature. The assemblies packet, and later window placement and
thermal bridges, reach them only through these registered operations (assemblies Q23). PLAN.md
fixes the action names and schemas against the transplanted APIs. Each works with the panel
closed and returns the same outcome to the panel, a console script and an external client.

| Operation | Contract |
| --- | --- |
| Face read | Face references with occurrence path, gross area in m2 (the face's own polygon; whether SketchUp's cut opening changes `Face#area` is measured in the window-types component spike, Q26), type, boundary condition and `assembly_id`. Read-only: it repairs nothing and marks nothing stale. The faces table and the assemblies usage scan share it, so there is one scan |
| Locate | Selects and reveals an explicit set of face references |
| Activate Classify with a preset | Starts the tool with the given palette choices, used by Paint onto faces |
| Reassign | An explicit face set, the new `assembly_id` and the expected current value per face. All or nothing. It opens its own `ModelOperation.perform` when called alone and joins the caller's when the assemblies delete command calls it, so delete with replacement is one Undo step |
| Classify | Explicit occurrence references, per-field keep/set intent, expected values, model/session and geometry/edit-context revision. Preview returns changed fields, required references and reciprocal scope; apply revalidates and commits all or nothing through the same transaction primitives as Reassign |
| Attached zone operations | Read, create, edit, duplicate and guarded delete/reassign through this feature's registered record kind and validated operations; no caller accesses dictionaries |

Reassign is the assembly-only operation: it preserves type and boundary fields. Classify may apply
the documented hint policy. Tool, table and scripts share Classify's validation and patch logic;
Auto-classify supplies explicit suggestions to that logic and never overwrites an existing record.
Requests target an explicit session and bind to the preview revision, including referenced records.
Use foundation retry/idempotency semantics; a duplicate retry cannot create another Undo entry.
Return changed references, findings and the resulting revision, distinguishing refusal, rollback,
no-op and success. Reads never mutate, start tools or open review dialogs.

PLAN.md includes a panel-closed script that reads face occurrences and an assembly, applies an
assembly-only change, then reads both endpoints of any Surface pairs back. Exact action schemas
bind to the transplanted APIs; these are required contracts, not implemented interfaces.

The assembly picker, the assembly Colour-by mode, the hint fill and the mismatch finding read
assemblies through that feature's assembly read, never its dictionary.

Opaque area net of windows is gross area less the glazed area the window-types packet reports per
host face reference. This feature declares that read as a dependency when window-types lands and
never reads window units itself. Until then the faces table and assembly usage show gross area
and say so.

### Attached zones

This feature owns the Attached zone record kind, registered through the foundation record engine.
Each record has a durable local UUID, schema version, timestamps, the fields below, `user_data`
and versioned extension payloads. Ordinary edits preserve metadata and unavailable-extension data;
unsupported schema edits refuse without rewriting or dropping payloads. Duplicate creates a new
UUID without reassigning existing faces. Library-provider import of this kind is outside the
four-kind libraries packet; hand entry remains complete.

An AttachedZone condition with no selected record is a visible incomplete authoring state.
Missing id, dangling id, invalid record and unavailable required schema/capability are distinct
findings and block canonical export. The default factor never manufactures a referenced record.
Cancelling inline creation writes neither a record nor the pending assignment; a previously
committed incomplete face stays incomplete. Successful inline create-and-assign is one atomic
operation, validated against the pending face proposal before either write.

Deleting a used Attached zone requires an explicit valid replacement or explicit reclassification
of every affected face in the same transaction. Preview actual references; refusal or cancellation
writes nothing. Changing away from AttachedZone clears `attached_zone_id`; changing only an
assembly or type preserves it. Replacing the referenced record preserves face identity, other
fields and payloads. No raw dictionary writes or hidden cross-feature scans are allowed.

- A Library tab beside Materials, Frames, Glazings and Psi-Install Types, plus inline creation
  from the boundary condition chip (Q21). A record is name, kind (garage, attic, crawlspace,
  stairwell, other), one temperature reduction factor, notes and datasheet links (Q20).
- The factor defaults to 0.95. Phius guidebook 6.9.1: in verification mode 0.95 is the lowest
  factor allowed without further evidence. A lower value is accepted, since Phius publishes a
  Temperature Reduction Factor and Auxiliary Space Heating Estimator (Excel, v26.1.3 as of
  August 2026) that justifies one with an auxiliary heating penalty; a value below 0.95 shows a
  warning naming that tool and expects its output linked as a datasheet. PH-Composer does not
  reimplement the estimator.
- An occupied residential or always-conditioned neighbour is To neighbour, not an Attached zone,
  per the same guidebook section. The tooltip on To neighbour says so.
- honeybee-ph's four PHPP-only reduction factors stay unexposed and are filled from the one.

### Colour-by: the shared visualization component

One component, built in this packet, that every later feature adds to (Q16, Q19). It is the
fourth contribution seam beside feature, provider and exporter.

- **Registry.** A mode is a name, the entity kind it colours, a colour function from entity to
  colour and label, and an optional sort for the legend. The entity kind is open: face and Zone
  here, Volume from the spaces packet, and any kind a later feature names through its public
  reader. A mode may also supply **derived geometry**, drawn by the service in the mode's colours
  and never added to the SKP; the spaces packet's Volume preview is the first. A **readout** is a
  separate registration for viewport text or a HUD block that does not depend on the active mode:
  the spaces packet registers Space labels and Selection totals (spaces Q22). The Classify tool
  has no mode registry. A feature that needs its own paint gesture ships its own
  `Sketchup::Tool` on the shared `core/` pick and drag primitives, as Mark floor does (spaces
  Q19). This packet registers
  face type, boundary condition and assembly. The zones packet registers Zone, Building-Segment and Level.
  Ventilation later registers served-by-unit and has-supply-air. One mode is active at a time.
- **Ownership and contract.** The shared Colour-by service owns registration and host drawing;
  features own pure mode projections and register explicit dependencies. Projections expose
  occurrence references, values, labels and unavailable states from public readers, with bounded
  entity enumeration and revision/invalidation rules. No mode reads another feature's internals.
  Store service state through generic session feature state; ModelSession names no mode or feature.
  PLAN.md names the service entrypoint and proves the contract with Zone modes and a synthetic
  outside mode, without new branches in the shell, session or shared renderer.
- **Overlay.** One `Sketchup::Overlay` owned by the ModelSession, following the predecessor's
  window overlay rules: built incrementally from the same reader as the faces table, cleared when
  geometry, tag, scene or active context invalidates it, republished only when coherent.
  Materials are never written; switching off leaves the model as drawn (Q15). Bake-to-materials
  is deferred indefinitely.
- **Panel legend.** Each colour with its label and count. Click a row to select and zoom to those
  entities; hover to highlight them; "Show only this" greys every other entity (Q18).
- **Viewport HUD legend.** While a mode is active, the overlay also draws a compact text legend
  in the upper left of the viewport, designPH-style, listing the active mode, each colour swatch,
  label and count. It appears with the mode and disappears with it, needs no panel visible, and
  is what a screenshot for QA carries (Q16).
- **Palette (Q17).** honeybee's own defaults, so a modeler sees the same colours in SketchUp,
  Rhino and honeybee-display. Type: Wall 230,180,60; Roof 128,20,20; Floor 128,128,128; Air
  boundary 255,255,200. Boundary condition: Outdoors 64,180,255; Ground 165,82,0; To neighbour
  255,128,128; Surface 0,128,0; Attached zone takes honeybee's Other, 255,255,200, until the
  interview on ventilation colours gives it a distinct hue. Assembly mode uses each assembly's
  display colour, a field defaulted from a ramp by record id and editable (assemblies Q6). Zone modes
  use a categorical ramp. In every mode, unclassified is hatched and incomplete is amber.
- **Default (Q12).** Off at rest, remembered per user; forced on while the Classify tool is
  active, in the mode the palette last touched.
- **Spike complete (Q22).** [Phase 0 B2](../../../archive/phase-00-foundation/evidence/spike-overlay.md)
  passed alpha, depth, picking and performance checks on the proving host. Plan filled modes;
  feature-specific cache invalidation and performance acceptance remain outstanding. Other
  platforms require their own host evidence.

### The faces table

- A tab body under the Zones section, or under Overview in a single-Zone model, per the zones
  packet's Q13 rule. One row per face record: Zone, type, boundary condition, assembly, area, and
  state. Filter, group and order come from the shared view controls; Locate follows the
  predecessor's rule and enters the owning Zone's context.
- Cells for type, boundary condition and assembly are editable chips, using the shared cell grid
  and `expected_value` guard. Area is read-only.
- Unclassified faces are not rows. They are the legend's count and its Locate.

### Validation rows

| Finding | Severity | Repair |
| --- | --- | --- |
| Opaque face to be emitted without a valid assembly/construction | blocking for canonical export | Assign or repair an assembly |
| Face record names a missing assembly | blocking for export | Choose a replacement |
| AttachedZone reference absent, dangling, invalid or required capability unavailable | blocking for canonical export; distinct finding codes | Choose or repair an Attached zone |
| Face to be emitted has no valid type | blocking for canonical export | Classify |
| Retired adjacency needs boundary classification | warning; blocking for EnergyPlus | Classify or Solve adjacencies |
| Unclassified faces in a multi-Zone model | warning | Suggest classification, or Classify |
| Unclassified faces in a single-Zone model | none; count in the legend only | |
| Face type disagrees with the suggested type by more than the thresholds (a "wall" facing up) | info | Reclassify or keep |
| Assembly type or exterior condition disagrees with the face | info | Reclassify or keep |
| Ground face whose lowest point is above the Zone's ground depth | info | Reclassify or keep |
| Face normal points into its Zone | info | Reverse face, keeping the record (Q13) |
| Attached zone factor below 0.95 | warning | Link the Phius estimator output, or raise the factor |
| Air boundary present | blocking for export in this packet | Reclassify |
| Face record outside any Zone | warning | Make Zone |

### Export mapping

Assembly requirements apply before writing the canonical HBJSON/report pair. Every emitted opaque
face receives an explicit valid construction from its authored assembly; this packet supports no
assembly-less emitted opaque face. Intra-Building-Segment Surface faces still need constructions
because they exist in the canonical HBJSON even though PHX later drops them. This deliberately
replaces the earlier Outdoors/Ground-only wording under the authorized architecture correction.

| Face state | Canonical HBJSON requirement | METr consequence |
| --- | --- | --- |
| Outdoors or Ground | Valid authored assembly required | Retained component uses that construction |
| AttachedZone | Valid authored assembly and Attached zone reference required | Retained component uses that construction and zone data |
| Adiabatic / To neighbour | Valid authored assembly required | Retained to-neighbour component uses that construction |
| Current reciprocal Surface, same Building-Segment | Valid authored assembly on both emitted faces required | PHX omits intra-segment faces |
| Current reciprocal Surface, different Building-Segments | Valid authored assembly on both emitted faces required | Retained to-neighbour components use those constructions |
| Stale/unresolved Surface, or condition absent after retirement | Omit with the zones packet's findings; absence of an assembly alone adds no block to an omitted face | No component; omission reported |
| AirBoundary | Unsupported and blocking in this packet | Not exported |

An explicit dangling assembly id remains an independent blocking finding, including on an omitted
face. Unclassified faces retain their existing omission rule. Never let honeybee defaults or the
development fixture construction substitute for a missing authored value. Construction lookup
failures carry a subject-specific finding and block the canonical pair; no exporter repairs them.

| Field | HBJSON | METr, via PHX |
| --- | --- | --- |
| face type | `Face.type` | PHX component colour and type from the same mapping PHX already applies |
| boundary condition | `Face.boundary_condition`; Surface carries the adjacency's face and Room identifiers; Attached zone becomes honeybee-ph `PhAdditionalZone` with the record's name, kind and factor | exposure exterior: Outdoors, Ground, to-neighbour for Adiabatic and cross-Building-Segment Surface, attached zone with its factor; intra-Building-Segment Surface omitted |
| assembly | `Face.properties.energy.construction`. The face section declares the assemblies builder's `constructions_by_assembly_id` result as a dependency and assigns from it (assemblies Q23). Failed required lookup produces a blocking incomplete-face finding | PHX construction |
| area and geometry | from the face through the occurrence path, transforms accumulated once | |
| unclassified face | not exported; count in the report | |
| incomplete face | consumer matrix and validation determine block versus reported omission; named in the report | no inferred construction or boundary data |

The zones packet owns pair freshness, reciprocal integrity and emitted-target checks. Stale or
unresolved Surface faces and faces awaiting classification after retirement are reported omissions,
not emitted with guessed conditions. Their missing boundary condition alone is warning-only for
HBJSON and METr, unlike the independent blocking assembly findings above. The contributor accounts
for paired counterparts withheld when one endpoint cannot be emitted.

The Export report gets a faces section: counts by type and boundary condition per Zone, the
envelope area per assembly, and every finding above with its face and Zone.

## Non-goals

- Thermal bridges, window placement and shading. Their own packets.
- Air boundaries. Stored vocabulary only; the tool does not offer them and export blocks on them.
- Any change to face geometry other than the Reverse face repair: no splitting, healing or
  merging. The suggestion uses the face's actual normal.
- Baking colours to SketchUp materials. Deferred indefinitely (Q15).
- The Phius temperature reduction factor estimator. Linked, not reimplemented.
- Per-face U-value overrides. A face's thermal properties come from its assembly.
- Reading designPH or any other extension's classification.

## Decisions recorded

Interviewed 2026-09-18, two rounds, Ed's answers. Each is cited where it applies above.

| # | Decision | Answer |
| --- | --- | --- |
| Q1 | Domain model | honeybee-shaped Ruby records in the SKP, translated at export; honeybee never run live |
| Q2 | Boundary condition set | Five: Outdoors, Ground, To neighbour, Attached zone (a Library record), Surface by solver |
| Q3 | Ground kinds | One Ground; foundation type is per Zone in a later packet |
| Q4 | Ground suggestion | Lowest point at or below a per-Zone ground depth, default z=0 |
| Q5 | Face type labels | Wall, Roof, Floor; Roof's tooltip covers ceilings between Zones |
| Q6 | Roof and floor thresholds | honeybee's 60 and 130 degrees |
| Q7 | Assembly type and the face | An assembly fills an untyped face's type and boundary condition from its own fields; mismatch is an info finding |
| Q8 | Air boundaries | Refused in this packet |
| Q9 | Double-click | Stays native SketchUp; a right-click "Select all faces of this type in Zone" instead |
| Q10 | Keep in the palette | An unselected row means keep |
| Q11 | Faces table placement | Under Zones and Overview, as part of a navigable model tree |
| Q12 | Overlay default | User preference at rest; forced on while the Classify tool is active |
| Q13 | Reversed faces | One-click Reverse face repair that keeps the record |
| Q14 | `source` field | Dropped |
| Q15 | Overlay or materials | Overlay only; bake to materials deferred indefinitely |
| Q16 | Shared Colour-by component | Yes, with a registry of modes as a contribution seam, and a viewport HUD legend shown while a mode is active |
| Q17 | Palette | Fixed hues, honeybee's defaults; assembly mode uses an assembly display colour |
| Q18 | Legend interaction | Click to select and zoom, hover to highlight, counts, Show only this |
| Q19 | Zone modes | Component built here; the zones packet registers Zone, Building-Segment and Level |
| Q20 | Attached zone record | Name, kind, one factor, notes, datasheet links; PHPP-only factors unexposed |
| Q21 | Where Attached zones live | A Library tab, plus inline creation from the boundary condition chip |
| Q22 | Overlay host facts | Spike now, before PLAN.md |

## Acceptance shape

Delivery update, 2026-09-20: D12 defers METr exporter development and consumer acceptance.
The HBJSON and authoring checks below remain Phase 1 work as allocated in PLAN.md; METr-specific
checks wait for the exporter's separately scheduled milestone. Existing consumer mappings remain
requirements for that future work.

Architecture corrections authorized 2026-09-18 supplement the interview: Attached zone reference
lifecycle, the assembly matrix, field-level intent and atomic gesture completion are now part of
this contract. Q22's spike passed in Phase 0; see [B2 evidence](../../../archive/phase-00-foundation/evidence/spike-overlay.md).
Feature cache invalidation and native acceptance remain pending.

Offline: fixtures for a single-Zone box (six faces, one gesture per type), a Zone under a rotated
wrapper group, a Zone that is a repeated component (shared records, finding), a face split after
classification (both halves keep the record), an assembly deletion with replacement, a Ground
suggestion at and above z=0, and a two-Zone model after Solve adjacencies where reclassifying a
Surface face clears the adjacency on both sides. Each proves the record, the overlay projection,
the validation rows and the export mapping.

Add these focused contract cases:

- AttachedZone hints with no selected record, cancelled inline creation, successful create-and-assign,
  two faces sharing one Attached zone, delete with replacement, and switching away from AttachedZone.
  Assert actual references, distinct incomplete states and atomic outcomes. Exercise unsupported
  schemas and preservation of `user_data` and unavailable-extension payloads.
- Every boundary condition with a valid, absent and dangling assembly reference; both intra- and
  cross-Building-Segment Surface pairs. Check the matrix, construction references and blocking
  versus omission accounting. No downstream default may hide a missing authored construction.
- Assembly-only and type-only changes on a current pair, explicit choices conflicting with hints,
  no-ops and boundary changes retiring a pair. Check both endpoints, retained fields and metadata.
- Escape, deactivation, changed context/model, an invalid target, target-limit overflow, failure
  after the first write and duplicate retry. Assert no partial writes and correct Undo grouping.
- Panel-closed read/preview/apply/read-back through the public operations, with stale and wrong-session
  refusal. Register Zone modes and a synthetic outside Colour-by mode without private hooks.

Host gate, fresh process: draw a box, Make Zone, run Suggest classification, paint one assembly
onto four walls by drag, a second onto the roof by click, Undo twice and see each gesture revert
whole, switch the overlay through all three modes and read the HUD legend from a window capture,
Locate from the panel legend, mark one wall Attached zone from a garage record, split a wall and
see both halves classified, Reverse face on an inward wall, export HBJSON and the METr model and
confirm the face types, boundary conditions, attached zone and constructions arrive.

Extend that fresh-process walkthrough with the reference and gesture cases above, native Undo/Redo,
save/reopen, cancellation with focus in the panel and a dialog opened before commit. Check that no
transaction spans a review dialog, and that rejected/cancelled gestures change no face. Record
feature overlay capability and capture evidence against the completed B2 baseline.

## Prior art and evidence

- honeybee face typing and boundary conditions: `honeybee-core/honeybee/facetype.py`
  (`get_type_from_normal`, roof 60, floor 130) and `boundarycondition.py` (`get_bc_from_position`).
- honeybee-ph adds no Face properties (`honeybee_ph/honeybee_ph/properties/face.py`).
- PHX exposure and colour mapping: `PHX/PHX/from_HBJSON/create_building.py`.
- Predecessor assembly usage scan, window overlay rules, Locate and the shared cell grid:
  `../../ph-navigator-sketchup/planning/archive/` and `context/TECH_STACK.md` here.
- honeybee's default face type and boundary condition colours: `honeybee-core/honeybee/face.py`,
  `TYPE_COLORS` and `BC_COLORS`.
- honeybee-ph attached zone boundary condition: `honeybee_ph/honeybee_energy_ph/boundarycondition.py`,
  `PhAdditionalZone`.
- Phius guidebook 6.9.1 Attached Zones, in the phius-rules corpus; the Temperature Reduction
  Factor and Auxiliary Space Heating Estimator at
  https://www.phius.org/phius-temperature-reduction-factor-auxiliary-space-heating-estimator is not
  yet in that corpus.
- designPH's own classify-by-painting interaction and its upper-left results text are the
  ergonomic precedent for the tool and the HUD legend, not a data source.
