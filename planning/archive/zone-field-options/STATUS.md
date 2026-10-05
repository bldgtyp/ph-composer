# Managed Zone options: status

DATE: 2026-10-05
STATUS: Complete implementation and current-host acceptance; PR #80 open, unmerged
AUTHOR: Ed May, BLDGTYP, with Codex
ISSUE: [#78](https://github.com/bldgtyp/ph-composer/issues/78)
PR: [#80](https://github.com/bldgtyp/ph-composer/pull/80)

Ed authorized the whole packet on a new branch and accepted D2–D10 on 2026-10-05.
Work is on `codex/zone-field-options`, based on `627b4f7`; implementation checkpoint `941166a`.

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
- Native: ZO-H1/H2/H3/O7 pass on SketchUp 26.1.188 / Ruby 3.2.2, with native controls and separate
  readback, immutable fixture/build baselines, exact Undo/Redo, within/between-Model copy,
  split/Restore and fresh normal-process reopen. [Native evidence](../../native-acceptance/evidence/zone-field-options-2026-10-05.md).
- Build: installed RBZ matches all 387 packaged files, no extras or mismatches; SHA-256
  `0c1241d3d20647f3e4f596919afe02f685238fab17f422c509b699b63c0205ac`.
  Raw logs, Models, captures and immutable receipts are ignored under
  `_private/host/zone-field-options-20261005/`.
- Normal restoration: saved source/destination reopened with exact records/defaults/metadata/stamps,
  new sessions, no fixture helper/test styles and no Model writes from reads/opening. The normal
  source Model and panel are left open.
- Delivery: Ed requested a PR on 2026-10-05. Branch pushed and [PR #80](https://github.com/bldgtyp/ph-composer/pull/80)
  opened against main; final visual hold closed by Ed. Ed subsequently authorized addressing the inline review and merging once resolved; release is not authorized. Shared Design System synchronization
  from main is deferred until merge. Native SketchUp 2023 and Windows proof
  remain separate repository gates. No task memory was changed.

Ed confirmed the three Zone rows render normally and supplied a native screenshot of `source.skp`
on 2026-10-05. The screenshot shows all three rows with the managed Segment/Level chips and custom
colours, closing the final normal-panel visual observation. Earlier automated white captures remain
recorded as unsuccessful observations; no product rendering defect or shipping fix is asserted.
Ed also reports successful testing in multiple files, without a separate assertion-level matrix.
The completed packet is archived. Merge/release and post-merge synchronization remain separate.

PR #80 review corrections: [receipt](evidence/pr80-review-corrections.md). All four findings are addressed;
local full gate and current-host public preflight probe pass. Required remote dual-Ruby checks and
verified merge are pending. Historical native/package evidence above is retained for its original build.
