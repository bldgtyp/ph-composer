# Refactoring status

DATE: 2026-10-13
STATUS: In progress; Ed authorized implementation on 2026-10-13, one stage per PR through the pr-loop. First PR: export wording EW-01 ([#99](https://github.com/bldgtyp/ph-composer/pull/99)).
ISSUE: none (local planning draft)

Ed accepted C1, C2, W1 and the Zone-child pattern on 2026-10-13. The same day the twelve plans were
reviewed against the baseline source and rewritten as phased implementation plans with per-packet
stage ledgers. Four technical defaults were simplified in that review and Ed accepted them the same day; they
are listed in [DECISIONS.md](DECISIONS.md) under "Deviations recorded 2026-10-13". Delivery began the same day:
issues and PRs are linked from each packet row as they open.

| Packet | Findings | Stages | State |
| --- | --- | --- | --- |
| [Export wording](export-contract-wording/STATUS.md) | F08 | EW-01 | Implemented on branch; [issue 98](https://github.com/bldgtyp/ph-composer/issues/98) |
| [Outcome hook](outcome-hook-isolation/STATUS.md) | JS-02 | OH-01, OH-02 | Scoped; implementation ready |
| [Contributor example](contributor-example-lifecycle/STATUS.md) | JS-03, JS-04 | CE-01 to CE-03 | Scoped; implementation ready |
| [Registration](registration-reliability/STATUS.md) | F01, F02 | RR-01 to RR-03 | Scoped; implementation ready |
| [Composition](cross-feature-composition/STATUS.md) | F04 | C-01 to C-04 | Scoped; after RR-02 |
| [Windows coordinator](windows-orchestration/STATUS.md) | RF-02 | W-01 to W-03 | Scoped; implementation ready |
| [Panel facts](panel-domain-ownership/STATUS.md) | JS-01, JS-05 | PD-01 to PD-04 | Scoped; implementation ready |
| [Library contracts](library-contracts/STATUS.md) | F05, RF-04 | LC-01 to LC-04 | Scoped; after RR-02 (LC-03 independent) |
| [Entity customization](entity-customization/STATUS.md) | RF-01, RF-03, F07 | EC-01 to EC-05 | Scoped; EC-03 needs Ed before EC-04 |
| [Zone-child lifecycle](zone-child-lifecycle/STATUS.md) | copied-Zone request | ZC-01 to ZC-04 | Design; ZC-01 is a host spike |
| [Geometry seams](geometry-contribution-contracts/STATUS.md) | F06 | G-01 to G-04 | Scoped; G-02 ready, rest with the adopter |
| [Foundation purity](foundation-purity/STATUS.md) | F03 | P-01 to P-03 | Scoped; optional |

Each packet's `STATUS.md` is its stage ledger and the entry point for `implement`. The
[review evidence](../evidence/README.md) records the unchanged baseline tests and probes.
[DELIVERY_ORDER.md](DELIVERY_ORDER.md) names dependencies and PR boundaries.

The 2026-10-13 source review found two facts the first drafts missed: a third `USER_DATA` constant
in Assemblies (export wording) and the Zones `retire_pairs` participant, called with non-JSON
arguments from the same feature (composition). Both are in their plans.
