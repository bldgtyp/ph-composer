# Equipment

DATE: 2026-09-18
STATUS: Requested. Draft, not interviewed.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (no remote)

## Problem

A METr model is not complete without its ventilators, heat pumps, water heaters, tanks, pumps
and appliances. Today a consultant exports geometry and then types all of that into METr by
hand, again for every variant. The data is small, tabular and has no geometry. What SketchUp
adds is the Zone: the consultant can say "this ERV serves these two Zones" against the thing
they can see.

## Port disposition

| Part | Disposition | Note |
| --- | --- | --- |
| Predecessor Q1 brief | Adapt | Roster kept. "Interview one family at a time" kept. "No data sheet hosting, no spec status" kept |
| Predecessor B4 brief | Adapt | The single-Room problem it describes is gone. Its proof is still owed, see STATUS |
| Record engine, inventory table, inline edit, usage scan | Port | From the foundation transplant |
| Unit fields | Port | From units. New quantity rows are listed there |
| All equipment records, the Zone assignment, the translation | New | |

## Vocabulary

Proposed. `context/UBIQUITOUS_LANGUAGE.md` is not changed until the interview.

| Term | Meaning |
| --- | --- |
| Equipment item | One record in one family. Model-local |
| Serves | The relation between an equipment item and a Zone |
| Ventilator | METr's and honeybee-ph's word for an ERV or HRV unit |
| Hot Water System | The container for tanks, heaters and piping. One per plant |

## The shared shape

Every family follows this. The family sections add only fields.

### Records

```
<Family item>   id, name, <family fields with SI unit suffixes>, quantity,
                in_conditioned_space, notes, datasheet_links, source,
                schema_version, created_at, updated_at

Zone            gains  ventilator_id, hot_water_system_id,
                       heat_pump_ids[], heater_ids[], pump_ids[], fan_ids[]
```

Assignment is stored on the Zone as ids. [spaces](../spaces/PRD.md) already fixed that
equipment belongs to the Zone and a Space inherits it. Appliances are the exception, see
family 7.

### Behaviors

- The Equipment subtab under the primary Systems tab has a family selector. Each family is an inventory table with inline edit, Add,
  Duplicate and Delete with a usage warning.
- A "Serves" column lists Zones as chips. Editing it opens a Zone picker. The Zone's row in the
  Overview tree shows the same links from the other side.
- Delete of an item in use asks, then clears the ids from the Zones. One Undo step.
- An item that serves no Zone is a warning and is not exported, since honeybee-ph has nowhere
  to put it.
- Registers Colour-by modes `By ventilator` and `By hot water system`, and regroups the Spaces
  airflow balance view by ventilator, as the spaces packet recorded.

### Export

honeybee-ph attaches mechanical equipment per Room through `room.properties.ph_hvac`:
one ventilation system, one hot water system, and sets of heating systems, heat pump systems,
exhaust devices, supportive devices and renewable devices. A PH-Composer Zone is one Room,
so the Zone's ids map straight onto those slots. An item serving three Zones is the same
honeybee-ph object, same identifier, set on three Rooms. Whether PHX then writes one METr
device or three is part of the round trip proof in STATUS.

Field units below are read from the honeybee-ph class docstrings where they state one.
Fields with no stated unit are confirmed at the family's interview.

## Family 1: Ventilators

`Ventilator`: `display_name`, `quantity`, `sensible_heat_recovery`, `latent_heat_recovery`,
`electric_efficiency` (Wh/m³, default 0.55), `frost_protection_reqd`,
`temperature_below_defrost_used` (°C, default -5), `in_conditioned_space`, and two optional
fields for subsoil heat exchange and preheated intake temperature. It sits inside a
`PhVentilationSystem` with `sys_type` (default 1, balanced with heat recovery) and the two duct
lists. A Room holds one ventilation system.

PH-Composer records one Ventilator and builds the system around it at export. The user never
sees a separate "system" record.

Open for this family's interview: the one-ventilator-per-Zone limit and what a Zone with two
units does; whether `sys_type` values other than 1 are offered.

## Family 2: Hot water, tanks and heaters

`PhHotWaterSystem`: four tank slots (`tank_1`, `tank_2`, `tank_buffer`, `tank_solar`), a set of
heaters, the distribution trunks, the recirculation elements and `number_tap_points`.

`PhHvacHotWaterTank`: `tank_type`, `quantity`, `in_conditioned_space`, `solar_connection`,
`solar_losses`, `storage_loss_rate`, `storage_capacity` (litres, default 300),
`standby_losses` (W/K, default 4.0), `standby_fraction`, `room_temp`, `water_temp`.

Heaters share `percent_coverage` and `in_conditioned_space`. Variants: Electric; Boiler (fuel,
condensing, efficiencies, return and boiler temperatures); Wood boiler; District; Heat pump
monthly (two COPs at two ambient temperatures); Heat pump annual (`total_system_perf_ratio`);
Heat pump inside (`annual_energy_factor`).

PH-Composer records a Hot Water System with tanks and heaters as child rows. The piping
packet links its Piping groups to it.

Open: which heater variants ship first. Recommendation: Electric and the three heat pump
variants. Boilers and district are rare on Phius projects and can follow.

## Family 3: Heat pumps

