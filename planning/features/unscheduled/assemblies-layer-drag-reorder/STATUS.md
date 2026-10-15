# Assembly Layer drag reordering: status

DATE: 2026-10-15
STATUS: In progress. Authorized 2026-10-15; LR-01 and LR-02 implemented on branch `feat/assemblies-layer-drag-reorder`.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: [#128](https://github.com/bldgtyp/ph-composer/issues/128)

The visual direction is approved; real drag behavior is not implemented. Packet created on
2026-10-07 under the owner's standing instruction to scope larger new features for dedicated
branches. The refactor's hover gear and the existing directional Move actions are separate and
merged.

## Stages

| Stage | State | Review | Gate | Notes |
| --- | --- | --- | --- | --- |
| [LR-01](phases/lr-01-reorder-action.md) `layers.reorder` | Implemented on branch | in the PR review | Ruby suite 1621 runs green on 3.2.2 and 2.7.2; rubocop clean; `make fixtures` adds one API reference section | Tests 1 to 8 as planned, in the commands and operations suites |
| [LR-02](phases/lr-02-grip-and-drag-gesture.md) grip and gesture | Implemented on branch | in the PR review | `make ci` exit 0 on 3.2.2 and 2.7.2 (1621 Ruby runs, 546 JS tests); `make coverage` Ruby 97.1%, JS 96.6% | Tests 1 to 7 in `tests/assembly_layer_drag_test.js` (own file: the Builder test file is 600 lines and registers tests, so it cannot be required); test 8 in `tests/icons_test.js`; the zoom-fit boundary in `tests/assembly_canvas_test.js` moved with the 128 px gutter |
| [LR-03](phases/lr-03-browser-checks.md) browser checks | Scoped | not run | not run | Needs a scratch Playwright |
| [LR-04](phases/lr-04-host-gate-and-closeout.md) host gate and closeout | Scoped | not run | not run | Native drag through the computer-use controller, one approval card |

## Decisions

LR-D1 to LR-D11 in [PLAN.md](PLAN.md), "Decisions proposed", are taken as proposed. The PRD's open
decisions map to them: action name and schema (LR-D1), auto-scroll and thin-Layer reach
(LR-D5, LR-D7), ghost versus reserved space (LR-D6). The gutter widening (LR-D11) is new.

## Delivery, as authorized on 2026-10-15

Ed started the packet through `implement-loop` on 2026-10-15 with these instructions, which
override the plan where they differ. Veto any of them here.

- One branch, `feat/assemblies-layer-drag-reorder`, and one pull request for the whole packet
  instead of one per stage. Each stage is its own signed commit on that branch.
- The review is one gpt-6.1-sol pass through `pr-loop`, which also stands for LR-04 step 12's
  "stronger independent pass": Ed named the model.
- Claude merges the PR once the review findings are resolved, then archives the packet and deletes
  the branch locally and on the remote.
- Guard detail settled during LR-02 design: `Editor.guard()` refuses while a Layer drag is active,
  not while `Editor.dragging` is set, because the Material drag's own busy check reads `guard()`
  on every move and would end itself.

Offline and native acceptance: NOT RUN. No release or API claim.
