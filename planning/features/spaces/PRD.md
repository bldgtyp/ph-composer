# Spaces: behavior contract

DATE: 2026-09-18
STATUS: Scoped. Interviewed 2026-09-18 in two rounds, 18 decisions recorded below. Architecture review folded in 2026-09-18 (Q19 to Q24). PLAN.md follows the overlay spike and the foundation transplant.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (no remote)

## Problem

A Phius model needs room-by-room data: floor area that counts toward iCFA, net volume, and
supply, extract and transfer airflows. METr and WUFI-Passive take it as a list of rooms under the
ventilation system. Keeping it in a side spreadsheet is the failure the 2019 dPH+ Rooms extension
was written to fix: drawings, spreadsheet and model drift apart, and a reviewer cannot see how a
number was derived.

The predecessor built the structural half of the answer and proved it on the host: a Space group
holding protected Volume groups holding Floor Segment faces, reconciled on context changes, with a
filterable table. It stopped there. It depended on designPH to say which faces were floor area.
It stored a ceiling height per Volume and computed Vn50 from it, and never showed that volume in
the model. It had no airflow entry, no way to see which Spaces are supplied or extracted, no
totals for a selection, and no labels. This packet finishes the feature.

## Port disposition

Measured on the predecessor at the frozen `f358ebf`: `features/spaces/` is 28 Ruby files and 2,678
lines, and 16 of the files name designPH or TFA. This table is the ruling. A later predecessor
fix enters only as an explicit change to it.

