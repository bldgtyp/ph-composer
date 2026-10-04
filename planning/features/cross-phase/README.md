# Cross-phase packets

DATE: 2026-09-30
STATUS: Active index.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

Packets whose scope is delivered in slices across several phases. Each records its per-phase
allocation in its own PLAN or STATUS.

| Packet | Delivered so far | Remaining |
| --- | --- | --- |
| [ui-ux-polish](ui-ux-polish/README.md) | Initial review and planning checkpoint, 2026-10-04 | Investigations, accepted design choices, seven proposed PRs and acceptance; implementation not authorized |
| [units](units/README.md) | The shared modules, in Phase 0 | Follow-ups and new quantities, with each owning feature |
| [validation-and-export](validation-and-export/README.md) | The HBJSON/report workflow, in Phase 1 | Each later feature's contributor and findings; METr in its own packet |
