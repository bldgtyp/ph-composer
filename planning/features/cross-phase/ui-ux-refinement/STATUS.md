# UI and UX refinement: status

DATE: 2026-10-03
STATUS: In progress

## Where this stands

All eight packets and the Zones / Faces follow-up are merged to main (last merge: pull request
#66). No branch is open and nothing is half-built. What is left needs Ed: his verification pass
below, the host capture session for the viewport tools (D7), and then the Design System artifact.
Ed gave a standing go on 2026-10-03 to proceed through the packets on the recorded
recommendations, with his checks gathered into one verification pass at the end.

| Step | State | Note |
| --- | --- | --- |
| Panel capture from the preview | Done 2026-10-03 | Before the polish; in the gitignored `planning/ui-baseline/screens/current-2026-10-03/` |
| Flow critique | Done for the panel 2026-10-03 | [FINDINGS.md](FINDINGS.md) |
| Ed's rulings on D1 to D7 | Done 2026-10-03 | All seven recommendations accepted; recorded in FINDINGS.md |
| Packet 1, page frame | Merged to main 2026-10-03, [#55](https://github.com/bldgtyp/ph-composer/pull/55) | [phases/phase-01-page-frame.md](phases/phase-01-page-frame.md) |
| Packet 2, table chrome | Merged to main 2026-10-03, [#56](https://github.com/bldgtyp/ph-composer/pull/56) | [phases/phase-02-table-chrome.md](phases/phase-02-table-chrome.md) |
| Packet 3, Zones / Faces layout | Merged to main 2026-10-03: P3-1 [#57](https://github.com/bldgtyp/ph-composer/pull/57), P3-2 [#58](https://github.com/bldgtyp/ph-composer/pull/58), P3-3 [#59](https://github.com/bldgtyp/ph-composer/pull/59), P3-4 [#60](https://github.com/bldgtyp/ph-composer/pull/60) | [phases/phase-03-zones-faces-layout.md](phases/phase-03-zones-faces-layout.md) |
| Packet 4, Installs editor (W4) | Merged to main 2026-10-03, [#61](https://github.com/bldgtyp/ph-composer/pull/61) | [phases/phase-04-installs-editor.md](phases/phase-04-installs-editor.md) |
| Zones / Faces follow-up (D9, D10) | Merged to main 2026-10-03, [#62](https://github.com/bldgtyp/ph-composer/pull/62) | A chosen Zone row takes the inspector until the selection changes; the selection's Assembly control shows the shared Assembly. Host-checked for D9; D10's shared value is covered offline only (the fixture has no Assembly) |
| Packet 5, Window Types frame (W1, W2, W3, W5, K9) | Merged to main 2026-10-03, [#63](https://github.com/bldgtyp/ph-composer/pull/63) | [phases/phase-05-window-types-frame.md](phases/phase-05-window-types-frame.md) |
| Packet 6, Assembly Builder toolbar and row actions (A1 to A4) | Merged to main 2026-10-03, [#64](https://github.com/bldgtyp/ph-composer/pull/64) | [phases/phase-06-assembly-builder.md](phases/phase-06-assembly-builder.md) |
| Packet 7, Library (L1 to L3, K11, D5) | Merged to main 2026-10-03, [#65](https://github.com/bldgtyp/ph-composer/pull/65) | [phases/phase-07-library.md](phases/phase-07-library.md) |
| Packet 8, completeness (X1, F3, K10; ruling on F1) | Merged to main 2026-10-03, [#66](https://github.com/bldgtyp/ph-composer/pull/66) | [phases/phase-08-completeness.md](phases/phase-08-completeness.md) |
| Host capture of viewport surfaces (D7) | Not started | Was to follow packets 1 and 2; needs one SketchUp session with Ed present |
| Design System artifact | Not started | After the kit-wide packets settle |

Every merged packet passed `make ci` (both Ruby versions in CI), `make ui-checks`, at least one
independent diff review, and a host check on SketchUp 26.1.188. Each plan's own outcome and host
check sections say what was and was not covered.

## Next steps, in order

1. **Ed's verification pass**, below: one sitting in SketchUp with a real project Model.
2. **The D7 host capture session** for the viewport tools (Classify, Place, Paint in their active
   states), the real Colour-by legend and a completed Export. It needs Ed present, and can share
   the sitting with step 1. F4 (the viewport tools signal their active state differently) waits on
   it.
3. **The Design System artifact**, now that the kit-wide packets have settled.
4. **Anything Ed overturns** from the decisions taken (D8 to D12, and each packet's "Decisions
   taken" table), as small follow-up changes.

## Verification pass, 2026-10-03

Run with Ed on SketchUp 26.1.188, merged main installed, Model `ui-verification-run.skp` (the
synthetic fixture, then worked on by hand). Items 1 to 7 were Ed's own mouse and keyboard. Items 8
to 14 were real pointer and key input sent to the panel through computer use, on the Model as Ed
left it.

| Item | Result |
| --- | --- |
| 1 to 3. Faces selected, Zone row takes the inspector, a new selection takes it back (D9) | Pass (Ed) |
| 4. "+ New Assembly" opens the Builder with the title selected (D5) | Pass (Ed) |
| 5. Builder: teal selection, selection tools, the "..." menu, Add Layer | Pass (Ed) |
| 6. Assemblies row icons in two groups, Replace glyph | Pass (Ed) |
| 7. The selection's Assembly control shows the shared Assembly, then "Mixed" (D10) | Pass (Ed) |
| 8. A new Window Type from the rail | Pass (Ed made "A New Type") |
| 9. Anchor bubble: three by three, Sill center tinted, Head right chosen | Pass |
| 10. Installs: a clicked edge repaints, Escape asks "Discard Installs changes?" | Pass |
| 11. A subtab click over a staged session asks the same | Pass |
| 12. Save Installs closes the editor and shows "Installs saved."; the next click clears it | Pass, with the notice finding below |
| 13. Library: the sidebar's one line in place of a repeated list; New Material's "required" mark and "Enter a name." | Pass |
| 14. Export: "Finish 6 things before exporting.", ten causes in two groups, Locate all selects ten Faces, Open Zones / Faces navigates | Pass, with the wording findings below |
| 15. A completed export | Not run: the Model has six blocking causes |

Found in the pass, not yet fixed:

- **The notice covers the subtabs.** "Installs saved." sits over U-Values and Schedule on the
  Window Types tab until the next click. Clicks pass through it, but the labels are hidden.
- **Zones / Faces at about 1150 wide with the inspector open:** the table is wider than its space
  and the Type column slides under the sticky Name column, leaving a header that reads "e".
- **No rail mark on a Window Type with no products.** "A New Type" has four blocking Export causes
  and no amber mark in the rail. The mark follows the thermal findings, which were empty here.
- **Export wording from the Model:** "Element: top: no Psi-Install Type resolves." names no Window
  Type; "The Face face type RoofCeiling differs from its Assembly type Wall." shows honeybee's
  stored word where the glossary says "Roof or ceiling"; "Face names incomplete Assembly" is hard
  to read. These come from Ruby (P8-Q1).
- **Locate all from Export does not fill the selection inspector**, the known limit for Faces
  selected from outside their Zone.

## Follow-ups noted, not scheduled

- `make ci` needs a UTF-8 locale; with `LANG` unset five Ruby tests that read source files raise an
  encoding error. One `export` in the Makefile would fix it.
- Inspector regions are created on first use, not written into `index.html`; do the static markup
  when a second pane takes an inspector. The kit does not warn when a pane's tools are never placed.
- Under 900 wide the inspector opens beneath a tall tree, out of view.
- The sort toggle announces no state change to a screen reader. A Library surface that is not a
  kit `Inventory` shows no count.
- An unclassified row sends no value guard; "Show all" drops focus to the page; Locate on more than
  250 Faces selects past the selection inspector's ceiling.
- Locate from outside a Zone selects its Faces while the edit path is the Model, and the selection
  inspector does not recognise Faces selected that way ("0 Faces selected" in the snapshot). Seen in
  the host on 2026-10-03; it predates this work.
- Export's header is rebuilt on every repaint, so Choose destination and Cancel export lose keyboard
  focus. Export's findings are grouped in the panel; a summary sentence per cause from Ruby would be
  cleaner but changes the findings contract (P8-Q1). Routes finer than one tab per feature.
- The Psi-Install Types tab still lists its records in the sidebar, because that list also sets the
  Model default. After a refused New Assembly, keyboard focus is not returned to the button.
- The Assembly Builder rebuilds its work surface on every repaint, so keyboard focus falls to the
  page after any toolbar action. At 420 wide its drawing is wider than the panel at the smallest
  zoom step and scrolls.
- The library sidebar opens by default at exactly 900 wide while the Window Types rail collapses
  there. After an anchor choice re-arms a placing tool, keyboard focus falls to the page.
- A main tab click on a clean Installs session is refused with a notice, where a subtab click now
  leaves it. A shared Assembly that is no longer among the records reads "Choose Assembly" in the
  selection inspector while its table cell says it is missing.
- Export lists blocking findings by record id, one row per Face (finding X1, packet 8).
- The capture scripts live only in the gitignored screens folder. Move `crawl.cjs` and `flows.cjs`
  beside `tools/ui-preview/*_checks.cjs` if before-and-after captures are wanted per packet.
- `.claude/launch.json` (the preview server entry for the Claude app) is untracked.

## Working notes for whoever resumes

- The rubric is `.agents/skills/ph-composer-ui-polish/SKILL.md`; its `references/patterns.md` now
  records the page header, the control row, the enum cell, the pane regions and the Zones / Faces
  inspector. The contracts are in `context/EXTENSIBILITY.md` (pane regions, tiers, `hold`) and
  `context/TECH_STACK.md` ("UI kit conventions carried over").
- Each packet ran as: plan on main, branch, implement, `make ci` and `make ui-checks`, one Sonnet
  diff review (plus a fresh Opus review for a new kit contract), pull request, host check through
  the development bridge, merge on Ed's word once CI is green.
- Host checks drive SketchUp through `tools/hostkit/host_bridge.py` on a fresh copy of a synthetic
  fixture under `_private/host/`, and capture the panel by window id. Pick the window whose
  `kCGWindowIsOnscreen` is true: a blank capture has twice been a stale or off-screen window, not a
  fault. Browser checks need Playwright from a scratch directory on `NODE_PATH`.
- Known capture gaps from the first critique still stand: populated U-Values and Schedule subtabs,
  the Place and Paint tools in their active state, the Replace dialog, Export on a real Model, and
  the real Colour-by legend.
