# Packet 8: completeness

DATE: 2026-10-03
STATUS: Implemented; pull request open
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

## Outcome, 2026-10-03

Implemented on `feat/ui-completeness`. `make ci` and `make ui-checks` pass.

What differs from the plan above:

- F3 was misread in the findings. "· incomplete" on the Window Types rail was the name of a record
  in the preview fixture, not a suffix the panel adds; the rail gave an incomplete Window Type no
  mark at all. It now carries the amber alert glyph with what is missing in its tooltip, and the
  fixture record is named "Two elements".
- "Open <tab>" does not name features in the Export page. A feature registers the tab its records
  are worked on with `panel.workedOn(prefix, tab)` and Export asks `panel.tabFor(section)`. This is
  a new kit contract, written into `context/EXTENSIBILITY.md`. It is one tab per feature: a Material
  gap reported by the Assemblies export opens Assemblies, not the Library.
- One Locate carries at most 500 records and then reads "Locate first 500", because a viewport
  command may refuse a longer list (the Windows locate does).
- A finding's sentence keeps its full stop and any name the user typed. Only its own record id is
  taken out: the finding's `object_id`, or a token shaped like one.
- A failed preflight reads "The Model could not be checked." in place of a count.
- With no Window Type the two product library sidebars are hidden; they come back with the first.
- The inventory's empty text is "No Assembly records yet. Choose + New Assembly.", built from the
  label the inventory already has.

Because the diff adds a kit contract, the one review was a fresh-context Opus pass against the
architecture and ui-polish rubrics. Applied: a blocking defect where Export counted findings it
did not list once an earlier export was on record; Locate refused past 500 Windows; the id pattern
eating names the user typed; a fallback on finding codes that never matched and a document that
said it did; prefixes matching past a dot; ids missing from the tooltip for findings that carry
them in `object_id`. Not taken: routes finer than one tab per feature, keeping the header's
buttons across repaints so they keep focus, a `createLabel` passed to the inventory.
