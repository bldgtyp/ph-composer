# Assemblies and materials: behavior contract

DATE: 2026-09-18
STATUS: Scoped. Interviewed 2026-09-18 in two rounds, 18 decisions recorded below. PLAN.md follows the foundation transplant.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (no remote)

## Problem

Every classified face needs an assembly, and a Phius model needs that assembly layer by layer:
METr and WUFI-Passive take materials, thicknesses and mixed layers, not a bare U-value. The
predecessor built the authoring half and proved it on the host: a graphical Assembly Builder, a
Materials inventory, shared material records, usage, guarded delete and an HBJSON export.

About a third of that feature existed to live beside designPH. designPH held the face-to-assembly
assignment, so the predecessor pushed each assembly into designPH's library as an equivalent
single layer, adopted assemblies designPH already had, and reviewed differences when a designPH
row changed. PassiveBuilder owns the face record, so that whole loop has no job. This packet is
the predecessor's feature with the loop removed and the honeybee mapping tightened.

## Port disposition

Measured on the predecessor at `f358ebf`: `features/assemblies/` is 4,103 lines of Ruby. Detail
lives in `../ph-navigator-sketchup/planning/archive/assembly-builder/`; this table is the ruling.

| Part | Lines | Disposition |
| --- | --- | --- |
| `material_schema`, `assembly_schema`, `attrs`, `model_library` | 364 | Port. Drop the `designph` field and the designPH source kind |
| `builder`, `commands/` (assembly, layers, material, material_resolution, change) | 1,083 | Port unchanged in behavior |
| `thermal`, `validation`, `snapshot`, `actions`, `message_parts` | 729 | Port. Validation loses its push and difference rows |
| `usage/` (scan, row_index, task) | 416 | Adapt. The scan reads face records, not designPH tables |
| `export_contract`, `export_report` | 178 | Adapt. Drops the push, difference and packed sections |
| `push/`, `adoption/`, `designph/`, `states`, `origin`, `designph_cell` | 1,291 | Drop |
| Python: `constructions/`, `phn_assemblies/`, `contract/sections/assemblies.py` and `assembly_records.py` in the translation package | about 900 | Port. This is the code that writes `OpaqueConstruction` and the division grid. Drop the declared-U sandwich and the designPH table resolution in `constructions/tables.py` |
| Panel: Builder SVG, toolbar, property bubbles, inventories, library sidebar | not counted | Port. Drop the push chip, the difference banner and the adoption view |

The predecessor's panel is the starting UI, as Ed directed on 2026-09-18.

## Decision

- An **Assembly** is a model-local record of ordered **Layers**. A Layer owns a thickness and one
  or more **Layer-Segments**. A Layer-Segment names one shared **Material**, a width, and
  optionally a steel stud spacing. One Material record serves every assembly that uses it.
- Assembly, Layer and Material are METr's own screen words and PassiveBuilder uses them on screen
  and in records. honeybee says `OpaqueConstruction` and `EnergyMaterial`; the mapping is recorded
  the way Zone maps to `Room` (Q1).
- Every assembly has real layers. The predecessor's declared-U kind is removed (Q4). What is
  exported is what the user sees in the Builder.
- The face record's `assembly_id` is the only assignment. There is no second copy of an
  assignment anywhere, and nothing to push, adopt or reconcile.
- The assembly's `type` and `exterior_condition` stay as hints, as face-assignment Q7 uses them,
  and store the Classify palette's words (Q2).
- U-values are computed in Ruby for display. The Builder header shows two, with surface films and
  without, as the predecessor does (Q8). The exported model carries the layers, and METr computes
  its own result. PassiveBuilder claims nothing about METr's number.
- An assigned incomplete assembly blocks export. An unused incomplete assembly does not.

## Vocabulary

