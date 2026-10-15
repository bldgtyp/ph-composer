# LR-01: the `layers.reorder` action

DATE: 2026-10-15
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: [#128](https://github.com/bldgtyp/ph-composer/issues/128)

## Entry and scope

Requires Ed's go and his confirmation of LR-D1 to LR-D4 in [PLAN.md](../PLAN.md). Owns the Model
side: one command, one declaration, their tests and the regenerated API reference. No panel file
changes. After this stage an agent can reorder Layers through the public API with the panel closed.

Behavior owner: the [PRD](../PRD.md), "Proposed contribution boundary". Paths are relative to
`src/ph_composer/`.

## Steps

1. **Command.** Add `Commands.reorder_layer(record, layer_id:, index:)` to
   `features/assemblies/commands/layers.rb`, beside `move_layer`. Inside `mutate`: find the Layer
   with `layer!` (`target.not_found` when missing); refuse `params.invalid` unless `index` is an
   Integer in `0..layers.length - 1`, with a message naming that range; delete the Layer from the
   array and insert it at `index`. Do not reuse `index!`, whose upper bound is the insertion range.
   The air barrier, orientation and every nested value are untouched because only the array order
   changes; `mutate` revalidates the copy as it does for every gesture.
2. **Declaration.** In `features/assemblies/declarations/layers.rb`, `declare_edit` gains
   `action(feature, "reorder", ...)` after `move`: params `layer_id` (`Shapes.id("lyr", LAYER_ID)`)
   and `index` (`type integer, minimum 0`, described as "The Layer's position in the resulting
   stored order, 0 first; the other Layers keep their relative order."); example
   `{ "layer_id" => Shapes::EXAMPLE_LAYER, "index" => 0 }`; description "Move one Layer to a
   position in the stored order, keeping the other Layers' relative order. Its current position
   changes nothing."; `undo_name` "Move Assembly Layer"; `side_effects` "Changes only the Layer
   order." Refusals are `Refuses::EDIT` through the shared `action` helper; no new code.
3. **Reference.** Run `make fixtures` so `docs/API_REFERENCE.md` gains the operation; the diff
   shows one new section and nothing else.
4. **Walkthrough.** Leave `tools/examples/authoring/assemblies_walkthrough.rb` alone; it is not an
   inventory of every Layer action.

## Source

| File | Disposition |
| --- | --- |
| `features/assemblies/commands/layers.rb` | Add `reorder_layer` |
| `features/assemblies/declarations/layers.rb` | Add the `reorder` declaration |
| `docs/API_REFERENCE.md` | Regenerated |
| `tests/assembly_records_commands_test.rb`, `tests/assembly_records_operations_test.rb` | Tests below |

## Tests (write first)

In `tests/assembly_records_commands_test.rb`, on the three-Layer fixture:

1. Reorder to the last position, to the first and to the middle: the Layer's id is at `index`, the
   other ids keep their relative order, and every Layer and Layer-Segment id, thickness, width,
   `material_id`, `steel_stud_spacing_mm`, orientation and `air_barrier` are unchanged. The input
   record is not mutated.
2. The same `index` returns a record equal to the input.
3. `index` of `layers.length`, a negative, a float and a string each refuse `params.invalid`; a
   missing `layer_id` refuses `target.not_found`.
4. With `orientation` set to `last_layer_outside` the result is identical to the
   `first_layer_outside` case (LR-D3).

In `tests/assembly_records_operations_test.rb`, through the API:

5. `invoke("assemblies.layers.reorder", ...)` with `expected_values` holding the read `layers`
   completes with `effect: committed`, the revision advances by one, and `describe` reports the
   Undo name "Move Assembly Layer".
6. The same call with `expected_values` carrying the pre-move order refuses `target.changed`, effect
   `none`, message ending "Nothing was written.", and the record is unchanged.
7. A call whose `index` is the Layer's current position completes with `effect: none`, the revision
   does not advance, and the engine recorded no write (the no-change rule in
   `context/CONTRACTS.md`, "Revisions, transactions and host execution").
8. `tests/api_reference_test.rb` and `tests/outcome_codes_test.rb` pass unchanged; the reference
   test fails until step 3 runs.

## Gate

`make ci` on both Rubies. One diff-focused review with the architecture rubric: the questions that
apply are the shared contract (an outside feature could declare the same shape through
`LayerRegistration.action`), pure domain behavior in the command, explicit identity and refusals.

## Out of scope

Any file under `html/`. Changing `layers.move`. A `move` with an `index` parameter (rejected by
LR-D1: two meanings on one action).

## Done when

Tests 1 to 8 pass, the reference carries the operation, the review is recorded in
[STATUS.md](../STATUS.md), the PR is merged, and the stage row reads `Merged to main`.
