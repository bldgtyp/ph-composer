# R04: finding and outcome codes are inconsistent across the Phase 2 features

DATE: 2026-10-01
STATUS: Merged to main 2026-10-02 (PR #19). Host acceptance of the changed screens not run (none named below)
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft; review of PR #15, issue #14)
CLASS: Evidenced contract violation, with one reproduced item.
ORDER: 4 of 11. See the packet README, Sequencing.

Paths are relative to `src/ph_composer/`.

## Governing rules

- `context/CONTRACTS.md`, "Outcomes and codes": "Codes are stable `noun.condition` strings." "A
  condition only one feature can have takes that feature's noun." "Add a foundation code here, with
  a test, before a caller relies on it."
- `context/AGENT_INTERFACE.md`: "Findings carry stable codes, affected references and recovery
  information; display labels remain separate."
- `context/CODING_STANDARDS.md`: "Distinguish failure states."

## Observed

1. **Finding codes without a noun.** Assemblies: `unreadable_material`, `material_missing_conductivity`,
   `material_thermal_mass_default`, `segment_without_material`, `dangling_material_reference`,
   `membrane_in_mixed_layer`, `assembly_no_thermal_layers`, `calculation_limit`
   (`features/assemblies/validation.rb`), `material_specific_heat_unavailable`,
   `construction_thermal_layer_limit` (`features/assemblies/export.rb:62,70`). Windows:
   `type_incomplete`, `element_incomplete`, `frame_operation_mismatch`, `dangling_product_reference`,
   `dangling_default_install` (`features/windows/snapshot.rb`), and the Unit codes `unhosted`,
   `off_host`, `scaled`, `mirrored`, `copy_id_pending` and others
   (`features/windows/units/state.rb:13-17`). Zones' preflight codes in the same export use the
   convention (`construction.missing`, `adjacency.stale`).
2. **One condition, two codes.** `ph_composer.windows.units.list` reports `unknown_type`; the export
   preflight reports `window.unknown_type` for the same Unit, because
   `features/windows/export_assessment.rb:236` prefixes on the way out and line 244 strips the prefix
   to look up the repair.
3. **Codes derived from message text.** `features/windows/snapshot.rb:55-56` picks
   `frame_operation_mismatch` when the message `include?("differs from element operation")`.
   `features/windows/export_assessment.rb:184` finds mismatches with `grep(/frame operation/)`.
   `features/windows/types/thermal.rb` returns one `findings` list that mixes tokens
   (`"top:unresolved_install"`, `"unresolved_frame_width"`) with sentences (`"Missing g-value."`), and
   the token is then published as a `message`.
4. **Zones interprets Assemblies' codes and record layout.** `features/zones/faces/export.rb:107-118`
   matches `material_specific_heat_unavailable` and `construction_thermal_layer_limit` by string and
   walks `layers[].segments[].material_id` to decide whether an Assembly can export.
5. **Repairs are named, not addressed.** Unit findings carry `"repair" => "rehost"` or
   `"next_mutation"` (`features/windows/units/state.rb`). Export preflight findings carry a full
   `locate: { name, params }` and `repairs` rows with an operation name. The panel re-derives which
   repair applies from codes in JavaScript (`html/window_schedule.js:77-85`), duplicating the Ruby
   table with different rules (for example it offers Reset for `copy_id_pending`).
6. **A new code duplicates an existing one.** Reproduced: `ph_composer.library.export_file` with a
   stale `expected_revision` answers `request.stale_revision` (`library/export_workflow.rb:16`). The
   documented code is `revision.stale`.
7. **The code table is behind.** At least 48 outcome codes raised by new code are absent
   from `context/CONTRACTS.md`: 29 `library.*`, 15 `window.*`, and `geometry.failed`,
   `identity.conflict`, `operation.proposal_required` and `request.stale_revision`. (Counted from
   codes raised with a literal in the diff; codes passed through a variable are not in the count.) `operation.query_missing`,
   `operation.dependency_missing` and `operation.query_cycle` appear in prose but not in the table.
   No test owns the list.
8. **Operations do not publish the codes they can refuse with.** `API.describe` returns kind, name,
   owner, description, params, result, examples, side effects and confirmation.

## Consequence

- A client cannot key on a Unit condition without knowing which read produced it.
- Rewording a thermal message silently changes a finding's code.
- Zones breaks when Assemblies renames a finding or reshapes Layers, with no declared contract
  between them.
- Agents learn refusal codes only by triggering them.

## Proposed correction

1. **One vocabulary.** Rename to `noun.condition` under the owning feature's nouns: `material.*`,
   `assembly.*`, `window_type.*`, `window_unit.*` (or `window.*`). The same code from every read.
   Remove the prefixing in `export_assessment.rb`.
2. **A finding value object.** `Finding = Struct.new(:code, :message, :subject, :repair, ...)` built
   where the condition is detected. `Thermal.calculate` returns findings with codes, never strings to
   be classified later. Delete both message matches.
3. **Repairs as operation references.** `"repair" => { "name" => "ph_composer.windows.units.rehost",
   "params" => {...} }` or nil, matching the preflight `locate` shape. The panel reads it; delete the
   derivation in `window_schedule.js`.
4. **Assemblies answers "can this export".** Add `export_ready` and `export_blockers` to each row of
   `ph_composer.assemblies.assemblies.all`. Zones reads those and stops matching codes and walking
   Layers.
5. **Fix `request.stale_revision`** to `revision.stale`.
6. **Own the code list.** Either extend the `CONTRACTS.md` table with a Library row and a Windows row,
   or generate a code index into `docs/API_REFERENCE.md` from a per-feature constant. Add one test
   that fails when source raises a code missing from the index.
7. **Optional:** declare `refuses: [codes]` on operations so `describe` can publish them.

## Decision

**Decided 2026-10-01 by Ed: rename now.** Finding codes move to `noun.condition` under the owning
feature's nouns, one code per condition from every read, in the same pass as the unit-bearing field
renames in [R09](R09-definition-feature-pattern.md). Do it once and completely. The app has no users and is not deployed, so no
deprecation path, alias or migration is needed. The pass covers the emitting Ruby and Python, panel label maps, the
report, tests, fixtures and the generated reference. Closed alternatives: codes only; fixing only the
duplicated codes; leaving the names.

## Verification

- A test enumerates every code the three features can emit and asserts the `noun.condition` pattern.
- `units.list` and `export_preflight` return the same code for the same seeded Unit condition.
- `grep -rn "include?(\"differs\|grep(/frame" src` is empty.
- `make fixtures` and the JS suite pass; update panel label maps by code, not by golden rewrite.

## Outcome

Implemented 2026-10-01 to 2026-10-02 on `refactor/r04-finding-codes`, with R09 item 5.

- **Vocabulary (1).** Window Type conditions take `window_type.*`; Unit conditions take `window.*`,
  the noun the Unit refusals already used, so `State` passes Fit's `window.overhang` and
  `window.overlap` through instead of remapping them (`overhang` is no longer folded into
  `off_host`). Materials and Assemblies take `material.*` and `assembly.*`. The Assemblies thermal
  preview's `flags`, which the finding file did not name, were a third vocabulary for the same
  conditions; they now use the same codes. Zones' `assembly.*_mismatch` findings borrowed Assemblies'
  noun and became `face.assembly_type_mismatch`, `face.assembly_exterior_condition_mismatch` and
  `face.assembly_pair_mismatch`; its interpolated `adjacency.`, `construction.` and `attached_zone.`
  codes became explicit maps. The `window.` prefixing in `export_assessment.rb` is gone.
- **Coded at detection (2).** `Windows::Thermal.finding` builds `{ code, message, side? }` where the
  condition is found; the thermal block's `findings` are those objects, not strings. The export
  reports each Type condition by its own code (one row per distinct condition per Unit, not one
  aggregate `incomplete_type`); `window_type.frame_operation_mismatch` stays non-blocking. Both
  message matches are deleted. A hash builder, not a Struct, because the findings are published JSON.
- **Repairs (3).** A Unit finding's `repair` is `{ name, params }` or null. Rehost adds `host` and
  swap adds `type_id`. With no known Type only Swap is offered; Reset is withheld beside
  `window.mirrored`, `window.surface_host` and `window.host_zone_unresolved`, all of which it refuses;
  an ambiguous host Zone has no Windows repair. The export preflight builds its repair rows from each
  Unit's full condition list under the same rule. The schedule reads the repairs; its derivation is
  gone, and it gains a Repair copied identities row action (it used to offer Reset for a copy).
- **Export readiness (4).** `assemblies.all` rows carry `export_ready` and `export_blockers`
  (conversion limits first, then every finding but the disclosed thermal mass default). Zones reads
  them and no longer queries the Assemblies preflight, matches its codes or walks Layers.
- **(5)** `revision.stale` replaces `request.stale_revision`.
- **Code list (6).** A new registration, `feature.code(code, description:)`, refuses a malformed or
  non-string code, a repeat, a noun another feature owns and a foundation noun. Each feature's
  `codes.rb` declares its codes; `docs/API_REFERENCE.md` lists them under "Feature codes".
  `tests/outcome_codes_test.rb` fails on a code literal in feature, library or translation source that
  is neither in `context/CONTRACTS.md` nor declared, including a bare code in a raising position, and
  on a schedule label for an undeclared code.
- **R09 item 5.** Thermal display fields carry units: `u_effective_w_m2k`, `u_construction_w_m2k`,
  `r_construction_m2k_w`, `rsi_m2k_w`, `rse_m2k_w`, `uw_w_m2k`, edge `psi_w_mk`; the Window construction
  row carries `uw_w_m2k`. The Python window records name `ug_w_m2k`, `g_value`, `width_m`, `uf_w_m2k`,
  `psi_g_w_mk` and `psi_install_w_mk`.
- **(7)** `refuses:` on operations was not done (optional).

Tests: `units.list` and `export_preflight` both report `window.copy_id_pending` for a seeded copy;
State repair rules for mirrored plus scaled and for an unknown Type; export repairs for mirrored plus
scaled; `export_blockers`; registration of codes; the schedule's offered repairs. `docs/API_REFERENCE.md`
was regenerated: its diff is the renamed fields, the new finding and repair shapes, the readiness
fields and the code list, not a golden rewritten to pass.

Gates: `make ci` passed on Ruby 3.2.2 and 2.7.2.

Review: one independent Opus pass with the architecture rubric found no blocking defect. Fixed: New
flipped Type and Rehost were offered for a Window with no known Type (a regression from removing the
panel's rule); the preflight built repairs without the Unit's other conditions; registration accepted
foundation nouns and Symbol codes; the scan test missed bare codes and stale schedule labels.

Follow-ups, not done here:

- The Unit read checks fewer host conditions than the preflight: a Ground or unclassified host shows
  nothing in `units.list` but `window.host_boundary_unsupported` or `window.host_unclassified` in the
  preflight. The codes agree where both report; the read could report the rest.
- Per-element Type findings without a side (`window_type.g_value_missing` on two elements) collapse
  into one preflight row per Unit and do not name the element.
- Feature codes appear in the generated reference only, not in `API.describe`; item 7 is the place.
- R09 item 4's single name for the Psi-Install collection (`psi_install_types` and `installs`) is
  still open.

