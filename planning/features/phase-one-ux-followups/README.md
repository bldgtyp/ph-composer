# Phase 1 UX follow-ups

DATE: 2026-09-30
STATUS: Requested; principle and Z4 decided 2026-09-30. Items to resolve before Phase 2 (Assemblies) starts. Nothing here is authorized for
implementation yet.
AUTHOR: Ed May, BLDGTYP
ISSUE: none (local planning draft)

Ed's notes from his first hands-on pass over the merged Phase 1 build (SketchUp 26.1, macOS), recorded
on 2026-09-30. Where a note asked a question, the answer from the current source is recorded under it.
Item owners are the existing packets: [zones-and-adjacency](../zones-and-adjacency/README.md),
[face-assignment](../face-assignment/README.md) and the shared Colour-by service
(`src/ph_composer/colour_by/`).

## UX principle: geometry first, then action

Confirmed by Ed on 2026-09-30. The default order is to select geometry, then choose the action.
Painting with a modal tool (action first, then geometry) stays available, but it is the secondary
route; a feature may make it primary only when its plan records why the UX is demonstrably better.
Each attribute (face type, boundary condition, later Assembly) is set on its own, against the
current selection. Folded into `context/TECH_STACK.md` ("Rules for later features") and
`.agents/skills/ph-composer-ui-polish/SKILL.md`.

## Zones

| ID | Item | Current behavior (source) | Kind |
| --- | --- | --- | --- |
| Z1 | Add **Make Zone** to the right-click menu when the selection is valid (one Group, or loose Faces and Edges), under the PH-Composer submenu | Make Zone is reachable only from the panel and the public operation; the zones feature declares no `menu_item` for it. `Commands.install_feature_menus` already builds context submenus from declarations with an `available` check, so this is a declaration plus an availability test | Build |
| Z2 | Keep the Zone name in sync both ways with SketchUp's own name, as shown in Entity Info and Outliner | Research first. Today the Zone record's `name` is the authority. It is written to `group.name` on Make Zone and on a Zone update (`features/zones/zone/steps.rb:34`, `:78`), and nothing reads it back: a rename in Entity Info or Outliner leaves the record, the Overview and the export on the old name. Questions for the research: can an entity observer catch the rename reliably (including Undo/Redo, copies and components); should the Group name become the single source instead of a copy; how does a native rename interact with the operation revision and stale-edit refusal; do Outliner renames raise the same events | Research |
| Z3 | Right-click on one or more selected Zones offers Building-Segment, Level and the other Zone attributes directly | Not offered. `ClassifyMenu.classifiable?` deliberately returns false when a Zone Group is selected at the Model root, so right-clicking a Zone today shows only SketchUp's own items plus Colour by. Needs a multi-Zone edit path (one Undo step, refusal if any target is stale) | Build |
| Z4 | Make Zone optionally runs Suggest classification straight away. A preference switches it on or off; the angle thresholds may be settable | Not done: Suggest classification is a separate action. Its thresholds are fixed at honeybee's defaults: tilt of 60° or less from up is a Roof, 130° or more is a Floor, anything between is a Wall (`features/zones/faces/geometry.rb:15`). **Decided 2026-09-30:** on by default, with the switch and both thresholds (default 60° and 130°) settable by the user in a settings menu. Make Zone plus Suggest should be one operation and one Undo step; two Undo steps is acceptable if one would cost significant work. Settings live in the Zones / Faces tab's settings (Z5) and are stored **per model** (decided 2026-09-30). Because they are stored in the SKP, changing one is a Model write: a registered operation with its own Undo step, open to agents like any other. The panel's display preferences stay per user | Build |
| Z5 | Rename the **Overview** tab to **Zones / Faces**, and give it a settings control: a gear icon at the right end of the tab's action bar that opens a settings popover. First contents are Z4's switch and thresholds | Decided 2026-09-30. The gear is chosen over a "…" menu: the UI-polish skill already puts tab settings in the tab's action bar, and keeps the "…" overflow menu for infrequent lifecycle and destructive actions. Later tabs follow the same pattern. The rename also updates ruling U1 in [ui-baseline](../../ui-baseline/README.md) and every Overview label in the panel, docs and acceptance walkthroughs | Build |

