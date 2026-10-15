# Zone views mockup

DATE: 2026-10-15
STATUS: Accepted direction from the Spaces UI and UX discussion, 2026-10-15 (D3a-16, D3a-17). Static mockup, not a screen.

`zone-views.html` is a static page that links the panel's real stylesheets and reuses the live
Zones / Faces markup; no panel script runs. Serve the repository root (`make ui-preview`) and open
`planning/features/phase-03a-spaces/mockups/zone-views.html?state=<state>`. Add `&views=all` to see
the eight-view row; Ed chose to hide views until they are built, so the PNGs show two.

| PNG | State |
| --- | --- |
| `zone-views-faces.png` | The Faces view: today's Zones / Faces table under a Faces / Spaces view row, tab renamed Zones |
| `zone-views-spaces.png` | The Spaces view at rest: Zone › Space › Volume › Segment rows, sums on Zone rows |
| `zone-views-menu.png` | The Weighting factor column menu: Mark floor as one paint choice per value |
| `zone-views-checked.png` | Two Floor Segments checked; the selection bar edits them together |

Markers: 1, the view row (shared subtabs nav, above the heading); 2, a Zone row's airflow
imbalance marker; 3, Height, editable on Volume rows and a read-only area-weighted average on
Space rows; 4, airflows (a typed value, a muted 0 for an unset rate on a user-specified Space,
"Zone" for an inheriting Space, "—" on a Zone row with any inheriting Space); 5, Mark floor's paint
choices; 6, the selection bar.

Values are the synthetic reference model in [ACCEPTANCE](../ACCEPTANCE.md). The weighting factor is
a number from 0 to 1 (D3a-17); the column menu's paint choices are 1.00 and 0.00 plus any other
value the model uses.
