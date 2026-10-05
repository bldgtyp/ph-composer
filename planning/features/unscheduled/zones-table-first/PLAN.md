# Zones / Faces: table-first layout: plan

DATE: 2026-10-04
STATUS: Implemented on branch
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

The staged route from the PRD to a host-accepted screen. Ed accepted the proposed answers to Q1 to Q9
on 2026-10-04 and authorized implementation through every stage on `feature/zones-table-first`. The
decisions are recorded below as D1 to D9; the PRD's open questions point here.

## Decisions

| Id | Question | Decision |
| --- | --- | --- |
| D1 | Q1, modes with no column | The table's options menu lists every registered mode not bound to a visible column, as a pressed-state toggle, so a mode a later feature registers is reachable without a column. |
| D2 | Q2, Window Type from the Assembly header | A Colour-by mode declares an optional `group` at registration. Assembly and Window Type both declare `"construction"`; the Assembly column binds to the group, so Zones never names a windows mode. A column bound to a group with one mode toggles it; with several, the toggle opens an anchored menu. |
| D3 | Q3, legend chip gestures | Clicking a chip runs the existing `colour_by.select_row` (select in SketchUp and zoom). The one-way sync then checks whatever Faces that selection holds. An isolate icon appears on chip hover or focus. Zone, Building-Segment and Level modes colour Zone Groups, so their chips select Groups, which the Faces selection read refuses: those chips frame and check nothing. The legend names no feature, so no Face route is added to it. |
| D4 | Q4, Unclassified as a filter value | Yes. A Face with no type (or no boundary) reads "Unclassified" in that column's value filter. |
| D5 | Q5, the selection bar | A kit part (`selection_bar.js`) any pane can place. Only Zones / Faces places it in this packet. |
| D6 | Q6, bulk Zone edits | Out of this packet. Checking a Zone row checks its Faces; the bar edits Faces only; Zone fields edit in their cells. |
| D7 | Q7, checked rows a filter hides | They stay checked. The bar reads "5 Faces selected, 2 hidden" and every choice still applies to all of them. |
| D8 | Q8, the Locate highlight | It lasts until the next Locate, the next SketchUp selection change, Escape, or the next pointer press in the panel outside a Locate control. No timer. The host clears it on the first two; the panel sends one clear for the others, only while one is live. |
| D9 | Q9, "Select faces using <Assembly>" | It opens Zones / Faces with those Faces checked (`panel.navigate("overview", { check })`) and locates them. It no longer changes SketchUp's selection. |

Implementation decisions made while planning, under the same authorization:

- **I1. The checkbox lives in the Actions cell**, first in its row, with the header box in the
  Actions header. Actions is already the first sticky column, so the sticky offsets stay as they are.
- **I2. Locate and Select are two view commands.** `ph_composer.zones.faces.locate` frames and
  highlights without selecting. A new `ph_composer.zones.faces.select` keeps today's behaviour (select
  and zoom) for agents and scripts, which `context/AGENT_INTERFACE.md` promises explicit selection.
- **I3. The Locate highlight is its own overlay**, owned by Zones Faces, not the Colour-by overlay:
  it lives while Colour by is off, and the Colour-by service names no feature.
- **I4. Column sort.** A Zone field (Name, Building-Segment, Level, Ground depth, Gross area) orders
  Zones, and their Faces by the same field where the Face has it (Name: place number; area). A Face
  field (Type, Boundary, Assembly) keeps Zone order and orders Faces within each Zone. One sort at a
  time; the menu's pressed item shows it.
- **I5. The other screens keep Order by.** `ui.ViewControls` gains column sort and value filters
  beside its select path; Assemblies, Window Types and Library are unchanged.
- **I6. The bar respects the gesture ceiling.** A choice that would touch more Faces than
  `gesture_face_limit` is disabled with its reason on the bar, rather than sent and refused.

## Stages

| Stage | Document | Owns |
| --- | --- | --- |
| ZT-01 | [phases/phase-01-zone-columns.md](phases/phase-01-zone-columns.md) | Name, Building-Segment, Level and Ground depth edited in place on Zone rows; the Zone details form and its draft hold removed |
| ZT-02 | [phases/phase-02-header-actions-and-column-menus.md](phases/phase-02-header-actions-and-column-menus.md) | The table's header-action and column-menu contract; sort and value filters replacing Order by on this screen; hover reveal |
| ZT-03 | [phases/phase-03-colour-by-in-headers.md](phases/phase-03-colour-by-in-headers.md) | Mode groups, header toggles, the legend in the control row, the options-menu route for unbound modes |
| ZT-04 | [phases/phase-04-checked-set-and-locate.md](phases/phase-04-checked-set-and-locate.md) | The checkbox set, one-way sync, Locate framing with its highlight, `select` for agents, Assemblies' action |
| ZT-05 | [phases/phase-05-selection-bar.md](phases/phase-05-selection-bar.md) | The floating selection bar for the checked set, and the Classify palette in it |
| ZT-06 | [phases/phase-06-no-inspector-and-contracts.md](phases/phase-06-no-inspector-and-contracts.md) | The inspector gone from this pane, the help button, sticky scroll at narrow widths, contracts and skill references updated |
| ZT-07 | [phases/phase-07-host-acceptance.md](phases/phase-07-host-acceptance.md) | The host walkthrough in SketchUp and the packet's close |

Each stage ends with its focused tests and `make ci`, and is committed on the branch. One review
covers the combined diff after ZT-06. The packet reads `Implemented on branch` after ZT-06 and is
archived only after ZT-07's host gate passes.
