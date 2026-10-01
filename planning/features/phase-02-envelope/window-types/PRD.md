# Window Types and placement: behavior contract

DATE: 2026-09-30
STATUS: Scoped. Interviewed 2026-09-18 in two rounds, 20 decisions recorded below. Architecture review folded in 2026-09-18 (Q21 to Q26). The component spike ran on 2026-09-18. Amended 2026-09-30 for what Phase 1 merged. [PLAN.md](PLAN.md) allocates the work to Phase 2 stages.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/14

## Amendments after Phase 1

Proposed 2026-09-30. Rows that restate what the merged code does are facts. Rows that cite a D2
decision are proposals and govern only once Ed confirms them; until then the body stands. The reasons are
in the Phase 2 [DECISIONS](../DECISIONS.md), and the names in [CONTRACTS](../CONTRACTS.md).

| Body text | Reads as |
| --- | --- |
| "face-assignment's face read" and the face-assignment folder | The `zones` feature's Face read. Zones owns Face code |
| One feature for definitions and placement | Still one feature, spanning two layers (D2-1, revised by Ed 2026-10-01). Frames, Glazings, Psi-Install Types and Window Types are definitions and call nothing in Zones. The unit and placement sit above Zones and read it. Zones never requires windows |
| "This feature installs with the face-assignment and zones folders unchanged" | Zones gains two rules for cutting components that name no feature (D2-5, confirmed 2026-09-30): a cutting instance's Faces are not Zone Faces, and Solve reports a Face that has glued instances. Without the first, every pane would read as an unclassified Zone Face |
| Model-level defaults "live in the Model-level attribute primitive the foundation transplant lands" | That primitive did not land. P2-10 promotes Zones' private settings pattern to `core/` and both features use it |
| The Colour-by mode's "outlines and marks are derived geometry" | The service outlines each pane from its Face today. Derived geometry with no backing entity is not supported, so operation marks wait (D2-6, confirmed 2026-09-30) |
| Place as a tool started with a type already chosen | Kept as the primary route, with the reason recorded under the geometry-first rule, plus a right-click start from a selected Face (D2-2, confirmed 2026-09-30) |
| "fresh timestamps" in Q21, and `created_at`, `updated_at` on the unit | D2-4, confirmed 2026-09-30: dropped |
| The shared `core/` pick primitive | It answers Face paths only. P2-13 adds the point on the Face |
| Net opaque area "from a declared window-types read" consumed by face-assignment | Windows owns and presents it (D2-10, confirmed 2026-09-30). Zones declares no dependency on windows |
| "Through PHX" in the Acceptance shape | Deferred with METr (D12) to the metr-export packet |

## Problem

A Phius model needs every window as an aperture on an envelope face with a glazing, four frame
edges, four installation psi-values and an operation. The predecessor built the definition half
and proved it on the host: a graphical Window Type Builder with a row and column grid, merge and
split, Empty panels, an eyedropper, a staged Installs view, shared Frame, Glazing and
Psi-Install Type records in the Library, and a U-Values report.

The placed half was designPH's. A window in the model was designPH's Dynamic Component with one
opening, fed from designPH's frame and glazing tables. Most of the predecessor's window code
exists to live with that: reading designPH's components, adopting them, grouping several into one
mulled unit, choosing one element as designPH's preview, manufacturing frame and install
combination rows and pushing them, reviewing differences, relaying designPH's shading result, and
staging every change as a reviewed propagation so records, rows and native windows never
disagreed. PH-Composer owns the placed window, so none of that has a job.

This packet keeps the definition half as it is and replaces the placed half with something much
smaller.

## Port disposition

Measured on the predecessor at `f358ebf`: `features/windows/` is 8,688 lines of Ruby. Detail lives
in `../ph-navigator-sketchup/planning/archive/window-types/`, and its `UI_UX_SPEC.md` stays the
interaction contract for every row marked Port.

