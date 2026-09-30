# Phase 01c: Overview draft ownership

DATE: 2026-09-30
STATUS: Scoped
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)
MERGE SET: Yes
BLOCKED ON: implementation authorization

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

(Fill on completion.)
