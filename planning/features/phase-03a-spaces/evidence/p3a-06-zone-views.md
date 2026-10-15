# P3a-06 evidence: Zone views

DATE: 2026-10-15
STATUS: Design note written and reviewed; implementation next on `feature/spaces-p3a-06`
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: [#133](https://github.com/bldgtyp/ph-composer/issues/133)

Register row S06. The contract is proposed in `context/EXTENSIBILITY.md`, "Zone views".

## Design review (step 1)

The view contract was written into `context/EXTENSIBILITY.md` first and reviewed against the
architecture rubric with the stage's three contributor tasks: move Faces onto it, add the Spaces view,
add an Occupancy view with no child rows. The review accepted the shape and asked for these, all
applied before code:

- **Persistence.** There is no per-Model panel preference, and view state must never be written to
  the Model (it would dirty it and add an Undo entry). The active view is session state initialised
  from a machine-wide preference written on each switch, as the last Colour-by mode is remembered.
  This resolves step 6's "per-Model" wording; it restores the view on reopen for a single-user tool.
- **One surface per view.** `subtabs.js` hands each tab its own surface, so each view gets its own
  table mount, and its widths and hidden columns are its own with no save and restore. The host keeps
  one controls row and swaps each view's column filters and sort (`ViewControls#columnFilters`,
  `#columnSort`) in and out of it on a switch; the text filter and expansion stay shared.
- **Registration.** Hosts declare themselves (`table_views.host(id)`); a view registered before its
  host is held and checked when the host declares; one whose host never declares is reported once
  the panel is ready; a duplicate id under one host refuses at `register`.
- **Locate** is the view's command (`locate(rows)`), with an optional `clearLocate` for a view whose
  Locate leaves an outline; the host owns the gestures that clear it. A navigation intent that checks
  rows names its view, and the host switches to it first.
- **Listing by sections.** A view is listed only while the snapshot publishes the sections it names,
  so a build without a feature shows none of its views with no composition-root line.
- **Which module names what.** `table_views.js` is a kit module and names no feature; Zones'
  `overview.js` is the host and may name Zones; `navigationGuard`, `outcomeText` and `workedOn` stay
  in the host.
- **Header.** The page header is built once a session; a switch repaints its settings slot from the
  new view.

Acceptance checks carried into the tests beside the plan's eight: a switch mid-paint stops the
Classify tool before its surface hides; a `check` intent from Assemblies lands in the Faces view; the
remembered view applies to a freshly opened Model; `make ui-checks` with both preview fixtures.
