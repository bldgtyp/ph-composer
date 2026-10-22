# Phase 4, mechanical: findings from source, and the decisions that follow

DATE: 2026-10-21
STATUS: Scoped. Part 1 is findings read from source on `main` at `420c783a` and the honeybee-ph and PHX checkouts on 2026-10-21. Part 2 was answered by Ed on 2026-10-21, every row as recommended; see "Ed's answers". The interviews (Q1 to Q12, V1 to V6, hot water H1 to H7) are answered and live in the equipment PRD.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

The [equipment PRD](equipment/PRD.md) is the interview record: its decisions table (Q1 to Q12),
family 1 (V1 to V6) and family 2 (hot water H1 to H7) hold Ed's answers of 2026-10-21. This file
does not restate them. Part 1 lists what the code and the stack say beyond the PRD; Part 2 lists
the choices those facts force at planning, each with a recommendation. The bindings that follow
are in [CONTRACTS.md](CONTRACTS.md); they change when an answer differs.

Decisions are D4-01 to D4-12, findings F1 to F14. Stages are P4-01 to P4-15, tracked in
[STATUS.md](STATUS.md). A reference to a Spaces or thermal-bridge decision always says which.

Paths are relative to `src/ph_composer/` unless stated. "Read from source" means the file was read,
not that the consequence was reproduced on a host or in a test.

## Part 1: findings

### Code on `main`

| # | Finding | Consequence |
| --- | --- | --- |
| F1 | `reference_identity` refuses an entry whose `record["id"]` is not a non-empty String (`core/records/reference_resolution.rb`, 3b F6) | The Serves record carries an `eqa_` id (CONTRACTS section 2) |
| F2 | The Zone reference target declares `locate:` (`features/zones/declarations/zone.rb:13`, `Occurrences.locate_zone`), and `request.locate(kind, reference)` resolves a writable entity with the owner's refusals (`shell/handler_request.rb:101`) | Serves resolves the Zone Group through Zones' own locate; no new Zones read |
| F3 | `transition_contributor` on `ph_composer.zones.occurrence_independent` gives a child its own restorable step in the Zone copy's proposal; `tests/support/zone_child_fixture.rb` is a second child built from public contracts alone, re-issuing tag ids by allocator | The Zone-copy contributor is the fixture's shape with one record per Zone (D4-04) |
| F4 | `Assembly::Operations.delete` calls `request.retarget_references(kind, from:, to:)` for a replacement and `propose_delete(..., reference_plan:)`; an explicit null clears references through referrer handlers (`context/CONTRACTS.md`, "Geometry records and occurrence references") | Delete in use per slot follows it (D4-05) |
| F5 | `assembly.py` `_attach` groups a section's objects by `attachment.key(translated)`, one host per object, and attaches each host's objects in one call | A shared item needs one object per served Room, or a new attachment shape (D4-01) |
| F6 | `Section.required_for_export` defaults True; Spaces is required (D3a-9); the thermal-bridge section will be the first optional one (D3b-20, H18) | Equipment chooses (D4-06) |
| F7 | `stack.PACKAGES` lists `honeybee_ph` and `honeybee_energy_ph` and not `honeybee_phhvac`; `load` raises `ValueError` for an unlisted top-level package; the pinned wheel ships `honeybee_phhvac` | One line in P4-01 (CONTRACTS A1) |
| F8 | `html/index.html` holds a disabled "Systems" button beside a disabled "Thermal Bridges" button, each with `data-tooltip="Planned"`; a `data-pane` is created by `panel.section` when absent, the tab button is not | P4-05 edits the composition root once (A2); 3b's P3b-05 edits the sibling button |
| F9 | `core/units.rb` has `airflow`, `volume`, `heat_loss_rate`, `conductivity`, `length` and no electric-efficiency, litre or temperature quantity; the panel registry has 18 quantities (units STATUS) | A3 adds what V4 and the tank fields need |
| F10 | Spaces' `ph_composer.spaces.all` `zones` rows carry `airflows` (null while any Space inherits), `inheriting_count` and `imbalanced`, and `Spaces::Metrics.imbalanced?` is the 10 percent rule | The balance by ventilator sums those rows per served Zone and reuses the rule (D4-10) |
| F11 | `features/zones/colour_modes.rb` registers `entity_kind: "zone"` modes whose projection walks `entries(read.model)` | `by_ventilator` takes that shape; P4-01 confirms the projection can key by Zone id (CONTRACTS section 7, question 3) |

