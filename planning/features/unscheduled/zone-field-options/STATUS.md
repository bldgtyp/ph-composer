# Managed Zone options: status

DATE: 2026-10-05
STATUS: Implemented locally; integration verification and native acceptance in progress
AUTHOR: Ed May, BLDGTYP, with Codex
ISSUE: [#78](https://github.com/bldgtyp/ph-composer/issues/78)

Ed authorized the whole packet on a new branch and confirmed D2–D10 on 2026-10-05.
Work is on `codex/zone-field-options`, based on `627b4f7`; all current changes belong to this task.

## Current execution receipt

- Completed implementation: model-owned choices/default, v1/v2 Zone/stamp handling, portable
  evidence, explicit adoption, collection validation, atomic management and reference inventory;
  select chips/dialogs, ID filters/colour projections; v2 export with supported legacy reads.
- Source/build: local working diff; API reference/extraction golden regenerated for the declared
  schema/contributor changes. No new build installed; SketchUp was inspected at its Welcome screen,
  with no open working document and no running bridge. Native fixture helper is prepared.
- Verification: full coverage passed: 1,448 Ruby cases / 14,706 assertions (97.0%), JavaScript
  96.3%, Python 95.59%. Twenty focused option cases passed including
  cross-Model explicit adoption, managed Restore, public commands and rollback. 82 focused JS cases
  and Chrome previews at 1280/900/420/280 px passed. 191 Python cases passed with real HBJSON reload
  identity/reference assertions. Ruby 2.7 focused checks and Chromium 88 runtime checks passed. Final lint/`make ci` remain pending.
- Review: accepted design review; one stronger `simplify` review of the combined implementation
  closed after independently reproducing and verifying two corrections: typed portable-extension
  reference validation and consistent adoption-survivor serialization. Native acceptance O7/H1–H3 and required host portions of O1–O9 remain NOT RUN.
- Decisions: D2–D10 accepted; no further owner choice pending. Local branch/commit work authorized;
  push, PR, merge and public release have not been requested.
- Exact next action: finish deterministic gates, commit the
  intended implementation checkpoint, install that reviewed build and execute the synthetic
  native acceptance batch with independent action/readback and immutable evidence.

Do not archive or claim completion before required host/final gates pass. No task memory was changed.
