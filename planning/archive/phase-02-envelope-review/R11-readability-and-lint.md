# R11: formatting and small readability items the gates do not catch

DATE: 2026-10-01
STATUS: Merged to main 2026-10-02 (PR #30), items 3 to 20; dual-Ruby `make ci` and `make ui-checks` pass; carried host gate passed 2026-10-02 (ledger case `R11H`)
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
   `features/windows/snapshot.rb` (`product`), `features/windows/products/operations.rb`
   (`replace_in_types`; R09 split `features/windows/operations.rb`), `features/windows/types/installs.rb:14-15`,
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
   `Products.kind` in `features/windows/products/schema.rb` (one place for the three products since
   R09) build a field list, then reach back into the `source`
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
11. **A context menu tests an entry provider twice.** Added 2026-10-02 from R02's follow-ups.
    `Commands#install_feature_menus` filters contextual items with `available?`, then
    `menu_entries` calls `available?` again for an item with `entries` (`shell/commands.rb`). Each
    test builds a read request and may run a query. Pre-existing.
12. **An unreadable Window Type raises in some menu reads and not others.** Added 2026-10-02 from
    R02's follow-ups. `choose_from_menu` (`features/windows/declarations/viewport.rb`) lists Types
    through `records.list`, at most one page, and skips unreadable ones. `type_rows`, used by the
    Place Window… `available:` test and the per-Face entry provider, calls `engine.find` and raises
    on an unreadable Type; the Window Type Colour-by mode does the same. The shell logs the raise
    and drops the item, so one bad Type removes Place Window… from the context menu. Pre-existing.
13. **A native approval dialog opens before dispatch can refuse.** Added 2026-10-02 from R03's
    follow-ups. `NativeApproval.call` (`shell/native_approval.rb`) asks for the file or folder
    first; dispatch then checks grant, params, busy state and `expected_revision`. A refusal arrives
    after the user has chosen a location.
14. **The library provider walkthrough reads one page.** Added 2026-10-02 from R03's follow-ups.
    `tools/examples/library_provider/walkthrough.rb` reads only the first page of `in_file` (and of
    `catalog`), so the worked example does not show paging.
15. **Two copies of the deterministic id allocator.** Added 2026-10-02 from R09's follow-ups.
    `Windows::Definitions.allocator` and `Assemblies::Definitions.identity_allocator` have the same
    body under two names (`features/windows/definitions.rb`, `features/assemblies/definitions.rb`).
    R09 kept them per feature, as its brief allowed. Phase 3's definition kinds would add a third.
16. **A leftover alias.** Added 2026-10-02 from R09's follow-ups. `Assemblies::SchemaFields`
    (`features/assemblies/schema_fields.rb`) aliases `Records::AuthoringFields` "so existing callers
    retain the same API". Windows calls the same module `Fields`. Since R09 moved the schema
    builders to `core/schema_shapes.rb`, the alias only renames the authoring-field helpers.
17. **Panel navigation is called but does not exist.** Added 2026-10-02 from R10's follow-ups.
    Found by reading the code, not by a click: `panel.js` exports no `navigate`, and `panel.section`
    ignores the `onNavigate` option that `library/section.js` and `features/windows/section.js` pass.
    Three Windows controls call `panel.navigate` and would throw a `TypeError`: "Open library" on a
    Type card (`html/features/windows/cards.js`), "Open type" in a product's uses bubble
    (`html/features/windows/inventory.js`), and leaving a dirty install editor
    (`html/features/windows/section.js`). No offline test or browser check clicks any of them.
    Pre-existing on main before R10.
18. **Windows' panel depends on a Zones module.** Added 2026-10-02 from R10's follow-ups.
    `html/features/windows/schedule.js` depends on `html/features/zones/face_words.js` for the
    display words of honeybee face types and boundary conditions. The words are honeybee's
    vocabulary shown on screen, not Zones' data, so a feature that shows a face type must otherwise
    reach into Zones.
19. **Two New Attached zone forms.** Added 2026-10-02 from R10's follow-ups.
    `html/features/zones/attached_zone_fields.js` (inline create-and-assign from a Face chip) uses a
    plain number input for the temperature reduction factor; `html/features/zones/attached_zones.js`
    (the Library surface) uses a `UnitField`. The two validate differently, each lists the five
    kinds, and `attached_zones.js` writes the factor's field descriptor twice.
20. **The UI polish reference is behind Phase 2.** Added 2026-10-02 from R10's follow-ups.
    `.agents/skills/ph-composer-ui-polish/references/patterns.md` lists the Assembly Builder,
    Library and Window Types under "predecessor only" with predecessor file names, and says they
    "arrive with Phase 2". They are local now, under `html/features/` and `html/library/`.

## Decision

**Decided 2026-10-01 by Ed.** Enable RuboCop's full `Layout` department, not the minimal set this
review recommended. Do it after PR #15 merges, on its own pull request, once the other refactor work
is done, so formatting changes stay separate from feature changes. The work is recorded in
[planning/archive/rubocop-layout.md](../rubocop-layout.md) with its completed outcome in
`planning/archive/README.md`. Items 1 and 2 above are therefore not fixed in this packet: the formatting
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
10. Item 11: test each contextual item once per menu build and pass the verdict to `menu_entries`.
11. Item 12: one Type read for all three callers that skips an unreadable Type, as `choose_from_menu`
    does, and pages past the first page or states the cap. One focused test: an unreadable Type
    leaves Place Window… in the menu.
12. Item 13: run dispatch's remaining non-interactive checks (grant, params, busy,
    `expected_revision`; an unknown name and a closed session already open no dialog) before the dialog, and keep the post-dialog checks. One focused test: a
    busy session refuses without opening the dialog.