| Part | Lines | Disposition |
| --- | --- | --- |
| `attrs`, `identifiers`, `index`, `names`, `entries`, `entry_transforms`, `transforms` | 457 | Port. Add the Zone stamp, the airflow fields and `user_data`; drop the colour field |
| `operations/` (context, creation, editing, recovery), `actions`, `active_path` | 887 | Adapt. Creation and recovery stop reading designPH TFA faces; the explicit mark replaces that trigger. Create Space takes a Zone reference |
| `scan`, `metrics`, `preview`, `baseline`, `contract`, `snapshot`, `panel_view`, `findings_index` | 582 | Adapt. The scan reads Floor Segment records, not TFA faces. Metrics gain projected area and the any-set airflow rule |
| `validation` | 179 | Adapt. Keeps `duplicate_identity`; loses every designPH finding |
| `reconciler`, `undo_ledger`, `pending_work`, `session_state` | 429 | Split. The generic deferred-reconciliation and Undo-ledger primitives land with the foundation transplant; what remains here is the Spaces-specific reconciliation |
| `spaces` (the feature's `install`) | 97 | Adapt |
| `designph` | 47 | Drop |
| Python `spaces/`: `authored.py`, `geometry.py` | not counted | Adapt. Adds the m3/h to m3/s conversion, the any-set rule, the floor projection and the prism geometry |
| Python `spaces/legacy_tfa.py` | not counted | Drop |
| Panel: the Spaces table, tree, inspector and preview dialog | not counted | Port. New: airflow columns, balance view, Mark floor palette |

## Where a Space sits

```
Model
  Zone  (Group; honeybee Room)            loads, schedules, mechanical equipment
    Space  (Group; honeybee-ph Space)      name, number, airflows
      Volume  (Group; honeybee-ph SpaceVolume)    average clear ceiling height
        Space Floor  (logical; honeybee-ph SpaceFloor)
          Floor Segment  (face; honeybee-ph SpaceFloorSegment)   iCFA factor, net area factor
```

A Space is in a Zone when its group is inside the Zone group. The parent group is the only
marker. Nothing tests geometric containment, and a user may draw a Space's floors anywhere in the
scene, off to the side of the building included, as long as they draw them inside the Zone's
edit context (Q2). A Floor Segment is its own face inside a Volume and is never the same face as
the Zone's envelope Floor, which is measured to a different boundary (Q1).

A Space inherits everything from its Zone: occupancy, lighting, equipment, hot water and
ventilation loads and schedules, and the mechanical equipment that serves it. Equipment is
assigned to the Zone, never to the Space; a model with two ERVs has at least two Zones. The one
exception, carried from honeybee-ph, is ventilation airflow: a Space may hold its own supply,
extract and transfer rates. When any of the three is set, the Space is user-specified: the
Space's values are used and an unset rate counts as zero. Only a Space with all three unset falls
back to the Zone's ventilation load (Q21). The exception exists so a modeler does not need one
Zone per room.

## Decision

- The Space record maps field for field to honeybee-ph's `Space`, `SpaceVolume`, `SpaceFloor` and
  `SpaceFloorSegment`. No new concepts. The predecessor's hierarchy, protection, reconciler,
  recovery states and table carry over unchanged in behavior.
- PH-Composer owns floor classification. **Mark floor** writes the Floor Segment record on a
  face the user drew inside a Volume, replacing the predecessor's dependence on designPH. It is a
  `Sketchup::Tool` that this feature owns, a sibling of the Classify tool and not a mode of it
  (Q19).
- **Volume is a height.** Each Volume carries an average clear ceiling height, and net volume is
  net floor area times that height, as honeybee-ph and the predecessor compute it. The model shows
  it: a **volume preview** extrudes each Volume's Floor Segments upward by the height as a
  translucent Colour-by overlay. A helper, **Height from solid**, sets the height from a closed
  group the user has drawn, for sloped and irregular rooms. It fills the field; it does not add a
  second volume model.
- QA tools from dPH+ Rooms become Colour-by modes, a selection HUD and viewport labels, all on the
  shared component the face-assignment packet builds.
- An **airflow balance view** lists supply and extract totals per Zone with an imbalance warning,
  and regroups by ventilator when the equipment packet lands (Q9, Q16).
- Drawing the floors correctly and choosing what counts toward iCFA is the user's job.
  PH-Composer states the Phius rule and enforces nothing (Q3, Q15).
- Airflows are entered per Space in the table and the inspector. Unset is stored distinct from
  zero, and the any-set rule decides what an unset rate means (Q21).

## Vocabulary

Carried from `context/UBIQUITOUS_LANGUAGE.md`. New terms are marked.

| Term | Meaning | honeybee-ph |
| --- | --- | --- |
| Space | One SketchUp Group inside a Zone with name, number and airflows | `Space` |
| Volume | A protected Group directly inside a Space, with one average clear ceiling height | `SpaceVolume` |
| Space Floor | The logical grouping of a Volume's Floor Segments; not a Group | `SpaceFloor` |
| Floor Segment | A face inside a Volume that the user has marked as floor area | `SpaceFloorSegment` |
| iCFA factor (new name) | Whether a Floor Segment counts toward iCFA. On screen two states, Counts and Does not count; stored as 1.0 and 0 in a float field so an HBJSON round trip is lossless (Q4) | `weighting_factor` |
| Net area factor | The share of a Floor Segment's area that counts toward net volume, default 1 | `net_area_factor` |
| Average clear ceiling height | The Volume's height used for net volume | `avg_ceiling_height` |
| Net volume | Net floor area times average clear ceiling height, summed over Volumes. Shown as Vn50 where the consumer calls it that | `net_volume` |
| Supply, Extract, Transfer airflow | Per-Space ventilation rates. All three unset means use the Zone's load. Any one set makes the Space user-specified, and its unset rates count as zero (Q21). Stored in m3/h; honeybee-ph holds m3/s | `_v_sup`, `_v_eta`, `_v_tran` |
| Volume preview (new) | The overlay extrusion of a Volume's Floor Segments by its height | |
| Height from solid (new) | The helper that sets a Volume's height to a selected closed group's volume divided by the Volume's net floor area | |
| Space label (new) | Viewport text drawn at a Space's reference point: number, name, iCFA, net volume, airflows | |
| Selection totals (new) | The HUD readout of iCFA, net volume and airflow sums for the selected Spaces | |
| Airflow balance view (new) | A grouped totals table: supply, extract and transfer sums with an imbalance warning label, grouped by Zone now and by ventilator with Zones underneath once equipment exists | |
| Move Space to Zone (new) | The action that relocates one whole Space group into another Zone group, keeping its world position and records, as one Undo step | |

## Records

Stored on the entities, as the predecessor does, with the Zone stamp added per the zones packet.

```
Space group     identifier, name, number, default_height_m, next_volume_sequence,
                v_sup_m3h, v_eta_m3h, v_tran_m3h   (each absent | number),
                zone stamp, user_data
Volume group    identifier, number, display_name, avg_ceiling_height_m, floor_identifier,
                home_transform, user_data
Floor Segment   identifier, display_name, icfa_factor (default 1.0),
                net_area_factor (default 1.0), user_data
```

- **Identity.** Each `identifier` is a UUID in PH-Composer's own dictionary on the entity, as
  the predecessor's `identifiers.rb` issues it. It is the durable identity that
  [TECH_STACK.md](../../../context/TECH_STACK.md) requires, because cut and paste can replace a
  `persistent_id`. References to a Space from the table, the overlay, the report and the export
  use the identifier plus the occurrence path. The honeybee-ph identifiers derive from it.
- **Copies (Q20).** A native copy of a Space, a Volume or a Floor Segment face copies its
  dictionary, so two entities share an identifier. That is the predecessor's blocking
  `duplicate_identity` finding, kept. Its repair is **Make independent**: the copy and everything
  inside it receive new identifiers and the Space the next free number, as one Undo step.
  Nothing reissues an identifier silently, because a deferred pass cannot tell a copy from a cut
  and paste. A Space inside a repeated component is the same finding with no repair offered:
  PH-Composer never makes a parent unique.
- **`user_data`.** All three records carry the `user_data` mapping and structured extension
  payloads that [EXTENSIBILITY.md](../../../context/EXTENSIBILITY.md) requires, under the
  foundation's storage contract. Move Space to Zone keeps it. Make independent keeps it, since a
  copy is the user's own. None of it is exported.

Not stored: the predecessor's per-Space colour is dropped in favour of a categorical ramp keyed
by Space id (Q13). `quantity` is always 1, because every Space is drawn (zones packet Q4), and
`wufi_type` waits for the Space Types packet. Floor level moved to the Zone (zones packet Q6).

## Behaviors

### Creating Spaces, Volumes and Floor Segments

- The user draws floor outlines as faces, selects them, and runs **Create Space**. The
  predecessor's preview is kept: it says which selected faces will be accepted, which are left
  out and why, before anything is written. Accepted faces become Floor Segments in one new Volume
  in one new Space, as one Undo step.
- Drawing a face inside an open Volume and marking it adds a Floor Segment to that Volume. Drawing
  one at the Space root and marking it creates the next Volume. Both are the predecessor's rules
  with the designPH trigger replaced by the explicit mark.
- **Mark floor** is this feature's own `Sketchup::Tool` (Q19): click or drag over faces inside a
  Volume. Its palette has one row with two chips, Counts and Does not count (Q4). A face outside
  any Volume offers Create Space inline. It sits beside the Classify tool on the toolbar and in
  the panel and follows the same drawing-tool state rule, so one of the two is pressed at a time.
  It shares the pick and drag primitives in `core/` and the UI kit's palette; it adds nothing to
  face-assignment's folder. While active it forces the By iCFA factor mode on, as Classify does
  with its own modes.
- In the panel and on the toolbar, Create Space is available only while a Zone's edit context is
  open, and says so when it is not. The user may still draw off to the side from inside that
  context. The operation underneath takes explicit face references and a Zone reference and needs
  no `active_path`, so a script or an external client runs it with the panel closed.
- **Move Space to Zone** relocates an existing Space group into another Zone as one Undo step; it
  is also the fix for a room put in the wrong Zone (Q18). SketchUp cannot reparent a group, so the
  operation re-instances the Space in the target Zone's entities and erases the original, inside
  one `ModelOperation.perform`. Identifiers, names, numbers, heights, factors, airflows and
  `user_data` are kept. The Zone stamp on the Space is rewritten. Each Volume's `home_transform`
  and the accumulated transform are recomputed against the new parent so the world position
  holds. Persistent ids may change, which the identifier rule absorbs. It is refused while a
  Volume inside the Space is open, and the refusal ends `Nothing was written.` Loose faces are
  never moved across contexts.
- A non-horizontal face may be marked. Its area is the projected horizontal area, with an info
  finding (Q14). The projection plane is horizontal at the face's mean z, the predecessor's
  flatten rule. Metrics, the preview prism's base and the export all use that one projection.
- Volume protection, exit protection, the pre-save rule and the recovery states are the
  predecessor's, unchanged. Their evidence is its B1 and B2 acceptance records.

### iCFA

- A Floor Segment's iCFA is its area times its iCFA factor. A Volume, Space, Zone and Building-Segment
  each show the sum.
- Phius guidebook 4.4.1.4 governs what the user draws: drywall-to-drywall of the thermal
  boundary, including interior walls, stairs once per floor, cabinets, mechanical and storage;
  at least 7 ft clear height; open-to-below excluded. The Mark floor tooltip states the rule.
- Nothing enforces it. Partition footprints, the 7 ft rule and what counts are the user's to draw
  and mark correctly (Q3). There is no height finding and no comparison against the Zone's
  envelope floor in the MVP; a model-validation pass may come later (Q15).

### Volume

- The Volume's average clear ceiling height is edited in the table and in the inspector. A drag
  handle on the preview's top face is a later phase, after the overlay spike (Q6).
- New Volumes take the Space's default height. A Space's default height takes the last value the
  user entered in this model, then 2.5 m, shown as 8.2 ft in IP (Q7).
- **Volume preview** draws each Volume as a translucent prism from its Floor Segments up by the
  height, in the active Colour-by mode's colour, with edges. It is the derived geometry of the
  four Spaces modes, so it is on while one of them is active and off otherwise. It is drawn,
  never modeled: nothing is added to the SKP.
- **Height from solid**, a later phase of this packet (Q5): with a Volume and one closed group selected, set the height to the
  group's volume divided by the Volume's net floor area, and report both numbers. The solid is
  the user's and is not read again; if the room changes, the user reruns the helper. This covers
  sloped ceilings, dormers and double-height rooms without a second data model.
- Phius guidebook 6.4.3: net volume does not affect the energy model and is not required for
  certification. METr and WUFI still take it, and it converts the airtightness result, so it must
  be present and plausible. A height-based volume meets that.

### Airflows

- Supply, extract and transfer are three optional numbers on the Space, in m³/h stored and in the
  user's display units shown. A typed zero means zero.
- **The any-set rule (Q21).** A Space with all three unset inherits: it uses the Zone's
  ventilation load, and its cells read as muted inherited values once Zone loads exist. A Space
  with any one set is user-specified: its unset cells read as a muted 0 and count as zero
  everywhere, in metrics, labels, totals, the balance view and the export. The record keeps unset
  distinct from zero, so clearing the last typed value returns the Space to inheriting.
- All three rates ship in the MVP (Q8). The Spaces table shows the three columns with range edit
  and paste.
- The **airflow balance view** is its own tab body: one row per Zone with its supply, extract and
  transfer sums, a click into the Zone's Spaces, a model total, and a warning label where supply
  and extract differ by more than 10 percent. Sums cover the user-specified Spaces. Until the
  Zone loads packet supplies an inherited value through a declared read, a Zone holding any
  inheriting Space is marked "partly inherited" with the count, and its warning is not
  evaluated. When the equipment packet lands the same view groups
  by ventilator with Zones underneath, and the warning applies per unit as well (Q9, Q16). The
  view takes a grouping provider, Zone by default; the equipment packet registers a second one and
  edits nothing in this feature's folder.
- PHX tests each override separately and falls back per rate (`create_rooms.py:133-140`), which is
  not the any-set rule. The exporter closes the gap without a PHX change: for a user-specified
  Space it writes all three values, with 0 for an unset rate; for an inheriting Space it writes
  none.

### The model tree and the table

- One tree, per the face-assignment packet's Q11: Zone, then Space, then Volume, then Floor
  Segment, with the faces table as a sibling under each Zone. Rows Locate, enter and leave
  contexts by the predecessor's rules.
- Columns: number, name, iCFA, net volume, height (on Volume rows), iCFA factor (on Floor Segment
  rows), supply, extract, transfer, state. Level is read from the Zone.
- **Select by**: a right-click on any cell value selects every Space with that value, the 2019
  tool's Select Rooms By generalized to every column (Q12). A column a contributor adds through a
  table-column contribution point would get it too; no authority defines that point yet and this
  packet does not add one.

### Seeing the data in the model

All on the Colour-by service that the face-assignment packet builds (Q22). That packet's contract
is widened for this one: a mode names an open entity kind and may supply derived geometry, and a
readout is a separate registration. This packet registers four modes, whose entity kind is the
Volume, and two readouts. Each mode colours the Volume's Floor Segment faces and its preview
prism alike. Every projection is pure and reads this feature's public readers.

| Mode | Colours | Legend |
| --- | --- | --- |
| By Space | a categorical ramp keyed by Space id, stable across sessions (Q13) | number and name, iCFA |
| By ventilation | supply only, extract only, both, transfer only, none | counts and flow sums |
| By iCFA factor | Counts, Does not count, and any other stored value, which a script can write | area per band |
| By height | bands of average clear ceiling height | net volume per band |

- **Space labels**: viewport text at each Space's reference point, number and name by default,
  with iCFA, net volume and airflows toggled from the legend (Q11). Labels are a readout, shown
  with any Spaces mode and with none. They replace the 2019 LayOut Auto-Text for
  on-screen QA; LayOut itself is out of scope.
- **Selection totals**: with one or more Spaces selected, the HUD shows their summed iCFA, net
  volume, supply and extract in the user's display units. This is the 2019 Quick View. It is a
  readout driven by the selection and independent of the active mode.
- By-unit and by-system modes are registered later by the equipment packet, colouring each Space
  by its Zone's unit, since equipment is assigned to Zones.

### Validation rows

| Finding | Severity | Repair |
| --- | --- | --- |
| Space outside any Zone | blocking for export | Move into a Zone, or Make Zone |
| Space with no Volume, Volume with no Floor Segment | warning; the predecessor's recovery states | Add, or remove the empty structure |
| Volume moved outside its edit context | warning | Restore, per the predecessor |
| Volume height missing | blocking for export | Enter a height |
| Supply and extract sums differ by more than 10 percent in a Zone, and per ventilator once units exist | warning, shown in the airflow balance view | Review airflows |
| Duplicate Space number within a Zone | warning | Renumber |
| Duplicate identity: two Spaces, Volumes or Floor Segments share an identifier | blocking for export | Make independent (Q20). Inside a repeated component: draw the Space directly |
| Floor Segment face not horizontal; projected area used | info | Review |

### Export mapping

One honeybee-ph `Space` per Space on its Zone's Room, with `name`, `number`, `quantity` 1, one
`SpaceVolume` per Volume carrying `avg_ceiling_height` and a `SpaceFloor` of `SpaceFloorSegment`s
built from the faces through the occurrence path, `weighting_factor` from the iCFA factor,
`net_area_factor` as stored. A non-horizontal Floor Segment is written projected onto the
horizontal plane at its mean z, so honeybee-ph's `floor_area`, which is the geometry's area,
equals the iCFA the panel showed. `_v_sup`, `_v_eta` and `_v_tran` follow the any-set rule: all
three for a user-specified Space, none for an inheriting one. The Python section converts m3/h to
honeybee-ph's m3/s there and nowhere else. Each `Space` attaches to the `Room` the zones section
builds; the Spaces section declares that result as a dependency, the same seam as assemblies Q23
and the same open foundation question. The
`SpaceVolume.geometry` list receives the preview prism's faces so a downstream viewer draws the
same volume the user saw (Q10). Geometry is exported where it was drawn; when a Space sits
outside its Zone's extents the Export report says so in one line, because a honeybee viewer
will show those rooms beside the building while PHX and METr read only areas, heights and flows
(Q17). The Export report gets a Spaces schedule per Zone with the same columns
as the table and the totals per Zone and Building-Segment.

## Non-goals

- Loads, schedules and equipment. They belong to the Zone and to later packets.
- Enforcing Phius's iCFA drawing rules, or any geometric containment test between a Space and its
  Zone. A model-validation pass may come later (Q3, Q15).
- A viewport drag handle for height, in the MVP (Q6).
- Space Types and `wufi_type`.
- A second volume model read live from drawn solids.
- LayOut integration and Dynamic Components. The 2019 tool's own README calls the latter a
  long-term risk with no public API.
- A CSV export of the schedule. The Export report carries it; a separate CSV is a later decision.
- Any PHPP output.

## Decisions recorded

Interviewed 2026-09-18, two rounds, Ed's answers. Each is cited where it applies above.

| # | Decision | Answer |
| --- | --- | --- |
| Q1 | Floor Segment faces versus envelope Floor faces | Separate faces, always |
| Q2 | How a Space belongs to a Zone | Its parent group. Users may draw Spaces anywhere, off to the side included. No geometric containment test |
| Q3 | Partitions and iCFA | The user's job to draw and mark properly. No enforcement |
| Q4 | iCFA factor on screen | Two chips, Counts and Does not count; the stored field stays a float |
| Q5 | Height from solid | A later phase of this packet |
| Q6 | Height drag handle | Later; table and inspector for the MVP |
| Q7 | Default height | The Space's default, from the last value entered, then 2.5 m (8.2 ft) |
| Q8 | Transfer airflow | All three rates in the MVP |
| Q9 | Imbalance finding | Per Zone now and per ventilator later, 10 percent, shown in a dedicated view listing Zones by ventilator with click-in and clear totals |
| Q10 | `SpaceVolume.geometry` on export | Write the preview prism's faces |
| Q11 | Space labels | In this packet; number and name by default, the rest toggled |
| Q12 | Select by | A right-click on any cell value |
| Q13 | Space colour | Field dropped; categorical ramp keyed by Space id |
| Q14 | Non-horizontal floors | Allowed, projected area, info finding |
| Q15 | 7 ft height finding | Dropped for the MVP; maybe a model-validate pass someday |
| Q16 | Balance view before ventilators exist | Built in this packet grouped by Zone; regrouped by ventilator by the equipment packet |
| Q17 | Off-to-the-side Spaces on export | Exported as drawn, one line in the Export report |
| Q18 | Creating a Space outside a Zone | Create Space only inside a Zone's edit context; Move Space to Zone for existing groups |

Architecture review, 2026-09-18. Q19 to Q21 are Ed's answers; Q22 to Q24 are the review's
recommendations, accepted with the instruction to fold the review in.

| # | Decision | Answer |
| --- | --- | --- |
| Q19 | Mark floor and the Classify tool | A sibling `Sketchup::Tool` owned by Spaces, sharing `core/` pick and drag primitives and the UI kit palette. No tool-mode contract |
| Q20 | A copied Space, Volume or Floor Segment | The blocking `duplicate_identity` finding, with a Make independent repair. No silent reissue |
| Q21 | Unset airflows | If any of the three is set, unset reads as zero. Only a Space with all three unset falls back to the Zone's load. The exporter writes explicit zeros, so PHX is unchanged |
| Q22 | Colour-by reach | The shared contract gains an open entity kind, optional derived geometry and separate readouts. Spaces modes colour Volumes; labels and totals are readouts |
| Q23 | Sloped floors on export | Projected to the horizontal plane at the face's mean z, in metrics, preview and export alike |
| Q24 | Move Space to Zone | Re-instance and erase in one operation; identifiers and data kept, Zone stamp rewritten, transforms recomputed, refused while a Volume is open |

## Acceptance shape

Offline: the predecessor's Spaces suite with the designPH double removed and Mark floor in its
place; fixtures for a Space under a rotated wrapper, a multi-Volume Space with two heights, a
Space drawn off to the side of its Zone, airflows absent, zero and set, a two-Zone model with
imbalance in one, Move Space to Zone under a rotated wrapper, a sloped floor face, and Height from
solid on a wedge. Each proves records, metrics, findings and the export mapping. For the sloped
face, Ruby's iCFA equals the loaded `SpaceFloorSegment.floor_area` and Ruby's net volume equals
`SpaceVolume.net_volume`. Airflow fixtures for supply only, all unset and all zero, read back
through PHX as m3/h, with the balance view row for each. A copied Space, Volume and Floor Segment
each raise `duplicate_identity`, and Make independent clears it in one Undo step. `user_data`
survives edit, Move Space to Zone, Make independent, Undo/Redo and save and reopen. A synthetic
mode with derived geometry and a synthetic readout register without editing the Colour-by
service, and Spaces installs with face-assignment's folder unchanged. A panel-closed script
creates a Space from explicit face and Zone references, marks a floor, sets a height and two
airflows, moves the Space and reads the result back.

Host gate, fresh process: draw three room outlines in a Zone, Create Space from each, set heights,
see the preview prisms, draw a fourth room off to the side from inside the Zone, run Height from
solid on a sloped room, enter airflows by range paste, open the airflow balance view and see the
imbalance label, move one Space to a second Zone, copy a Space and repair it with Make independent,
switch between Classify and Mark floor and confirm one pressed state, switch through the four modes
and read the HUD, select two Spaces and read the totals, Undo each step, save, reopen inside an open
Volume, export, and confirm the honeybee-ph Spaces, volumes, factors and airflow overrides arrive
and PHX writes the METr rooms.

## Prior art and evidence

- Predecessor Spaces feature: `../../ph-navigator-sketchup/src/ph_navigator_sketchup/features/spaces/`
  (attrs, metrics, reconciler, preview, recovery) and its B1, B2 and Spaces table controls
  acceptance records under `planning/archive/`.
- honeybee-ph: `honeybee_ph/honeybee_ph/space.py` (`Space`, `SpaceVolume.net_volume`,
  `SpaceFloorSegment.weighting_factor` and `net_area_factor`) and `properties/space.py`
  (`_v_sup`, `_v_eta`, `_v_tran`, `has_ventilation_flow_rates`).
- dPH+ Rooms, 2019: https://github.com/PH-Tools/dph-plus-rooms. Source of Colour the scene by,
  Select rooms by, Quick View and room labels. Its drawn-solid volume and Dynamic Components are
  not carried over.
- Phius guidebook 4.4.1.4 (iCFA), 6.4.3 (net volume), 6.4.4, in the phius-rules corpus.
