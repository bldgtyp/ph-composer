# Assembly Layer drag reordering: status

DATE: 2026-10-15
STATUS: Scoped. Stages LR-01 to LR-04 planned on 2026-10-15; none authorized.
ISSUE: none (local planning draft)

The visual direction is approved; real drag behavior is not implemented. Packet created on
2026-10-07 under the owner's standing instruction to scope larger new features for dedicated
branches. The refactor's hover gear and the existing directional Move actions are separate and
merged.

## Stages

| Stage | State | Review | Gate | Notes |
| --- | --- | --- | --- | --- |
| [LR-01](phases/lr-01-reorder-action.md) `layers.reorder` | Scoped | not run | not run | Waits for Ed's go and LR-D1 to LR-D4 |
| [LR-02](phases/lr-02-grip-and-drag-gesture.md) grip and gesture | Scoped | not run | not run | Waits for LR-01 merged and LR-D5 to LR-D9 |
| [LR-03](phases/lr-03-browser-checks.md) browser checks | Scoped | not run | not run | Needs a scratch Playwright |
| [LR-04](phases/lr-04-host-gate-and-closeout.md) host gate and closeout | Scoped | not run | not run | Native drag through the computer-use controller, one approval card |

## Decisions

LR-D1 to LR-D10 are proposed in [PLAN.md](PLAN.md), "Decisions proposed", and wait for Ed. The
PRD's open decisions map to them: action name and schema (LR-D1), auto-scroll and thin-Layer reach
(LR-D5, LR-D7), ghost versus reserved space (LR-D6).

Next: Ed reads the plan and confirms or changes the decisions, then LR-01 runs through `pr-loop`.
Offline and native acceptance: NOT RUN. No release or API claim.
