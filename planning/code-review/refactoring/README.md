# Architecture refactoring plans

DATE: 2026-10-13
STATUS: Scoped; twelve packets reviewed against source and fleshed out for implementation handoff on 2026-10-13. Direction accepted; implementation authorized on 2026-10-13, delivered one stage per PR in the [delivery order](DELIVERY_ORDER.md).
ISSUE: none (local planning draft)
BASELINE: `cfe01a6aad99a0e09d5ecf0de5659c606d7ba4f9`

Start with the accepted [Zone-child pattern](ZONE_CHILD_PATTERN.md) and the source-backed
[Windows rationale](../WINDOWS_BOUNDARY.md). Reusable values stay independent of their placement;
authoring coordinators compose owner operations and native adapters.

Each packet holds three files. `PLAN.md` is the phased plan a coding agent executes from: a table of
what the source does at the baseline, the target design with concrete Ruby or JavaScript shapes, one
`### Stage` section per stage with files, tests and commands, and a decisions table that separates
what the agent decides from what goes to Ed. `STATUS.md` is the stage ledger; it says the phases live
in `PLAN.md` under `## Stages` and there is no `phases/` folder, which is what to tell `implement`
when it asks where the phases are. `ACCEPTANCE.md` holds the observable checks; its case ids are
stable, and rows a later simplification made moot are marked withdrawn rather than renumbered.

## Packets and readiness

| Packet | Findings | Readiness | Documents |
| --- | --- | --- | --- |
| Export contract wording | F08 | Complete; merged 2026-10-13 ([PR #99](https://github.com/bldgtyp/ph-composer/pull/99)) | archived at [planning/archive/export-contract-wording](../../archive/export-contract-wording/PLAN.md) |
| Outcome hook isolation | JS-02 | Complete; merged 2026-10-13 ([PR #102](https://github.com/bldgtyp/ph-composer/pull/102)) | archived at [planning/archive/outcome-hook-isolation](../../archive/outcome-hook-isolation/PLAN.md) |
| Contributor example lifecycle | JS-03, JS-04 | Complete; merged 2026-10-13 ([PR #102](https://github.com/bldgtyp/ph-composer/pull/102)) | archived at [planning/archive/contributor-example-lifecycle](../../archive/contributor-example-lifecycle/PLAN.md) |
| Registration reliability | F01, F02 | Implementation ready, three stages, first of the foundation pair | [plan](registration-reliability/PLAN.md), [status](registration-reliability/STATUS.md), [acceptance](registration-reliability/ACCEPTANCE.md) |
| Cross-feature composition | F04 | Implementation ready after RR-02, four stages | [plan](cross-feature-composition/PLAN.md), [status](cross-feature-composition/STATUS.md), [acceptance](cross-feature-composition/ACCEPTANCE.md) |
| Windows orchestration | RF-02 | Implementation ready, three stages | [plan](windows-orchestration/PLAN.md), [status](windows-orchestration/STATUS.md), [acceptance](windows-orchestration/ACCEPTANCE.md) |
| Panel domain ownership | JS-01, JS-05 | Implementation ready, four stages, two independent slices | [plan](panel-domain-ownership/PLAN.md), [status](panel-domain-ownership/STATUS.md), [acceptance](panel-domain-ownership/ACCEPTANCE.md) |
| Library contracts | F05, RF-04 | Implementation ready after RR-02, four stages | [plan](library-contracts/PLAN.md), [status](library-contracts/STATUS.md), [acceptance](library-contracts/ACCEPTANCE.md) |
| Entity customization | RF-01, RF-03, F07 | EC-01 and EC-02 ready; EC-03 is a contract stage for Ed before EC-04 | [plan](entity-customization/PLAN.md), [status](entity-customization/STATUS.md), [acceptance](entity-customization/ACCEPTANCE.md) |
| Zone-child lifecycle | copied-Zone Windows request, shared pattern | Design; ZC-01 is a host spike with a document deliverable | [plan](zone-child-lifecycle/PLAN.md), [status](zone-child-lifecycle/STATUS.md), [acceptance](zone-child-lifecycle/ACCEPTANCE.md) |
| Geometry contribution contracts | F06 | G-02 ready; the rest waits for the thermal-bridge adopter | [plan](geometry-contribution-contracts/PLAN.md), [status](geometry-contribution-contracts/STATUS.md), [acceptance](geometry-contribution-contracts/ACCEPTANCE.md) |
| Foundation purity | F03 | Implementation ready, optional, lowest priority | [plan](foundation-purity/PLAN.md), [status](foundation-purity/STATUS.md), [acceptance](foundation-purity/ACCEPTANCE.md) |

[Delivery order](DELIVERY_ORDER.md) records dependencies and PR boundaries. [Decisions](DECISIONS.md)
records Ed's accepted direction, the technical defaults, the deviations the 2026-10-13 source review
introduced, and the questions still open. [Status](STATUS.md) is the program ledger.

## Handing a packet to a coding agent

Give the agent the packet folder. It reads `STATUS.md`, then `PLAN.md`, and implements the first
stage whose state is `Scoped`. One stage is one reviewable change. Before starting a stage the
agent confirms the dependency named in the plan's header has landed. A stage that names a document
deliverable (ZC-01, G-01, EC-03) ends with the document and a note to Ed, not with code.

Each plan's "Verified at the baseline" table was checked against `cfe01a6` on 2026-10-13. A later
head may have moved a method; the table names files and methods rather than line numbers so the
agent can re-find them. Planning points at code; code never cites planning.
