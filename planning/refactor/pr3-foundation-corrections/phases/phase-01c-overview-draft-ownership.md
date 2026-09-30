# Phase 01c: Overview draft ownership

DATE: 2026-09-30
STATUS: Blocked
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)
MERGE SET: Yes
BLOCKED ON: [R-D4](../DECISIONS.md#r-d4-overview-draft-ownership)

## Scope

U1: a dirty or pending Zone details editor is never disposed silently by row selection,
filtering or tab navigation. See
[U1](../review/PIPELINE-UI-REVIEW.md#p2-row-selection-silently-destroys-a-zone-details-draft).
Load `.agents/skills/ph-composer-ui-polish/SKILL.md` first; its progressive-disclosure rule is the
standard this phase meets. Model switch still withdraws the old session's editor safely.

Under R-D4 option A this adds a whole-form Cancel and a guard. Choose between keeping the editor
pinned while selection moves, or refusing the navigation with an inline notice, during this
phase and record the choice in **Result**. No browser modal dialogs.

## Source

- `src/ph_composer/html/sections/overview.js`: selection handler, editor disposal, `dirty` tracking

## Regression tests (write first)

In `tests/overview_panel_test.js`, starting from the review's reproduction:

1. Type a new Zone name; select a Face row; return to the Zone. The draft is either still present
   or was explicitly cancelled by the user. Never silently reverted. Zero writes sent.
2. Same for Building-Segment, Level and Ground depth drafts.
3. Filtering the selected Zone out, and changing tabs, follow the same rule.
4. Cancel restores stored values and ends the draft; Save sends one write.
5. A pending request keeps Save/Cancel visible; a refusal leaves the draft and a focus route.
6. Existing unit-switch, stale-value and Undo/Redo preservation tests still pass.

## Out of scope

Per-occurrence draft retention (unless R-D4 chooses it), other Overview layout changes.

## Ledger screen

Expect case A09. Add R05 to the case catalog. Host run in Phase 05 with native keyboard focus.

## Done when

- Tests fail before, pass after; full JS suite passes.
- UI polish review checklist applied and noted in **Result**.
- STATUS row U1 set to `Implemented on branch`.

## Result

(Fill on completion, including the pinned-versus-refuse choice.)
