# Units: SI and IP display

DATE: 2026-10-07
STATUS: In progress. Shared infrastructure and Assembly/Window follow-ups merged; remaining feature quantities and Spaces work planned.
AUTHOR: Ed May, BLDGTYP, with Codex
ISSUE: none (local planning draft)

## Problem

Phius consultants in the United States read and enter most values in IP. METr, honeybee-ph and
every PH-Composer record are SI. The predecessor solved this once, across every screen, and
the solution has no designPH dependency. PH-Composer should not redo the interview or the
code. The shared port and the Assembly/Window editor follow-ups are now implemented and merged.
The remaining extension of this contract belongs to Spaces, piping, ducting, equipment and
climate. [STATUS.md](STATUS.md) records the audited implementation, evidence and items left to do.

## The rule this packet serves

Ed set it during the libraries interview: all persistence, all libraries, all wire formats and
all real work are SI, with the unit in the key name (`thickness_mm`, `u_w_m2k`). IP is a display
and entry conversion in the panel and nowhere else. It is recorded in
[`context/TECH_STACK.md`](../../../../context/TECH_STACK.md) under "Display units".

## Historical port disposition

Sizes and proposed dispositions below describe the predecessor at `f358ebf` and the original
2026-09-18 scope. They are not an outstanding transplant checklist. The shared port landed in
Phase 0; Phase 1/2 added table editing and feature screens. See STATUS for current source paths.

| Predecessor part | LOC | Disposition | Note |
| --- | --- | --- | --- |
| `core/units.rb` | 90 | Port | Host conversion between SketchUp inches and SI geometry |
| `html/units.js` | 226 | Port | The one parser and formatter. No second parser, no second unit table |
| `html/length_expression.js` | n/a | Port dependency | Required parser helper at the frozen source commit; include alongside the six originally listed unit modules |
| `html/unit_tables.js` | 163 | Adapt | Quantity registry. Remaining feature rows require owner confirmation; existing primitives are reused |
| `html/unit_numbers.js` | 82 | Port | Regional decimal and grouping formats |
| `html/unit_field.js` | 139 | Adapt | Shared unit field delivered; Assembly editor adopted it for U1-F3 in Phase 2 |
| `html/unit_preferences.js` | 149 | Port | Global preference and per-builder format memory |
| `Assemblies::MessageParts` pattern | n/a | Port | Ruby sends canonical values in message parts. The panel formats them |
| Unit tests and numerical vectors | n/a | Port | `unit_field_test.js` and the known-value vectors for U, R, conductivity, psi, H |
| Plan contracts C1 to C8 | n/a | Port | From the predecessor's `planning/archive/units/PLAN.md`; implemented durable display rules now live in `context/TECH_STACK.md`. This packet has no PLAN.md |
| designPH and foreign-source unit adapters | n/a | Drop | No designPH data is read |
| Follow-up U1-F2, host coverage for designPH Window reviews | n/a | Drop | The reviews it covers no longer exist |
| Follow-up U1-F5, column insertion with Psi-install assignments | n/a | Drop here | A window-types behavior, not a units one |

## Inherited contract

These are the predecessor's confirmed decisions. They are carried as settled. The round numbers
refer to the interview log in the predecessor's `U1_units.md`.

| # | Decision | Round |
| --- | --- | --- |
| I1 | Records hold explicit SI field units. Millimetre assembly fields and metre window fields both stay. SketchUp geometry stays in inches and converts at the host adapter. The switch never scales geometry or touches SketchUp's model units | 2 |
| I2 | The preference is a local user preference shared by every panel and open Model, restored after restart, stored with `Sketchup.write_default`. It never dirties the SKP or adds an Undo step | 3 |
| I3 | First-use default is SI | 4 |
| I4 | Both builders have a dimension format selector limited to the active system: mm, cm and m in SI; decimal inches, decimal feet, feet and inches, and fractional inches in IP | 5 |
| I5 | Builder defaults are mm in SI and decimal inches in IP | 6, 7, 8 |
| I6 | Each builder remembers its SI format and its IP format separately, across switches and restarts | 9 |
| I7 | A switch during an unfinished edit keeps the draft text and its starting unit until commit or Escape. Everything else repaints at once | 10 |
| I8 | Conductivity shows as W/(m K) and Btu/(h ft °F). R per inch is a different display and does not replace it | 11 |
| I9 | Length fields accept mixed-unit addition and subtraction. `1 ft + 2 in` is 355.6 mm | 12 |
| I10 | Human input and display follow the computer's regional decimal and grouping convention. Stored numbers and JSON never do | 13, 14 |
| I11 | Scientific notation is accepted, with an optional unit suffix | 15 |
| I12 | A length may be multiplied or divided by a plain number. `2 ft * 3 ft` is refused in a length field | 16 |
| I13 | A bare additive term takes the field's starting unit. A suffix binds to its own value or parenthesised group. In a mm field `100 + 2 in` is 150.8 mm | 17 |
| I14 | A human-readable report captures the active system when it is generated and keeps it. HBJSON and library files stay SI | 18 |
| I15 | Other quantities take PH-Navigator web's SI and IP pairs where the physical quantity matches. A quantity with no match goes back to its owning feature | 19 |

