# ERV ducting

DATE: 2026-09-18
STATUS: Requested. Draft, not interviewed.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (no remote)

## Problem

The ducts between an ERV and the outside wall carry outdoor-temperature air through the
conditioned space. Phius counts their heat loss from length, size and insulation, and it lowers
the effective heat recovery. The inputs are two short runs per ventilator. They are easy to
draw over the model and tedious to measure any other way on a building with forty units.

## Port disposition

| Part | Disposition | Note |
| --- | --- | --- |
| Predecessor M2 brief | Adapt | Its boundary is kept: no duct design, no pressure drop, no routing |
| Record engine, inventory table, usage scan | Port | From the foundation transplant |
| Draw in a group, Assign, edge Classify tool, schedule | Port | From hot-water-piping, once adapted for edges there |
| Edge tagging rules | Port | From thermal-bridges |
| Duct Type record, Ducting group | New | |
| Python translation to `PhDuctElement` | New | |

## Vocabulary

Proposed. `context/UBIQUITOUS_LANGUAGE.md` is not changed until the interview.

| Term | Meaning |
| --- | --- |
| Duct Type | A named duct specification: shape, size, insulation. Model-local and reusable |
| Duct | One drawn SketchUp edge that carries a Duct Type |
| Duct-Segment | honeybee-ph's `PhDuctSegment`. Always qualified. One per Duct at export |
| Duct run | The Ducts of one direction in one Ducting group. One `PhDuctElement` at export |
| Direction | Supply or Exhaust. honeybee-ph's `duct_type` 1 and 2 |
| Ducting group | A SketchUp group that holds drawn Ducts and links to one Ventilator |

## What honeybee-ph and METr take

Verified in `honeybee_phhvac/ducting.py`, `ventilation.py`, PHX `model/hvac/ducting.py` and
`to_METr_JSON/metr_schemas.py`.

- `PhDuctSegment`: `geometry`, `diameter`, `height`, `width`, `insulation_thickness`,
  `insulation_conductivity`, `insulation_reflective`. The honeybee-ph names carry no unit
  suffix. PHX's carry `_mm`. PassiveBuilder records carry the suffix and the translation maps them.
- A segment with height and width is rectangular. Otherwise it is round and uses diameter.
- `PhDuctElement`: `display_name`, `duct_type` (1 supply, 2 exhaust), and its segments.
- `PhVentilationSystem` holds `supply_ducting` and `exhaust_ducting` lists, and validates that
  each element's `duct_type` matches the list it is in.
- METr takes ducts as one model-level list in the distribution block. Each duct carries name,
  diameter, width, height, length in m, insulation thickness, conductivity, `quantity`,
  direction, shape, reflective flag, and `lassVU`, the ids of the ventilators it serves. PHX
  reduces a run of mixed segments to length-weighted values, so one run is one METr row.

## Records

```
DuctType        id (dct_), name, shape, diameter_mm, width_mm, height_mm,
                insulation_thickness_mm, insulation_conductivity_w_mk,
                insulation_reflective, color, notes, source, schema_version,
                created_at, updated_at

duct assignment duct_type_id, direction, schema_version
(on the Edge)

Ducting group   ventilator_id, schema_version
(on the Group)
```

`shape` is `Round` or `Rectangular`. A Round type holds a diameter and blank width and height.
A Rectangular type holds the reverse.

## Behaviors

Draw, Assign, the schedule and the Colour-by mode work as in hot-water-piping, with these
differences.

- "New Ducting group" asks for the Ventilator it serves.
- Assign sets a Duct Type and a direction. There is no tree and no parent. Connection between
  lines does not matter, only the sum.
- A Ventilator's row in the Systems > Equipment subtab shows its two duct lengths, so a missing run is
  visible where the ventilator is edited.
- A Ducting group may be copied with its Ventilator link intact. Forty identical units need one
  drawn pair and either forty copies or a quantity. Q4 chooses.

### Validation rows

| Finding | Severity |
| --- | --- |
| Duct with no Duct Type, or a deleted one | Blocks export |
| Duct with no direction | Blocks export |
| Ducting group with no Ventilator, or a deleted one | Blocks export |
| Ventilator with no supply run or no exhaust run | Warning. METr will assume none |
| Duct Type with insulation thickness but no conductivity | Blocks export |
| Round type with no diameter, Rectangular type missing width or height | Blocks export |

### Export mapping

| PassiveBuilder | honeybee-ph |
| --- | --- |
| Duct, one line | `PhDuctSegment` with the type's fields and the line as `geometry` |
| Duct run | `PhDuctElement` with `duct_type` from direction |
| Supply run | Appended to the Ventilator's `PhVentilationSystem.supply_ducting` |
| Exhaust run | Appended to `exhaust_ducting` |

## Decisions for the interview

| # | Question | Recommendation |
| --- | --- | --- |
| Q1 | Which ducts are drawn: only the two cold runs between ventilator and exterior, or room-side distribution too? | Only the two cold runs. They are the ones Phius counts. Say so on the tab so nobody traces a whole distribution layout |
| Q2 | Direction words: Supply and Exhaust as honeybee-ph has them, or Outdoor air and Exhaust air? | Match METr's screen. Supply is ambiguous, since room supply air is a different duct. Check METr's words before the interview |
| Q3 | Does direction live on the line or on the Ducting group? | On the line. One group per ventilator with both runs inside is the natural drawing |
| Q4 | Repeated units: copy the group, or a quantity on the run? | Both. A copied group works with no code. A `quantity` field is one number and METr has the field |
| Q5 | Same native Line tool and group rule as piping? | Yes |
| Q6 | Do Ducts belong to a Zone? | No. They belong to a Ventilator |
| Q7 | Are Duct Types a library kind? | Not now |
| Q8 | One primary tab for piping and ducting, two primary tabs, or peer subtabs under a Systems home? | Confirmed in D4: Systems is the primary tab, with Equipment, ERV ducting and Hot-water piping as peer subtabs |

## Non-goals

No sizing, no pressure drop, no fittings, no automatic routing, no room-side layout.

## Acceptance shape

On a synthetic model with two Ventilators: one Round and one Rectangular Duct Type, a supply and
an exhaust run per Ventilator drawn with the Line tool. Schedule lengths match hand measurement.
Delete one Ventilator and see the finding. Export and find each run in HBJSON under the right
ventilation system and in METr's duct list with the right `lassVU`. One Undo per assign. Save
and reopen.

## Prior art and evidence

- Predecessor `planning/phases/M2_ducting.md`.
- honeybee-ph `honeybee_phhvac/ducting.py`, `ventilation.py`.
- PHX `model/hvac/ducting.py`, `to_METr_JSON/metr_schemas.py`, `_PhxDuctElement`.
- honeybee-grasshopper-ph "HBPH - Create Ventilation Duct".
