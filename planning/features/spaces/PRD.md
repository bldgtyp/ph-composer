# Spaces: behavior contract

DATE: 2026-09-18
STATUS: Scoped. Interviewed 2026-09-18 in two rounds, 18 decisions recorded below. PLAN.md follows the overlay spike and the foundation transplant.
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
extract and transfer rates, and when any is present PHX uses the Space's values and otherwise
falls back to the Zone's ventilation load. The exception exists so a modeler does not need one
Zone per room.

## Decision

- The Space record maps field for field to honeybee-ph's `Space`, `SpaceVolume`, `SpaceFloor` and
  `SpaceFloorSegment`. No new concepts. The predecessor's hierarchy, protection, reconciler,
  recovery states and table carry over unchanged in behavior.
- PassiveBuilder owns floor classification. **Mark floor** in the Classify tool's family writes the
  Floor Segment record on a face the user drew inside a Volume, replacing the predecessor's
  dependence on designPH.
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
  PassiveBuilder states the Phius rule and enforces nothing (Q3, Q15).
- Airflows are entered per Space in the table and the inspector, with missing distinct from zero.

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
| Supply, Extract, Transfer airflow | Per-Space ventilation rates; absent means use the Zone's load; zero means zero | `_v_sup`, `_v_eta`, `_v_tran` |
| Volume preview (new) | The overlay extrusion of a Volume's Floor Segments by its height | |
| Height from solid (new) | The helper that sets a Volume's height to a selected closed group's volume divided by the Volume's net floor area | |
| Space label (new) | Viewport text drawn at a Space's reference point: number, name, iCFA, net volume, airflows | |
| Selection totals (new) | The HUD readout of iCFA, net volume and airflow sums for the selected Spaces | |
| Airflow balance view (new) | A grouped totals table: supply, extract and transfer sums with an imbalance warning label, grouped by Zone now and by ventilator with Zones underneath once equipment exists | |
| Move Space to Zone (new) | The action that relocates one whole Space group into another Zone group, keeping its world position and records, as one Undo step | |

## Records

Stored on the entities, as the predecessor does, with the Zone stamp added per the zones packet.

```
Space group     name, number, default_height_m, next_volume_sequence,
                v_sup_m3h, v_eta_m3h, v_tran_m3h   (each absent | number),
                zone stamp
Volume group    number, display_name, avg_ceiling_height_m, floor_identifier, home_transform
Floor Segment   display_name, icfa_factor (default 1.0), net_area_factor (default 1.0)
```

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
- **Mark floor** is a mode of the Classify tool: click or drag over faces inside a Volume. Its
  palette has one row with two chips, Counts and Does not count (Q4). A face outside any Volume
  offers Create Space inline.
- Create Space is available only while a Zone's edit context is open, and says so when it is not.
  The user may still draw off to the side from inside that context. **Move Space to Zone**
  relocates an existing Space group into another Zone as one Undo step, keeping world position
  and records; it is also the fix for a room put in the wrong Zone (Q18). Loose faces are never
  moved across contexts.
- A non-horizontal face may be marked. Its area is the projected horizontal area, with an info
  finding (Q14).
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
  height, in the active Colour-by mode's colour, with edges. It is on while a Spaces Colour-by
  mode is active and off otherwise. It is drawn, never modeled: nothing is added to the SKP.
- **Height from solid**, a later phase of this packet (Q5): with a Volume and one closed group selected, set the height to the
  group's volume divided by the Volume's net floor area, and report both numbers. The solid is
  the user's and is not read again; if the room changes, the user reruns the helper. This covers
  sloped ceilings, dormers and double-height rooms without a second data model.
- Phius guidebook 6.4.3: net volume does not affect the energy model and is not required for
  certification. METr and WUFI still take it, and it converts the airtightness result, so it must
  be present and plausible. A height-based volume meets that.

### Airflows

- Supply, extract and transfer are three optional numbers on the Space, in m³/h stored and in the
  user's display units shown. An empty cell means "use the Zone's ventilation load" and reads as a
  muted inherited value once Zone loads exist. A typed zero means zero.
- All three rates ship in the MVP (Q8). The Spaces table shows the three columns with range edit
  and paste.
- The **airflow balance view** is its own tab body: one row per Zone with its supply, extract and
  transfer sums, a click into the Zone's Spaces, a model total, and a warning label where supply
  and extract differ by more than 10 percent. When the equipment packet lands the same view groups
  by ventilator with Zones underneath, and the warning applies per unit as well (Q9, Q16).
- PHX already reads the overrides first and falls back to the Room's rate. Nothing changes there.

### The model tree and the table

- One tree, per the face-assignment packet's Q11: Zone, then Space, then Volume, then Floor
  Segment, with the faces table as a sibling under each Zone. Rows Locate, enter and leave
  contexts by the predecessor's rules.
- Columns: number, name, iCFA, net volume, height (on Volume rows), iCFA factor (on Floor Segment
  rows), supply, extract, transfer, state. Level is read from the Zone.
- **Select by**: a right-click on any cell value selects every Space with that value, the 2019
  tool's Select Rooms By generalized to every column, including any a contributor adds (Q12).

### Seeing the data in the model

All on the Colour-by component. This packet registers four Space modes and two readouts.

| Mode | Colours | Legend |
| --- | --- | --- |
| By Space | a categorical ramp keyed by Space id, stable across sessions (Q13) | number and name, iCFA |
| By ventilation | supply only, extract only, both, transfer only, none | counts and flow sums |
| By iCFA factor | Counts, Does not count, and any other stored value from an imported model | area per band |
| By height | bands of average clear ceiling height | net volume per band |

- **Space labels**: viewport text at each Space's reference point, number and name by default,
  with iCFA, net volume and airflows toggled from the legend (Q11). They replace the 2019 LayOut Auto-Text for
  on-screen QA; LayOut itself is out of scope.
- **Selection totals**: with one or more Spaces selected, the HUD shows their summed iCFA, net
  volume, supply and extract in the user's display units. This is the 2019 Quick View.
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
| Floor Segment face not horizontal; projected area used | info | Review |

### Export mapping

One honeybee-ph `Space` per Space on its Zone's Room, with `name`, `number`, `quantity` 1, one
`SpaceVolume` per Volume carrying `avg_ceiling_height` and a `SpaceFloor` of `SpaceFloorSegment`s
built from the faces through the occurrence path, `weighting_factor` from the iCFA factor,
`net_area_factor` as stored, and `_v_sup`, `_v_eta`, `_v_tran` written only when present. The
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

## Acceptance shape

Offline: the predecessor's Spaces suite with the designPH double removed and Mark floor in its
place; fixtures for a Space under a rotated wrapper, a multi-Volume Space with two heights, a
Space drawn off to the side of its Zone, airflows absent, zero and set, a two-Zone model with
imbalance in one, Move Space to Zone, a sloped floor face, and Height from solid on a wedge. Each proves records, metrics, findings and the export mapping.

Host gate, fresh process: draw three room outlines in a Zone, Create Space from each, set heights,
see the preview prisms, draw a fourth room off to the side from inside the Zone, run Height from
solid on a sloped room, enter airflows by range paste, open the airflow balance view and see the
imbalance label, move one Space to a second Zone, switch through the four modes and read the HUD,
select two Spaces and read the totals, Undo each step, save, reopen inside an open Volume, export, and confirm the honeybee-ph
Spaces, volumes, factors and airflow overrides arrive and PHX writes the METr rooms.

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