## Classify faces

| ID | Item | Current behavior (source) | Kind |
| --- | --- | --- | --- |
| C1 | Give the Classify tool its own cursor icon | The tool defines no `onSetCursor`, so SketchUp keeps whatever cursor the previous tool left, which is how an Orbit or Rotate cursor shows up | Build (small) |
| C2 | With Faces already selected, choosing a value from the right-click menu applies it to the **selection** at once. Painting stays as the secondary route | Choosing a menu value only loads the palette and starts the paint tool (`ClassifyMenu.declare` calls `classify_tool.choose`); nothing is written to the selected Faces. Needs a selection-scoped write under the existing 250-Face ceiling and one Undo step | Build (follows the principle above) |
| C3 | Remove "Keep what the Face has", or rethink it | It does something, but only because the palette carries a face type **and** a boundary condition at once, and each paint gesture writes both. "Keep" means "leave this field alone when I paint". Once C2 makes each attribute a separate action on the selection, the Keep items have nothing left to do and should go. In the tool, the palette state they stand for could stay as the default for any field not chosen | Resolve with C2 |
| C4 | "Stop classifying": clarify it or remove it | It ends the paint tool (`classify_tool.stop`), the same as pressing Escape or picking another tool. The label is unclear, and it appears on every Face right-click even when the tool is not running. Remove it, or show it only while the tool is active under a label such as "Exit Classify tool" | Build (small) |
| C5 | Setting the boundary condition to an Attached zone from the right-click menu | Not offered there, by design at the time: Attached zone is left out of the native menu because it needs a record picker (`classify_menu.rb` header). Today it is only reachable from the panel's Classify palette: the Attached zone picker, including "New attached zone". Proposal: one menu item for each existing Attached zone record, plus "New attached zone…" opening the panel form, all applied to the selection as in C2 | Build |

## Solve adjacencies

| ID | Item | Current behavior (source) | Kind |
| --- | --- | --- | --- |
| S1 | How does the user trigger Solve adjacencies? | Today only in two ways: as the "Solve stale adjacencies before export" repair checkbox in the export preflight (`features/zones/export.rb:44`), and through the public operation `ph_composer.zones.solve_adjacency`. There is no panel button and no menu item. That is a gap against the PRD ("runs only when asked; validation offers it again"). Proposal: a panel action in the Overview, plus a right-click item on selected Zones ("Solve adjacencies for selected Zones"), with the whole-model form in the panel | Build |
| S2 | What is "Add Snaps"? | Not PH-Composer's. The source declares no such item; it is SketchUp's own Snaps feature, which adds a context-menu entry for Groups and Components. No action is needed | Answered |

## Colour by

| ID | Item | Current behavior (source) | Kind |
| --- | --- | --- | --- |
| K1 | Colour Faces only, not their edges, so SketchUp's native selection highlight stays visible. The Outdoors blue is nearly the same as SketchUp's selection blue | The overlay draws each Face's fill and then its outline in the same hue (`colour_by/overlay.rb`, `draw_outlines`), so a selected Zone's blue selection edges are painted over. Proposal: drop the coloured outlines for classified Faces and keep only the fills. Keep the unclassified outline and hatch, which have no fill and would otherwise vanish, but move them off selection blue. Check that the Face type and boundary condition palettes don't collide with SketchUp's selection, hover and inference colours. Recheck A08 fill legibility and occlusion without outlines | Build |

## Next step

The principle, Z4 and Z5 are decided. Z2 needs its research. Then this list gets a GitHub issue and
splits into an implementation slice of the Build items, which runs through the native acceptance
cases in the Zones and Faces owners.