### Editing rules carried with them

- A unit-bearing input is a text input, so suffixes and fractions can be pasted.
- An unsuffixed entry means the unit the field showed when editing began.
- Presentation is one-way until the user edits. Focus, blur, repaint and a switch never write a
  rounded display string back to a record.
- Sorting, equality, limits, thermal calculations and fingerprints use stored values.
- An error sits beside the field, sets `aria-invalid` and keeps the typed text. The messages
  distinguish an unsupported unit, a wrong quantity such as `kg` in a length field, a malformed
  number and a value outside the field's range.
- The parser consumes the whole string, checks for finite results and never uses `eval`.

### Parsing table, carried

| Input | Behavior |
| --- | --- |
| Bare decimal, including `.5` | The field's displayed unit at edit start |
| `0.5 ft`, `152.4 mm`, `6 in`, `0.1524 m` | The same length, accepted without a dialog |
| `1/2 in`, `2 1/2 in`, `2-1/2"`, `1' 2"`, `1 ft 2 in` | Architectural input, with prime and quote characters normalised |
| `100 + 50`, `(1200 - 50) / 4` | Bounded length arithmetic |
| `2 kg` in a length field | Wrong quantity error. Text and stored value kept |
| Unknown suffix, incomplete expression, division by zero, NaN, Infinity | Refused without a write |
| A thermal, material or airflow suffix | Accepted only when registered for the field's quantity |

## Quantity table

### Carried from the predecessor and implemented in the panel

The current panel registry has 18 quantity ids. Ruby carries ten report quantities:
length, length_mm, area, volume, u_value, thermal_resistance, conductivity, linear_psi,
heat_loss_rate and airflow. The standalone volume/airflow groundwork is merged through
PR #84; P3a-01 reuses it, with feature integration and acceptance still owned by Spaces. The
inherited unchanged-display rule for counts/angles adds no named quantity registry rows.

| Quantity | SI | IP |
| --- | --- | --- |
| Length | mm or m by field | in or ft by field |
| Area, volume | m², m³ | ft², ft³ |
| U-value | W/(m² K) | Btu/(h ft² °F) |
| R-value | m² K/W | h ft² °F/Btu |
| Conductivity | W/(m K) | Btu/(h ft °F) |
| Psi-value | W/(m K) | Btu/(h ft °F) |
| Heat-transfer coefficient | W/K | Btu/(h °F) |
| Density, specific heat | kg/m³, J/(kg K) | lb/ft³, Btu/(lb °F) |
| Airflow | m³/h | cfm |
| Temperature, temperature difference | °C, K | °F, °F difference |
| Air permeance | L/(s m²) at 75 Pa | cfm/ft² at 1.57 psf |
| Equivalent air-layer thickness, vapor diffusion resistance | sd in m, μ | perm, perm-in (reciprocal conversions) |
| Ratios, fractions, counts, angles | unchanged | unchanged |

### New quantities

The predecessor left these to their owning features, which it never built. None of these
feature integrations is implemented in PH-Composer yet. The owning packet confirms each row;
the IP column is a proposal until then. Length, airflow, heat-loss rate, temperature and
unitless fields reuse existing primitives where they match. A tank stored in litres cannot
use the existing m³/ft³ volume pair unchanged. Capacity, ventilator efficiency and radiation
also need new conversions if the proposals are accepted. Add descriptors and known-value
tests for reused quantities as well as for genuinely new rows.

