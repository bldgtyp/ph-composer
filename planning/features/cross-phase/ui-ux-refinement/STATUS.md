# UI and UX refinement: status

DATE: 2026-10-03
STATUS: In progress

## Where this stands

Packets 1 to 6 and the Zones / Faces follow-up are merged to main (last merge: pull request #64).
No branch is open and nothing is half-built. Packet 7 is next and has no plan yet. Ed gave a
standing go on 2026-10-03 to proceed through the remaining packets on the recorded
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
| Packets 7 and 8 | Requested | Order and coverage in FINDINGS.md, "Proposed packets" |
| Host capture of viewport surfaces (D7) | Not started | Was to follow packets 1 and 2; needs one SketchUp session with Ed present |
| Design System artifact | Not started | After the kit-wide packets settle |

Every merged packet passed `make ci` (both Ruby versions in CI), `make ui-checks`, at least one
independent diff review, and a host check on SketchUp 26.1.188. Each plan's own outcome and host
check sections say what was and was not covered.

## Next steps, in order

1. **Write the packet 7 plan**: the Library (L1 to L3, K11) and D5 (New acts at once where the
   record draws something; number-only records keep a form with required fields marked).
2. **Packet 8**: completeness (one vocabulary for "not finished", Export readiness, empty states;
   F1, F3, X1, K10).
3. **The D7 host capture session** for the viewport tools, the real Colour-by legend and Export.
4. **The Design System artifact**, once the kit-wide packets have settled.

## For Ed's verification pass

Gathered here so they can be checked in one sitting, in SketchUp, by hand:

- Installs editor: Escape from the keyboard at each layer, and painting edges with the pointer.
  Both were exercised offline and in the browser checks, not with native input.
- Window Types now shows its messages. Notices such as "Installs saved." and the eyedropper
  instructions appear for the first time, in the panel's notice under the tab row. Say if any is
  unwanted or badly placed.
- A notice that is only information no longer blocks a click on the control beneath it.
- Assembly Builder: the single toolbar (selection tools appear with a selection; Mirror and the two
  Flips are in the "..." menu), the back link above the title, the teal selection outline, and the
  grouped row icons in the Assemblies table with the new Replace glyph. Decisions P6-Q1 to Q3 are in
  the packet 6 plan.
- Window Types: the anchor bubble beside Place (a three by three grid in place of the Anchor
  select), rail rows on hover and in manual order, and the restyled library sidebar on every screen
  that has one. Decision P5-Q2 left the Installs palette where it is, not in a pane inspector.
- Zones / Faces: click a Zone row while Faces are selected, then change the selection (D9).
- The selection's Assembly control with Faces that share an Assembly, and with Faces that differ
  (D10).

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
