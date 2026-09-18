# Thermal bridges

DATE: 2026-09-18
STATUS: Requested. Draft, not interviewed.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (no remote)

## Problem

A Phius model needs every linear thermal bridge as a length and a psi-value. Today the consultant
measures edges by hand or draws polylines in Rhino. In SketchUp the edges already exist: the
slab edge, the parapet, the balcony line are the edges of the faces the consultant has assigned.
The workflow should be three steps. Build the type once, select the edges, assign.

## Port disposition

Nothing to port from the predecessor's features. It had no thermal bridge feature and designPH
owned that data.

| Part | Disposition | Note |
| --- | --- | --- |
| Record engine, typed ids, `source` and fingerprint | Port | From the foundation transplant |
| Inventory table, inline edit, usage scan on open and Refresh | Port | The Assemblies inventory pattern |
| Classify tool | Adapt | From face-assignment. It picks faces. Picking edges is a different `PickHelper` path |
| Colour-by component and HUD legend | Adapt | It fills faces. Thick coloured edges are a line draw with a width, and may not need the overlay fill spike |
| Thermal Bridge Type and assignment records | New | |
| Edge tagging rules | New | Shared with piping and ducting |
| Python translation to `PhThermalBridge` | New | Small. One class, one target |

## Vocabulary

Proposed. `context/UBIQUITOUS_LANGUAGE.md` is not changed until the interview.

| Term | Meaning |
| --- | --- |
| Thermal Bridge Type | A named junction detail with one psi-value. Model-local, editable, reusable |
| Thermal bridge | One assigned run of edges with a measured length. The exported thing |
| Group | The three-way class honeybee-ph and METr share: Ambient, Perimeter, and `FS/BC`, floor slab or basement ceiling. METr's screen word for the third is not yet checked |

## What honeybee-ph and METr take

Verified in `honeybee_energy_ph/construction/thermal_bridge.py`, `honeybee_ph/bldg_segment.py`
and PHX `to_METr_JSON/metr_schemas.py`.

- `PhThermalBridge`: `display_name`, `quantity` (default 1.0), `group_type` (15 Ambient,
  16 Perimeter, 17 FS/BC), `psi_value` (default 0.1), `fRsi_value`, `is_interior_pipe`, and
  `geometry` as a `LineSegment3D` or `Polyline3D`. Length comes from the geometry.
- Thermal bridges live on the honeybee-ph `BldgSegment`, keyed by identifier. They do not live
  on a Room or a Face.
- METr receives `n`, `typeTbZ` (the group number, negated), `lengthTbZ` and `psiTbZ` per zone.
  `fRsi_value` and `is_interior_pipe` are not written to METr.
- There is no point thermal bridge class. A chi-value exists only on a window frame element. D3
  confirms that point thermal bridges and chi-values are wholly outside the MVP. See Q3.

## Records

```
ThermalBridgeType  id (tbt_), name, psi_w_mk, group, color, notes, source,
                   datasheet_links, schema_version, created_at, updated_at

edge assignment    thermal_bridge_type_id, quantity, schema_version
(on the Edge)
```

`group` is `Ambient`, `Perimeter` or `FloorSlabBasementCeiling`, or blank. The third key is provisional, see Q4. The assignment is an attribute on
the SketchUp edge. There is no separate thermal bridge record in the model. The schedule and the
export both build the list of thermal bridges by scanning edges.

## Behaviors

### Types tab

An inventory table like Assemblies: name, psi-value, group, colour, used length, notes. Add,
duplicate, delete with a usage warning, inline edit. Psi-value is a unit field. A negative
psi-value is legal and common for exterior-dimension models.

### Assign

1. Select edges with the native Select tool, inside a Zone group. Pick a type in the panel and
   press Assign. One Undo step.
2. Or arm the Classify tool with a type and click edges. Same tool family as face-assignment.
3. Clear removes the assignment. Reassign replaces it.

Only edges inside a Zone group are assignable. The Zone gives the thermal bridge its
Building-Segment at export.

### Runs

Connected edges that carry the same type, in the same Zone, export as one thermal bridge with a
polyline, named from the type plus a counter. Edges that do not connect export separately. The
schedule shows the same grouping so the list matches what METr will show.

### Schedule

Below the types table: one row per run with Zone, type, length, psi-value, and psi times length
in W/K. Totals by type and by group. Click a row to select its edges in the model.

### Colour-by mode

A `Thermal bridges` mode registered with the shared Colour-by component. Assigned edges draw
thick in the type's colour. The HUD legend lists types with their lengths. Unassigned edges
draw nothing, since most edges in a model are not thermal bridges.

### Validation rows

