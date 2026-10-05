# Managed Zone options: decisions

DATE: 2026-10-05
STATUS: Recommendations awaiting owner approval
AUTHOR: Ed May, BLDGTYP, with Codex
ISSUE: [#78](https://github.com/bldgtyp/ph-composer/issues/78)

| ID | Decision | State / recommended default |
| --- | --- | --- |
| D1 | Two existing fields become managed selects; users can edit options and colours | Requested by Ed |
| D2 | Where to manage options | Proposed: respective column menus open one reused management dialog; no new tab |
| D3 | Identity and ownership | Proposed: model-owned records with stable IDs; Zone references IDs, not category names |
| D4 | Name equivalence | Proposed: case-insensitive, whitespace-normalized, spaces/hyphens/underscores equivalent; preserve display spelling |
| D5 | Management transaction | Proposed: dialog draft, explicit Save/Cancel; one atomic Undo step per saved batch |
| D6 | New-model defaults | Proposed: one Segment seeded from the existing Model-name default when first needed by a write; Level remains Not set. Later filename changes do not rename it |
| D7 | Older Models | Proposed: explicit adoption preview; preserve exact categories unless owner-approved merges resolve collisions; no mutation on read/open |
| D8 | Deletion and merge | Proposed: replacement or nullable Level clear, including membership-stamp recovery references; preserve surviving option colour |
| D9 | Export identity | Proposed: keep existing Segment export identifiers during adoption and hold them stable through rename; merge adopts the surviving target's identity |
| D10 | Copy/paste and older callers | Open implementation frontier: define portable recovery and legacy string-write policy before schema changes; never silently create missing choices |

The implementation checkpoint requires decisions D2 to D10 to be confirmed or revised. The packet
records a recommendation, not an accepted schema. Choose field names, record-kind names and prefixes
through the existing contributor/record conventions during contract design.
