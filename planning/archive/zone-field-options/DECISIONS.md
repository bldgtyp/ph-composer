# Managed Zone options: decisions

DATE: 2026-10-05
STATUS: Accepted by Ed on 2026-10-05
AUTHOR: Ed May, BLDGTYP, with Codex
ISSUE: [#78](https://github.com/bldgtyp/ph-composer/issues/78)

| ID | Decision | Accepted policy |
| --- | --- | --- |
| D1 | Two existing fields become managed selects; users can edit options and colours | Requested by Ed |
| D2 | Where to manage options | Accepted: respective column menus open one reused management dialog; no new tab |
| D3 | Identity and ownership | Accepted: model-owned records with stable IDs; Zone references IDs, not category names |
| D4 | Name equivalence | Accepted: case-insensitive, whitespace-normalized, spaces/hyphens/underscores equivalent; preserve display spelling |
| D5 | Management transaction | Accepted: dialog draft, explicit Save/Cancel; one atomic Undo step per saved batch |
| D6 | New-model defaults | Accepted: one Segment seeded from the existing Model-name default when first needed by a write; Level remains Not set. Later filename changes do not rename it |
| D7 | Older Models | Accepted: explicit adoption preview; preserve exact categories unless owner-approved merges resolve collisions; no mutation on read/open |
| D8 | Deletion and merge | Accepted: replacement or nullable Level clear, including membership-stamp recovery references; preserve surviving option colour |
| D9 | Export identity | Accepted: keep existing Segment export identifiers during adoption and hold them stable through rename; merge adopts the surviving target's identity |
| D10 | Copy/paste and older callers | Accepted: portable recovery evidence travels with copied Zones/stamps; explicit destination adoption maps or creates local choices; older string callers resolve existing unambiguous options only, refusing unknown names |

Ed confirmed these defaults and D10 on 2026-10-05: "yes, accepted. Confirmed".
The reviewed implementation proposal is in DESIGN.md, including export-key collision refusal and
the detached membership-stamp reference adapter. Implementation and acceptance remain outstanding.