| Term | Meaning | honeybee |
| --- | --- | --- |
| Assembly | A reusable construction definition: ordered layers, outside to inside or the reverse per its orientation | `OpaqueConstruction` |
| Layer | One position in an assembly. Owns thickness. Holds one or more Layer-Segments | One `EnergyMaterial` in the construction's material list |
| Layer-Segment | One side-by-side strip of a Layer: a Material and a width. Always written with its qualifier (Q3) | One column of the layer material's honeybee-ph `PhDivisionGrid` |
| Building-Segment | The zones packet's unit that becomes one METr model. Always written with its qualifier (Q3) | honeybee-ph `BldgSegment` |
| Mixed layer | A Layer with two or more Layer-Segments, such as studs and cavity insulation | An `EnergyMaterial` whose `properties.ph.divisions` is populated |
| Steel stud layer | A mixed layer whose stud Layer-Segment carries a spacing | `PhDivisionGrid.is_a_steel_stud_cavity` |
| Material | Shared thermal properties and a display colour. Thickness is never on the Material | `EnergyMaterial` properties, `properties.ph.ph_color` |
| SD assembly (later) | A placeholder for early design: three real layers sized to a target U-value | An ordinary `OpaqueConstruction` |
| Assembly usage | The faces whose record names this assembly, as of the last scan | Derived |

## Records

Carried from the predecessor with the changes the interview made. Units are in the key names.

```
Material     id (mat_), name, category, conductivity_w_mk, density_kg_m3,
             specific_heat_j_kgk, emissivity, color, notes, source,
             datasheet_links, schema_version, created_at, updated_at

Assembly     id (asm_), name, type, orientation, exterior_condition,
             ventilated_cladding, color, layers[], air_barrier, notes,
             photo_collections, source, schema_version, created_at, updated_at

  layer      id (lyr_), thickness_mm, segments[]
  segment    id (seg_), width_mm, material_id, is_continuous_insulation,
             steel_stud_spacing_mm
```

- Removed: `kind`, `declared_u_w_m2k`, `declared_thickness_mm` (Q4), the `designph` push slot and
  the `designph_model` source kind. `source` keeps `manual`, `derived` and `library`.
- Added: `color` (Q6) and `ventilated_cladding` (Q8).
- `type` is `Wall`, `RoofCeiling`, `Floor` or absent. `exterior_condition` is `Outdoors`, `Ground`,
  `AttachedZone`, `Adiabatic` or absent, shown as the palette shows them, To neighbour included
  (Q2).
- The record key stays `segments`. Only the written word carries the qualifier (Q3, Q19).
- `air_barrier`, `photo_collections` and `ventilated_cladding` are local and not exported (Q9,
  Q10, Q20). The Export report says so once per model.

## Behaviors

### Carried over unchanged

These were settled in the predecessor's interviews and do not depend on designPH. They are already
in [docs/PRODUCT.md](../../../docs/PRODUCT.md) and are not reopened here.

- Partially built assemblies save and reopen. Missing inputs withhold the U-value; they never
  show zero.
- A committed edit updates every face that names the assembly. To change only some faces,
  duplicate the assembly and assign the copy.
- Duplicate Assembly reuses its materials and datasheets and starts with empty photo collections.
- Deleting an assigned assembly requires a replacement, shows the affected faces and can be
  cancelled. Deleting an in-use material requires a replacement for every use.
- Conductivity, density and specific heat belong to the Material. Thickness belongs to the layer.
- Material categories are preset with Uncategorized available. A membrane material cannot sit in
  a mixed layer.
- The Builder edits the drawing through an always-visible toolbar and anchored property bubbles.
  Total thickness and U-value stay in the header.
- Both inventories share Filter, Group by, Order by and Direction. Filtering never changes the
  model or the export scope.
- The library sidebar sits beside the Builder and beside Library / Materials. Its rules are in the
  [libraries packet](../libraries/PRD.md).

### Changed by the pivot

