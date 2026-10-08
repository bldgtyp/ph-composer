# Windows preview repaint wait

DATE: 2026-10-07
STATUS: Merged to main through PR #88
ISSUE: [#44](https://github.com/bldgtyp/ph-composer/issues/44)

The existing check waits for two animation frames after the full-page screenshot, before
resolving the drawing element. The screenshot can resize the page, and the Window Type editor's
ResizeObserver repaints its drawing. The wait landed on 2026-10-03 in `ef7adc1`; this issue
predates it. No additional code change was needed.

## Current execution receipt

- Source: `codex/issue-44-window-preview-wait`, shipping/test source unchanged from `main@5931c89`.
- Acceptance: 20 consecutive `windows_checks.cjs` runs passed, each at 1280, 900, 420 and 280 px
  with headless installed Chrome 154.0.8037.98 against `make ui-preview`'s loopback server.
  All 80 viewport cases passed, with no page errors. No fixed sleep added.
- Evidence: per-run logs and SHA-256 receipt are ignored in `_private/issue-sweep/issue44/`.
- Verification: source/document consistency review passed. Reuse #42's full offline gate and
  coverage because code, tests, manifest and dependencies are unchanged. Browser acceptance is
  bounded to these observations; it does not prove native acceptance or all scheduling conditions.
- Delivery: signed evidence-only [PR #88](https://github.com/bldgtyp/ph-composer/pull/88)
  merged at `139ccee` after both remote Ruby jobs passed on `7964c96`. Main synchronized; local
  branch removed after merge verification; remote branch automatically removed by GitHub.
- Next: issue #48 in the sequential queue.
