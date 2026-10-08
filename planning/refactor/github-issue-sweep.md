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
| 1 | [#53](https://github.com/bldgtyp/ph-composer/issues/53) | Preview validation refusal | Merged in PR #86 as `80bc4aa`; branches cleaned |
| 2 | [#42](https://github.com/bldgtyp/ph-composer/issues/42) | Product-side reading order | Merged in PR #87 as `5931c89`; branches cleaned |
| 3 | [#44](https://github.com/bldgtyp/ph-composer/issues/44) | Preview check reliability | Merged in PR #88 as `139ccee`; branches cleaned |
| 4 | [#48](https://github.com/bldgtyp/ph-composer/issues/48) | Tab action guidance | Merged in PR #89 as `727c2ba`; branches cleaned |
| 5 | [#43](https://github.com/bldgtyp/ph-composer/issues/43) | Library picker hierarchy | Merged in PR #90 as `d5e7843`; branches cleaned |
| 6 | [#41](https://github.com/bldgtyp/ph-composer/issues/41) | Export result vocabulary | Merged in PR #91 as `dd4aa89`; branches cleaned |
| 7 | [#54](https://github.com/bldgtyp/ph-composer/issues/54) | Catalog note codes | Merged in PR #92 as `aec762b`; branches cleaned |
| 8 | [#52](https://github.com/bldgtyp/ph-composer/issues/52) | Foundation refusal meanings | Merged in PR #93 as `a4c45b5`; branches cleaned |
| 9 | [#47](https://github.com/bldgtyp/ph-composer/issues/47) | Shared single-value editor | Merged in PR #94 as `c82a945`; branches cleaned; DesignSystem synced |
| 10 | [#51](https://github.com/bldgtyp/ph-composer/issues/51) | Callback refusal declarations | Implemented; focused checks passed; final gates and review pending |

Source: `codex/issue-51-library-callback-refusals`, based on `main@c82a945`.
Evidence: [preview validation](../archive/preview-user-error.md),
[product-use side order](../archive/product-use-side-order.md).
Human actions: none required. Next: deliver the final issue #51 through review, full gates,
PR, dual-Ruby CI and verified merge/cleanup.
Release, SketchUp 2023 native proof, Windows support and certification remain separate gates.

### Issue #42 checkpoint

The out-of-order fixture reproduced `Bottom, left, right, top (default)` before the fix.
The view now reuses the editor's canonical side order. All 14 inventory tests pass, preserving
inheritance labels, first-use navigation and snapshot data. JS lint and coverage (96.3%) pass;
final `make ci` and independent architecture/UI review passed with no findings. No human or native gate is specified for #42.

Issue #44 acceptance and unchanged-check reuse: [receipt](../archive/windows-preview-repaint-wait.md).

### Issue #47 checkpoint

[Shared value-bubble receipt](../archive/single-value-bubble.md) records unchanged existing
regressions, callback/disposal tests, full gates, all browser widths and fresh native GH47 acceptance.
Both original feature owners retain guarded commands. No manual host action remains.
PR #94 merged after both remote Ruby jobs passed. The private static DesignSystem README was
synced to `main@c82a945` and verified after reload; CSS, tokens and the fifteen gallery parts
remain unchanged. The artifact remains private.
