# Zones / Faces: table-first layout

DATE: 2026-10-04
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## Problem

The Zones / Faces pane splits its information between the Zone tree and an inspector column. The
inspector holds, by tier: the Classify palette, the Face selection (Type, Boundary, Assembly for
every selected Face), the selected Zone's fields (name, Building-Segment, Level, ground depth) as a
form with Save and Cancel, the Colour-by legend, and an always-on hint that keeps the column
standing. Colour by is a separate select in the control row. To see a Zone's Level the user selects
the Zone; to colour the model by the thing a column shows, the user goes to a different control.

Ed's direction (2026-10-04): put all the data in the table, embed Colour by and filtering in the
column headers, and drop the right-hand column.

## Behavior

### Columns

- Zone rows gain Building-Segment, Level and Ground depth columns, edited in place like any
  editable cell (type to edit, Enter or leaving applies, Escape restores). Face rows leave them
  blank. Ground depth is a unit-aware length column, shown by default.
- The Zone name edits in place in the Name column.
- Each committed cell edit is one operation and one Undo step, as the Zone form's Save is today.
  The Zone details form, its draft hold on the inspector, and the "one draft at a time" navigation
  refusal for that form are removed; a cell edit carries no draft beyond the cell.
- With the inspector gone the table spans the pane. At narrow widths it scrolls sideways with the
  identity columns (Actions, Hierarchy, Name) sticky.

### Column header actions

- A column that has a Colour-by mode carries a colour-by icon toggle in its header: Name (Zone),
  Building-Segment, Level, Type (Face type), Boundary (Boundary condition), Assembly.
- One mode at a time. Pressing a column's toggle turns its mode on and releases any other; pressing
  the pressed toggle turns Colour by Off. The toggle is `aria-pressed`, named "Colour by <mode>".
- The Assembly header's toggle offers two modes, Assembly and Window Type, in an anchored menu;
  the toggle reads pressed while either is on, and the legend names which. Ed chose to keep every
  Colour-by mode on this screen rather than putting Window Type on the Window Types tab.
- Header icons are hidden at rest and appear while the pointer is over that header cell or focus
  is inside it. Two states stay visible at rest because they are state, not affordance: a pressed
  colour-by toggle, and a column with an active filter (its filter glyph).
- A column menu (ellipsis) holds Sort A to Z, Sort Z to A, and a value checklist filter with Clear
  filter. It replaces the Order by select and the sort-direction toggle. The text filter field stays
  in the control row. The count reads "2 Zones · 1 filter" while a column filter applies.
- Filtering hides rows and never drops records, as `ui.ViewControls` does today.

### Legend

- While a mode is on, the control-row slot that holds the Colour by select today holds the legend:
  the mode's name, then one chip per value with its count. Empty when Colour by is Off. The slot
  keeps its place so the table never moves.
- The legend's existing affordances stay: a chip selects and zooms to what it counts; Isolate fades
  the rest, with Show all while one value stands alone (decision Q3 settles which gesture is which).

### Select and Locate

Select and Locate are separate operations. Select builds a set of rows for a bulk assignment.
Locate drives the SketchUp scene. Ed's direction, 2026-10-04.

- A checkbox column, first in the table, holds the checked set. A Face row's box checks that Face;
  a Zone row's box checks every Face under it and reads mixed when only some are checked. The
  header box checks every visible Face row and reads mixed when some are. Shift-click checks the
  range between the last box clicked and this one. Unclassified Face rows can be checked.
- The checked set belongs to the panel. It can span Zones, and checking rows never changes
  SketchUp's selection. SketchUp's selection only holds entities in the open edit context
  (`context/SKETCHUP_HOST_BEHAVIOR.md`, `Selection#add`), so a mirrored set could not span Zones.
- One-way sync from SketchUp: when the SketchUp selection changes, the checked set is replaced by
  the Faces now selected there, and an empty selection clears it. Selecting geometry first and then
  choosing what to do to it stays the primary route.