| Part | Lines | Disposition |
| --- | --- | --- |
| `model/` (types, constituents, grid, operations, thermal, edge_resolution, anchors, guards) | 1,170 | Port. Drop `preview_id` and the adoption source kind |
| `reviews/install_draft`, `reviews/install_review` | 416 | Port. The staged Installs session and its Save and Cancel |
| `export/export_contract`, `export_report` | 354 | Adapt. Reads window units, not designPH rows. Drops shading provenance |
| `assign/schedule` and the occurrence reader | about 300 | Adapt. The Schedule lists PH-Composer's own units |
| `panel/overlay/` | 397 | Adapt. Becomes a Colour-by mode on the shared service: component instances as the entity kind, element outlines and operation marks as derived geometry (spaces Q22) |
| `placement/placement_geometry`, anchors, the Tool's pick and preview | about 400 | Adapt. The plane, axes and anchor arithmetic hold. The designPH template and the Dynamic Components commit go |
| `designph/`, `compare/`, the rest of `assign/`, the rest of `reviews/`, `workflow/`, `export/ppp_shading_parser`, the rest of `placement/` | about 5,600 | Drop |
| Python: `apertures.py`, `phn_windows.py`, `contract/sections/windows.py` and `window_apertures.py` in the translation package | about 690 | Port. This is the code that writes the `Aperture`, its construction and the honeybee-ph frame and glazing. Adapt the install mapping per Q24: installs are written into the frame elements and no aperture install types are written |
| Panel: Builder, type browser, element cards, pickers, Installs, U-Values, Library tabs | not counted | Port. Drop Push, the preview reference, adoption and difference views, and the shading handoff |

Requirements in the predecessor's `UI_UX_SPEC.md`: WUX01 to WUX11, WUX13 to WUX16 and WUX18 port.
WUX12, the designPH preview reference, drops. WUX17 is rewritten by this packet.

## Decision

- Frame, Glazing, Psi-Install Type and Window Type records carry over field for field. The
  predecessor's "Frame segment" becomes **Frame** (Q15). The Library stays their one home. The
  model default Psi-Install Type carries over.
- A **window unit** is an instance of one plain component definition per Window Type, authored by
  PH-Composer in code, glued to its host face and cutting it (Q1, Q3, Q17). It is not a
  Dynamic Component and no file ships with the extension.
- The definition is flat: one face per glazed element, in the host face's plane, and nothing
  else. No frame thickness, no backset, no reveal geometry (Q1, Q16). designPH's one opening per
  component rule is gone, so a mulled unit is drawn as what it is.
- Every unit follows its type. There are no per-unit product or installation overrides. A variant
  is a duplicated type.
- Editing a used type rewrites its definition in the same Model operation, with the affected count
  shown before commit. One Undo reverts the record and the geometry together. The predecessor's
  propagation reviews are not needed.
- Each glazed element of a unit exports as one honeybee `Aperture`. Products, psi-values, install
  depth and the type name go to the honeybee-ph properties that PHX already reads.
- A **Psi-Install Type is an authoring layer**, not a second place psi-install lives. honeybee-ph
  holds psi-install on the construction's frame elements, and its aperture install types are an
  override that PH-Composer does not need, because installs belong to the Window Type. The
  layer exists so one Frame product serves a wood wall and a brick wall without a copy per wall.
  The export writes the value into the frame element (Q24).
- PH-Composer authors no shading of any kind. METr and WUFI-Passive handle shading after
  export (Q10).
- Everything in the type editor ports except designPH interactions (Q11).

## The placed window: three candidates

Recorded for the reasoning. Ed chose A on 2026-09-18.

| | A. Component per type | B. Plain group per unit | C. Stamped sub-face |
| --- | --- | --- | --- |
| What it is | One `ComponentDefinition` per Window Type holding one face per element. Each unit is an instance, glued to the host face and cutting it | A group per unit holding the same faces, glued where the host allows | No container. The unit is the face or faces SketchUp splits off when its outline is drawn on the wall. Each carries a record with `window_type_id` |
| Global control | Native. Rewrite the definition once and every unit follows | Every unit rewritten one at a time | Every unit's edges erased and redrawn one at a time |
| Count and Schedule | `definition.instances` | A model walk | A model walk |
| Moving and copying | Native Move and Move-copy along the wall. The hole follows | Same, if glue holds for groups | Native Move of the edges. Easy to distort by accident |
| Matches honeybee | Exporter flattens instances to Apertures | Same | Closest. An Aperture is a coplanar sub-face of its parent Face |
| Accidents | A scaled or mirrored instance no longer matches its type. Detectable from the transformation | Same, plus a unit edited inside its group | Any edge move changes a unit silently. Detectable only by measuring |
| Host unknowns | Glue and cut inside a Zone group; a definition rewrite as one Undo step | The same, and whether groups glue | Whether erasing a unit's edges heals the wall face and keeps its face record |

