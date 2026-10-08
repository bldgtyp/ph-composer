# GitHub issue delivery queue

DATE: 2026-10-07
STATUS: Complete; all eleven issues closed, delivered branches cleaned
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
| 0 | [#78](https://github.com/bldgtyp/ph-composer/issues/78) | [Managed Zone options](zone-field-options/STATUS.md) | Closed against merged PR #80 and archived acceptance |
| 1 | [#53](https://github.com/bldgtyp/ph-composer/issues/53) | [Preview validation refusal](preview-user-error.md) | Merged in PR #86 as `80bc4aa`; branches cleaned |
| 2 | [#42](https://github.com/bldgtyp/ph-composer/issues/42) | [Product-side reading order](product-use-side-order.md) | Merged in PR #87 as `5931c89`; branches cleaned |
| 3 | [#44](https://github.com/bldgtyp/ph-composer/issues/44) | [Preview check reliability](windows-preview-repaint-wait.md) | Merged in PR #88 as `139ccee`; branches cleaned |
| 4 | [#48](https://github.com/bldgtyp/ph-composer/issues/48) | [Tab action guidance](tab-action-guidance.md) | Merged in PR #89 as `727c2ba`; branches cleaned |
| 5 | [#43](https://github.com/bldgtyp/ph-composer/issues/43) | [Library picker hierarchy](library-picker-actions.md) | Merged in PR #90 as `d5e7843`; branches cleaned |
| 6 | [#41](https://github.com/bldgtyp/ph-composer/issues/41) | [Export result vocabulary](export-result-vocabulary.md) | Merged in PR #91 as `dd4aa89`; branches cleaned |
| 7 | [#54](https://github.com/bldgtyp/ph-composer/issues/54) | [Catalog note codes](catalog-note-contract.md) | Merged in PR #92 as `aec762b`; branches cleaned |
| 8 | [#52](https://github.com/bldgtyp/ph-composer/issues/52) | [Foundation refusal meanings](refusal-discovery.md) | Merged in PR #93 as `a4c45b5`; branches cleaned |
| 9 | [#47](https://github.com/bldgtyp/ph-composer/issues/47) | [Shared single-value editor](single-value-bubble.md) | Merged in PR #94 as `c82a945`; branches cleaned; DesignSystem synced |
| 10 | [#51](https://github.com/bldgtyp/ph-composer/issues/51) | [Callback refusal declarations](library-callback-refusals.md) | Merged in PR #95 as `5f69340`; branches cleaned |

Delivered source: `main@5f69340`. PRs #86 through #95 merged in the order above after scoped
review and green Ruby 2.7.2/3.2.2 remote CI. Merge commits were verified on main and each local
and remote issue branch removed before starting the next item. No new issues were needed.
Final GitHub open-issue query returned an empty list.

Human actions: none required. Native acceptance for library setup, export findings and the
shared editors was completed through the bridge and native controls. The final callback slice
passed `make ci` and coverage (Ruby 97.0%, JS 96.3%, Python 95.60%) with no remaining review
findings. Implementation and delivery are complete; this receipt closes the workflow record.
Release, SketchUp 2023 native proof, Windows support and certification remain separate gates.

### Issue #42 checkpoint

The out-of-order fixture reproduced `Bottom, left, right, top (default)` before the fix.
The view now reuses the editor's canonical side order. All 14 inventory tests pass, preserving
inheritance labels, first-use navigation and snapshot data. JS lint and coverage (96.3%) pass;
final `make ci` and independent architecture/UI review passed with no findings. No human or native gate is specified for #42.

Issue #44 acceptance and unchanged-check reuse: [receipt](windows-preview-repaint-wait.md).

### Issue #47 checkpoint

[Shared value-bubble receipt](single-value-bubble.md) records unchanged existing
regressions, callback/disposal tests, full gates, all browser widths and fresh native GH47 acceptance.
Both original feature owners retain guarded commands. No manual host action remains.
PR #94 merged after both remote Ruby jobs passed. The private static DesignSystem README was
synced to `main@c82a945` and verified after reload; CSS, tokens and the fifteen gallery parts
remain unchanged. The artifact remains private.