- Locate frames the camera on the row's Faces (a Zone row: the Zone) and highlights them in the
  viewport overlay. It no longer changes SketchUp's selection, so it never replaces the checked set.
  Today Locate selects; this changes the `ph_composer.zones.faces.locate` view command, which
  agents also call (`context/AGENT_INTERFACE.md`, "explicit selection, reveal and camera
  operations").
- Row icons (the checkbox, Locate, Suggest classification) are hidden at rest and appear while the
  pointer is over the row or focus is inside it. A checked box stays visible, and while any row is
  checked every row shows its box, so adding to the set is obvious.
- Escape clears the checked set as its own layer: an open bubble or menu first, then an active
  tool, then the checked set.

### Floating selection bar

- While any Face is checked, its rows take the selection tint and a bar floats over the bottom of
  the table in the overlay layer: "N Faces selected", then Type, Boundary and Assembly controls,
  then a clear icon. Each choice applies to every checked Face as one Undo step; a value they do
  not share reads Mixed. These are the selection inspector's rules today, moved, and acting on the
  checked set instead of the SketchUp selection. Assembly is disabled with its reason while an
  unclassified Face is checked.
- While the Classify tool is on, the same bar holds the Classify palette. The drawing-tool state
  rule is unchanged: pressed button, icon and cursor change together; Escape unwinds one layer.
- The bar never reflows the table. It keeps clear of the last rows by padding the scroll area by its
  own height while it shows.

### What goes

The inspector region on this pane, the Zone details form, the Colour by select, the inspector
legend, and the ambient hint (its text moves to a help button in the control row).

## Contracts this changes

- `context/TECH_STACK.md`, panel rules: "One work surface per pane, with an inspector beside it"
  becomes a choice a pane makes, and the floating selection bar becomes a kit part.
- `table.js`: a column declares header actions. The Colour-by toggle binds a column to one or more
  registered mode names; the table names no mode and no feature. A feature owns the binding for its
  columns.
- `sections/colour_by.js`: the mode control and legend become parts a pane places, not an inspector
  section and a `tools` section.
- The UI polish skill's `references/patterns.md` Zones / Faces entry, the inspector tiers it cites,
  and the comment at `overview.js` "The selected Zone's own fields" record the old rule and change
  with this packet.

## Open decisions

- Q1. Registered modes with no column here. The mode registry is open: Spaces, Thermal bridges and
  contributors will add modes. If the Colour by select goes, a mode with no bound column has no
  route. Proposed: the table's options menu lists every mode not bound to a visible column.
- Q2. How the Assembly header reaches Window Type without Zones naming a windows mode id. Proposed:
  a mode declares a grouping key at registration (for example `:group => "construction"`) and the
  column binds to the group.
- Q3. Legend chip gestures. Today a row click selects and zooms and Isolate is a separate button.
  Proposed: click selects and zooms; an isolate icon appears on chip hover.
- Q4. Whether the Unclassified summary rows are a value in the Type and Boundary filters (the
  mockup shows "Unclassified" as a filter value).
- Q5. Does a selection bar replace any other pane's inspector later, or is it a Zones-only part for
  now? It should be built in the kit either way.

- Q6. Bulk edits on Zones. Checking a Zone row checks its Faces. Should checked Zones also get the
  bar's Building-Segment, Level and Ground depth controls, and how does a mixed Zone and Face set
  read?
- Q7. Checked rows a filter hides. Proposed: they stay checked and the bar says how many are hidden
  ("5 Faces selected, 2 hidden"), so an assignment never reaches Faces the user cannot see without
  saying so.
- Q8. How long the Locate highlight lasts: until the next pointer or keyboard interaction, or a
  fixed time.
- Q9. The Assemblies tab's "Select faces using <Assembly>" action calls Locate today. Under this
  split it could check those Faces in the Zones table, frame them, or both.

The open bug [locate-outside-zone-selection](../../../bugs/locate-outside-zone-selection.md) is
about Locate's selection reaching the inspector. If Locate stops selecting, that bug's symptom goes
away with this packet; settle it here or close it as superseded when this lands.

## Acceptance

- Offline: focused panel tests for header toggles (one at a time, pressed off returns Off), hover
  reveal leaving pressed and filtered states visible, column-menu sort and filter, Zone cell edits as
  single operations, checkbox states (Zone and header mixed, Shift range, hidden-at-rest rules),
  SketchUp selection replacing the checked set, Locate leaving the set alone, the selection bar's
  Mixed and one-Undo rules, Classify in the bar, Escape
  layering; `make ui-checks` at the four panel sizes with no sideways page scroll.
- Host: the Zones / Faces walkthrough in SketchUp covering each Colour-by column, Window Type from
  the Assembly header, a viewport selection and a checked set across two Zones edited from the bar,
  Locate framing without selecting, the Classify tool, and a narrow
  panel.
