# Managed Building Segments and Levels

DATE: 2026-10-05
STATUS: Scoped draft; not implemented or authorized for implementation
AUTHOR: Ed May, BLDGTYP, with Codex
ISSUE: [#78](https://github.com/bldgtyp/ph-composer/issues/78)

Replace free-text Building Segment and Level cells with select chips backed by editable,
model-owned option lists. Each option has a name and colour. This is a data-model feature,
carried out of the UI refinement branch because identity, migration, recovery and export are affected.

Read [PRD.md](PRD.md), [DECISIONS.md](DECISIONS.md), [CONTRACTS.md](CONTRACTS.md),
[PLAN.md](PLAN.md), [ACCEPTANCE.md](ACCEPTANCE.md), then [STATUS.md](STATUS.md).

Recommended entry points: **Manage Building Segments…** and **Manage Levels…** in the respective
column menus. Both open the same management dialog pattern for their own list. The table remains
the assignment surface. No extra tab or permanent toolbar controls are proposed.

The request covers the two existing fields' option sets, not arbitrary new columns. Shared
cross-project templates can follow later. The current text editors remain until this packet is approved,
implemented and accepted. Its parent intake is [UI refinements](../../../refactor/ui-ux-refinements.md).
