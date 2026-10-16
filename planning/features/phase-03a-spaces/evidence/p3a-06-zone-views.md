# P3a-06 evidence: Zone views

DATE: 2026-10-15
STATUS: Implemented on `feature/spaces-p3a-06`, in review; host gate pending
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: [#133](https://github.com/bldgtyp/ph-composer/issues/133)

Register row S06. The built contract is recorded in `context/EXTENSIBILITY.md`, "Zone views".

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

## Implementation

Three commits after the design note and the kit part (`html/table_views.js`, `tests/table_views_test.js`):

- **Extract.** `features/zones/faces_view.js` takes the Face rows, Face columns and chips, the Classify
  column paint, the checked-Face bar, checked-Zone Solve, Locate and Escape out of `overview.js`, with
  the host still calling it directly. The 89 Zones and Assemblies panel tests and `make ui-checks`
  passed with no test or selector change.
- **Register.** Faces registers under `"ph_composer.zones"` and the host lists views from
  `table_views.host(...)`. Every hook takes the view's own state first; a view that leaves a hook out
  takes the host's default, so the synthetic view (`tools/examples/zones/example_zone_view.js`, Areas:
  two read-only columns, no rows beneath, no Zone cells) is complete with `columns` and `value`. One
  surface per view (`.phc-zone-view`, its own table mount, widths, hidden columns and menus); the
  shared controls trade the view's column filters and sort on a switch and keep the Zone filters and
  the text filter. The view row is `subtabs.js` with `aria-label` "Zone views" above the heading,
  hidden with one view listed. A switch is refused while a draft or Faces' Attached zone draft is open;
  otherwise it calls the old view's `leave` (Faces stops its paint tool and hides its bar), repaints
  the header's settings slot and writes the `table_view` display preference (new in
  `shell/preferences.rb`, keyed by host id, mirrored in `unit_preferences.js` and the preview host).
  The panel reports a view whose host never declares at ready. The tab reads "Zones", the reserved
  Spaces tab is gone, and the settings bubble is "Faces settings". Assemblies' "Select faces using"
  names the Faces view in its intent.
- **Locate.** S06 asks a switch to keep Locate: the outline outlasts it, and the host's clear gestures
  reach every view's `clearLocate`.

Selector and boot-list changes, each named: the Zones panel tests start `features/zones/faces_view`
(the host no longer depends on it); two browser checks scope `.phc-table-mount` to the shown view's
surface; the tooltip check drops the removed Spaces tab; label assertions follow the renames ("Zones",
"Faces settings").

Phase doc tests: 1 and 2 (`zone_views_panel_test.js`: row hidden with Faces alone, shown with two;
switch keeps the text filter, expansion, the checked set and the Locate outline and sends only the
preference), 3 (each view's column filters and sort survive a switch away and back), 4 (the Areas view:
Zone rows, no chevrons, no checkboxes, Collapse all disabled), 5 (`table_views_test.js` and the
unhosted report), 6 (a source check: the host names no view, the kit no feature), 7 (Escape layers in
`overview_panel_test.js`, plus Escape in the other view clearing an outline) and 8 (every existing
test and browser check). Also: a Model switch replaces the previous Model's surfaces; a remembered view
opens a new session; a navigation intent switches first.

Deviation, carried to P3a-07: H18 has the host keep "checked rows" across views. Here a view owns its
checked rows (Faces' set survives a switch away and back), because no second view checks rows yet;
a shared checked-Zone set lands with the Spaces view, the first view that checks Zones, and is a step
for P3a-07. Step 7's one-view preview fixture is covered offline (test 1); the preview always loads
the example so the browser checks exercise two views.

## Reviews

Code: Codex `gpt-6-astra` on #149. The first pass found four P1 (a native Attached-zone handoff and a
late-starting paint tool never reached a hidden Faces view; Assemblies' Paint started the tool without
showing Faces; the no-view fallback threw in Subtabs) and four P2 (a pointer press on a view tab cleared
Locate; a contributed column could not sort Zone rows; Table options hid Zone modes the shown view had
no column for; a view that stopped being listed skipped its departure). The fixes: every listed view
consumes each snapshot, views can be shown through `host.show` and view-only intents, `sortValue`, and
the departure path shared with switching. The second pass found one P1 (a view holding a draft was
replaced when its section was withdrawn) and four P2 (an invalid Faces settings entry did not hold a
switch; a Zone filter outlived its column in a view without it; the default viewport mask ignored the
view's `zoneMatch`; a filter-only column had no menu). Each of the thirteen was reproduced by a test in
`tests/zone_views_panel_test.js` and fixed; the second pass's five were gated by `make ci` and
`make ui-checks` only, at the review cap.

## Offline

`make ci` pass; `make ui-checks` pass (Playwright from a scratch `NODE_PATH`).

## Host

Not run. The S06 gate (fresh process, the synthetic view installed with
`PhComposer::Panel.add_development_script`, Classify paint stopped by a switch, the view returned after
reopening the panel and the Model, the Zones / Faces ledger cases repeated) is batched with the
S03 to S05 native rows. The ui-polish `references/patterns.md` entry waits for Ed's acceptance there.

