# UI and UX polish: decisions

DATE: 2026-10-04
STATUS: Scope confirmed; solution decisions open.
ISSUE: none (local planning draft)

## Settled direction

Ed requests end-user-centered design, progressive disclosure and a consistent UI grammar;
authorizes designer pushback; asks for applicable Assembly Builder parity with the predecessor;
and includes updates to the Design System and polish skill. The present authorization covers
organizing and committing planning documents. Implementation is not authorized.

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
