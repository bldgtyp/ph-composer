# Make Zone entry points

DATE: 2026-09-30
STATUS: Requested. Carried from the archived zones-and-adjacency packet; Ed chose on 2026-09-30 to
keep both for later.
AUTHOR: Ed May, BLDGTYP
ISSUE: none (local planning draft)

The [zones-and-adjacency PRD](../../archive/phase-01-zones-and-adjacency/PRD.md) Q23 named three Make Zone
entry points. The right-click item on a selected Group shipped with the Phase 1 UX follow-ups,
alongside the panel action. Two remain:

| ID | Entry point | Current behavior | Notes |
| --- | --- | --- | --- |
| E1 | A toolbar button for Make Zone | PH-Composer has no toolbar | Needs a shell toolbar contribution point (features declare buttons the way they declare menu items), not a Zones special case |
| E2 | An inline Make Zone offer from the Classify tool when the user clicks a Face outside any Zone | The tool refuses: "That Face is in no Zone. Make it a Zone first, then classify its Faces." | Action-first; under the geometry-first rule (`context/TECH_STACK.md`) record why it helps before building it |

Next step: scope E1 with the first other feature that wants a toolbar button; interview E2.
