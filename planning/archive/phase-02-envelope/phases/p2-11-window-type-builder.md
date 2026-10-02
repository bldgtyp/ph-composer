# P2-11: the Window Type Builder

DATE: 2026-09-30
STATUS: Implemented on branch; named acceptance passes with qualified retained evidence; Phase 2 integration remains open.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/14

## Entry and scope

Requires P2-10 and, for the Library page, P2-03. Owns the definition screens for windows: the
Window Types tab with its Builder, Installs and U-Values, and the Frames, Glazings and
Psi-Install Types subtabs of Library. No placed unit, so the Schedule subtab and Place stay out.

Behavior owner: [window-types PRD](../../window-types/PRD.md). The interaction contract is the
predecessor's `../ph-navigator-sketchup/planning/archive/window-types/UI_UX_SPEC.md`:
requirements WUX01 to WUX11, WUX13 to WUX16 and WUX18 port, WUX12 drops, WUX17 waits for P2-13.
Screen rulings: [ui-baseline](../../../ui-baseline/README.md) sections 4 and 6. Load the UI
polish skill first.

Predecessor paths are relative to `../ph-navigator-sketchup/src/ph_navigator_sketchup/` at
`f358ebf`.

## Steps

1. **Enable the tab.** Replace the disabled Window Types button and add its pane. Subtabs through
   `subtabs.js`: Window Types and U-Values. Schedule joins in P2-13.
2. **Type browser.** Port `window_type_list.js`: add, duplicate, delete, rename, sort, groups and
   manual order.
3. **Drawing.** Port `window_canvas.js`: the dimensioned drawing, selection by click, shift-click
   and background, insert controls, name pills, operation marks, Exterior and Interior viewing.
4. **Editor.** Port `window_editor.js` and `window_editor_shared.js`: the header with name, U-w,
   installed U-w and overall size; the drawing toolbar with Clear, Merge, Split, Empty, Flip, the
   eyedropper with repeat paste. Each gesture is one action from P2-10. In-place dimension editing
   uses the unit field only, which closes units follow-up U1-F4. Remove the star toggle and the
   push icon. Place is shown disabled with its reason until P2-13.
5. **Element cards.** Port `window_cards.js`: Glazing, four Frame rows and Operation, product
   selects, incomplete rows in the warning treatment.
6. **Installs.** Port `window_install_editor.js`: opened for the active type, paint a Psi-Install
   Type onto perimeter edges, shared internal edges shown as derived zero and unpaintable, an
   unset edge shown inheriting the model default, Apply to all edges, Copy to other Window Types,
   one Save and one Cancel for the session. Leaving with an unsaved session asks through
   `panel.navigationGuard`.
7. **U-Values.** Port `window_audit.js`: the type, element and edge report from the thermal block.
8. **Library subtabs.** Port `window_inventory.js` for Frames, Glazings and Psi-Install Types on
   the Library page from P2-03, with use sites and guarded delete with replacement. Add the two
   model defaults beside them: the default Psi-Install Type and the default install depth. Add
   the install depth override to the type header's menu.
9. **Sidebar adapters.** Add Frame and Glazing entries to the sidebar's per-kind adapters so the
   In this file source serves the element cards.
10. **Preview and manifests.** Fixtures and checks under `tools/ui-preview/`; regenerate both
    manifests.

## Source

| Predecessor file | Lines | Disposition |
| --- | --- | --- |
| `html/window_editor.js`, `window_editor_shared.js`, `window_type_list.js`, `window_canvas.js`, `window_cards.js`, `windows.css` | 1,287 | Port |
| `html/window_install_editor.js`, `window_audit.js` | 295 | Port |
| `html/window_inventory.js` | 227 | Port onto the Library page |
| `html/window_integration.js`, `window_assignment.js` | 423 | Drop |
| `html/window_schedule.js` | 187 | Wait for P2-13 |
| `tests/window_editor_test.js` | 1,619 | Port the cases for what ports |

## Tests (write first)

1. The drawing renders one, two and three element types with an Empty panel from fixtures.
2. Each toolbar gesture sends one named action with explicit element ids.
3. Element cards mark an incomplete row and never show a zero for a missing value.
4. Installs: painting stages locally and sends nothing; Save sends one action; Cancel sends none;
   a shared internal edge cannot be painted.
5. The U-Values report shows the uninstalled U-w as the headline and the installed value beside.
6. A unit switch during a dimension draft does not reinterpret typed text.

## Host gate

Fresh process, real panel: build a three-element mulled type with one Empty panel, merge and
split, flip, eyedropper and repeat paste, edit band sizes in place, run an Installs session and
Save it, read U-Values, duplicate the type, delete a Frame in use with a replacement. One Undo
per commit.

## Out of scope

Place, Schedule, the Colour-by mode (P2-13). Provider sources for the three kinds (P2-15).
Product photos UI.

## Done when

- E11 has evidence in `evidence/p2-11-window-type-builder.md`, with the UI polish review recorded.
- `make ci` and `make ui-checks` pass.

Current consolidation and provenance: [P2-17](../evidence/p2-17-acceptance.md#register-consolidation-at-f4f6576).