### honeybee-ph 1.33.65 and PHX

| # | Finding | Consequence |
| --- | --- | --- |
| F12 | `RoomPhHvacProperties` has `set_ventilation_system`, `set_hot_water_system`, `add_heating_system`, `add_heat_pump_system`, `add_supportive_device`, `add_exhaust_vent_device`, `add_renewable_device`; one ventilation and one hot water system per Room | The one-per-Zone rules (V1, hot water H6) match the carrier |
| F13 | PHX keys ventilation systems, tanks and heaters by identity across Rooms (`create_variant.py`, `get_mech_device_by_key`, `device_in_collections`); requires a unit on every ventilation system; takes tap points, recirculation temperature and hours once per variant and falls back to 60 °C and 24 h when systems disagree; skips a Room with no system; reads exhaust ventilators and supportive devices through a Room's Spaces | D4-01's shared-identifier rule is what PHX dedups on; `equipment.recirc_disagrees` (CONTRACTS section 6); the Spaces-walk consequence is metr-export's |
| F14 | `PhHotWaterSystem` has four typed tank slots (`tank_1`, `tank_2`, `tank_buffer`, `tank_solar`) and no calculation-method field; PHX's `PhxRecirculationParameters.calc_method` is written to WUFI and METr but never set from HBJSON ([honeybee_ph#135](https://github.com/PH-Tools/honeybee_ph/issues/135)) | Tank slotting needs a rule (D4-07); the method field waits (D4-12) |

## Part 2: decisions for Ed

Each row names the stages it blocks. A stage does not start until every row it names has an
answer. Kind: Code, UI or Scope.