## Vocabulary

| Term | Meaning | honeybee-ph |
| --- | --- | --- |
| Window Type | A reusable exact-size layout: row and column bands, elements, products, operation, perimeter installs | `AperturePhProperties.variant_type` carries the name |
| Element | One cell or merged block of the grid: glazed or Empty | One `Aperture` when glazed. Nothing when Empty |
| Frame | One head, jamb, sill or mullion profile: width, U-f, psi-g. An element references four | `PhWindowFrameElement` |
| Glazing | U-g and g-value | `PhWindowGlazing` |
| Psi-Install Type | A named installation junction psi-value, painted onto a Window Type's perimeter edges. An authoring layer over the Frame, so a Frame record never carries a psi-install | `PhWindowFrameElement.psi_install` on that side of the exported construction's frame (Q24) |
| Window unit | One placed use of a Window Type on one host face: an instance of the type's component, with its own id | The Apertures of one unit share an identifier stem from the unit id |
| Window anchor | The fixed point for placement and resize. Sill center by default | None |
| Install depth (new) | The reveal depth: distance from the wall's outer surface to the glass. A model default with a Window Type override | `AperturePhProperties.install_depth`, which PHX writes to METr's `depthWRevC` |

## Records

Definition records are the predecessor's, less `preview_id`.

```
Frame             id (frm_), name, manufacturer, product_code, position, operation,
                  width_m, uf_w_m2k, psi_g_w_mk, color, notes, source, datasheet_links,
                  user_data
Glazing           id (glz_), name, manufacturer, product_code, description,
                  ug_w_m2k, g_value, color, notes, source, datasheet_links, user_data
Psi-Install Type  id (psi_), name, psi_w_mk, notes, source, datasheet_links, user_data
Window Type       id (wnt_), name, rows_m[], columns_m[], elements[], install_depth_m (absent
                  means the model default), product_photos, source, user_data
  element         id (wel_), name, kind ("glazed" | "empty"), row_span, column_span,
                  glazing_id, frames{top,right,bottom,left}, installs{top,right,bottom,left},
                  operation {type: fixed | swing | slide, directions[]}
Model             default_psi_install_id, default_install_depth_m
```

The window unit record, new, on the component instance:

```
id (wun_)          a UUID-based id in PH-Composer's dictionary on the instance
window_type_id     the Window Type this unit follows
anchor             one of the nine anchors; sill_center by default
user_data
schema_version
```

- **Identity (Q21).** The unit's `id` is its durable identity, because cut and paste can replace a
  `persistent_id` ([TECH_STACK.md](../../../../context/TECH_STACK.md)). The table, the overlay, the
  report and the Aperture identifiers use the id plus the occurrence path.
- **Copies (Q21).** A Move-copy or paste copies the dictionary, so two instances share an id.
  Copies are ordinary here (Q7), so the answer is not a blocking finding. When this feature next
  mutates the Model, it gives one of the two instances a new id, inside that
  operation. A read never does it; until then the Schedule lists both rows under a "copy, id
  pending" mark and export treats a shared id as blocking. This is a recorded exception to spaces
  Q20, and the reason is that a unit holds nothing authored beyond its type and anchor, so
  nothing is lost and nothing is ambiguous. `user_data` stays with both.
- **No Zone stamp on the unit.** The unit's Zone is the Zone group that contains it, read through
  the zones packet's Zone read. A stamp on the instance would not survive explode, so it would
  serve nothing. The faces inside the definition carry a stamp holding `window_type_id` only.
- **`user_data`.** All five records carry the `user_data` mapping and structured extension
  payloads that [EXTENSIBILITY.md](../../../../context/EXTENSIBILITY.md) requires, under the
  foundation's storage contract. Duplicate type copies it. Swap type keeps the unit's. None of it
  is exported.
- **Model-level defaults.** `default_psi_install_id` and `default_install_depth_m` live in the
  Model-level attribute primitive the foundation transplant lands. The predecessor's is in its
  Spaces `attrs`. This feature adds no second mechanism.

