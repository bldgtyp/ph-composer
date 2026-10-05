# Zones / Faces: table-first layout

Implemented on branch `feature/zones-table-first`; host acceptance passed 2026-10-04, awaiting merge. The Zones / Faces screen becomes one full-width table with no inspector column. Zone fields
become columns, Colour by moves into the column headers, sort and filter move into column menus,
Select becomes a checkbox set separate from Locate, and a floating bar over the table edits that
set and holds the Classify palette.

Read [PRD.md](PRD.md), then [PLAN.md](PLAN.md) (decisions and stages, with one document per stage in
`phases/`), then [STATUS.md](STATUS.md). [mockup.png](mockup.png) is the static mockup
Ed accepted on 2026-10-04, with one refinement: the header icons appear only on hover (PRD,
"Column header actions").

In: the Zones / Faces pane; a header-action contract on the shared table (`table.js`); a column-menu
contract for sort and value filter; moving the Colour-by mode control and legend off the inspector;
a checkbox selection set split from Locate, with one-way sync from SketchUp's selection; a
floating selection bar in the overlay layer; row and header icons hidden until hover.
Out: the Assemblies, Window Types and Library screens (they keep their layouts); new Colour-by modes;
legend hover-to-highlight ([its own packet](../legend-hover-highlight/README.md)).

Came from the Zones / Faces polish session on branch `feature/zones-faces-polish`. That branch's
first note (the Assembly chip takes its Assembly's colour, commit `d0b07ea`) is independent of
this packet.
