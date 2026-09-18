# Hot water piping

DATE: 2026-09-18
STATUS: Requested. Draft, not interviewed.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (no remote)

## Problem

Phius counts hot water distribution losses from the pipes themselves: length, diameter, material
and insulation. On a multifamily project this is hundreds of metres of pipe. The consultant
already has the building in SketchUp, so tracing the risers and branches as lines over the model
is the fastest measurement there is. The extension's job is to turn those lines into the
structure METr wants.

## Port disposition

| Part | Disposition | Note |
| --- | --- | --- |
| Predecessor M1 brief | Adapt | Its open questions are answered or carried below. Its boundary "no new general-purpose drawing tool" is kept |
| Record engine, inventory table, usage scan | Port | From the foundation transplant |
| Classify tool family, Colour-by component | Adapt | As thermal-bridges adapts them for edges |
| Edge tagging rules | Port | From thermal-bridges |
| Pipe Type record, role and tree assignment | New | |
| Python translation to the honeybee-ph piping classes | New | |

## Vocabulary

Proposed. `context/UBIQUITOUS_LANGUAGE.md` is not changed until the interview.

| Term | Meaning |
| --- | --- |
| Pipe Type | A named pipe specification: material, diameter, insulation. Model-local and reusable |
| Pipe | One drawn SketchUp edge that carries a Pipe Type |
| Pipe-Segment | honeybee-ph's `PhHvacPipeSegment`. Always qualified, under the rule that gave Building-Segment and Layer-Segment. One per Pipe at export |
| Role | What a Pipe does: Trunk, Branch, Fixture or Recirculation. honeybee-ph says fixture, METr says twig |
| Piping group | A SketchUp group that holds drawn Pipes and nothing else |

## What honeybee-ph and METr take

Verified in `honeybee_phhvac/hot_water_piping.py`, `hot_water_system.py`, PHX
`model/hvac/piping.py` and `to_METr_JSON/metr_schemas.py`.

- `PhHvacPipeSegment`: `geometry` (a line), `diameter_mm`, `insulation_thickness_mm`,
  `insulation_conductivity`, `insulation_reflective`, `insulation_quality` (1 None, 2 Moderate,
  3 Good), `daily_period`, `water_temp_c`, `material`.
- `material`: 1 Copper M, 2 Copper L, 3 Copper K, 4 CPVC CTS SDR, 5 CPVC Sch 40, 6 PEX, 7 PE,
  8 PEX CTS SDR.
- `PhHvacPipeElement`: a set of segments. `PhHvacPipeBranch`: one element plus a list of fixture
  elements. `PhHvacPipeTrunk`: one element, `multiplier`, `demand_recirculation`, and a list of
  branches.
- `PhHotWaterSystem` holds `_distribution_piping`, trunks by id, and `_recirc_piping`, plain
  elements by id, plus `_number_tap_points`.
- METr's tree: trunk, branch, twig, written by PHX as `lTruncW` in the distribution block. Each takes name, length in m, material and a diameter enum.
  The enum is a nominal inch list: 3/8, 1/2, 5/8, 3/4, 1, 1 1/4, 1 1/2, 2. PHX snaps the
  length-weighted diameter to the nearest entry, so a 22 mm pipe and a 3/4 in pipe export the same.
- METr does not take per-pipe insulation in the tree. Trunk also takes `cUoF`, the multiplier,
  and `drecW`.
- Recirculation is not a tree. METr takes one total length, one length-weighted heat loss
  coefficient in W/(m K) that PHX computes from diameter and insulation, daily recirculation
  hours, water temperature, air temperature, and an "all pipes insulated" flag.
- PHX's enum has four calculation methods: simplified individual pipes, simplified hot water
  calculator, unit method and floor method. Which of them read the drawn tree and which need
  only counts is not yet checked. The interview needs that before Q5.

## Records

```
PipeType        id (ppt_), name, material, diameter_mm, insulation_thickness_mm,
                insulation_conductivity_w_mk, insulation_reflective, insulation_quality,
                color, notes, source, schema_version, created_at, updated_at

pipe assignment pipe_type_id, role, parent_ref, schema_version
(on the Edge)

Piping group    hot_water_system_id, schema_version
(on the Group)
```

`water_temp_c`, `daily_period`, the trunk `multiplier` and `demand_recirculation` sit on the Hot
Water System record or the trunk run, not on the Pipe Type. They are operating conditions, and
METr holds them once per system.

## Behaviors

### Pipe Types tab

An inventory table: name, material, diameter, insulation thickness, conductivity, reflective,
quality, colour, used length. Add, duplicate, delete with a usage warning.

### Draw

Pipes are drawn with SketchUp's native Line tool inside a Piping group. "New Piping group" in
the panel creates the group, links it to a Hot Water System and opens it for editing, so the
next lines land inside. Membership is by parent group, the same rule Spaces follow. Lines
outside a Piping group are never Pipes, so tagging cannot leak onto envelope edges.

### Assign

