# UI and UX polish: status

DATE: 2026-10-04
STATUS: Complete. Merged to main through PR #71 (merge commit 82a1ca5) on 2026-10-04; archived.
ISSUE: none (local planning draft)

## Delivery ledger

| Item | State | Evidence / next action |
| --- | --- | --- |
| Initial intake | Complete | UX-001 through UX-022 and nine attachment references in REQUESTS |
| Planning organization | Complete | PLAN, DECISIONS and ACCEPTANCE; local document checks |
| P0 investigations | Complete | UX-007 reproduced in preview (below); UX-016 audit in [evidence/ASSEMBLY_PARITY.md](evidence/ASSEMBLY_PARITY.md); Colour by "Show only this" is a viewport isolate, no table filter (`colour_by/service.rb#isolate`) |
| P1 shared tables | Implemented on branch | UX-003, 004, 005, 011, 012, 013; D3, D4 taken. `make ci` and `make ui-checks` pass |
| P2 shared feedback/dialogs | Implemented on branch | UX-002, 010, 020 (shared contract); D1, D5, D7 taken. `make ci` passes |
| P3 Library flows/surfaces | Implemented on branch | UX-018, 019, 020 (Library), 021; D6, D7 taken. Shared sidebar and setup serve both Builders |
| P4 Zones / Faces workspace | Implemented on branch | UX-001, 006, 008, 009; D2 taken. Table width measured constant (960 px at 1280) across rest, Colour by and Classify |
| P5 Assembly Builder | Implemented on branch | UX-014, 015, 016, 017; D9 taken; audit in evidence/ASSEMBLY_PARITY.md |
| P6 Windows toolbar | Implemented on branch | UX-022; grouping recorded under P6 in DECISIONS |
| P7 sorting | Implemented on branch | Not a defect at its scope: Order by sorted Zones only, so with one Zone it changed nothing. D8 now orders Faces within each Zone; `overview_panel_test.js` covers Name, Area and both directions |
| Skill/pattern changes | Updated per slice | P1: editable-table rule, page header, control-row count, enum pill. P2: success tone, reason button, dialog close and focus return |
| Design System sync | Complete | Artifact re-synced from main@82a1ca5 on 2026-10-04 (version 5): README, tokens (row hover wash, nine chip tints, row height), Table, Notice, PageHeader, Toolbar, RecordForm, LibrarySidebar and Inspector cards, bundle.css rebuilt from the seven panel stylesheets |
| Reviews | Complete | P1 to P3: one Sonnet review, no high-severity defect, material findings fixed in the P4 commit. P4 to P6: fresh-context Opus review (high assurance for P5), no double-send path; two confirmed and ten traced or plausible findings fixed (dispose with an open draft, equal retype, live bubble close, draft kept on reopen, reopen by dimension key, focus after insert, header focus, Enter order on Chromium 88, pendingInsert timing, window-blur partial apply, membrane insert reach, notice hover hold) |
| Verification | Complete offline | `make ci` and `make ui-checks` (1280/900/420/280) pass on the final branch; JS suite under tools/js_test_guard.js peaks near 750 MB |
| Host acceptance | Accepted by Ed | Branch build installed with `make install` on 2026-10-04; Ed checked it in SketchUp 2026 and approved. No agent-driven native walkthrough was run, and the final review fixes (commit 516cbeb) landed after the installed build |
| Merge | Complete | [PR #71](https://github.com/bldgtyp/ph-composer/pull/71), CI `make ci` on Ruby 2.7.2 and 3.2.2 passed |

## P0 findings

- UX-007 (2026-10-04, `?fixture=authoring`, 1280 px): Order by Name and Area, and the direction toggle,
  reorder the two Zones as intended. Faces never move: `overview.js` `ordered()` keeps each Zone's Faces
  in projection order. A Model with one Zone (Ed's screenshots S2 to S5) therefore shows no change.

## For Ed's verification pass

- Chip tints: Wall's pale amber sits near the "?" flag's amber. Accept honeybee's hue, or choose another.
- Counts moved from page headers to control rows app-wide (D4).
- No footer help strip (D5): blocked reasons open beside their action instead.
- Library rail stays right in both Builders (D6), against the predecessor's left rail.
- Zones / Faces keeps a standing inspector column instead of an overlay card (D2).
- Builder dimension bubbles now apply on blur (D9); earlier they kept the draft until Apply.

## Follow-ups noticed, not in scope

Resolved on 2026-10-04 in the follow-up PR from `feature/polish-follow-ups`, except the Design System contract
upgrade, which an artifact made from a type cannot take (the type's publisher owns its runtime): committed
outcomes say "Done: <undo name>."; the four Builder items below are built; the Library sidebar has a category
choice and name order; the DOM test stub models capture, target and bubble with `dom.dispatch`.

- Reword the generic "Done." outcome message per operation (D1).
- Builder: read-only Material properties at the Layer-Segment, an Assembly information bubble, hover-open thickness bubbles, delete-layer from the dimension bubble (parity gaps 11 to 14).
- Library sidebar category filter and sort, if search proves insufficient (D6).
- The DOM test stub keeps one listener per event type, so it cannot catch listener-order bugs.

## Next action

None. Archived 2026-10-04. Follow-ups above remain open for later packets.