| Finding | Severity |
| --- | --- |
| Edge assignment points at a deleted type | Blocks export |
| Type has no psi-value | Blocks export |
| Type has no group | Warning. Exports as Ambient |
| Assigned edge is outside any Zone group | Warning. Not exported |
| Assigned edge belongs to no assigned envelope face | Warning. The likely cause is a stray line |
| Two types assigned to one edge | Cannot happen. One attribute per edge |

### Export mapping

| PH-Composer | honeybee-ph |
| --- | --- |
| Run of edges | `PhThermalBridge.geometry`, a `Polyline3D`, or a `LineSegment3D` for one edge |
| Type `name` plus counter | `display_name` |
| Type `psi_w_mk` | `psi_value` |
| Type `group` | `group_type` 15, 16 or 17 |
| Assignment `quantity` | `quantity` |
| Zone's Building-Segment | The `BldgSegment` whose `thermal_bridges` holds it |
| none | `fRsi_value`, `is_interior_pipe` left at defaults |

## Edge tagging rules

These apply to this packet, to hot-water-piping and to erv-ducting. They are proposals until the
spike measures them.

1. The assignment is an attribute dictionary on the `Sketchup::Edge`. No separate index keyed by
   `persistent_id`, so a copied edge carries its assignment and a deleted edge takes it away.
2. SketchUp splits an edge when another edge crosses it or a face is cut. The spike measures
   whether both halves keep the dictionary. If they do, a split is harmless. If one half loses
   it, the schedule shows a gap and a Repair action copies the type across collinear neighbours.
3. No observer watches edges. The panel scans on open and on Refresh, as the Assemblies usage
   scan does.
4. An edge carries at most one assignment of each kind. A thermal bridge edge is envelope
   geometry. A pipe or duct edge is a loose line in its own group. The two never share an edge.

The spike: tag an edge, then split it, join it with Weld, move it, push-pull its face, place a
cutting window component on its face, Undo each, save and reopen. Record which operations keep
the dictionary on which resulting edges. It runs with the two deferred host spikes.

## Decisions for the interview

| # | Question | Recommendation |
| --- | --- | --- |
| Q1 | Does the assignment live on the edge, with no separate thermal bridge record? | Yes. The edge is the record. Fewer things to keep in step |
| Q2 | One psi-value per type, or may an assignment override it? | Per type only. A second value is a second type, the same rule Window Types follow |
| Q3 | Point thermal bridges and chi-values: honeybee-ph has no carrier | Confirmed in D3: linear only for MVP. Point bridges and chi-values are not authored, assigned or exported, and are never encoded as fake 1 m linear bridges |
| Q4 | Group words: METr's or honeybee-ph's? | METr's screen words, as Assemblies did. Confirm the third word against METr's screen |
| Q5 | Do connected same-type edges merge into one exported thermal bridge? | Yes. A parapet of 40 edges should be one METr row |
| Q6 | Is `quantity` exposed? | Yes, on the assignment, default 1. It covers a detail repeated on floors that are not modelled |
| Q7 | A shared edge between two Zones: which Zone owns it? | The edge is drawn inside one Zone group, so that Zone owns it. An edge on a Surface boundary between Zones is a finding, since an interior junction is not an envelope thermal bridge |
| Q8 | Are Thermal Bridge Types a fifth library kind? | Not now. The libraries interview fixed four kinds. Record it as the first candidate for a fifth |
| Q9 | Does a type hold a link to the psi-value calculation report? | Yes, `datasheet_links` as Materials have. Certification needs the source |
| Q10 | Where is the tab? | The reserved "Thermal Bridges" tab from the UI baseline, types table above, schedule below |
| Q11 | Window install edges: can a user assign a Thermal Bridge Type to a window perimeter? | No. Psi-Install Types own those edges. A finding if both exist would double count |

## Non-goals

Point thermal bridges and chi-values in any MVP surface or artifact. They may be reconsidered only
as later scope after the canonical data model has a real point-bridge carrier.

No psi-value calculation. No fRsi. No automatic junction detection. No Flixo link.

## Acceptance shape

On a synthetic two-Zone model: build three types, assign a parapet loop, a slab edge and a
single balcony line; confirm the schedule lengths against hand measurement; split an assigned
edge and confirm the documented behavior; export and find the three runs in the HBJSON on the
right Building-Segments and in the METr JSON with the right `typeTbZ`, length and psi-value. One
Undo per assign. Save and reopen.

## Prior art and evidence

- honeybee-ph `honeybee_energy_ph/construction/thermal_bridge.py`, `honeybee_ph/bldg_segment.py`.
- PHX `to_METr_JSON/metr_schemas.py`, `_PhxComponentThermalBridge`.
- honeybee-grasshopper-ph "HBPH - Create Thermal Bridges": polylines in, thermal bridges out.
- [face-assignment](../face-assignment/PRD.md): Classify tools and the Colour-by component.
- [assemblies](../assemblies/PRD.md): the inventory pattern and the usage scan rule.
