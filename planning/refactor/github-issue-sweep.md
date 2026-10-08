# GitHub issue delivery queue

DATE: 2026-10-07
STATUS: In progress
AUTHOR: Ed May, BLDGTYP, with Codex

Ed authorized all open repository issues, product decisions, one branch per issue,
signed commits, review, merge after green CI, and verified local/remote branch cleanup.
New issues discovered within this scope may enter the queue. Work starts on each next issue
only after the previous merge and cleanup. Unavoidable manual steps collect in one phase.

## Current execution receipt

Ordinary fixes use focused checks, coverage, one coherent review and `make ci`.
API/callback/host boundaries use stronger architecture review and applicable native checks.
Required remote CI covers Ruby 2.7.2 and 3.2.2. Rank reflects importance, effort and dependencies.

| Order | Issue | Scope | State |
| --- | --- | --- | --- |
| 0 | [#78](https://github.com/bldgtyp/ph-composer/issues/78) | Managed Zone options | Closed against merged PR #80 and archived acceptance |
| 1 | [#53](https://github.com/bldgtyp/ph-composer/issues/53) | Preview validation refusal | Offline verification/review passed; PR/CI pending |
| 2 | [#42](https://github.com/bldgtyp/ph-composer/issues/42) | Product-side reading order | Queued |
| 3 | [#44](https://github.com/bldgtyp/ph-composer/issues/44) | Preview check reliability | Queued |
| 4 | [#48](https://github.com/bldgtyp/ph-composer/issues/48) | Tab action guidance | Queued |
| 5 | [#43](https://github.com/bldgtyp/ph-composer/issues/43) | Library picker hierarchy | Queued; native look required |
| 6 | [#41](https://github.com/bldgtyp/ph-composer/issues/41) | Export result vocabulary | Queued; native look required |
| 7 | [#54](https://github.com/bldgtyp/ph-composer/issues/54) | Catalog note codes | Queued |
| 8 | [#52](https://github.com/bldgtyp/ph-composer/issues/52) | Foundation refusal meanings | Queued |
| 9 | [#47](https://github.com/bldgtyp/ph-composer/issues/47) | Shared single-value editor | Queued |
| 10 | [#51](https://github.com/bldgtyp/ph-composer/issues/51) | Callback refusal declarations | Queued |

Source: `codex/issue-53-preview-validation`, based on `main@bd8c559`.
Evidence: [preview validation](../archive/preview-user-error.md).
Human actions: none identified. Next: finish #53 CI, PR, merge and cleanup, then #42.
Release, SketchUp 2023 native proof, Windows support and certification remain separate gates.
