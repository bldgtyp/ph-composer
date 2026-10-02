# R06: finding and outcome codes are inconsistent across the Phase 2 features

DATE: 2026-10-01
STATUS: Requested
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft; review of PR #15, issue #14)
CLASS: Evidenced contract violation, with one reproduced item.
PRIORITY: 3. Codes become a compatibility surface the moment a client keys on them.

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
renames in [R08](R08-definition-feature-pattern.md). Do it once and completely. The app has no users and is not deployed, so no
deprecation path, alias or migration is needed. The pass covers the emitting Ruby and Python, panel label maps, the
report, tests, fixtures and the generated reference. Closed alternatives: codes only; fixing only the
duplicated codes; leaving the names.

## Verification

- A test enumerates every code the three features can emit and asserts the `noun.condition` pattern.
- `units.list` and `export_preflight` return the same code for the same seeded Unit condition.
- `grep -rn "include?(\"differs\|grep(/frame" src` is empty.
- `make fixtures` and the JS suite pass; update panel label maps by code, not by golden rewrite.
