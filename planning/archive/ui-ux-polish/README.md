# UI and UX polish

DATE: 2026-10-04
STATUS: Complete. Merged to main through PR #71 on 2026-10-04; archived.
ISSUE: none (local planning draft)

This packet organizes Ed's 22 requests from the Zones / Faces, Assemblies and Windows review.
It is a new pass, separate from the archived UI and UX refinement. No code, host interaction,
Design System edit or skill edit is part of this planning commit.

## Read order

1. [REQUESTS.md](REQUESTS.md): every owner request, screenshot reference, recommendation and uncertainty.
2. [PLAN.md](PLAN.md): investigation checkpoint, proposed PR boundaries and dependencies.
3. [DECISIONS.md](DECISIONS.md): settled scope and design choices still open.
4. [ACCEPTANCE.md](ACCEPTANCE.md): verification and evidence requirements.
5. [STATUS.md](STATUS.md): delivery ledger and next authorized action.

## Design direction

Design from the consultant's task: clear, intuitive, flexible and forgiving. Use progressive
disclosure for secondary tools and information, while keeping active state and recovery visible.
Ed authorizes thoughtful disagreement with his suggested solutions. Recommendations are not
accepted decisions merely because they appear in this packet.

The [UI polish skill](../../../.agents/skills/ph-composer-ui-polish/SKILL.md), its linked
patterns and the [UI baseline](../../ui-baseline/README.md) govern the work. Source remains
behavioral authority. Shared kit changes must be reflected in the skill and the private Design
System once accepted and merged. Screenshots remain outside tracked files.

## Boundaries

In scope: shared tables, feedback, dialogs and library setup; Zones / Faces workspace;
Assembly Builder authoring parity; Windows library consistency and toolbar polish.

Out of scope: new Spaces, Thermal Bridges or Systems features, designPH integration,
provider privilege, stored-data migrations, exporter changes, release and platform claims.
If investigation reveals a contract or model change is necessary, identify it explicitly and
resolve the scope before implementation. Existing keyboard-focus work remains separately owned
by [panel-keyboard-focus](../../features/unscheduled/panel-keyboard-focus/README.md); coordinate overlapping
fixes rather than duplicate or silently close that packet.