The definition carries `window_type_id` in its dictionary, and that is its identity. Its name is
a fixed prefix plus the Window Type name and is rewritten with the type; a user rename in the
Components browser is overwritten without a finding (Q19). Its behavior is set to glue to any
face, cut an opening, and refuse scaling (`no_scale_mask` with every handle off, Q8).

Faces inside a definition carry one PH-Composer glass material, translucent, so a window reads
as a window with every overlay off. It is applied only inside window definitions. A user who
repaints a unit keeps their paint (Q18).

An opaque door is, for the MVP, a Window Type whose Glazing has a g-value of 0. Nothing special
is stored and no finding is raised (Q5, Q20). The export writes `shgc` 0, which honeybee-energy
accepts and honeybee-schema's range (`gt=0, lt=1`) does not. That deviation is disclosed, not
hidden (Q23): the Export report names each such construction, `docs/` states it, and local
conformance carries it as its one documented schema exception. A g-value of exactly 1 is treated
the same way. PH-Composer never writes a nearby number on the user's behalf.

## Behaviors

### Carried over unchanged

Settled in the predecessor's interviews and recorded in its `UI_UX_SPEC.md`. Not reopened here.

- The Builder: type browser with sort, groups and manual order; header with name, U-w and overall
  size; the dimensioned drawing; click, shift-click and background selection; element cards with
  Glazing, four Frame rows and Operation; in-place dimension editing with the shared length
  grammar; insert and delete bands; merge and split; Empty panels; the eyedropper and repeat
  paste; Exterior and Interior viewing; the committed Flip.
- Installs: opened for the active type, paint a Psi-Install Type onto perimeter edges, shared
  internal edges are derived zero and unpaintable, an unset edge inherits the model default,
  Apply to all edges, Copy to other Window Types, one Save for the whole session.
- Library / Frames, Glazings and Psi-Install Types: manual create, edit, duplicate, use sites,
  guarded delete with replacement, the library sidebar.
- U-Values: the type, element and edge report, with incomplete elements visible and never
  counted as zero. U-w excludes installation. The installed U-value is shown beside it.
- Incomplete types save. With size and layout they can be placed. A placed type missing thermal
  inputs blocks export. An unused one does not.

### Place

- A `Sketchup::Tool` owned by this feature, a sibling of Classify and Mark floor on the shared
  `core/` pick and drag primitives and the UI kit palette (spaces Q19). Started from the Builder
  header, the type browser or the Schedule with a type already chosen. The operation underneath
  takes an explicit face reference, an anchor and offsets, so a script or an external client
  places a unit with the panel closed. Swap type and Re-host take explicit unit references.
- Hovering a face shows the unit's outline at the anchor. The up direction on the face is world
  up projected onto the face plane. On a horizontal face, such as a flat roof, it is the model's
  green axis projected the same way, so skylights and roof windows place like any other unit
  (Q6).
- The measurement box takes a sill height, or an offset from the nearest host edge, while the
  tool is active. Click places. The tool stays active for the next unit; Escape ends it.
- The host face needs a Zone but does not need a face record at placement time (Q4), so windows
  may be laid out before envelope classification is complete. Export requires the host face to be
  classified as Outdoors because a honeybee Aperture must have an exported parent Face. A
  placement is refused with a reason when the host face has no Zone, is a Surface face paired by
  Solve adjacencies (zones Q12), or the outline leaves the host face. Host face state comes from
  face-assignment's face read, never from its dictionary. Outdoors-only is honeybee's own rule:
  `Face._acceptable_sub_face_check` refuses a sub-face on any other boundary condition. One
  consequence for Q5: a door between the house and an Attached zone garage cannot export as a
  unit, and is modeled as part of its wall's assembly. An overlap with another unit
  is refused.
- One placement is one Model operation: the definition is created on first use, and the instance
  is added, glued and given its record. The opening follows from the definition's cut behavior.

### Editing a used type

- Products, operation and installs: the record changes. No geometry changes. Every unit follows
  because it holds no copy.
- Size and layout: the definition's faces are rewritten. Each instance is translated so its own
  anchor stays fixed. The confirmation comes from a non-mutating preview. It shows how many units
  change, whether any would leave its host face, which blocks the edit until resolved, and which
  units sit on a definition the user edited inside, since the rewrite replaces that geometry.
- **Swap type** replaces the type on selected units, keeping each anchor.
- Delete a used type requires a replacement type or explicit removal of its units.

