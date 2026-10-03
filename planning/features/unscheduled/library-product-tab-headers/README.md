# Library product tabs use the pane heading

DATE: 2026-10-02
STATUS: Implemented on branch `feat/library-product-tab-headers` 2026-10-02; host look passed 2026-10-03 (ledger `PTAB`); awaiting review and merge (PR #46). See [PLAN.md](PLAN.md) "Implementation record". Scoped and decided (D1, D2) 2026-10-02.
A UI follow-up from the Phase 2 review's R10, which did not take it.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/38

## Why this packet exists

R10 ([R10](../../../archive/phase-02-envelope-review/R10-ui-kit-organization.md)) made every Library
inventory a registered surface. A surface can name a `createLabel`, and the Library pane then shows
that surface's "+ New" button in its own heading, beside "Export library". Materials and Attached
zones do this. The three Windows products (Frames, Glazings, Psi-Install Types) still open their tab
body with an `h2` title and their own "+ New" button (`src/ph_composer/html/features/windows/inventory.js`).

The UI polish skill says tabs inside one page share that page's heading, and a tab body starts with
its action bar, never with a second page title. So the Library pane shows two layouts depending on
the tab, and a contributor copying the Windows products learns the route the rule discourages.
R10 left it alone because it is a visible change that needs the polish review and a host look.

## Required behavior

- Each Windows product surface registers a `createLabel` ("+ New Frame", "+ New Glazing",
  "+ New Psi-Install Type") and gives its view `create()` and `canCreate()`. The in-tab `h2` and
  button go.
- The Psi-Install Types tab keeps its model-default settings, placed in the tab's action bar as the
  polish skill orders it.
- `context/EXTENSIBILITY.md` then drops "A surface may instead keep its '+ New' inside its own tab
  body", so the surface contract has one route.

- While the polish reference is open: `.agents/skills/ph-composer-ui-polish/references/patterns.md`
  still lists Window placement under "Patterns still to be established", but the screen exists
  (`src/ph_composer/html/features/windows/placement.js`). Move it to the local list with its path, or
  say what remains unaccepted. Added 2026-10-02 from R11's follow-ups.

## Verification

- `tests/window_inventory_test.js` and `tests/window_library_test.js` reach "+ New" through the pane
  heading; `make ui-checks` passes, with the Window library checks updated.
- A host look at the Library pane at 1280 and 420 px wide, through the polish skill's checklist.

## When to schedule

With the next Library or Window Types screen work, or before outside contributors are invited to add
Library surfaces. It depends on nothing else.
