# UI and UX refinement: findings

DATE: 2026-10-03
STATUS: Scoped; D1 to D7 ruled 2026-10-03
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## Summary

The individual editors are in good shape. The Window Type Builder is the strongest screen: a clear
title, two named metrics, an icon toolbar, one filled primary action, a crisp drawing. The
weakness is that the app does not yet read as one application. Each tab frames its page
differently, the first screen a new user meets stacks four jobs in one column, and three screens
break rules the ui-polish skill already states.

The four findings that matter most:

1. **Every tab has a different page frame (K1, K2, K3).** Five header treatments, two gutters and
   two primary-button styles across five tabs. This is the largest single cause of the app
   feeling unfinished, and it is one kit-level fix.
2. **Zones / Faces stacks four jobs in one scroll (Z1, Z2).** The table, the Zone details form,
   Colour by and the Classify palette sit one under another. At 1280 by 800 with a Zone selected
   the Classify palette is below the fold. This is the first screen of the first flow.
3. **The Installs editor is not at the standard of the screen it opens from (W4).** Labels
   overlap in the drawing, Save and Cancel sit below the visible area, and subtab clicks are
   refused with no message.
4. **Nothing tells the user what is left to do (F3, X1).** Incompleteness shows in four different
   ways on four screens, and Export, where the flow ends, does not summarise it.

Severity: **High** misleads or blocks a flow; **Medium** is friction on every use; **Low** is
polish. "Verified" means checked in the live preview by script, not only read from a capture.
Captures are named under `planning/ui-baseline/screens/current-2026-10-03/`.

## Kit-wide

| Id | Sev | Finding | Evidence |
| --- | --- | --- | --- |
| K1 | High | Five page-header treatments. Zones: small "Zones 2" with a grey count. Assemblies and Library: a very large heavy "Assemblies · 2" with a caption. Window Types: no page heading, the pane opens on subtabs. Export: a padded heading over a rule. Assembly Builder: a Back button, then the title as a permanent input. | `tabs/inventories--assemblies.png`, `tabs/authoring--zones-faces.png`, `flows/A1-…-1280.png`, `tabs/authoring--export.png`, `flows/B2-…-1280.png` |
| K2 | High | Two page gutters. Zones, Assemblies and Library content starts at the panel's left edge and their right-hand buttons touch the right edge. The tab row, Export and the builders are inset. | Same captures |
| K3 | Medium | Two primary-action styles. "Place" is filled teal. "+ New Assembly" and "+ New Material" are outline buttons, indistinguishable from secondary ones. In Library "+ New Material" floats mid-header and "Export library" takes the primary position at the right. | `tabs/inventories--library--materials.png` |
| K4 | Medium | "Definitions stored in this model." sits under the title on Assemblies and Library, and "Assignments belong to this Window Type." under Installs. The skill bans a constant caption under a title. The Library heading count ("Library · 2") is the active subtab's count shown as the page's. | Same |
| K5 | Medium | Table chrome is three rows before the first record: the heading, a row of four labelled view controls (Filter, Group by, Order by, Direction), then fill-down, fill-right and a permanent keyboard hint. With two records the chrome is taller than the data. The baseline ruled Keep on this row, so changing it is D2. | `tabs/inventories--assemblies.png` |
| K6 | High | Narrow panels lose navigation. At 420 wide the tab row scrolls sideways with no affordance, so Library and Export are off-screen (verified: row is 540 wide in a 337 box). At 900 "Export" is clipped under the IP/SI switch and the two-word Planned tabs wrap to three lines. At 1280 three Planned tabs take about a third of the row. | `flows/A1-…-420.png`, `flows/A1-…-900.png` |
| K7 | Medium | Three treatments for an enum cell: plain selects in Zones, grey pill selects in Assemblies, coloured pill selects for Material category. The baseline calls for coloured chips with a chevron throughout. | `tabs/authoring--zones-faces.png`, `tabs/inventories--assemblies.png`, `tabs/inventories--library--materials.png` |
| K8 | Low | Assemblies cells repeat the unit the header already carries ("165 mm" under "Thickness mm"). Zones follows the rule (bare numbers). The builders' metrics put the unit in the value too, where the Window Type header puts it in the label. | `tabs/inventories--assemblies.png`, `flows/B2-…-1280.png` |
| K9 | Medium | The library sidebar draws its own heading ("Material Library"), its category headings ("Insulation", "Woods") and its records as the same bordered button, so groups and records cannot be told apart. | `flows/D2-library-provider-selected.png` |
| K10 | Medium | Empty states are uneven. Zones and the Window Schedule name the next step. Assemblies says "No Assembly records match this view", which reads as a filter miss. Window Types with no Types shows two empty library panels and no prompt at all. | `tabs/empty--assemblies.png`, `tabs/inventories--window-types--window-types.png` |
| K11 | Low | Dialog action icons: "Add library file…" carries a check mark though it opens a file picker. In the Libraries dialog the "Other provider" row has no state and no action. | `flows/D4-library-setup.png` |