13. Item 14: page `catalog` and `in_file` with `cursor` until `next_cursor` is null.
14. Item 15: one allocator in core, such as `Records::Identity.allocator(request, inputs)`, used by
    both features and by the Window Unit repairs. Keep the seed keys each caller passes today, so
    derived ids do not change; the existing preview-equals-invoke tests check that.
15. Item 16: call `Records::AuthoringFields` (or one short alias shared by both features) directly
    and delete `schema_fields.rb`, moving its kind-id constants to the Assemblies entry file.
16. Item 17: write the failing test first (click "Open library" on a Type card in
    `window_editor_test.js`). Then add `panel.navigate(tab, intent)` to `panel.js`: it goes through
    the same navigation guards as a tab click, shows the tab, and calls the destination section's
    `onNavigate(root, intent)`. Document it beside `panel.section` in `context/TECH_STACK.md`,
    "Panel".
17. Item 18: move `face_words.js` into the kit (`html/face_words.js`). Zones and Windows both depend
    on the kit module; `tests/panel_layout_test.js` keeps holding.
18. Item 19: one Attached-zone field set used by both forms, built on `UnitField`, with the kinds and
    the factor descriptor declared once in `attached_zone_fields.js`.
19. Item 20: move the three entries to the local list with their `html/features/` and `html/library/`
    paths, and drop the "arrive with Phase 2" sentence.

## Verification

For this packet's remaining items (3 to 20): `make lint` passes on both Rubies under the current
configuration. No behaviour change except items 6, 9, 10, 12, 13, 17 and 19, each with one focused
test. Items 17 to 19 change panel assets: refresh the runtime manifest and run `make ui-checks`. The
widened cop list is verified in the formatting pull request.

**Host gate, carried from R10** (which carried it from R03; neither ran it). Run in a fresh SketchUp
process with the branch RBZ, after item 13 lands, because item 13 changes when the native approval
dialog opens:

- the library setup dialogs (add file, add folder), from the panel and from the Libraries menu;
- library export to an existing destination: record whether the macOS save panel and the replace
  message box both ask, as for HBJSON;
- paging through a library longer than one page;
- the Window Type grid gestures;
- item 17's three navigation controls, clicked in the panel.

Record the results in the native-acceptance case ledger. These need native modal dialogs, so plan a
short session with Ed at the host.

## Outcome

Implemented 2026-10-02 on `refactor/r11-readability`; merged as PR #30. Items 1 and 2 stay with the formatting pull
request. Paths are relative to `src/ph_composer/`.

- **3.** Named predicates in `features/windows/units/restore_panes.rb` (`faces_valid`, `stamps_valid`,
  `ids_match`, with `pane_face?` and `pane_stamp?`) and `type_cleanup_step.rb` (`only_added`,
  `configured`, `planned`); the split block parameter list in
  `features/zones/declarations/assembly_assignment.rb` is whole. The seven-line `unless` the finding
  cites had moved from `restore_step.rb` to `restore_panes.rb` under R08.
- **4.** `Records::AuthoringFields.with_source_snapshot(fields, snapshot_schema = ...)` returns the
  completed list; Materials passes its own snapshot schema (category as plain text) instead of
  mutating one.
- **5.** `Units::Anchors.validate!`. **6.** `ModelSettings#read` refuses invalid stored settings with
  `record.unreadable` and no mutation sentence; `validate!` keeps `validation.failed` for writes.
  **7.** The export example names `example_parts`. **8.** A `_ConstructionUsage` dataclass replaces
  the two `type: ignore` comments.
- **9.** `Library::Setup.state` reports `readable` or `unreadable`; reads still see no libraries, but
  `save` (so `add_file` and `remove`) refuses with the new `library.setup_unreadable`. New query
  `ph_composer.library.providers.setup_state` with snapshot section
  `ph_composer.library.provider_setup`; new setup command `ph_composer.library.providers.reset`,
  which clears only an unreadable setup and leaves a readable one unchanged. The setup dialog
  (`html/library/setup.js`) shows the state with a Reset button and disables Add; the Libraries menu
  says so before any picker opens.