| ID | Kind | Question | Recommendation | Blocks |
| --- | --- | --- | --- | --- |
| D4-01 | Code | An item serves several Zones and a section attaches one host per object (F5). One translated object per (item, Zone) pair sharing the item's identifier, or a new attachment shape? | One object per pair. Each `PhVentilationSystem` and `PhHotWaterSystem` is built per served Room with identifiers derived from the item id, so honeybee-ph holds equal objects on each Room and PHX's key dedup (F13) sees one device. The assembly is unchanged; `conformance` checks the identifiers agree across Rooms. The alternative, a multi-host attachment, changes `assembly.py` for one consumer | P4-04, P4-06 |
| D4-02 | Code | One feature for seven families, or one per family? (Q1 said one packet) | One feature, `ph_composer.equipment`, with a folder per family and one `serves/` folder. One composition-root entry, one codes noun, one Serves record with a slot per family. A layer test keeps family folders from naming Zones. Seven features would need seven Serves records or a shared one none owns | P4-02 |
| D4-03 | Code | The Serves record's shape (Q3) | One dictionary `ph_composer.equipment_serves` on the Zone Group with one slot per family: single references for Ventilator and Hot Water System, arrays for the rest, each a core `Records::Reference`; an `eqa_` id (F1); removed when every slot empties. A record per (Zone, item) pair would need an id per pair and a walk to answer "what serves this Zone" | P4-03 |
| D4-04 | Code | What does a copied Zone keep? (Q3's answer: what serves it) | Everything: the copy's Serves record is kept verbatim except its `eqa_` id, which the transition contributor re-issues in the Zone's own proposal (F3), so two Zones never share an `entity_id`. A shared Ventilator serving both copies is a legitimate model (one unit, two apartments) and the user reassigns when it is not. Dropping the record on copy would lose the multifamily case Q4 named | P4-03 |
| D4-05 | Code | Delete in use, per slot (F4) | Without a replacement: refuse while any Serves slot names the item, listing the Zones. With `replacement_id`: rewrite that slot on every Serves record. With explicit null: clear the slot, removing a record that empties. One proposal, one Undo step, as Assemblies | P4-02, P4-03 |
| D4-06 | Code | Are the equipment sections required for export? (F6) | Yes, `required_for_export = True`, as Spaces (D3a-9). Ruby filters what is not exportable before translation with its own findings (an unserved item, an omitted Zone), so a translation or attach failure is a real fault. The thermal-bridge section's optionality (D3b-20) rests on runs being derived; equipment records are authored | P4-04, P4-06 |
| D4-07 | Code | Hot water H3 chose a free tank list slotted at export. By list order alone, or by a role? | By role. Each tank carries `role`: `storage`, `buffer` or `solar`. Storage tanks fill `tank_1` then `tank_2` in list order; the buffer tank fills `tank_buffer`, the solar tank `tank_solar`. A third storage tank, or a second buffer or solar, is `equipment.tank_unslotted`, omitted with a non-blocking finding. honeybee-ph's slots are typed (F14), so pure order would put a buffer tank in `tank_2` silently | P4-06 |
| D4-08 | UI | The Systems tab's layout (Q9, D4 of the cross-cutting register) | Enable the reserved tab (F8). One subtabs row, Equipment, ERV ducting, Hot-water piping, each listed only once built, as Zone views are. Inside Equipment, a family selector as a select in the page header, one inventory table beneath it; not a second subtabs row. The UI polish review in P4-05 may revise | P4-05 |
| D4-09 | Code | Piping and ducting objects belong inside equipment's translated systems, and a section attaches only to `MODEL`, `ROOM` or `FACE` | The later section `requires` the equipment section and, in `translate`, adds its elements to the required object it was handed (the coordinator orders sections by requirements, and objects are shared references); the equipment section attaches afterwards. No new attachment host. Bound now so P4-04's section keeps its objects mutable and keyed by (item, Zone); confirmed when piping is planned | P4-04 (shape), P4-13, P4-14 |
| D4-10 | Code | Where is the balance by ventilator computed? (Q11, F10) | In a pure Ruby function in `serves/balance.rb` over Spaces' Zone rows and the Serves rows, exposed on `ventilators.all` and the snapshot section. The feature therefore requires `ph_composer.spaces`; its family folders never read it. The alternative, computing it in the panel from two sections, puts a rule in JavaScript | P4-05 |
| D4-11 | Code | Which unit rows does Phase 4 add? (F9, V4) | `electric_efficiency` (Wh/m³ stored, W/cfm in IP), `volume_l` (litres stored, US gallons in IP), and `temperature` (°C stored, °F in IP) unless the panel registry already has it; W, kWh and kBtu/h wait for the families that show them. Recorded in the units packet as its Q3 outcome | P4-05, P4-07 |
| D4-12 | Code | Hot water H5: store the piping calculation method now. How does it sit until the pinned wheel carries the field? | A nullable field on the Hot Water System record, shown in the view, written to the honeybee-ph object only when the loaded class accepts it (checked at translate), otherwise `equipment.method_not_exported`, non-blocking. Not passed as `user_data`, which nothing standard reads. When the wheel is bumped the check becomes a no-op and the finding disappears | P4-06 |

## Ed's answers

Ed answered D4-01 on its own and then accepted every remaining recommendation on 2026-10-21.
A row here supersedes the recommendation in Part 2; none differs.

| ID | Answer | Date |
| --- | --- | --- |
| D4-01 | As recommended: One translated object per (item, served Zone) pair with equal identifiers | 2026-10-21 |
| D4-02 | As recommended: One feature, `ph_composer.equipment` | 2026-10-21 |
| D4-03 | As recommended: One `ph_composer.equipment_serves` dictionary per Zone Group, a slot per family, `eqa_` id | 2026-10-21 |
| D4-04 | As recommended: A copied Zone keeps its Serves record; only the id is re-issued | 2026-10-21 |
| D4-05 | As recommended: Refuse in use, rewrite with a replacement, clear with null | 2026-10-21 |
| D4-06 | As recommended: `required_for_export = True` | 2026-10-21 |
| D4-07 | As recommended: Slot by role: storage to tank 1 and 2 in order, buffer, solar; the rest unslotted | 2026-10-21 |
| D4-08 | As recommended: Enable the reserved tab; one subtabs row; a family select in the page header | 2026-10-21 |
| D4-09 | As recommended: The later section requires the equipment section and adds to its object before attach | 2026-10-21 |
| D4-10 | As recommended: A pure Ruby read in `serves/balance.rb` over Spaces' Zone rows; the feature requires Spaces | 2026-10-21 |
| D4-11 | As recommended: `electric_efficiency`, `volume_l`, `temperature` | 2026-10-21 |
| D4-12 | As recommended: A nullable record field, written only when the loaded class accepts it | 2026-10-21 |

## Ledger

| Date | Event |
| --- | --- |
| 2026-10-21 | Drafted from `420c783a` and the three interviews of the same day: fourteen findings, twelve decisions. None answered. |
| 2026-10-21 | Ed answered D4-01 to D4-12, all as recommended. The bindings in CONTRACTS stand as drafted. |
