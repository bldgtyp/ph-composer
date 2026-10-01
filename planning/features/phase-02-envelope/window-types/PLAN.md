# Window Types and placement: implementation plan

DATE: 2026-09-30
STATUS: Scoped. Not authorized.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

The [PRD](PRD.md) owns behavior. The [Phase 2 plan](../PLAN.md) sequences delivery and
[CONTRACTS](../CONTRACTS.md) binds names. This file allocates the PRD to stages and carries the
five consequences of the component spike.

## Allocation

| PRD scope | Stage |
| --- | --- |
| Frame, Glazing, Psi-Install Type and Window Type records, grid operations, thermal display values, the Installs commit, model defaults | [P2-10](../phases/p2-10-window-records.md) |
| The Builder, Installs, U-Values, three Library subtabs | [P2-11](../phases/p2-11-window-type-builder.md) |
| The window unit, the generated definition, place, type rewrite, Swap type, Re-host, Reset to type, Restore unit, native-edit states | [P2-12](../phases/p2-12-window-unit-and-placement.md) |
| The Place tool, the Schedule, the Window Type Colour-by mode | [P2-13](../phases/p2-13-place-tool-schedule-colour-by.md) |
| Export mapping, validation rows, the g-value exception, net opaque area | [P2-14](../phases/p2-14-aperture-export.md) |
| Library adapters for the three product kinds | [P2-15](../phases/p2-15-window-library-kinds.md) |
| "Through PHX" acceptance | Deferred to [metr-export](../../unscheduled/metr-export/README.md) |
| Explicit door support, reveal geometry | Later, as the PRD records |

## The spike's five consequences

From [B3](../../../archive/phase-00-foundation/evidence/spike-window.md). Each is bound to a stage step.

| Consequence | Where it is implemented |
| --- | --- |
| Panes authored facing out | P2-12 slice C, the definition generator, with a test |
| Net area never read from `Face#area` | P2-14 step 2 and step 9: areas come from the unit's outline |
| Glue verified geometrically | P2-12 slice C, the hosted check, used by placement, Re-host, the Schedule and export |
| `no_scale_mask` is UI only | P2-12 slice C, the scaled and mirrored states read the transformation |
| A type edit re-validates placements | P2-12 slice C, the `types.update` preview blocks on a unit leaving its host or overlapping |

## Why Place is a tool

`context/TECH_STACK.md`, "Rules for later features", makes select-then-act the default and lets a
modal tool be primary only when the feature's plan records why. Ed confirmed on 2026-09-30 (D2-2)
that the Place tool is the primary route for windows. The reason: a placement needs a point on
the host Face and a live outline at that point before it commits, and a selection carries
neither. A right-click on a selected Face, choosing a Window Type, starts the tool with that Face
as the host, so the geometry-first entry exists as well. The tool calls the same `units.place`
action a script does.

## Code owner and boundaries

Feature id `ph_composer.windows`, folder `src/ph_composer/features/windows/`, requiring
`ph_composer.zones`. Under the layering Ed set on 2026-10-01 (D2-1) it spans two layers. Products
and Window Types are definitions: their code calls nothing in Zones, and a test holds that line,
so the Window Types tab and the product Library subtabs work in a Model with no Zone. The unit and
placement are the placed layer: they read host Face state through Zones' reads and write no Face
record. Zones never requires windows. Splitting the feature in two stays an option if the internal
line proves hard to hold.
Zones gains two rules for cutting components that name no feature (D2-5, confirmed 2026-09-30).

## Verification and handoff

Acceptance rows E10 to E15 in the [register](../ACCEPTANCE.md).
