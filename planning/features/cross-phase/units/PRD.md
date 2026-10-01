# Units: SI and IP display

DATE: 2026-09-18
STATUS: Scoped. Phase 0 inheritance and scope confirmed; later quantity choices remain with their owners.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (no remote)

## Problem

Phius consultants in the United States read and enter most values in IP. METr, honeybee-ph and
every PH-Composer record are SI. The predecessor solved this once, across every screen, and
the solution has no designPH dependency. PH-Composer should not redo the interview or the
code. It should port both and add the quantities that piping, ducting, equipment and climate bring.

## The rule this packet serves

Ed set it during the libraries interview: all persistence, all libraries, all wire formats and
all real work are SI, with the unit in the key name (`thickness_mm`, `u_w_m2k`). IP is a display
and entry conversion in the panel and nowhere else. It is recorded in
[`context/TECH_STACK.md`](../../../../context/TECH_STACK.md) under "Display units".

## Port disposition

Sizes are from the predecessor at `f358ebf`.

| Predecessor part | LOC | Disposition | Note |
| --- | --- | --- | --- |
| `core/units.rb` | 90 | Port | Host conversion between SketchUp inches and SI geometry |
| `html/units.js` | 226 | Port | The one parser and formatter. No second parser, no second unit table |
| `html/length_expression.js` | n/a | Port dependency | Required parser helper at the frozen source commit; include alongside the six originally listed unit modules |
| `html/unit_tables.js` | 163 | Adapt | Quantity registry. Gains the rows in "New quantities" |
| `html/unit_numbers.js` | 82 | Port | Regional decimal and grouping formats |
| `html/unit_field.js` | 139 | Adapt | The unit field control. Takes on follow-up U1-F3 |
| `html/unit_preferences.js` | 149 | Port | Global preference and per-builder format memory |
| `Assemblies::MessageParts` pattern | n/a | Port | Ruby sends canonical values in message parts. The panel formats them |
| Unit tests and numerical vectors | n/a | Port | `unit_field_test.js` and the known-value vectors for U, R, conductivity, psi, H |
| Plan contracts C1 to C8 | n/a | Port | From the predecessor's `planning/archive/units/PLAN.md`. Copied into this packet's PLAN.md when written |
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

### Carried from the predecessor

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
| Ratios, fractions, counts, angles | unchanged | unchanged |

### New quantities

The predecessor left these to their owning features, which it never built. The owning packet
confirms each row. The IP column is a proposal until then.

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

| ID | Item | Proposal |
| --- | --- | --- |
| U1-F1 | A switch on a 300-Space table repaints every cell, a median 513 ms | Spaces owns this optimization if measurements justify it; outside Phase 0 |
| U1-F3 | Assembly Builder thickness drafts keep their own draft logic outside the unit field | Assemblies owns moving these drafts onto the unit field; outside Phase 0 |
| U1-F4 | The window editor form branches between a plain input and a unit field | Window Types owns the dimension-form cleanup; outside Phase 0 |

## Decisions for the interview

| # | Question | Recommendation |
| --- | --- | --- |
| Q1 | Carry all fifteen inherited decisions without reopening them? | Confirmed by Ed: carry I1 through I15 unchanged |
| Q2 | Pipe diameter in IP: a converted decimal, or the nominal size list METr uses? | The nominal list in both systems, since METr snaps to it on export. Confirm with the piping packet |
| Q3 | Power and energy in IP: W and kWh, or Btu-based? | W and kWh. US equipment data sheets and Phius targets both use them. Capacity alone shows as kBtu/h |
| Q4 | Do the three follow-ups ride with the transplant or wait? | Confirmed by Ed: F3 with Assemblies, F4 with Window Types, F1 with Spaces if measurements justify it |

Ed confirmed the Phase 0 split on 2026-09-18. Phase 0 owns the shared parser, quantity registry,
unit-field control and preferences, with applicable inherited tests. New equipment, piping,
ducting and climate quantities remain with their owning features. Q2 and Q3 remain proposals for
those feature interviews and do not block the foundation. No feature editor lands in Phase 0.

## Non-goals

No change to SketchUp's model units. No IP values in any file. No unit conversion in Ruby for
display. No general physical-quantity algebra.

## Acceptance shape

The predecessor's fifteen acceptance checks, A1 to A15 in `planning/archive/units/ACCEPTANCE.md`,
rerun on the transplanted code with the designPH-specific parts of A14 removed. Each new quantity
adds one known-value vector.

Map these checks to their delivery owners: Phase 0 verifies shared infrastructure using synthetic
controls; feature-screen checks run with the corresponding feature. Do not claim all fifteen
checks passed when only the foundation subset has run.

## Prior art and evidence

- Predecessor `planning/phases/U1_units.md`: the contract and the interview log.
- Predecessor `planning/archive/units/`: PLAN, AUDIT, COVERAGE, ACCEPTANCE, HOST_MEASUREMENTS.
- Predecessor `planning/bugs/u1-units-follow-ups.md`.
- PH-Navigator web's units library, the source of the quantity pairs. It is a private repository
  and is named here as prior art only.