Select lines, pick a Pipe Type and a role, press Assign. Or arm the Classify tool with a type
and role and click lines. One Undo step.

### The tree

METr needs to know which branches hang off which trunk and which fixtures off which branch.
Two ways to get that, and Q1 chooses:

- **By connection.** The exporter walks the lines. A Branch that touches a Trunk belongs to it.
  A Fixture that touches a Branch belongs to it. The user only sets roles. A line that touches
  nothing is a finding.
- **By explicit parent.** The user picks the parent in the panel for each run.

Connected lines with the same role and type form one run. Each run is one trunk, one branch or
one fixture at export, holding one Pipe-Segment per line.

### Recirculation

Lines with the Recirculation role are summed per Hot Water System. No tree. The schedule shows
the total length and the weighted heat loss coefficient PHX will compute.

### Schedule

One row per run: system, role, parent, Pipe Type, length, line count. Totals by role and system.
Click a row to select its lines.

### Colour-by mode

`Piping` mode: lines draw thick, coloured by role or by Pipe Type. HUD legend with lengths.

### Validation rows

| Finding | Severity |
| --- | --- |
| Pipe with no Pipe Type, or a deleted one | Blocks export |
| Pipe with no role | Blocks export |
| Branch that reaches no Trunk, Fixture that reaches no Branch | Blocks export under by-connection |
| Piping group with no Hot Water System | Blocks export |
| Pipe Type diameter far from any METr nominal size | Warning, names the size METr will use |
| Trunk with no branches | Warning |
| Pipe Type with insulation thickness but no conductivity | Blocks export |

### Export mapping

| PassiveBuilder | honeybee-ph |
| --- | --- |
| Pipe, one line | `PhHvacPipeSegment` with the type's fields and the line as `geometry` |
| Run | `PhHvacPipeElement` |
| Trunk run | `PhHvacPipeTrunk`, with `multiplier` and `demand_recirculation` |
| Branch run | `PhHvacPipeBranch` under its trunk |
| Fixture run | An element in the branch's `fixtures` |
| Recirculation lines | Elements in `PhHotWaterSystem._recirc_piping` |
| Hot Water System | `PhHotWaterSystem`, attached to the Rooms of the Zones it serves |

## Decisions for the interview

| # | Question | Recommendation |
| --- | --- | --- |
| Q1 | Tree by connection or by explicit parent? | By connection. The drawing already says it, and findings catch the gaps |
| Q2 | Draw with the native Line tool in a Piping group, or a custom Draw Pipe tool? | Native Line in a Piping group. M1's boundary was no new drawing tool, and inference snapping to the model is what makes tracing fast |
| Q3 | Is "pipe type" the specification only, with role set separately? | Yes. The same 3/4 in PEX is a branch in one place and a fixture run in another |
| Q4 | Diameter entry: free mm, or METr's nominal size list? | The nominal list, stored as `diameter_mm`. A free value METr rounds is false precision |
| Q5 | Support the simplified methods, with no drawn pipes? | Yes, as a choice on the Hot Water System. A single-family model should not need a drawn tree |
| Q6 | The trunk multiplier: expose it? | Yes. One drawn riser times twelve identical risers is the multifamily case |
| Q7 | One Piping group per Hot Water System, or many? | Many. A group per floor or riser is how people organise. The system link is on each group |
| Q8 | Do Pipes belong to a Zone? | No. They belong to a Hot Water System, which serves Zones. Pipes cross Zone boundaries |
| Q9 | Is insulation kept on the Pipe Type though METr's tree ignores it? | Yes. The recirculation heat loss coefficient uses it and honeybee-ph carries it |
| Q10 | Are Pipe Types a library kind? | Not now. Same answer as Thermal Bridge Types |
| Q11 | Rename: Pipe-Segment qualified, role word Fixture or Twig? | Pipe-Segment. Twig on screen, matching METr, as Assemblies matched METr |
| Q12 | Where does piping live in primary navigation? | Confirmed in D4: under Systems, with Equipment, ERV ducting and Hot-water piping as peer subtabs |

## Non-goals

No sizing, no flow or pressure calculation, no fittings, no hydronic heating pipes, no automatic
routing.

## Acceptance shape

On a synthetic three-storey model: two Pipe Types, one riser trunk with a multiplier, three
branches, six fixture runs and a recirculation loop, all drawn with the Line tool. Schedule
lengths match hand measurement. Break one branch from its trunk and see the finding. Export and
find the tree in HBJSON and in METr JSON with the right lengths, materials and diameter enums,
and the recirculation total. One Undo per assign. Save and reopen.

## Prior art and evidence

- Predecessor `planning/phases/M1_piping.md`.
- honeybee-ph `honeybee_phhvac/hot_water_piping.py`, `hot_water_system.py`.
- PHX `model/hvac/piping.py`, `model/enums/hvac.py`, `to_METr_JSON/metr_schemas.py`.
- honeybee-grasshopper-ph "HBPH - Create SHW Pipe" family: curves in, trunks and branches out.