## Zones / Faces

| Id | Sev | Finding | Evidence |
| --- | --- | --- | --- |
| Z1 | High | Four peer jobs stacked in page flow: the Zone tree, the Zone details form, Colour by and Classify faces. The skill says not to stack an editor after an inventory and to give peer jobs subtabs or one work surface at a time. Selecting a Zone inserts the form and pushes Classify below the fold; turning Colour by on pushes it further. At 420 wide Classify starts two screens down. | `flows/E2-…-1280.png`, `flows/E5-colour-by-face-type.png`, `flows/E1-zones-420.png` |
| Z2 | Medium | The Classify palette is always open and wordy: four groups, "blank keeps what each Face has" three times, and two explanations drawn as disabled buttons ("Attached zone · choose a record below", "Surface · set by Solve adjacencies"). In an empty Model it shows in full for Faces that do not exist. | `tabs/empty--zones-faces.png` |
| Z3 | Medium | "Make Zone" is the first action in the app and is greyed with its reason only in a tooltip. The skill asks for the reason beside a blocked primary action. | Same |
| Z4 | Medium | State is hard to read. The Zone row carries an amber count that means "unclassified Faces" and says so only in a hover tooltip. An incomplete Face says "Incomplete" in plain text in the far-right State column, away from the empty Boundary cell that is the actual gap. The skill asks for the flag on the cell that needs input. | `tabs/authoring--zones-faces.png`, `features/zones/overview.js` |
| Z5 | Low | Every Face row has an expand chevron; in the fixture it reveals nothing (verified: no rows added). The Hierarchy column repeats "Face" on every row. | `flows/E4-face-expanded.png` |
| Z6 | Medium | An unclassified Face is not a row. That is a recorded Phase 1 decision (archive `phase-01-faces-and-zones/PLAN.md`, "Two narrowings"): the Zone row carries the count and Suggest classification. The cost is that the tree is not the complete list of what is left, and a Face the user wants to classify by hand cannot be reached from the table. See D4. | `tabs/authoring--zones-faces.png` |
| Z7 | Medium | Selecting Faces inserts a "2 Faces selected · Choose Assembly" row above the view controls and moves the table down. The skill asks for a still work surface. | `flows/C1-assignment-zones.png` |
| Z8 | Low | The Zone details fields render in grey and read as disabled. Save and Cancel show before anything is edited. The settings button is an unlabelled glyph. | `flows/E2-…-1280.png` |

## Assemblies

| Id | Sev | Finding | Evidence |
| --- | --- | --- | --- |
| A1 | Medium | Each inventory row carries six unlabelled icons in an Actions column about 200 wide. Three act on Faces in the Model (select, paint, replace) and sit beside three record actions with no grouping. The Replace glyph is an undo arrow. The skill puts per-record Rename, Duplicate and Delete on hover and keeps the row quiet. | `tabs/inventories--assemblies.png` |
| A2 | Medium | The builder's toolbars are two rows of nine text buttons, four of them disabled until a selection exists. The skill asks for a compact icon toolbar and for only the actions the selection can use, which is what the Window Type Builder does. "Material Library" appears as a toolbar button and again as the sidebar heading. | `flows/B2-…-1280.png` |
| A3 | Low | The builder title is a permanent input box and "Back to Assemblies" sits to its left, pushing the title off the page's left edge. The skill's rule is rename in place. | Same |
| A4 | Medium | At 420 wide the drawing is cut off at the right with no scroll cue and the toolbars wrap to four rows. | `flows/B2-…-420.png` |

## Window Types

| Id | Sev | Finding | Evidence |
| --- | --- | --- | --- |
| W1 | Medium | The "Anchor" control sits above all three subtabs. It is a setting of Place and has no meaning on U-Values or Schedule. The skill puts configuration for the primary action in a bubble beside it. | `tabs/inventories--window-types--schedule.png` |
| W2 | Medium | Sidebar names truncate to "Single o…" and "Three el…" although the rail is 180 wide (verified: the label gets 78). At 900 the rail is clipped to a sliver showing "S", "T", "T" instead of collapsing. | `flows/A1-…-1280.png`, `flows/A1-…-900.png` |
| W3 | Medium | Two library sidebars (Frame, Glazing) stand side by side and take about 40 percent of the width at 1280; the Glazing one runs off the right edge. | `tabs/inventories--window-types--window-types.png` |
| W4 | High | The Installs editor. Element labels and edge values overlap in the drawing. The heading is flush to the panel edge with a constant caption. Save Installs and Cancel Installs sit at y 785 of an 800-high panel, under the status bar (verified). While it is open, clicking a subtab does nothing and says nothing, and Escape does not leave (both verified). The thick blue dashed edges are a third highlight colour outside the two the kit defines. | `flows/A3-window-installs-1280.png` |
| W5 | Low | An Empty element is plain white with no mark that it is a deliberate state. | `flows/A1-…-1280.png` |

## Library

