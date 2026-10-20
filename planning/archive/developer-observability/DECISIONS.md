# Developer observability: decisions

DATE: 2026-10-19
STATUS: Complete
AUTHOR: Ed May, BLDGTYP, with Codex
ISSUE: [#254](https://github.com/bldgtyp/ph-composer/issues/254)

Ed accepted all recommended steps and phases on 2026-10-19 and requested separate feature packets
for developer tooling and end-user production support. No code has started in this chat.

| ID | Accepted direction | Consequence |
| --- | --- | --- |
| DV-D01 | Independent feature packet and implementation chat | Own PRD, stage ledger and acceptance; no developer release gate is added to production support |
| DV-D02 | Extend existing tools | Reuse bridge, Playwright library scripts, runtime measurements and acceptance provenance |
| DV-D03 | Browser collector and bounded waits first | DV-01/DV-02 can proceed independently of production support |
| DV-D04 | One shared diagnostic projection | Production PS-01 owns the schema/store/read projection; DV-03 consumes it after landing |
| DV-D05 | Explicit synthetic faults and verified restore | Development helpers remain outside the RBZ and do not target working user Models |
| DV-D06 | Product assertions stay with product fixes | Production PS-01/PS-02/PS-05 own behavior evidence; developer stages test tooling mechanics and link those receipts |
| DV-D07 | No new backend or product-agent authority | Hosted telemetry, another eval server, public log readers and grant changes remain outside scope |

Routine choices of helper names, output bounds and polling defaults belong to the owning stage
and its tests. They do not require another product interview. Broader data access, background
transmission or automation against user work would change scope and return to Ed.
