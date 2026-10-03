# UI and UX refinement: status

DATE: 2026-10-03
STATUS: In progress

## Where this stands

Packets 1, 2 and 3 are merged to main (last merge commit `6a3133d`, pull request #60). No branch
is open and nothing is half-built. Packet 4 is next and has no plan yet. No polish work is
authorized beyond what is merged: each packet gets a plan Ed reads before it is built.

| Step | State | Note |
| --- | --- | --- |
| Panel capture from the preview | Done 2026-10-03 | Before the polish; in the gitignored `planning/ui-baseline/screens/current-2026-10-03/` |
| Flow critique | Done for the panel 2026-10-03 | [FINDINGS.md](FINDINGS.md) |
| Ed's rulings on D1 to D7 | Done 2026-10-03 | All seven recommendations accepted; recorded in FINDINGS.md |
| Packet 1, page frame | Merged to main 2026-10-03, [#55](https://github.com/bldgtyp/ph-composer/pull/55) | [phases/phase-01-page-frame.md](phases/phase-01-page-frame.md) |
| Packet 2, table chrome | Merged to main 2026-10-03, [#56](https://github.com/bldgtyp/ph-composer/pull/56) | [phases/phase-02-table-chrome.md](phases/phase-02-table-chrome.md) |
| Packet 3, Zones / Faces layout | Merged to main 2026-10-03: P3-1 [#57](https://github.com/bldgtyp/ph-composer/pull/57), P3-2 [#58](https://github.com/bldgtyp/ph-composer/pull/58), P3-3 [#59](https://github.com/bldgtyp/ph-composer/pull/59), P3-4 [#60](https://github.com/bldgtyp/ph-composer/pull/60) | [phases/phase-03-zones-faces-layout.md](phases/phase-03-zones-faces-layout.md) |
| Packet 4, Installs editor (W4) | Requested; no plan yet | Next |
| Packets 5 to 8 | Requested | Order and coverage in FINDINGS.md, "Proposed packets" |
| Host capture of viewport surfaces (D7) | Not started | Was to follow packets 1 and 2; needs one SketchUp session with Ed present |
| Design System artifact | Not started | After the kit-wide packets settle |

Every merged packet passed `make ci` (both Ruby versions in CI), `make ui-checks`, at least one
independent diff review, and a host check on SketchUp 26.1.188. Each plan's own outcome and host
check sections say what was and was not covered.

## Next steps, in order

1. **Write the packet 4 plan**: the Window Type Installs editor, finding W4. Labels overlap in the
   drawing; Save and Cancel sit under the status bar at 800 high; a subtab click is refused with
   no message; Escape does not leave; the thick blue dashed edges are a third highlight colour.
   The source is `src/ph_composer/html/features/windows/install_editor.js` and `windows.css`.
2. **Ed's rulings on the open points below**, which can ride with any later packet.
3. **Packets 5 to 8** as FINDINGS.md orders them: the Window Types frame (Anchor control, rail
   names, library sidebars), the Assembly Builder toolbars and inventory row actions, the Library,
   then completeness (one vocabulary for "not finished", Export readiness, empty states).
4. **The D7 host capture session** for the viewport tools, the real Colour-by legend and Export.
5. **The Design System artifact**, once the kit-wide packets have settled.

## Open points for Ed

Raised during packets 1 to 3 and not ruled on. None blocks packet 4.

| From | Question |
| --- | --- |
| Packet 1 | Planned tabs say "Planned" only in their tooltip. Keep, or add a small visible hint? |
| P3-2 | With Faces selected in the viewport, clicking a Zone row shows the Face selection, not Zone details, because a selection outranks a record. Locate on a Zone row has the same effect. Should an explicit row click win? |
| P3-2 | The selection inspector's Assembly control reads "Choose Assembly", not the Assembly the selection already shares. Show the shared one? |
| P3-3 | While it paints, the Classify tool turns on the last colour mode the user chose, not Face type. That is the accepted Phase 1 contract. Change it to always use Face type? |
| P3-4 | A Zone's area and Locate now cover every Face, recorded or not. Keep, or return the area to recorded Faces only? |

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
