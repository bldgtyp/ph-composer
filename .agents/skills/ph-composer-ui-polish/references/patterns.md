# Current PH-Composer UI reference points

These paths identify accepted patterns. Reinspect them before reuse and extract shared components when the behavior truly matches.

Paths under **Local** are in this repository at `src/ph_composer/html/`. The UI kit registers modules with `PhComposerUI.define` and uses the `phc-` class prefix. Paths under **Predecessor only** are in `../ph-navigator-sketchup/src/ph_navigator_sketchup/html/` and have not transplanted; they are reference points for screens this repository will build (Assemblies, Library and Window Types arrive with Phase 2), not current files. The predecessor's Window Schedule, assigned-window propagation and designPH review screens do not transplant; their designPH-specific patterns are omitted here.

## Shared primitives (local)

- `workspace.js` is the `ui` facade over the shared layer; each part has one file: `dom.js` (elements, `svg`, `commandButton`, `memoPaint`), `icons.js` (the icon registry, which throws on an unknown name, icon buttons and state-aware icon painting), `overlay.js` (`Bubble`, `ActionMenu`, dialog action rows, `formDialog`, `floatingNotice`, tooltips), `table.js` (table presentation) and `view_controls.js` (filter, group and order controls, group headings; an optional `guard`/`refused` pair refuses a filter edit while a draft would be hidden).
- `panel.js` owns the snapshot reducer, the one floating notice and the tabs. `panel.notify(message, tone)` raises a page-side notice; `panel.navigationGuard(name, guard)` lets a section refuse a tab change while it owns work in progress. `request.js` gives each view a request channel with one correlated result; `snapshot.js` reads the host snapshot a render receives.
- `overlay.js` with `overlay.css` (bubbles, action menus, notices, dialogs) and `base.css` (the interaction tokens on `:root` and the shared subtabs nav). Pass `tone` to `notice.show`: omitted means `info` (white), `warning` is yellow, `error` is red; `data-tone` carries it to CSS. Toolbar glyphs are Lucide outlines with the ISC notice kept beside them; take new glyphs from the same set. Classify each notice as transient or persistent: confirmations and ordinary information may fade on the next meaningful interaction; warnings, errors, and active-tool instructions remain until resolved or explicitly dismissed.
- `table.js` and `table.css`: shared table behavior. Header-edge separators provide mouse and keyboard column resizing; double-click and the Table options menu reset widths. Keep show/hide choices in that anchored menu, not in-flow controls. Use the shared cell-input and editable-cell classes so the table grid supplies the resting boundary and the cell supplies interaction emphasis. Focus styles and resized widths must preserve sticky offsets and never move identity cells unexpectedly.
- `overlay.js` `formDialog(className, onCancel)` and the form-dialog class in `overlay.css`: the modal for record forms. `record_form.js` is the lifecycle every record form shares: container, title, submit and Cancel order, status line, one single-flight request. `ui.table` passes the clicked row button as the third `action` argument so a bubble can anchor to the row that asked.
- Stylesheets, one owner each, linked in this order by `index.html`: `base.css` (tokens, page defaults, typography, shared controls and navigation), `overlay.css`, `shell.css` (the shell, the Export section and the status bar), `table.css`, `features/zones/zones.css` (the Zones / Faces screen, the Zone details form and the Colour-by legend). A screen's override of a shared primitive carries that screen's scope class so specificity, not link order, decides it.
- `unit_field.js` `UnitField`, `units.js`, `unit_preferences.js` and `fields.js`: every unit-bearing input and its stored-field descriptor.

## Accepted screen patterns (local)

- Zones / Faces: `features/zones/overview.js`, `features/zones/zones.css`. The Zone tree as a shared table, Face rows beneath their Zone, type and boundary edited in place as chips, Locate and Suggest classification as row actions. The selected Zone's fields are a form beneath the table with Save and a whole-form Cancel. One draft at a time: while the form is dirty or its Save is pending, selecting another row, filtering and changing tabs are refused with a warning notice and focus returns to the form.
- Attached-zone inline creation: `features/zones/attached_zone_assignment.js` and `features/zones/attached_zone_fields.js`. A `formDialog` opened from a Face's boundary chip; Cancel leaves the chip unchanged, a refusal keeps the draft, success closes and restores focus to the chip.
- Classify tool and palette: `features/zones/classify.js` in the panel and the viewport tool in `src/ph_composer/features/zones/faces/classify_tool.rb` with its native menu. The drawing-tool state rule applies: pressed control, icon and cursor change together, Escape unwinds one layer, and a refusal is a warning notice.
- Colour-by legend: `sections/colour_by.js`. Rows come from the shared service's legend, so a new mode needs no line here.
- Export: `sections/export.js`. A running export locks tab changes through the navigation guard and keeps its progress and Cancel visible.

## Accepted screen patterns (predecessor only)

- Assembly Builder: `assembly_editor.js`, `assembly_canvas.js`, `assembly.css`. Use for compact toolbars, header metrics, contextual inspectors, crisp drawings, insertion controls, and anchored editors.
- Library and library sidebar: `sections/library.js`, `library_sidebar.js`, `library.css`. Use for browsing density, source status, filters, row selection, and collapsible sidebar behavior. The sidebar is provider-agnostic: it shows a provider's name and connection state, never its address.
- Library tabs: `sections/library.js` and `window_inventory.js`. One page heading for every tab; each tab body opens with the shared action bar (view controls, tab settings, then "+ New") and keeps it to one line at 1280 px. Record forms use `formDialog`; a record's uses open in a bubble anchored to its row action.
- Window Types: `window_editor.js`, `window_canvas.js`, `windows.css`. Use for the page-header action hierarchy, title and metrics, floating notices, contextual drawing tools, selection treatment, edge inserts, single-value dimension bubbles and the adapted collapsible sidebar.
- Spaces table: `spaces_table.js`, `sections/spaces_workspace.js`, `cell_edits.js`, `spaces.css`. Use for tree tables, the Level rail, saved table layout, range edits and Locate.
- Consequential multi-step review: the assigned-window resize in `window_editor.js` and `windows.css`. Use the shared dialog treatment for a review the user must read before committing, including modal Escape cancellation and trigger-focus restoration without work-surface reflow. Only the dialog shape carries over.

## Patterns still to be established

- Window placement: a viewport tool from a Window Type. The predecessor proved the anchor grammar and the placement transaction; its panel affordance was minimal.
- Thermal bridges: edge and point picking in the viewport plus a schedule. No accepted pattern yet.

Record each here once the owner accepts a screen.

## Shared visual semantics

- `--interaction-highlight`: interactive borders, selected controls, active sidebar rows and selected drawing elements.
- `--interaction-highlight-hover`: stronger hover and active emphasis.
- `--interaction-highlight-tint`: low-contrast selected backgrounds, including the selected drawing element fill.
- `--drawing-highlight`: drawing hover, keyboard focus, insertion geometry and drop targets; never selection.
- `--drawing-highlight-halo`: focused or hovered drawing affordance halo.
- `--line`, `--muted`, `--surface`: neutral structure and hierarchy.

Do not create a feature-local substitute for these semantics without evidence that the shared token is wrong app-wide.