- **10.** `HandlerRequest` holds a deep-frozen copy of its params (`DeepCopy.frozen`); the full suite
  found no operation that edits its params in place.
- **11.** `menu_entries` no longer re-tests `available?`; only the context menu carries entry
  providers and it has already tested them.
- **12.** `Windows::Snapshot.readable(engine, kind)` is the one Type read for Place Window...'s test,
  the per-Face entries and the Window Type Colour-by mode; it skips an unreadable Type. The chooser
  pages through `records.list` until `next_cursor` is null.
- **13.** `Dispatch#setup_refusal` and `#file_export_refusal` give the refusal dispatch would give
  (session, grant, params, busy) without running the handler; `NativeApproval` asks before opening a
  dialog, and dispatch repeats every check after it. `expected_revision` is not among them: it is a
  `library.export_file` param its handler checks, not a dispatch check, so it still refuses after the
  dialog. Moving it would need a dispatch-level contract for that param.
- **14.** The provider walkthrough pages `catalog` and `in_file` at one row per page.
- **15.** `Records::Identity.allocator(request, inputs)` replaces both feature copies with the same
  seed keys; derived ids are unchanged.
- **16.** `features/assemblies/schema_fields.rb` is gone; its kind constants and a `Fields` alias,
  the name Windows already uses, open `features/assemblies/install.rb`.
- **17.** `panel.navigate(tab, intent)` in `html/panel.js`, documented in `context/TECH_STACK.md`,
  "Panel", and the UI polish reference.
- **18.** `html/face_words.js` is a kit module; Zones and Windows depend on it.
- **19.** `html/features/zones/attached_zone_fields.js` builds the one field set (name, kind, factor
  on `UnitField`, kinds and factor descriptor declared once) used by the Library form, the Classify
  palette and inline create-and-assign. Enter in the name or factor takes the submit path. The
  Library's New Attached zone form now starts at a free name ("Attached zone N") rather than blank,
  as the other two forms did.
- **20.** The UI polish reference lists the Assembly Builder, Library and Window Types at their local
  paths.

**Review.** One Sonnet pass with the architecture rubric. Fixed: the Libraries menu opened the file
picker for an unreadable setup (now a notice first); `ids_match` lost its short-circuit and raised
`NoMethodError` on an unstamped pane (reproduced, now a test); the invalid-factor message showed twice
after Enter; `reset` could wipe a readable setup (now unchanged); `admission_refusal` did not turn an
unexpected error into an outcome; the chooser's second page and reset through the API were untested.

**Verification.** `make ci` passes on Ruby 3.2.2 and 2.7.2. `make ui-checks` passes with Playwright
resolved from a scratch install. New focused tests: `model_settings_test.rb` (6),
`library_setup_test.rb` and `library_setup_commands_test.rb` and `library_setup_test.js` (9),
`handler_request_test.rb` (10), `registry_test.rb` (11), `window_place_tool_test.rb` (12),
`file_export_test.rb` (13), `window_editor_test.js` (17), `overview_panel_test.js` (19),
`window_unit_restore_step_test.rb` (the review's unstamped pane).

**Host gate: passed 2026-10-02**, with Ed at the host and main `cf18ede` installed. All seven
checks passed: the library setup dialogs from the panel and the menu, export to an existing
destination, paging past one page, the Window Type grid gestures, the three navigation controls, and
the unreadable setup with Reset. Export over an existing file asks twice: macOS's replace sheet, then
SketchUp's message box. Evidence:
[r11-host-gate-2026-10-02](../../native-acceptance/evidence/r11-host-gate-2026-10-02.md); ledger
case `R11H`. Five UI findings, none a failure, are recorded in
[host-gate-ui-findings](../host-gate-ui-findings/README.md).

**Follow-ups, not in this change.** Each is recorded where it will be done:

- The third deep-freeze (`DeepCopy.frozen` beside `ModelSettings` and `Registry`):
  [shared-deep-freeze](../shared-deep-freeze.md), merged through PR #83 on 2026-10-07.
- The UI polish reference's stale Window placement entry: folded into
  [library-product-tab-headers](../library-product-tab-headers/README.md), the next
  change that opens that reference.
- `export_file`'s `expected_revision` checked only after the save dialog: folded into
  [agent-authorized-file-access](../agent-authorized-file-access/README.md), which
  redesigns the export params.
- The `runtime_page_test.js` flake seen in this branch's `make ci`:
  [planning/bugs/runtime-probe-test-flake.md](../../bugs/runtime-probe-test-flake.md).
- The carried host gate: step 3 of the packet README's Sequencing.
