# Managed Zone options: status

DATE: 2026-10-05
STATUS: Merged to main through PR #80; current-host acceptance complete
AUTHOR: Ed May, BLDGTYP, with Codex
ISSUE: [#78](https://github.com/bldgtyp/ph-composer/issues/78)
PR: [#80](https://github.com/bldgtyp/ph-composer/pull/80)

Ed authorized the whole packet on a new branch and accepted D2–D10 on 2026-10-05.
Implementation was on `codex/zone-field-options`, based on `627b4f7`; checkpoint `941166a`.
PR #80 merged on 2026-10-05 at `81f5426` after both GitHub Ruby matrix jobs passed on `ddc295e`.

## Current execution receipt

- Scope: model-owned choices/default, versioned Zone/stamp compatibility, explicit adoption,
  portable recovery, atomic management/reference retargeting, chip/dialog presentation, ID filters,
  custom colours and stable export identities are implemented and verified.
- Verification: final `make ci` passed: 1,451 Ruby cases / 14,745 assertions, 475 JS cases and
  191 Python cases, with lint, typing, fixtures, manifests, runtime pins, hostkit and RBZ checks.
  Implementation-checkpoint coverage: Ruby 97.0%, JS 96.3%, Python 95.59%. Ruby 2.7 focused and Chromium 88 runtime checks pass.
  Real Chrome panel previews at 1280/900/420/280 px pass.
- Review: the coherent stronger independent architecture/UI `simplify` review is closed, including
  independently reproduced corrections to portable typed-reference validation and adoption-survivor
  serialization. [Implementation review](evidence/implementation-review.md).
- Native: original ZO-H1/H2/H3/O7 observations passed on SketchUp 26.1.188 / Ruby 3.2.2, with native controls and separate
  readback, immutable fixture/build baselines, exact Undo/Redo, within/between-Model copy,
  split/Restore and fresh normal-process reopen. [Native evidence](../../native-acceptance/evidence/zone-field-options-2026-10-05.md).
- Build: installed RBZ matches all 387 packaged files, no extras or mismatches; SHA-256
  `97d30a432c31ac7132d853e52fe94bade8f8cbddb130ccbc86aac49c5be95f2c`.
  Raw logs, Models, captures and immutable receipts are ignored under
  `_private/host/zone-field-options-20261005/`.
- Normal restoration: saved source/destination reopened with exact records/defaults/metadata/stamps,
  new sessions, no fixture helper/test styles and no Model writes from reads/opening. The normal
  source Model is left open; the panel is closed. The final corrected build’s normal source readback
  matches exact option/Zone/stamp data with no fixture helper or Model writes.
- Delivery: Ed authorized addressing the inline findings and merging once resolved. All four
  threads are resolved. Both GitHub `make ci` jobs (Ruby 2.7.2 and 3.2.2) passed on `ddc295e`;
  [PR #80](https://github.com/bldgtyp/ph-composer/pull/80) merged at `81f5426`. Local main is synchronized.
  Release, SketchUp 2023 native proof and Windows support remain separate gates. No task memory changed.
- Design System reading aid: the existing private artifact was synchronized to `main@4f51621` on
  2026-10-05. Its six embedded stylesheets match the repository sources, and the repaired gallery
  renders static component previews. Repository stylesheets remain authoritative; see the
  [sync receipt](../../refactor/ui-ux-refinements.md#design-system-sync-receipt).

Ed confirmed the three Zone rows render normally and supplied a native screenshot of `source.skp`
on 2026-10-05. The screenshot shows all three rows with the managed Segment/Level chips and custom
colours, closing the final normal-panel visual observation. Earlier automated white captures remain
recorded as unsuccessful observations; no product rendering defect or shipping fix is asserted.
Ed also reports successful testing in multiple files, without a separate assertion-level matrix.
The completed packet is archived and merged; the private Design System reading-aid follow-up is
closed. Release remains a separate gate.

PR #80 review corrections: [receipt](evidence/pr80-review-corrections.md). All four findings are addressed;
local full gate, current-host public preflight probe and required remote dual-Ruby checks passed;
merge is verified. Original native receipts retain their original package identity; the final
corrected build’s package and normal-restoration evidence are in the correction receipt.