### Native edits the tool did not make

| The user does | PH-Composer |
| --- | --- |
| Moves, Move-copies or pastes a unit | The unit and its opening move natively and the record copies with it. A copy receives its own id at this feature's next mutation (Q21). Its Zone is its parent, read when needed (Q7) |
| Moves a unit off its face or onto another | The unit shows as unhosted in the Schedule until it is glued again. **Re-host** does it |
| Tries to scale an instance | The Scale tool shows no handles: the definition refuses scaling. A scale applied by another extension is a finding, size differs from type, with Reset to type or New type from this unit |
| Mirrors an instance | Finding: handed opposite to its type. Offers New flipped type |
| Edits inside the definition | Finding: geometry differs from type. Offers Reset to type |
| Explodes a unit | Native Undo is the full recovery. **Restore unit** is a limited repair (Q22): from exploded faces that still carry the `window_type_id` stamp and still match the type's outline, it places a new unit of that type at that outline and removes the loose faces, as one Undo step. The unit gets a new id and the default anchor; the old id, anchor and `user_data` are gone. Faces that merged with the wall or no longer match are refused, with Place as the route |
| Edits nothing but still differs | No observer reacts at the moment of any of these. Validation and the Schedule show them, and all block export (Q8) |
| Makes an instance unique | Finding: unit uses a detached definition. Repaired by Reset to type, which re-points the instance to the type's definition. Nothing folds it back silently, and a type rewrite leaves a detached definition alone (Q22) |
| Pastes a unit from another Model | Finding: unknown Window Type. Offers Swap type |

### Schedule and seeing windows in the model

The Schedule lists Window Types with counts, expandable to units with Zone, host face, Level and
Locate. Unhosted and differing units are listed with their finding. A Colour-by mode, **Window
Type**, colours units by type, with the predecessor's element outline and operation marks as its
detail at close zoom. It registers with the shared Colour-by service as a mode whose entity kind
is the window unit and whose outlines and marks are derived geometry (spaces Q22), and waits on
the overlay spike. Counts come from unit records, so a detached definition does not hide a unit.

### Validation rows

| Finding | Severity | When |
| --- | --- | --- |
| Placed type incomplete | Blocks export | A glazed element lacks a glazing, a frame, or a required value |
| Perimeter edge with no install and no model default | Blocks export | The edge would export an invented psi-value |
| Unit unhosted | Blocks export | The instance is glued to nothing or its host face no longer exists |
| Host face unclassified or not Outdoors | Blocks export | The unit has no exportable parent Face; classify the host face or move the unit |
| Unit on a Surface face | Blocks export | Zones Q12. This row is the one owner of the finding; the zones packet's "Interior window" row points here |
| Two units share an id | Blocks export | A copy this feature has not yet given its own id (Q21). Any mutation of this feature clears it; the Schedule offers one |
| Unit uses a detached definition | Blocks export | Make unique (Q22). Reset to type |
| Unknown Window Type | Blocks export | The unit names a type this Model never had. Swap type |
| Size, handedness or geometry differs from type | Blocks export | See the table above |
| Unit leaves its host face or overlaps another | Blocks export | Measured at validation, since native moves can cause it |
| Dangling product reference | Blocks export | A deleted record is still named |
| Frame and operation mismatch | Info | Carried from the predecessor |

### Export mapping

Checked against `honeybee_ph/honeybee_ph/properties/aperture.py`,
`honeybee_energy_ph/construction/window.py`, `honeybee_ph_utils/aperture_psi_install.py` and
`PHX/from_HBJSON/create_building.py` and `create_assemblies.py` on 2026-09-18.