| Id | Sev | Finding | Evidence |
| --- | --- | --- | --- |
| L1 | Medium | With the source set to "In this file" the sidebar lists the same records as the table beside it. The sidebar earns its width only once a provider is chosen. | `tabs/inventories--library--materials.png` |
| L2 | Medium | Nothing on a provider record says how to copy it in. It is a bordered button with no verb, icon or hint. | `flows/D2-library-provider-selected.png` |
| L3 | Medium | New Material opens an empty form with Create disabled and no sign of which fields it is waiting for. The skill says two things here: record forms open in the shared dialog, and New acts at once under a default name with round defaults. They conflict. See D5. | `flows/D5-new-material.png` |

Replace-and-delete for a Material in use is clear and well worded. Keep it as the pattern.

## Export

| Id | Sev | Finding | Evidence |
| --- | --- | --- | --- |
| X1 | High | Export is one sentence and one button. It is where the flow ends and where the user should learn what is incomplete, with a route back to each gap. Confirmed in the host on 2026-10-03: a Model with twelve Faces and no Assemblies lists twelve rows of "Face fac_c3d5e3f176e1 needs an authored Assembly", each with Locate. The record id is on screen, which the skill's words rule forbids, and one cause is repeated per Face instead of grouped. | `tabs/authoring--export.png` |

## Across flows

| Id | Sev | Finding |
| --- | --- | --- |
| F1 | Medium | No orientation for a first run. The tab order implies a sequence, but nothing marks where the user is in it, and three Planned tabs interleave with the working ones. |
| F2 | Medium | Assigning an Assembly to Faces has four routes: the per-row select in the Zone tree, the "Choose Assembly" bar on a multi-selection, the Assembly select in the Classify palette, and Paint from an Assemblies row. The skill's rule is geometry first, then action. One route should be primary and the others visibly secondary. See D6. |
| F3 | High | Four vocabularies for "not finished": an amber count on a Zone, "Incomplete" in a State column, an amber dash for a U-value, and "· incomplete" appended to a Window Type's name in the sidebar. None is aggregated anywhere. |
| F4 | Medium | Viewport tools signal their active state differently in the panel. Classify turns its heading teal and adds "Stop classifying"; Place swaps to "Stop placing". Their viewport side is not captured yet. |

## Not findings

- The Colour-by legend in the captures shows "RoofCeiling", a duplicate "Wall" and identical
  swatches. The preview's stand-in host builds that legend, so check the real service in the host
  session before filing anything.
- "Example parts · Development only" under Zones / Faces is the development editor.

## Proposed packets, in order

Kit-wide first, because every later packet inherits the frame.

| # | Packet | Covers | Size |
| --- | --- | --- | --- |
| 1 | Page frame: one header, one gutter, one primary style, tab row at narrow widths | K1, K2, K3, K4, K6 | Medium |
| 2 | Table chrome and cells: view-control row, enum chips, units in headers | K5, K7, K8 | Medium |
| 3 | Zones / Faces layout: one work surface at a time, Classify as a tool | Z1 to Z8, F2 | Large |
| 4 | Installs editor | W4 | Medium |
| 5 | Window Types frame: Anchor, rail, library sidebars | W1, W2, W3, W5, K9 | Medium |
| 6 | Assembly Builder toolbars and inventory row actions | A1 to A4 | Medium |
| 7 | Library: sidebar role, copy-in affordance, New record | L1 to L3, K11 | Small |
| 8 | Completeness: one vocabulary, Export readiness, empty states | F1, F3, X1, K10 | Large |

Packet 3 and packet 8 change how a flow works, not only how it looks, so each needs a short
design step with Ed before code. Packet 3 and the viewport-tool pattern (F4) are where a few
Claude Design canvas explorations would help. The rest are applications of rules the skill
already has.

## Decisions

Ed accepted all seven recommendations on 2026-10-03.

| Id | Ruling | Lands in |
| --- | --- | --- |
| D1 | The standard page header is the Window Type Builder's scale: a moderate title, a muted count, actions at the right, no caption. Inventory pages take the same frame. | Packet 1 |
| D2 | The view-control row may change: keep Filter, fold Direction into Order by as a toggle, move the keyboard hint into the Table options menu. The baseline README is corrected when this lands. | Packet 2 |
| D3 | Planned tabs keep their pattern with shorter labels and sit after the working tabs. | Packet 1 |
| D4 | The Phase 1 decision that an unclassified Face is not a row is reopened. Unclassified Faces become rows flagged on their empty cells, collapsed under the Zone's count by default. | Packet 3 |
| D5 | New acts at once with defaults where the record draws something (Assembly, Window Type). Records that are only numbers (Material, Frame, Glazing, Psi-Install Type, Attached zone) keep a form, with required fields marked. The ui-polish skill states the split when packet 7 lands. | Packets 6 and 7 |
| D6 | The primary route for assigning an Assembly is select Faces, then one control. Paint stays as the secondary modal tool. The Assembly select leaves the Classify palette. | Packet 3 |
| D7 | The host capture session runs after packets 1 and 2. | After packet 2 |
