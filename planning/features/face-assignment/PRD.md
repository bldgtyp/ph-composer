# Face assignment: behavior contract

DATE: 2026-09-18
STATUS: Scoped. Interviewed 2026-09-18 in two rounds, 22 decisions recorded below. PLAN.md follows the overlay spike and the foundation transplant.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (no remote)

## Problem

designPH owned envelope classification in the predecessor: which faces are the thermal envelope,
what each one is, what is on the other side, and which construction it carries. PassiveBuilder
has to do this itself, and it is the first thing a user does in every model. Everything downstream
reads it: assembly usage, window placement, thermal bridges, iCFA, the HBJSON Room faces and the
METr envelope.

The zones-and-adjacency packet settled the container: a face is classified in the context of the
Zone group that owns it, interior faces between Zones are found by Solve adjacencies, and the
unpaired remainder of any face is this packet's job. This packet settles the face record, the
tool that writes it, what the model shows, and what validation and export do with it.

## The domain model this packet rests on

Confirmed by Ed 2026-09-18 (Q1): the authored model is a set of honeybee-shaped Ruby records in
the SKP, translated to honeybee objects at export. PassiveBuilder does not run honeybee live and
does not invent its own vocabulary where honeybee has one. A face record therefore uses
honeybee's face types and boundary conditions by their honeybee names as stored values, and adds
only what authoring needs: identity, the Zone stamp, and the states a partial model has that a
simulation-ready one does not. The reasoning is in the founding brief's decisions table.

## Decision

- One **face record** per classified face, in PassiveBuilder's own dictionary on the face,
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
  incomplete records (a face with a type and no assembly) are findings that block export only
  when the face is Outdoors or Ground.

## Vocabulary

Carried from `context/UBIQUITOUS_LANGUAGE.md`; new terms this packet adds are marked.

| Term | Meaning | Stored value | Shown as |
| --- | --- | --- | --- |
| Envelope face | A face with a face record whose boundary condition is Outdoors or Ground | | |
| Face type | honeybee face type | `Wall`, `RoofCeiling`, `Floor`, `AirBoundary` | Wall, Roof (tooltip: also ceilings between Zones), Floor, Air boundary |
| Boundary condition | What is on the other side | `Outdoors`, `Ground`, `Adiabatic`, `Surface`, honeybee-ph `PhAdditionalZone` | Outdoors, Ground, To neighbour, Surface, Attached zone |
| Attached zone (new) | A named unconditioned space outside the envelope (garage, attic, crawlspace) with one temperature reduction factor; a Library record kind, assigned to faces as a boundary condition | `PhAdditionalZone` with `zone_name`, `zone_type`, `temperature_reduction_factor` | Attached zone |
| Colour-by (new) | The shared component: one overlay, one panel legend, one viewport HUD legend, and a registry of modes any feature adds. A mode names an entity kind (face or Zone), a colour function and a label | | Colour by |
| Face record (new) | The classification record on one face: type, boundary condition, assembly id, Zone stamp, timestamps | | |
| Classify tool (new) | The modal viewport tool that writes face records | | Classify |
| Suggested classification (new) | The type and boundary condition the tool proposes for a hovered face from its normal and position; shown, never written without a click | | |
| Unclassified face (new) | A face inside a Zone with no face record | | shown only in the overlay's legend as a count |
| Incomplete face (new) | A face record missing its assembly, or naming an assembly that no longer exists | | amber in the overlay and in the faces table |
| Classification overlay (new) | The Colour-by overlay in its three face modes: type, boundary condition, assembly | | |
| Faces table (new) | The panel inventory of face records for the current Zone or the whole model, with Locate | | |

`AirBoundary` is in the stored vocabulary because honeybee has it and the translation must round
trip it, but the tool does not offer it in this packet. See the decisions.

## The face record

```
face_type            "Wall" | "RoofCeiling" | "Floor" | "AirBoundary"
boundary_condition   "Outdoors" | "Ground" | "Adiabatic" | "Surface" | "AttachedZone"
attached_zone_id     record id of an Attached zone; present only when boundary_condition is "AttachedZone"
assembly_id          record id of a model-library assembly, or absent
adjacency            present only when boundary_condition is "Surface"; written by Solve adjacencies
zone_id, segment, level   the Zone stamp, per the zones packet
schema_version, created_at, updated_at

No `source` field: nothing reads it (Q14).
```

Rules:

- The record lives on the face's own attribute dictionary, so it survives explode, cut, paste and
  Restore Zone with the face.
- A face inside a repeated component shares its record across occurrences, as the zones packet
  and the predecessor's window reader already require. Independent classification requires
  explicit uniqueness, which PassiveBuilder never applies.
- Splitting a face in SketchUp gives the new faces copies of the original's dictionary. That is
  SketchUp's behavior and it is the right one here: both halves keep the classification.
- Merging faces keeps one dictionary. The deferred pass notices a record whose face area changed
  materially and marks the assembly usage stale, nothing more.