| PH-Composer | honeybee |
| --- | --- |
| Glazed element of a unit | One `Aperture` on the host `Face`. Identifier from the unit id and the element id, display name from unit and element names. The host `Face` exports as its gross polygon with the Apertures as sub-faces, which is honeybee's shape (Q26) |
| Empty element | Nothing. The area stays wall |
| Products of an element | One `WindowConstruction` per distinct combination of glazing, four Frames and four resolved installs, as a simple glazing system with U-w and g-value, carrying `properties.ph.ph_glazing` and `properties.ph.ph_frame`. Its identifier is deterministic and keyed by those record ids, so two exports of one Model agree |
| Frame | `PhWindowFrameElement`: `width`, `u_factor`, `psi_glazing`, and `psi_install` from that side's Psi-Install Type |
| Psi-Install Type on a perimeter edge | The value goes to that side's `PhWindowFrameElement.psi_install`, the model default included. `Aperture.properties.ph.install_types` is left empty (Q24). The Export report lists each Window Type's installs by name, since the names do not travel in HBJSON |
| Shared internal edge | `psi_install` 0.0 on that side's frame element |
| Window Type name | `properties.ph.variant_type` |
| Operation | `Aperture.is_operable` is true for swing and slide |
| Install depth | `properties.ph.install_depth`, from the type or the model default. PHX writes it to METr as `depthWRevC` |
| Shading | Nothing authored. honeybee-ph serializes its own default factors, and the Export report says PH-Composer sets no shading (Q10) |

honeybee-ph holds psi-install on the construction's frame elements. Its aperture install types
are a per-aperture override, there so one construction can serve apertures installed differently
(`honeybee_ph_utils/aperture_psi_install.py`): an aperture-level install type wins, and otherwise
the frame element's value applies. METr and WUFI hold psi-install on the window type's frame, so
PHX's `synthesize_window_type_psi_variants` (`PHX/model/transforms.py`) creates a variant window
type wherever an aperture's resolved values differ from its type's frame, and never removes the
base. In PH-Composer installs belong to the Window Type and no unit overrides them, so the
override layer has no job. Writing the values into the frame elements means no aperture differs,
PHX synthesizes nothing, and METr receives one window type per distinct combination. Writing 0.0
on the frames and every value on the Apertures would have sent M unused base types plus M
variants. The predecessor's rule that psi-install is never a Frame product input still holds
where it applies: in the Frame record and the Library. The export is a projection of both.

Each `Aperture` attaches to the `Face` the face section builds. This section declares that result
as a dependency, the same seam as assemblies Q23 and the same open foundation question.

## Later, decided now

- **Explicit door support**: an `opaque` element kind exported as a honeybee `Door`, if users ask
  for it (Q5).
- **Reveal geometry**: a five-sided box whose depth is the install depth, so the reveal shows in
  the model. A spike candidate, with three costs to measure: the glass leaves the wall plane and
  each Aperture must be projected back onto its parent Face at export; the box resizes on two axes
  plus depth; its walls are geometry a user can select and paint (Q9).

## Non-goals

designPH in any form. Shading of any kind: factors, dimensions, shade geometry. Frame thickness,
backset or any 3D frame model; a unit is flat. Curtain wall and storefront systems as systems.
Arched, raked or otherwise non-rectangular units. Per-unit overrides. CSV and XLSX report
downloads. A window component file shipped in the RBZ.

## Decisions recorded

Interviewed 2026-09-18 in two rounds. Answers are Ed's.

| # | Decision | Answer |
| --- | --- | --- |
| Q1 | Representation | One plain component definition per Window Type. Flat for the MVP, with none of designPH's frame thickness or backset geometry, unless a flat component proves hard to click and manage |
| Q3 | Cut | The unit cuts a real hole in its host face |
| Q4 | Host face | A Zone is required. A face record is not |
| Q5 | Opaque doors | MVP: a Window Type whose Glazing has a g-value of 0. Explicit support later if users ask. Closes assemblies Q11 |
| Q6 | Skylights and roof windows | Included now |
| Q7 | Native copies | A Move-copied or pasted unit is a full unit. Unhosted until Re-host when pasted onto nothing |
| Q8 | Native transforms | Scaling is refused through the definition's `no_scale_mask`. Mirrored and edited-inside units are findings with a repair offer and block export. No observer reacts live |
| Q9 | Install depth | An attribute for the MVP: a model default with a Window Type override. The five-sided box is a later spike |
| Q10 | Shading | None at all. METr and WUFI-Passive handle it after export |
| Q11 | Simplify the type | Port everything except designPH interactions and support |
| Q12 | Installs session | Kept, one Save and Cancel |
| Q13 | U-w on screen | As the predecessor: uninstalled U-w as the headline, installed beside it |
| Q14 | Window Type Colour-by mode | This packet, last phase, after the overlay spike |
| Q15 | Words | Window Type, Glazing, Psi-Install Type. Frame segment becomes Frame |
| Q16 | Faces in the definition | One face per glazed element. Empty panels stay wall |
| Q17 | Source of the component | Generated in Ruby from the Window Type record. No shipped .skp. Reset to type is the same routine |
| Q18 | Look at rest | One PH-Composer glass material inside window definitions only |
| Q19 | Definition naming | Prefix plus type name, rewritten with the type. Identity is `window_type_id` |
| Q20 | g-value 0 | No finding |

