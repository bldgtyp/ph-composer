# Phase 01c: Overview draft ownership

DATE: 2026-09-30
STATUS: Implemented on branch
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/4
MERGE SET: Yes

## Scope

U1: a dirty or pending Zone details editor is never disposed silently by row selection,
filtering or tab navigation. See
[U1](../review/PIPELINE-UI-REVIEW.md#p2-row-selection-silently-destroys-a-zone-details-draft).
Load `.agents/skills/ph-composer-ui-polish/SKILL.md` first; its progressive-disclosure rule is the
standard this phase meets. Model switch still withdraws the old session's editor safely.

Behavior, per [R-D4](../DECISIONS.md#r-d4-overview-draft-ownership): one draft at a time.

- The Zone details form gains a whole-form Cancel that restores stored values and ends the draft.
- While the form is dirty or has a pending request, row selection, filter changes and tab
  changes are refused, and a `warning` floating notice (for example "Save or cancel the Zone
  details first") points the user at the form. The skill's rule: lock navigation that would hide
  the draft's controls.
- Model switch and panel close still withdraw the editor safely.
- Single-cell Face table edits, which commit on Enter or blur, are unaffected.
- No browser modal dialogs.

## Source

- `src/ph_composer/html/sections/overview.js`: selection handler, editor disposal, `dirty` tracking

## Regression tests (write first)

In `tests/overview_panel_test.js`, starting from the review's reproduction:

1. Type a new Zone name; click a Face row. The selection does not change, a warning notice
   appears, the draft and its controls stay visible, and zero writes are sent.
2. Same for Building-Segment, Level and Ground depth drafts.
3. A filter change and a tab change are refused the same way.
4. Cancel restores stored values, ends the draft and unlocks navigation; Save sends one write
   and unlocks navigation on success.
5. A pending request keeps Save/Cancel visible; a refusal leaves the draft and a focus route.
6. Existing unit-switch, stale-value and Undo/Redo preservation tests still pass.

## Out of scope

Per-row draft retention (rejected in R-D4), other Overview layout changes.

## Ledger screen

Expect case A09. Add R05 to the case catalog. Host run in Phase 05 with native keyboard focus.

## Done when

- Tests fail before, pass after; full JS suite passes.
- UI polish review checklist applied and noted in **Result**.
- STATUS row U1 set to `Implemented on branch`.

## Result

Implemented in one commit (see the phase ledger in [STATUS.md](../STATUS.md)).

- `sections/overview.js`: the Zone details form gains a whole-form Cancel (restores the last
  stored values, cancels any Ground depth edit, ends the draft) and tracks `pending` beside
  `dirty`. While either holds, row selection away from the Zone, filter edits and tab changes
  are refused with the warning notice "Save or cancel the Zone details first." and focus returns
  to Save. Model switch still disposes the editor.
- Two small UI kit seams, both feature-neutral: `panel.notify(message, tone)` raises a page-side
  notice (`showTab` now uses it for its own guard refusals), and `ViewControls` takes an optional
  `guard`/`refused` pair that keeps the previous filter text when a filter edit is refused. The
  Overview registers its tab guard through the existing `panel.navigationGuard`.
- `zones.css`: one more `auto` column so Cancel sits beside Save. Runtime manifest refreshed.
- Tests in `tests/overview_panel_test.js` (7, written first; 5 failed before the change): Face
  row and other-Zone row refusals for Name, Building-Segment, Level and Ground depth drafts;
  filter and tab refusals; Cancel restores and unlocks; pending Save keeps Save/Cancel and locks
  navigation, success unlocks; refused Save keeps the draft and focus; Model switch withdraws a
  dirty draft. Full JS suite 191 tests pass, including the existing unit-switch, stale-value and
  refresh tests.

UI polish checklist: warning tone for a refusal, floating notice (no reflow, no browser modal),
the draft surface stays visible while navigation that would hide it is locked, Cancel is a plain
button beside Save with no restating text, Face chip edits are unaffected. Visual check of the
two-button row at narrow width is part of the R05 host run in Phase 05.

Ledger screen: A03, A04, A07, A09 to A16. R05 added to the case catalog.