- **Usage.** The usage scan walks face records and counts faces and area per `assembly_id`. It
  runs when the panel opens and on Refresh, shows its as-of time and a stale mark, and is never
  driven by an observer (Q13). It no longer needs designPH, so it has no unknown state.
- **Locate.** A usage row selects its faces in the model, through the faces table's Locate.
- **Assign from here.** The Assemblies inventory row gains **Paint onto faces**, which starts the
  Classify tool with only this assembly chosen. It is the same tool, entered from the other end
  (Q14).
- **Colour.** The assembly Colour-by mode reads the Assembly's own `color`, defaulted from a ramp
  by record id and editable in the inventory and the Builder header (Q6).
- **Films and two U-values.** The Builder header shows the U-value with surface films and
  without. Films come from `type`, `exterior_condition` and `ventilated_cladding`, with the
  predecessor's constants. They are display only (Q8).
- **Interior assemblies.** To neighbour is a hint value, so partition and party-wall assemblies
  sort first for those faces. When Solve adjacencies pairs two faces naming different assemblies,
  that is a warning. One side naming none is the ordinary incomplete face. The exporter writes
  each face's own construction and reverses nothing (Q7).

### Dropped

Declared-U assemblies (Q4). Push to designPH, push states, the equivalent-layer packer and its error disclosure, adoption from
designPH rows, difference review, the digest migration, and every finding that names designPH.

### Validation rows

| Finding | Severity | When |
| --- | --- | --- |
| Assembly incomplete | Blocks export when assigned, info when unused | A segment has no material, or a material lacks conductivity |
| Material incomplete | Same rule, through the assemblies that use it | Conductivity missing. Density and specific heat missing is a warning, with the export default disclosed |
| Paired faces name different assemblies | Warning | Q7 |
| Type hint mismatch | Info | Carried from face-assignment Q7 |
| Unreadable record | Blocks export | The record fails its schema |

### Export mapping

Checked against `honeybee_ph/honeybee_energy_ph/properties/materials/opaque.py` and
`PHX/from_HBJSON/create_assemblies.py` on 2026-09-18.

| PassiveBuilder | honeybee |
| --- | --- |
| Assembly | `OpaqueConstruction`, identifier from the record id, display name from the name |
| Layer order | Material list, outside first. `orientation` decides whether the stored order is reversed on write |
| Single-segment layer | One `EnergyMaterial` with the layer's thickness and the Material's properties |
| Mixed layer | One `EnergyMaterial` carrying a `PhDivisionGrid`: one row, one column per segment, column widths from `width_mm`, a cell material per segment. PHX reads `properties.ph.divisions` and writes METr's layer divisions |
| Steel stud layer | The same grid with `is_a_steel_stud_cavity` set. PHX then takes the cavity material as the source layer |
| Material colour | `properties.ph.ph_color` |
| Face assignment | `Face.properties.energy.construction` |

`EnergyMaterial` needs values the Material record does not hold: roughness, thermal, solar and
visible absorptance. The exporter writes honeybee's defaults (MediumRough, 0.9, 0.7, 0.7), uses
the record's emissivity for thermal absorptance when present, and says so in the Export report.
A Material with no density or specific heat exports with a disclosed default and a warning,
because honeybee's `EnergyMaterial` requires both (Q5).

## Later, decided now

**New SD assembly** (Q16, later phase). The action asks for a name, a target U-value and a
thickness, and builds three ordinary layers: a thin mass layer, a core whose Material's
conductivity is back-solved, and a thin mass layer. The generated Materials are named for the
assembly. No no-mass Material kind is added (Q17). The assembly carries a `placeholder` flag that
the helper sets and the user clears, and an assigned placeholder is one warning at export (Q18).

A per-component `Rse` carried through PHX to METr, so a ventilated film reaches the calculated
model, is a recorded follow-up with no issue filed (Q20).

## Non-goals

Assemblies without layers. Hygrothermal properties. Assembly-level thermal bridge allowances. Cost and embodied carbon. A
fourth layer kind for ventilated cavities beyond what the predecessor supports. Any write back to
a library. designPH in any form.

