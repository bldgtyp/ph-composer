# P2-02: Material and Assembly records

DATE: 2026-09-30
STATUS: In progress. Authorized 2026-10-01; preceding stage attestations remain open.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/14

## Entry and scope

Requires P2-01 and D2-4. Owns the `ph_composer.assemblies` feature without any screen: the two
record kinds, the pure commands, the display thermal values, the findings on a record and the
registered operations. A script can build and edit an Assembly when this stage closes. No panel
section, no Face assignment and no export.

Behavior owner: [assemblies PRD](../assemblies/PRD.md), sections Records, Behaviors (carried over
unchanged) and Validation rows. Names: [CONTRACTS](../CONTRACTS.md) sections 2 and 3.

Paths are relative to `src/ph_composer/`. Predecessor paths are relative to
`../ph-navigator-sketchup/src/ph_navigator_sketchup/` at `f358ebf`.

## Steps

1. **Feature skeleton.** `features/assemblies/install.rb` with one `install(registry)`, the
   feature id, contract version and no `requires`. Assemblies is a definitions feature at the
   bottom of the layering (D2-1): add it to `FEATURES` in `extension.rb` before `Zones`, and add
   a dependency-direction test that fails if any file under `features/assemblies/` names `Zones`,
   a Face or a window. Follow the layout of `features/zones/install.rb`.
2. **Material kind.** `features/assemblies/materials/schema.rb`: the `RecordKind` from CONTRACTS
   section 2, the thirteen category ids with their aliases, and `membrane?`. A Material whose
   category is `membrane` needs no conductivity. Port from `features/assemblies/material_schema.rb`
   and `core/material_categories.rb`. Drop the designPH source kind.
3. **Assembly kind.** `features/assemblies/assembly/schema.rb`: the `RecordKind` with nested
   `layers` and `segments`, the `lyr_` and `seg_` ids, the declared Material references, and the
   schema refusals: more than one Layer-Segment with a steel stud spacing in one Layer. `type` is
   `Wall`, `RoofCeiling`, `Floor` or absent. `exterior_condition` is `Outdoors`, `Ground`,
   `AttachedZone`, `Adiabatic` or absent. Port from `assembly_schema.rb`. Drop `kind`, both
   declared-U fields and the `designph` slot. Add `color` and `ventilated_cladding`.
4. **Pure commands.** Port `commands/assembly.rb`, `commands/layers.rb`, `commands/material.rb`
   and `commands/change.rb` as functions from a record and explicit `layer_id` and `segment_id`
   to a changed record plus findings. Drop adopt, accept and restore, and
   `commands/material_resolution.rb`. No SketchUp access in these files.
5. **Thermal display values.** Port `thermal.rb`: `effective` and `preview`. Keep the film
   constants and the mean of the parallel-path and isothermal-planes resistances. Drop `packed`
   and the declared-U branch. `ventilated_cladding` sets the displayed exterior film equal to the
   interior film, as the predecessor's ventilated rows did. Missing inputs withhold the value with
   a named reason; they never produce zero. An all-membrane Assembly has no U-value.
6. **Record findings.** Port `validation.rb` less its push and difference rows, as a pure function
   from one Assembly and its Materials to findings: incomplete, Material incomplete, membrane in a
   mixed Layer, unreadable. Whether a finding blocks export depends on assignment and is decided
   in P2-06; here each finding carries its condition only.
7. **Operations.** Register the queries, snapshot sections and actions of CONTRACTS section 3 in
   `features/assemblies/declarations/`. Each action handler reads through `request.engine`, runs
   the pure command and calls `propose_create`, `propose_update` with `expected_values`,
   `propose_duplicate` or `propose_delete`. One gesture is one action and one Undo step.
   `materials.delete` with a `replacement_id` rewrites every Layer-Segment naming the Material in
   the same proposal through `propose_update`; `propose_delete` checks those staged catalog rewrites.
   `reference_plan` is for entity targets, not catalog records.
   Without a replacement, a Material in use refuses as `reference.in_use`.
   `assemblies.delete` takes no replacement in this stage. Nothing can write a Face's
   `assembly_id` yet; the reference declaration and delete with replacement arrive in P2-05.
8. **Read block.** The Assembly read returns canonical SI values and message parts. Ruby formats
   no unit-bearing text (`context/TECH_STACK.md`, "Display units"). Port `message_parts.rb` and
   the projection in `snapshot.rb`.
9. **Duplicate.** A duplicated Assembly gets a new id, new Layer and Layer-Segment ids, the same
   Material references, an independent `user_data` copy and empty `photo_collections`.
10. **Walkthrough and reference.** Add `tools/examples/authoring/assemblies_walkthrough.rb`: panel
    closed, discover, create two Materials, build a three-Layer Assembly with one mixed Layer,
    read it back, recover from a stale edit. Regenerate `docs/API_REFERENCE.md` with
    `make fixtures`.

## Source

| Predecessor file | Lines | Disposition |
| --- | --- | --- |
| `features/assemblies/material_schema.rb`, `assembly_schema.rb`, `attrs.rb`, `model_library.rb` | 364 | Adapt to `RecordKind` |
| `features/assemblies/commands/{assembly,layers,material,change}.rb` | 742 | Port the pure parts |
| `features/assemblies/builder.rb`, `actions.rb` | 329 | Replace with proposal handlers; keep the gesture list |
| `features/assemblies/thermal.rb`, `validation.rb`, `snapshot.rb`, `message_parts.rb` | 585 | Port, less designPH |
| `core/material_categories.rb` | 51 | Port into the feature |
| `tests/assembly_{attrs,commands,thermal}_test.rb`, `material_{attrs,commands}_test.rb`, `assemblies_validation_test.rb`, `message_parts_test.rb`, `support/assembly_fixtures.rb` | about 1,300 | Port with the code |

## Tests (write first)

1. Schema round trip for each kind; an unknown key is unreadable; every refusal in step 3.
2. Thermal: the predecessor's reference cases in `tests/assembly_thermal_test.rb` and
   `tests/support/assembly_fixtures.rb` produce the same values to six places; a missing
   conductivity withholds; a membrane Layer contributes nothing; all membranes has no value;
   the ventilated flag changes only the with-films value.
3. Each Layer and Layer-Segment command against explicit ids, including a wrong id refusal.
4. Stale `expected_values` refuses with nothing written.
5. Material delete: in use without replacement refuses; with replacement rewrites every use and
   deletes in one proposal; an injected failure on the last write leaves every record unchanged.
6. Duplicate per step 9. `user_data` survives edit and Duplicate. An unavailable extension payload survives edit;
   Duplicate refuses `copy.rule_missing` under the foundation contract until its copy rules are
   available. Understood local-only extension payloads survive Duplicate.
7. Every registered operation has schemas and a validating example (`tests/api_reference_test.rb`).
8. The walkthrough runs as written and names no feature module.
9. The dependency-direction test: no file under `features/assemblies/` names `Zones`.

## Host gate

Fresh process, panel closed: run the walkthrough through the bridge, then native Undo and Redo
across each step, save, reopen in a fresh process and read the records back. Two Models with the
same synthetic ids stay isolated.

## Out of scope

Any screen (P2-03, P2-04). Face assignment, usage, delete with replacement of an Assembly, the
Colour-by mode (P2-05). Export (P2-06). Library import (P2-07). The SD assembly helper.

## Done when

- E02 has evidence in `evidence/p2-02-assembly-records.md`.
- `make ci` passes on both Rubies; the generated API reference is current.
- The assemblies packet STATUS records the delivered scope.