| Quantity | Owning packet | Stored as | Proposed IP display |
| --- | --- | --- | --- |
| Pipe diameter | hot-water-piping | `diameter_mm` | Nominal inches. METr stores an inch-size enum, so the display may be the enum label and not a converted number |
| Pipe and duct insulation thickness | piping, ducting | `insulation_thickness_mm` | in |
| Run length | thermal-bridges, piping, ducting | measured, m | ft |
| Duct diameter, width, height | erv-ducting | `_mm` | in |
| Tank volume | equipment | `storage_capacity_l` | gal (US) |
| Tank standby loss | equipment | `standby_losses_w_k` | Btu/(h °F) |
| Electrical power | equipment | `_w` | W in both systems |
| Annual energy | equipment | `_kwh` | kWh in both systems |
| Heating and cooling capacity | equipment | `_kw` | kBtu/h |
| Ventilator electric efficiency | equipment | `electric_efficiency_wh_m3` | W/cfm |
| Exhaust airflow | equipment | honeybee-ph holds `exhaust_flow_rate_m3s`. Records hold `_m3h` and convert at export | cfm |
| COP, recovery efficiencies, coverage fractions | equipment | unitless | unchanged |
| Monthly radiation | climate-data | `_kwh_m2` | kBtu/ft² |
| Peak-load radiation | climate-data | `_w_m2` | Btu/(h ft²) |
| Elevation | climate-data | `_m` | ft |

## Follow-ups carried from the predecessor

| ID | Item | Current disposition, audited 2026-10-07 |
| --- | --- | --- |
| U1-F1 | The predecessor measured a median 513 ms on its 300-Space table | Open: P3a-07 measures the new table and decides whether to optimize. No PH-Composer measurement or numeric refresh budget exists yet |
| U1-F3 | Assembly Builder thickness drafts kept their own draft logic outside the unit field | Delivered in P2-04, merged through PR #15. Current thickness/width editors use `UnitField`; owner logic retains pending-operation and stale-value guards |
| U1-F4 | The predecessor window editor branched between a plain input and a unit field | Delivered in P2-11, merged through PR #15. Current numeric dimension bubbles share `editQuantity`/`UnitField` |

The other inherited deferral, table editing, is partially closed: shared cell drafts and
resizing exist. D3a-11 (answered 2026-10-15) gives the Spaces view no layout store of its own;
persisted column order and widths, if wanted, are a shared-table change.

## Decision disposition

| # | Question | Recommendation |
| --- | --- | --- |
| Q1 | Carry all fifteen inherited decisions without reopening them? | Confirmed by Ed: carry I1 through I15 unchanged |
| Q2 | Pipe diameter in IP: a converted decimal, or the nominal size list METr uses? | The nominal list in both systems, since METr snaps to it on export. Confirm with the piping packet |
| Q3 | Power and energy in IP: W and kWh, or Btu-based? | W and kWh. US equipment data sheets and Phius targets both use them. Capacity alone shows as kBtu/h |
| Q4 | Do the three follow-ups ride with the transplant or wait? | Confirmed by Ed: F3 with Assemblies, F4 with Window Types, F1 with Spaces if measurements justify it |

Ed confirmed the Phase 0 split on 2026-09-18. Phase 0 delivered the shared parser, quantity
registry, unit-field control and preferences, with applicable inherited tests. Phase 2 delivered
the Assembly/Window editor follow-ups. New equipment, piping, ducting and climate quantities
remain with their owning features. Q2 and Q3 remain proposals for those feature interviews.
The existing foundation does not need another interview or port.

## Non-goals

No change to SketchUp's model units. No IP authoring quantities in records, library files,
wire formats or HBJSON; human-readable reports may show IP. Ruby sends canonical panel values; Ruby report
formatting converts them through `core/units.rb`. No general physical-quantity algebra.

## Acceptance shape

The predecessor's fifteen acceptance checks, A1 to A15 in `planning/archive/units/ACCEPTANCE.md`,
are allocated to PH-Composer's delivery owners with the designPH-specific parts of A14 removed.
Each new quantity adds one known-value vector; each new feature verifies its actual field and
export/report boundary even when it reuses an existing quantity.

Phase 0 verified shared infrastructure using synthetic controls; Phase 2 supplies accepted
Assembly/Window evidence. Feature-screen checks run with the corresponding feature. Reuse
unchanged passing evidence with its provenance instead of repeating closed gates. Do not claim
all fifteen checks passed across future screens, or use the predecessor's timing as a current
measurement. STATUS records current focused checks and the remaining owner gates.

## Prior art and evidence

- Predecessor `planning/phases/U1_units.md`: the contract and the interview log.
- Predecessor `planning/archive/units/`: PLAN, AUDIT, COVERAGE, ACCEPTANCE, HOST_MEASUREMENTS.
- Predecessor `planning/bugs/u1-units-follow-ups.md`.
- PH-Navigator web's units library, the source of the quantity pairs. It is a private repository
  and is named here as prior art only.