- `Surface` is never set by the tool. It is written by Solve adjacencies and cleared when the user
  reclassifies the face, which also removes the adjacency on both sides.
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
  when the face's lowest point is at or below the Zone's ground depth, a per-Zone field defaulting
  to the model's z=0 (Q4), else Outdoors. When the palette has an explicit choice, the preview
  shows that choice instead.
- Painting an assembly onto a face with no type fills the type from the assembly's `type` and the
  boundary condition from its `exterior_condition`. Both hold the palette's own words (assemblies
  Q2), so the fill is a copy: Attached zone leaves the zone to choose, and a blank hint fills
  nothing. A mismatch on an already-typed face is an info finding, never a refusal (Q7).
- Click applies to one face. Click-drag paints every face the cursor crosses. Shift-click applies
  to all connected coplanar faces in the same Zone. Double-click keeps SketchUp's native meaning
  and is not overridden (Q9). A right-click item, **Select all faces of this type in Zone**,
  selects every face whose suggested type matches, so one click on the palette then classifies
  them; it is a selection command, not a paint gesture.
- A click on a face outside any Zone offers Make Zone inline, per the zones packet, and applies
  nothing until a Zone exists.
- Every application is one named Model operation, so one Undo reverts one gesture, including a
  drag over forty faces.
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

### Attached zones

- A Library tab beside Materials, Frames, Glazings and Psi-Install Types, plus inline creation
  from the boundary condition chip (Q21). A record is name, kind (garage, attic, crawlspace,
  stairwell, other), one temperature reduction factor, notes and datasheet links (Q20).
- The factor defaults to 0.95. Phius guidebook 6.9.1: in verification mode 0.95 is the lowest
  factor allowed without further evidence. A lower value is accepted, since Phius publishes a
  Temperature Reduction Factor and Auxiliary Space Heating Estimator (Excel, v26.1.3 as of
  August 2026) that justifies one with an auxiliary heating penalty; a value below 0.95 shows a
  warning naming that tool and expects its output linked as a datasheet. PassiveBuilder does not
  reimplement the estimator.
- An occupied residential or always-conditioned neighbour is To neighbour, not an Attached zone,
  per the same guidebook section. The tooltip on To neighbour says so.
- honeybee-ph's four PHPP-only reduction factors stay unexposed and are filled from the one.

### Colour-by: the shared visualization component

One component, built in this packet, that every later feature adds to (Q16, Q19). It is the
fourth contribution seam beside feature, provider and exporter.

- **Registry.** A mode is a name, the entity kind it colours (face or Zone), a colour function
  from entity to colour and label, and an optional sort for the legend. This packet registers
  face type, boundary condition and assembly. The zones packet registers Zone, Building-Segment and Level.
  Ventilation later registers served-by-unit and has-supply-air. One mode is active at a time.
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
  display colour, a new field defaulting from its outermost layer's material colour. Zone modes
  use a categorical ramp. In every mode, unclassified is hatched and incomplete is amber.
- **Default (Q12).** Off at rest, remembered per user; forced on while the Classify tool is
  active, in the mode the palette last touched.
- **Spike first (Q22).** Before PLAN.md, a probe through the predecessor's bridge measures on the
  proving host whether an overlay polygon fill honours alpha and depth-tests against the model,
  and the frame cost of a few thousand filled faces with batching. If fills draw through walls,
  the design falls back to edge-plus-label and the palette work waits.

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
| Envelope face without an assembly | blocking for export | Assign an assembly |
| Face record names a missing assembly | blocking for export | Choose a replacement |
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

| Field | HBJSON | METr, via PHX |
| --- | --- | --- |
| face type | `Face.type` | PHX component colour and type from the same mapping PHX already applies |
| boundary condition | `Face.boundary_condition`; Surface carries the adjacency's face and Room identifiers; Attached zone becomes honeybee-ph `PhAdditionalZone` with the record's name, kind and factor | exposure exterior: Outdoors, Ground, to-neighbour for Adiabatic and cross-Building-Segment Surface, attached zone with its factor; intra-Building-Segment Surface omitted |
| assembly | `Face.properties.energy.construction`, built by the existing assembly translation | PHX construction |
| area and geometry | from the face through the occurrence path, transforms accumulated once | |
| unclassified face | not exported; count in the report | |
| incomplete face | export blocked; named in the report | |

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

Offline: fixtures for a single-Zone box (six faces, one gesture per type), a Zone under a rotated
wrapper group, a Zone that is a repeated component (shared records, finding), a face split after
classification (both halves keep the record), an assembly deletion with replacement, a Ground
suggestion at and above z=0, and a two-Zone model after Solve adjacencies where reclassifying a
Surface face clears the adjacency on both sides. Each proves the record, the overlay projection,
the validation rows and the export mapping.

Host gate, fresh process: draw a box, Make Zone, run Suggest classification, paint one assembly
onto four walls by drag, a second onto the roof by click, Undo twice and see each gesture revert
whole, switch the overlay through all three modes and read the HUD legend from a window capture,
Locate from the panel legend, mark one wall Attached zone from a garage record, split a wall and
see both halves classified, Reverse face on an inward wall, export HBJSON and the METr model and
confirm the face types, boundary conditions, attached zone and constructions arrive.

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