`PhHeatPumpSystem` with `percent_coverage` and a `cooling_params` block. Variants: Annual
(`total_system_perf_ratio`), Rated monthly (`COP_1` at `ambient_temp_1` -8.333 °C, `COP_2` at
`ambient_temp_2` 8.333 °C, which are 17 °F and 47 °F), and Combined. Cooling parameters hold
four sub-blocks, each with a `used` flag: Ventilation, Recirculation, Dehumidification, Panel.
Recirculation carries `capacity`, `min_coil_temp`, `flow_rate_m3_hr`, `flow_rate_variable`,
`single_speed` and an annual COP.

Open: whether the editor shows all four cooling sub-blocks or only Recirculation, which is the
mini-split case and nearly every project.

## Family 4: Electric heaters

`PhHeatingDirectElectric`: `percent_coverage` and a name. The smallest family. The same
`PhHeatingSystem` base has Fossil boiler, Wood boiler and District variants, which Ed's list
leaves out. See Q7.

## Family 5: Pumps

`PhSupportiveDevice`: `device_type` (4 heat circulation pump, 6 DHW circulation pump, 7 DHW
storage load pump, 10 other), `quantity`, `in_conditioned_space`, `norm_energy_demand_W`,
`annual_period_operation_khrs` (default 8.760), `ihg_utilization_factor`, `ihg_usage_profile`.

## Family 6: Fans

honeybee-ph has no "Fan" class. Two carriers fit. Exhaust ventilators
(`ExhaustVentKitchenHood`, `ExhaustVentDryer`, `ExhaustVentUserDefined`) hold `quantity`,
`annual_runtime_minutes` and `exhaust_flow_rate_m3s`, and they affect the ventilation balance.
A supportive device of type 10 holds watts and hours only. See Q6.

## Family 7: Appliances

`PhEquipment` subclasses in `honeybee_energy_ph/load/ph_equipment.py`: dishwasher, clothes
washer, clothes dryer, refrigerator, freezer, fridge-freezer, cooktop, Phius MEL, Phius interior,
exterior and garage lighting, three custom annual entries, and three elevator types. Shared
fields: `quantity`, `in_conditioned_space`, `reference_quantity`, `reference_energy_norm`,
`energy_demand` (kWh), `energy_demand_per_use`, `comment`.

These are a Room load, held on the Room's electric equipment properties, not on `ph_hvac`.
honeybee-ph also ships Phius residential and multifamily default sets
(`phius_residential.py`, `phius_mf.py`), which compute the standard appliance list from
bedroom and dwelling counts.

Open: whether appliances are authored per item, or the user picks "Phius residential defaults"
for a Zone and edits only the exceptions. Recommendation: the default set first. It is what
most Phius models use and needs dwelling count and bedroom count per Zone, nothing else.

## Decisions for the interview

Shared shape first. Each family gets its own round later.

| # | Question | Recommendation |
| --- | --- | --- |
| Q1 | One packet with seven family phases, or seven packets? | One packet, one PRD section and one phase per family. The shape is shared and the families are small |
| Q2 | Family order? | Ventilators, hot water, heat pumps, electric heaters, pumps, appliances, fans |
| Q3 | Is assignment stored on the Zone as ids? | Yes. It matches honeybee-ph's per-Room slots and the spaces decision |
| Q4 | A product definition reused with different installed quantities: two records, or a type and instances? | One record with a `quantity`. No type and instance split. Duplicate covers the rest. Q1 of the predecessor asked this and the honeybee-ph classes answer it |
| Q5 | Is equipment placed in the model as geometry? | No. Records only. A Ventilator has no position. Ducts and pipes give the lengths that matter |
| Q6 | Fans: exhaust ventilators, supportive devices, or both under one tab? | Exhaust ventilators under "Fans", since kitchen hoods and dryers are what Phius asks for. Anything else is a Pump-tab "Other" device |
| Q7 | Boilers, wood boilers, district heat and PV are in honeybee-ph and not on the list. In or out? | Out for MVP, recorded as later. PV waits for the climate and site packet |
| Q8 | Are equipment items a library kind? | Later. The libraries interview named Ventilators and Heat Pumps as likely future kinds |
| Q9 | One Equipment tab with sub-tabs, or the predecessor's reserved "HVAC" tab plus others? | Confirmed in D4: one Systems primary tab, with Equipment, ERV ducting and Hot-water piping as peer subtabs. Equipment owns the seven family views |

## Non-goals

No data sheet storage beyond links. No specification status. No sizing or load calculation. No
schedules. No equipment geometry.

## Acceptance shape

Per family, on a synthetic two-Zone model: create two items, serve one Zone with one and both
Zones with the other, export, and find each object once in HBJSON on the right Rooms and once in
METr JSON with the right values. Delete an item in use and Undo it. Save and reopen. The
ventilator family also closes B4's proof: two Zones, two ventilators, both distinct in METr.

## Prior art and evidence

- Predecessor `planning/phases/Q1_equipment.md`, `B4_ventilation-units.md`.
- honeybee-ph `honeybee_phhvac/`: `ventilation.py`, `heat_pumps.py`, `heating.py`,
  `hot_water_devices.py`, `hot_water_system.py`, `supportive_device.py`,
  `properties/room.py`.
- honeybee-ph `honeybee_energy_ph/load/`: `ph_equipment.py`, `phius_residential.py`,
  `phius_mf.py`.
- PHX `model/enums/hvac.py`, `to_METr_JSON/metr_schemas.py`.
