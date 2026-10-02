# R11: formatting and small readability items the gates do not catch

DATE: 2026-10-01
STATUS: Requested
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft; review of PR #15, issue #14)
CLASS: Optional improvement. Gate decision made 2026-10-01; see Decision.
ORDER: 11 of 11. See the packet README, Sequencing.

Paths are relative to `src/ph_composer/`.

## Governing rules

`context/CODING_STANDARDS.md`: "Sequenced statements do not share a line." "Prefer a readable
operation." "Do not weaken an existing gate opportunistically." `.rubocop.yml` enables five cops:
frozen-string comment, `Style/Semicolon`, line length 120, method length 40, class length 300. All
`Layout` cops are off. The lint configuration was not changed by this PR.

## Observed

1. **Lines broken to meet 120 columns with the continuation at column 0.**
   `features/assemblies/declarations/layers.rb:31-32`, `features/windows/library_kinds.rb:36-37`,
   `features/windows/declarations/grid.rb:12-13, 21-22`, `library/file_provider.rb:44-45, 76-77`.
   Mid-expression breaks with one-space indent: `core/records/fields.rb` (`remap`),
   `library/setup.rb:60-61`, `library/file_provider.rb:38-39`, `library/library_file.rb:89-90`,
   `features/windows/operations.rb:120-121, 127-128`, `features/windows/snapshot.rb:95-96`,
   `features/windows/products/schema.rb:50-51`, `features/windows/types/installs.rb:14-15`,
   `features/windows/units/changes.rb:27-28`, `features/windows/units/type_retargeter.rb:16-17, 64-65`.
   These read as the output of a mechanical wrap.
2. **Windows uses a different continuation style from the rest of the tree.** Hash and argument
   continuations in `features/windows/` are indented a fixed amount unrelated to the opening
   delimiter (`features/windows/types/schema.rb:14-18`, `features/windows/types/edge_resolution.rb:16-23`,
   `features/windows/settings.rb:11-13, 30-35`). Zones and Assemblies align to the delimiter.
3. **Multi-line conditions folded into one expression.**
   `features/windows/units/restore_step.rb:150-156` (a seven-line `unless` joining three `all?`
   blocks) and `:299-301`; `features/windows/units/type_cleanup_step.rb:66-67, 72-74`;
   `features/zones/declarations/assembly_assignment.rb:31-33` (a block parameter list split across
   lines).
4. **Schema mutation after construction.** `features/assemblies/assembly/schema.rb:94-95`,
   `features/assemblies/materials/schema.rb:57-61`, `features/windows/types/schema.rb:92-93` and
   `features/windows/products/schema.rb:45-46` build a field list, then reach back into the `source`
   field's schema to insert the snapshot schema derived from that list.
5. **A validation call used for its exception.** `features/windows/place_tool.rb:27` calls
   `Units::Anchors.point(anchor, :width_m => 1, :height_m => 1)` only to validate `anchor`.
6. **`"Nothing was written."` on read failures.** `core/model_settings.rb:29` appends it in
   `validate!`, which `read` also calls. `context/CONTRACTS.md`: a refused read does not carry that
   sentence. Pre-existing in the Zones settings code this was extracted from.
7. **A foundation example names a feature kind.** `library/export_registration.rb:36` uses
   `ph_composer.assemblies.material` in the registered example of a foundation operation.
8. **Two `type: ignore` comments** in `python/ph_composer_translation/model_sections.py:316-317`, on
   an accumulator typed as `dict[str, JSONValue]`. A small dataclass removes both.
9. **Stale corrupted setup reads as empty.** `library/setup.rb:23-24` returns `[]` when the stored
   provider configuration fails to parse or validate; the next `add_file` then saves over it.
   Unverified risk: no report of it happening. `CODING_STANDARDS.md`: "Distinguish failure states."
10. **The frozen request's params are not frozen.** Added 2026-10-02 from R07's review.
    `HandlerRequest` freezes the struct (`shell/handler_request.rb`), but `params` stays a mutable
    Hash, so an operation could alter the params a later nested read or the dispatcher's digest
    sees. Nothing mutates them today; the contract is stated, not enforced.

## Decision

**Decided 2026-10-01 by Ed.** Enable RuboCop's full `Layout` department, not the minimal set this
review recommended. Do it after PR #15 merges, on its own pull request, once the other refactor work
is done, so formatting changes stay separate from feature changes. The work is recorded in
[planning/refactor/rubocop-layout.md](../../../refactor/rubocop-layout.md) with a row in
`planning/STATUS.md`. Items 1 and 2 above are therefore not fixed in this packet: the formatting
pass fixes them. Do not hand-reformat files in the review refactors beyond the lines a change already
touches.

## Proposed correction

1. Items 1 and 2: deferred to the formatting pull request (see Decision).
2. (Superseded by the Decision: the full `Layout` department, later, on its own pull request.)
3. Name the intermediate predicates in item 3 (`faces_valid`, `stamps_valid`, `ids_match`).
4. Item 4: a helper `Fields.with_source_snapshot(fields)` that returns the completed list.
5. Item 5: `Units::Anchors.validate!(anchor)`.
6. Item 6: `ModelSettings#read` raises `record.unreadable` without the mutation sentence.
7. Item 7: use the synthetic `example_parts` kind the other library examples use.
8. Item 9: return a distinct `library.setup_unreadable` state that the panel shows and that refuses
   `add_file` until the user confirms replacing it.
9. Item 10: deep-freeze `params` when a request is built (`HandlerRequest#initialize`, after the
   existing `DeepCopy`), so an in-place edit raises `FrozenError`. Run the suite to find any operation
   that edits its params in place and give it a copy. One focused test in `handler_request_test.rb`.

## Verification

For this packet's remaining items (3 to 10): `make lint` passes on both Rubies under the current
configuration. No behaviour change except items 6, 9 and 10, each with one focused test. The widened cop
list is verified in the formatting pull request.
