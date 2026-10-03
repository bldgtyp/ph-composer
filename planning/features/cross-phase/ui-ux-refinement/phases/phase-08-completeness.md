# Packet 8: completeness

DATE: 2026-10-03
STATUS: Plan; built under Ed's standing go of 2026-10-03
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

Covers findings X1, F3 and K10 in [FINDINGS.md](../FINDINGS.md), and rules on F1. The decisions
taken are listed for Ed's verification pass.

## Outcome

Export says what is left to do, once per cause, in the product's words, with a way back to each
gap. An empty screen names the next step. "Not finished" looks the same on the Window Types rail
as it does everywhere else. No command, payload, guard or Undo step changes, and nothing changes
in Ruby: the Export findings arrive as they do today.

## What is there today, re-measured on main

| Finding | On main today |
| --- | --- |
| X1 Export lists one row per Face, by record id | True. Each finding carries `code`, `message`, `blocks_export` and often `locate`. The message embeds the record id ("Face fac_c3d5e3f176e1 needs an authored Assembly."), and twelve Faces with one cause make twelve rows |
| X1 one sentence and one button | True. The button sits under the findings, and nothing says whether the Model is ready |
| F3 four vocabularies for "not finished" | Three remain. Packet 3 replaced the Zone tree's State column with flags on the cells. The Window Types rail still appends "· incomplete" to a name; Zones and Assemblies use an amber mark with a tooltip |
| K10 uneven empty states | True. An inventory with no records says "No Assembly records match this view.", which reads as a filter miss. Window Types with no Types shows an empty rail and no prompt |
| F1 no first-run orientation | True |

## Design

**Export readiness (X1).** The page opens with the kit header carrying "Choose destination…" as
its primary action, then one status line: "Ready to export." or "Finish 2 things before
exporting." Findings are grouped by cause (the finding's `code` and its message with the record id
taken out) and split into "Before exporting" (those that block) and "Worth checking" (those that
do not). A group shows its sentence once, the number of records it covers, one Locate that selects
all of them in the viewport, and a link to the tab where it is fixed. The record ids stay in the
row's tooltip for diagnosis. Repairs, progress, Cancel and the result summary are unchanged.

**The Window Types rail (F3).** An incomplete Window Type shows the amber alert glyph after its
name, with what is missing in its tooltip, in place of the "· incomplete" suffix. Its accessible
name still says it is incomplete.

**Empty states (K10).** An inventory with no records at all says what to do: "No Assemblies yet.
Choose + New Assembly." A filter that hides every record keeps the "match this view" wording.
Window Types with no Types says "No Window Types yet. Choose + in the Window Types list." where
the Builder would be.

## Decisions taken

| Id | Question | Decision |
| --- | --- | --- |
| P8-Q1 | Group Export findings in Ruby, with a summary sentence per cause? | Not here. It would change the Export findings contract and the generated API reference. The panel groups what it is given; a Ruby summary can replace the panel's wording later without changing the screen. |
| P8-Q2 | F1: add a first-run guide or a progress strip across the tabs? | No. The tab order is the sequence, Planned tabs now sit after the working ones, each empty screen names its next step, and Export says what is left. A guide would be a second place to keep in step with the screens. |
| P8-Q3 | Show a readiness count on the Export tab itself? | No. It would need the preflight to run on every Model change, which today runs only when Export is shown. |

## Files

`src/ph_composer/html/sections/export.js`, `shell.css`, `inventory.js`,
`features/windows/type_list.js`, `features/windows/editor.js`, `features/windows/windows.css`.
Then the manifests.

## Tests and gates

- Export: twelve findings of one cause paint one group with a count and one Locate carrying all
  twelve references; a blocking and a non-blocking cause land under their own headings; no record
  id is in the visible text; the status line and the primary action follow readiness.
- Inventory: the empty text differs between no records and a filter miss.
- Window Types: the rail's mark and its accessible name; the empty prompt.
- `make ci`, `make ui-checks`, one Sonnet diff review, a host check on a Model with Faces and no
  Assemblies.

## Not in this packet

Export findings wording at the source (P8-Q1). The viewport tools' active states (F4), which wait
for the D7 capture session.