Architecture review, 2026-09-18. Q21 to Q24 are Ed's answers; Q25 and Q26 are the review's
recommendations, accepted with the instruction to fold the review in.

| # | Decision | Answer |
| --- | --- | --- |
| Q21 | Unit identity and copies | A unit id on the instance. A copy gets its own id at this feature's next mutation, never on a read. A recorded exception to spaces Q20, because a unit holds nothing authored beyond its type and anchor |
| Q22 | Make unique and explode | Make unique is a "detached definition" finding repaired by Reset to type, with no silent fold-back. Restore unit is a limited repair: new id, default anchor, refused when the faces no longer match. Native Undo is the full recovery |
| Q23 | g-value 0 against honeybee-schema | Disclosed in the Export report and `docs/`, with one documented exception in local conformance. No substituted value |
| Q24 | Where psi-install is exported | Into `PhWindowFrameElement.psi_install`, where honeybee-ph holds it. The Psi-Install Type is an authoring layer so a Frame product is not duplicated per wall. No aperture install types, so PHX synthesizes no variants |
| Q25 | Cross-feature seams | Place is a sibling tool (spaces Q19). The Colour-by mode uses the open entity kind and derived geometry (spaces Q22). Host face state comes from the face read. The Aperture to Face join is the declared section dependency (assemblies Q23). The unit carries no Zone stamp |
| Q26 | The cut opening | The host Face exports gross with Apertures as sub-faces. What SketchUp's cut does to `Face#loops` and `Face#area` is measured in the component spike before any rule relies on it |

Measured during the interview: PHX writes `install_depth` to METr's window component as
`depthWRevC` (`to_METr_JSON/metr_schemas.py`). SketchUp's
`ComponentDefinition#behavior.no_scale_mask` removes the Scale tool's handles per definition; it
does not stop Move, Flip or editing inside the definition. Locking an instance would, and it also
blocks Move and Erase, so it is not used.

## Acceptance shape

Offline: schema round trips; the predecessor's thermal fixtures; grid operations; the export
projection for a one-element unit, a three-element mulled unit with an Empty panel and a unit on a
roof, validated by loading the HBJSON in honeybee and resolving psi-install per side. A two-type,
four-unit fixture through PHX yields two window types with the painted psi-install on each frame
side. A g-value 0 unit exports, the report and conformance name the exception, and PHX reads 0.
Two units sharing an id block export and any feature mutation clears it; Aperture identifiers
hold across save and reopen. A detached definition and an unknown Window Type each raise their
finding. `user_data` survives edit, Duplicate type, Swap type, Undo/Redo and save and reopen.
This feature installs with the face-assignment and zones folders unchanged, and a panel-closed
script creates products and a type, places a unit by explicit face reference, copies it, resizes
the type and reads the result back. On the host:
place on a wall and on a flat roof, Move-copy, resize a used type with three anchors in play, Swap
type, confirm the Scale tool shows no handles, mirror an instance and see the finding, Make unique
and Reset to type, cut and paste a unit across Zones, explode and Restore unit and see its limits,
one Undo per gesture. Through PHX: the units
appear in the METr model as window components with their frames, glazing and install psi-values.

## Prior art and evidence

- Predecessor packet: `../ph-navigator-sketchup/planning/archive/window-types/`, with
  `UI_UX_SPEC.md` as the interaction contract.
- Predecessor code: `../ph-navigator-sketchup/src/ph_navigator_sketchup/features/windows/`.
- honeybee-ph: `honeybee_ph/properties/aperture.py`, `honeybee_energy_ph/construction/window.py`,
  `honeybee_ph_utils/aperture_psi_install.py`.
- PHX: `PHX/from_HBJSON/create_building.py`, `create_assemblies.py`.
- [zones-and-adjacency PRD](../../../archive/phase-01-zones-and-adjacency/PRD.md), Q12 and Q14.
