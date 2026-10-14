# Cross-phase packets

DATE: 2026-09-30
STATUS: Active index.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

Packets whose scope is delivered in slices across several phases. Each records its per-phase
allocation in its own PLAN or STATUS.

| Packet | Delivered so far | Remaining |
| --- | --- | --- |
| [units](units/README.md) | The shared modules, in Phase 0 | Follow-ups and new quantities, with each owning feature |
| [validation-and-export](validation-and-export/README.md) | The HBJSON/report workflow, in Phase 1 | Each later feature's contributor and findings; METr in its own packet |
| [geometry-contribution-contracts](geometry-contribution-contracts/STATUS.md) | Edge entries in the export snapshot (G-02, PR 119), from the architecture refactoring | G-01, G-03, G-04 with the thermal-bridge adopter; the [phase 3b ledger](../phase-03b-thermal-bridges/STATUS.md#deferred-foundation-stages) schedules them |
