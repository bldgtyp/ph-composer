# P2-03: Materials and Assemblies inventories

DATE: 2026-09-30
STATUS: Implemented on branch; named acceptance passes with qualified retained evidence; Phase 2 integration remains open.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/14

## Entry and scope

Requires P2-02 and D2-7. Owns the first two definition screens: Library / Materials and the
Assemblies inventory, with the Library and Assemblies tabs enabled. Opening an Assembly shows a
placeholder until P2-04 lands the Builder. No library provider, no sidebar and no Face usage.

Behavior owner: [assemblies PRD](../assemblies/PRD.md), "Carried over unchanged". Screen rulings:
[ui-baseline](../../../ui-baseline/README.md) sections 2 and 5. Load the UI polish skill first.

Paths are relative to `src/ph_composer/`. Predecessor paths are relative to
`../ph-navigator-sketchup/src/ph_navigator_sketchup/` at `f358ebf`.

## Steps

1. **Enable two tabs.** In `html/index.html` replace the disabled Assemblies and Library buttons
   with `data-tab` buttons and add their `data-pane` nodes. Window Types stays "Planned".
2. **Library page.** `html/sections/library.js`: the heading with its count and "Definitions
   stored in this model.", and the subtabs through `subtabs.js`. Subtabs in this stage: Materials
   and Attached zones. Frames, Glazings and Psi-Install Types arrive in P2-11.
3. **Materials table.** Columns and row actions per ui-baseline section 5: Actions (Duplicate,
   Delete, uses count with its bubble), Name, Color swatch, Category chip, conductivity, density,
   specific heat, emissivity, Notes. Cells edit in place through `record_edits` against
   `materials.update` with `expected_values`. Every number goes through `units.js`. "+ New
   Material" opens the form (`material_form.js`). The uses count is the number of Assemblies
   naming the Material, read from the assemblies snapshot section.
4. **Material delete and replace.** Port the duplicate, colour picker, replace and delete flows
   from `library_forms.js`. Delete of a Material in use asks for a replacement and names the
   affected Assemblies before commit. Use `ui.actionRow` and the destructive treatment.
5. **Attached zones subtab.** A table over the existing Attached zone records using the existing
   `ph_composer.zones.faces.attached_zone.*` actions. It adds no operation. The inline creation on
   the Zones / Faces tab is unchanged.
6. **Assemblies inventory.** `html/sections/assemblies.js` per ui-baseline section 2: Actions
   (Open, Duplicate, Delete), Name, Color swatch, Type chip, Exterior chip, Thickness, U with
   films, Notes. Chips show the palette's short words and store honeybee's. An Assembly with a
   withheld U-value shows the reason, not a number. "+ New Assembly" opens `assembly_form.js`.
   The Faces column and the Select faces, Replace and Paint onto faces actions arrive in P2-05;
   leave no dead control in their place.
7. **View controls.** Filter, Group by, Order by and Direction through `view_controls.js` on both
   tables. Filtering hides rows and never changes the Model or drops a draft.
8. **Preview and manifests.** Add both sections' fixtures to `tools/ui-preview/host.js` and port
   `tools/ui-preview/assemblies_checks.cjs` and `library_checks.cjs`. Regenerate the panel
   manifest and refresh the vendor manifest.

## Source

| Predecessor file | Lines | Disposition |
| --- | --- | --- |
| `html/sections/library.js`, `library_forms.js`, `material_form.js`, `library.css` | 747 | Port. Sidebar wiring waits for P2-08 |
| `html/sections/assemblies.js`, `assembly_form.js` | 380 | Port the inventory. Drop every designPH control |
| `html/assemblies_designph.js` | 227 | Drop |
| `tests/library_section_test.js`, the inventory parts of `tests/assemblies_section_test.js` | about 1,000 | Port with the code |

## Tests (write first)

1. Each table renders from its snapshot fixture; a withheld U-value shows its reason.
2. An in-place edit sends one action with `expected_values`; a refusal keeps the draft.
3. Switching SI and IP reformats values and leaves a typed draft alone.
4. Delete of an in-use Material cannot commit without a replacement.
5. Filter, group and order send nothing to the host.
6. The Attached zones subtab sends only the existing registered actions.
7. `tests/panel_messages_test.rb` passes with no new message type.

## Host gate

Fresh process, real panel: create, edit in place, duplicate and delete a Material and an
Assembly; replace an in-use Material; one Undo per commit; a narrow panel width; tab and subtab
switches keep drafts or cancel them explicitly; Escape order per the UI polish skill.

## Out of scope

The Builder (P2-04). Face usage, Paint onto faces, Replace (P2-05). The sidebar and Library
badges (P2-08). Saved table layout, which stays with the first screen that needs it.

## Done when

- E03 has evidence in `evidence/p2-03-inventories.md`, with the UI polish review recorded.
- `make ci` and `make ui-checks` pass.

Current consolidation and provenance: [P2-17](../evidence/p2-17-acceptance.md#register-consolidation-at-f4f6576).