## Decisions recorded

Round 1, 2026-09-18. Answers are Ed's.

| # | Decision | Answer |
| --- | --- | --- |
| Q1 | Words | Assembly, Layer and Material on screen and in records, matching METr's own screen words. Mapped to `OpaqueConstruction` and `EnergyMaterial` |
| Q2 | Hint values | `type` is Wall, RoofCeiling, Floor or blank. `exterior_condition` is Outdoors, Ground, Attached zone, To neighbour or blank. `ventilated` leaves the enum |
| Q3 | Segment collision | Both carry a qualifier everywhere: **Building-Segment** (`BldgSegment`) and **Layer-Segment** (the strip in a layer). The bare word is not used |
| Q4 | Declared-U assemblies | Removed. Every assembly has real layers. Early design uses the SD technique from honeybee-grasshopper-ph ("HBPH - Create SD Constructions": mass layer, resistance layer, mass layer), built as a visible layered assembly, so the user sees what is exported |
| Q5 | Missing density or specific heat | Disclosed default and a warning. Missing conductivity blocks |
| Q6 | Assembly colour | A `color` field on the Assembly, defaulted from a ramp by record id, editable |
| Q8 | Films | Display only, the predecessor's constants. The Builder shows both U-values, with films and without, as the predecessor does. A `ventilated_cladding` flag on the Assembly changes only the displayed exterior film |
| Q9 | Air barrier | Kept, local, not exported |
| Q10 | Photo collections | Field kept. No photo UI in this packet |
| Q12 | Orientation | Kept per assembly |
| Q13 | Usage scan | On panel open and on Refresh, with the as-of time and stale mark. Never observer-driven |
| Q14 | Paint onto faces | Yes, from the inventory row |
| Q15 | Material categories | The predecessor's thirteen, unchanged |

Measured for Q2 and Q8: METr's component carries `Rse` and `Rsi`. PHX's
`to_METr_JSON/metr_schemas.py` writes them from face type and exposure only (0.04 for a wall or
roof to air, 0.0 to ground), so a ventilated film does not reach METr today.

Round 2, 2026-09-18.

| # | Decision | Answer |
| --- | --- | --- |
| Q7 | Interior assemblies on paired Surface faces | Different assemblies is a warning; one missing is the incomplete-face finding; the exporter reverses nothing |
| Q16 | SD assembly helper | Later phase |
| Q17 | The SD core | An ordinary Material with back-solved conductivity. No no-mass kind |
| Q18 | SD in export | A `placeholder` flag and one warning per assigned placeholder |
| Q19 | Q3's ripple | Building-Segment applied across the zones, face-assignment and spaces PRDs and the ubiquitous language. Record keys unchanged |
| Q20 | Ventilated film to METr | Not now. Recorded as a follow-up |

Q11, opaque doors, moved to the window-types interview.

## Acceptance shape

Offline: schema round trips for every record kind; the thermal calculation against the
predecessor's fixtures; the usage scan against synthetic face records; the export projection for a
single Layer-Segment, a mixed and a steel stud layer, validated by loading the HBJSON in honeybee and
reading the division grid back. On the host: build a three-layer wall with a stud layer, paint it
onto faces, edit a material, see the faces' usage update, delete with replacement, one Undo per
gesture. Through PHX: the exported assembly appears in the METr model with its divisions.

## Prior art and evidence

- Predecessor packet: `../ph-navigator-sketchup/planning/archive/assembly-builder/`.
- Predecessor code: `../ph-navigator-sketchup/src/ph_navigator_sketchup/features/assemblies/`.
- honeybee-ph: `honeybee_energy_ph/properties/materials/opaque.py`.
- PHX: `PHX/from_HBJSON/create_assemblies.py`.
- [face-assignment PRD](../face-assignment/PRD.md), Q7 and "Assigning assemblies".
