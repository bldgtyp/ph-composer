# UI and UX refinement

DATE: 2026-10-03
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

A dedicated pass on the panel's flows and visual consistency, run before further feature work.
Ed asked for it on 2026-10-03. The goal is an app a consultant can use without instruction, so the
unit of review is the consultant's task, not the tab.

## Read order

1. [FINDINGS.md](FINDINGS.md): the critique, ranked, with the evidence for each finding and the
   decisions Ed owes.
2. [STATUS.md](STATUS.md): what has run and what is authorized.
3. [phases/phase-01-page-frame.md](phases/phase-01-page-frame.md): the first polish packet's plan.
4. [phases/phase-02-table-chrome.md](phases/phase-02-table-chrome.md): the second packet's plan.

The rubric is `.agents/skills/ph-composer-ui-polish/SKILL.md`. The predecessor rulings are in
[`../../../ui-baseline/README.md`](../../../ui-baseline/README.md); where a finding here
challenges one of them it says so and waits for Ed.

## Method

1. Capture every tab, state and width from the preview page, which is the real panel on synthetic
   fixtures. Viewport surfaces (the Colour-by overlay and HUD, the Classify, Paint and Place tools)
   need a SketchUp session and are not captured yet.
2. Walk five flows end to end: empty Model to classified Zones and Faces; build an Assembly and
   assign it; build a Window Type and place it; copy records in from a library; export.
3. Record findings against the rubric, split into kit-wide and per-screen.
4. Ed reads the findings and rules on the open decisions.
5. Polish packets, kit-wide first, each run with the ui-polish skill and its host check.
6. Publish the settled kit as a Design System artifact and point the ui-polish skill at it.

Steps 1 to 4 are done for the panel. Nothing in step 5 is authorized.

## Evidence

Captures are in `planning/ui-baseline/screens/current-2026-10-03/`, which is gitignored:

| Folder | Holds |
| --- | --- |
| `tabs/` | Every fixture by every tab and subtab at 1280 by 800, named `<fixture>--<tab>--<subtab>.png` |
| `flows/` | Editors, dialogs, bubbles and tool states at 1280, 900 and 420 wide, named by the finding prefix they support |
| `capture/` | The Playwright scripts that produced both sets, and the script that verified three findings |

To recapture after a polish packet: start `make ui-preview`, install Playwright in a scratch
directory as `tools/ui-preview/.index.md` describes, and run `node crawl.cjs <out>` and
`node flows.cjs <out>` from that directory. The scripts are scratch tooling, not part of the
repository's checks.

## Scope

In: the HtmlDialog panel's layout, hierarchy, words, empty states, narrow-width behavior and the
consistency of the shared kit. The viewport tools' panel-side state.

Out: new features, changes to stored data or contracts, and the designPH-era screens that did not
transplant. Screens for Spaces and Thermal Bridges are designed in their own packets; this pass
supplies the frame they will sit in.
