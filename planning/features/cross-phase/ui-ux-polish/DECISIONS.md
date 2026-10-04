# UI and UX polish: decisions

DATE: 2026-10-04
STATUS: Decisions taken on Ed's behalf during implementation, 2026-10-04; open to veto.
ISSUE: none (local planning draft)

## Settled direction

Ed requests end-user-centered design, progressive disclosure and a consistent UI grammar;
authorizes designer pushback; asks for applicable Assembly Builder parity with the predecessor;
and includes updates to the Design System and polish skill. The present authorization covers
organizing and committing planning documents. On 2026-10-04 Ed asked for every UI update in this
packet to be implemented on a new branch (`feature/ui-ux-polish`); the decisions below were taken on
his behalf under that go and are recorded here so he can veto any of them in one pass.

## Open decisions

Defaults below are recommendations. Resolve each before its affected code, not every decision
before any independent work.

| ID | Choice | Recommended default | Affected PR |
| --- | --- | --- | --- |
| D1 | Success dismissal policy | About 3 seconds for disposable success only; pause on hover/focus, preserve active instructions, warnings and errors | P2 |
| D2 | Colour-by/Classify surfaces and toolbar | Stable nonmodal disclosed cards; separate view from authoring tools; inspect filter target before naming it; retain labels for unfamiliar actions | P4 |
| D3 | Table density, palette and grouping | Compact readable pills with forgiving targets; shared viewport category tokens; subtle row hover and quiet grid; stronger Zone headers | P1 |
| D4 | Heading counts and row numbering | Footer totals/filtered counts, no new row-number column without a reference need; decide app-wide versus scoped removal | P1 |
| D5 | General help versus blocked-action reasons | Shared disclosed help for recommendations; keep blocking explanations beside their actions | P2 |
| D6 | Builder Library layout and initial state | Audit and closely match predecessor foldable rail, with one shared grammar for Materials and Windows products | P3 |
| D7 | Modal and Library completion semantics | Common X/footer/focus behavior; specific commit labels; Cancel discards drafts, Close/Done ends immediate-action managers; first task is Add a library | P2, P3 |
| D8 | Sorting scope | Preserve hierarchy, make supported sorting visibly useful; decide Zone-only or within-Zone scope from current contract and reproduction | P7 |
| D9 | Assembly parity differences | Restore applicable authoring affordances; retain Composer contracts and exclude retired designPH integration | P5 |

Exact card placement, category palette, density, library rail default and toolbar grouping await
source inspection and visual comparison. A global rule must be tested against other shared
consumers before it is promoted into the skill or Design System.

## Decisions taken, 2026-10-04

Each row is what was built. "Differs from default" says where it departs from the recommendation above.

| ID | Taken | Differs from default |
| --- | --- | --- |
| D3 | Chips are 24px pills, 12px text. Face type and boundary chips take a 26% tint of honeybee's display hue, the one the viewport's Colour-by modes draw (`colour_modes.rb`), held in `face_words.js` and kept equal to the Ruby table by `tests/face_words_test.js`. Read-only values (a paired Surface, an Air boundary) are the same pill, not text. Row hover is a wash over the whole row; the cell tint is gone. Grid: row hairlines only, column separators in the header only. A tree's Zone rows are heading rows: tinted, bold, with a firmer rule above each. Chevrons are borderless. | Wall's tint is a pale amber near the "?" flag's amber; the "?" text and the flagged cell tell them apart. Kept honeybee's hue rather than invent a palette (D3 says not to). |
| D4 | The page header counts nothing, app-wide (`page_header.js` lost `count`). Every control row shows its count: "2 total", "1 of 2" when filtered; Zones / Faces words it "2 Zones". No row-number column. | Count sits in the control row, the app's existing place for it, rather than a new table footer. One place for counts beats two. |
| D8 | Order by sorts Zones, and Faces within each Zone by the same field and direction; unclassified Faces keep their summary place after the recorded ones. A Face's Name orders by its place number, not its text, because the text starts with its type and a chip edit must not move the row. | Name order within a Zone is place order (reversible), not alphabetical. |
| D1 | A new notice tone, `success`, for a completed action: it fades after 3 s, held while hovered or focused, and a newer message replaces it and stops its clock. Completed context-menu commands and approvals send `:success`; tool instructions stay `info`, warnings and errors stay until dismissed. | None. The generic "Done." wording comes from the operations' default outcome message; rewording each operation's message is left as a follow-up. |
| D5 | Blocked-action reasons stay beside their action: the shared `ui.reasonButton` opens the reason in an anchored bubble instead of raising a page notice. No footer help strip. | Declines Ed's footer suggestion: a footer is far from the blocked action and would reflow or crowd the work surface. One shared control gives the consistency he asked for. |
| D7 (dialogs) | Every `formDialog` gets the same top-right close, equivalent to Escape and Cancel, re-inserted on each open; closing returns focus to the opener. Footers already run Cancel then a consequence-named commit; the Library manager's Close-only footer is P3's. | Keeps consequence labels (Create, Save, Delete) rather than a generic OK. |
| D6 | Library rail stays at the right in both Builders; groups carry counts and start folded when a list holds more than 20 records; a search opens what it finds. No category filter or sort control: search already matches category, and the groups are the categories. | Departs from the predecessor's left rail: the Window Builder's left edge is its Types rail, and one side for the library in both Builders is the consistency Ed asked for in UX-021. |
| D7 (Library) | Library setup applies each change at once, so it is a manager with Done. With no library, the file and folder choices show at once; afterwards behind "Add a library…". A completed add names the library, marks its row and folds the choice; Done becomes primary. Adding a library needs no approval (the native picker is the consent), so approved locations move into a folded "Agent access" section with that sentence. | None. |
