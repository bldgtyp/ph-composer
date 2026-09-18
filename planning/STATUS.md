# Planning Status

DATE: 2026-09-18
STATUS: Active index of tracked planning work.
AUTHOR: Ed May, BLDGTYP

Master index. Every active item gets a row; archived items move to
`archive/README.md`.

The order the work is planned in is in [ROADMAP.md](ROADMAP.md).

## Active work

| Item | Kind | State | Issue | Pointer |
| ---- | ---- | ----- | ----- | ------- |
| Zones and adjacency | feature | Scoped, interviewed | none (no remote) | [features/zones-and-adjacency/](features/zones-and-adjacency/README.md) |
| Face assignment | feature | Scoped, interviewed | none (no remote) | [features/face-assignment/](features/face-assignment/README.md) |
| Spaces | feature | Scoped, interviewed | none (no remote) | [features/spaces/](features/spaces/README.md) |
| Assemblies and materials | feature | Scoped, interviewed | none (no remote) | [features/assemblies/](features/assemblies/README.md) |
| Window Types and placement | feature | Scoped, interviewed | none (no remote) | [features/window-types/](features/window-types/README.md) |
| Libraries (provider seam) | feature | Scoped, interviewed | none (no remote) | [features/libraries/](features/libraries/README.md) |
| Units: SI and IP display | feature | Requested, PRD drafted | none (no remote) | [features/units/](features/units/README.md); a port of the predecessor's U1 |
| Thermal bridges | feature | Requested, PRD drafted | none (no remote) | [features/thermal-bridges/](features/thermal-bridges/README.md); owns the edge tagging rules |
| Hot water piping | feature | Requested, PRD drafted | none (no remote) | [features/hot-water-piping/](features/hot-water-piping/README.md) |
| ERV ducting | feature | Requested, PRD drafted | none (no remote) | [features/erv-ducting/](features/erv-ducting/README.md) |
| Equipment (seven families) | feature | Requested, PRD drafted | none (no remote) | [features/equipment/](features/equipment/README.md) |
| Climate data | feature, post-MVP | Requested, PRD drafted | none (no remote) | [features/climate-data/](features/climate-data/README.md) |
| Sun-path view | feature, post-MVP | Requested, PRD drafted | none (no remote) | [features/sun-path-view/](features/sun-path-view/README.md) |
| Window performance overlays | feature, post-MVP | Requested, PRD drafted | none (no remote) | [features/window-performance-overlays/](features/window-performance-overlays/README.md) |
| UI baseline from the predecessor's six screens | reference | Scoped | none (no remote) | [ui-baseline/](ui-baseline/README.md) |
| Window component host spike (glue, cut, select, rewrite, no-scale) | spike | Deferred | none (no remote) | window-types STATUS; runs with the overlay spike |
| Edge identity spike (attribute survival across split, weld, move, cut, Undo, reopen) | spike | Requested | none (no remote) | thermal-bridges PRD, "Edge tagging rules"; gates thermal bridges, piping and ducting |
| Overlay fill spike (alpha, depth, cost) | spike | Deferred | none (no remote) | face-assignment PRD, Q22; runs after the feature packets are drafted |
| Foundation transplant from the predecessor | refactor | Requested | none (no remote) | [FOUNDING_BRIEF.md](FOUNDING_BRIEF.md), transplant tables |
| PHX without Excel (spike) | external | Requested | [PH-Tools/PHX#157](https://github.com/PH-Tools/PHX/issues/157) | founding brief, open questions |

States: `Requested` · `Scoped` · `In progress` · `Blocked` · `In review` ·
`Implemented on branch` · `Merged to main` · `Complete` · `Deferred` ·
`Superseded`
