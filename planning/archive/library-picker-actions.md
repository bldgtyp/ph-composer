# Libraries picker actions

DATE: 2026-10-07
STATUS: Complete; current-host acceptance passed; remote delivery pending
ISSUE: [#43](https://github.com/bldgtyp/ph-composer/issues/43)

Keep the implemented equal file/folder route cards without apply glyphs, and Done for the
immediate-change dialog. This is the authorized product decision; it matches the current
accepted Library pattern. The old issue's action-row implementation has already been replaced.

## Current execution receipt

- Source: `codex/issue-43-library-picker-actions`, based on `main@727c2ba`; shipping code unchanged.
- Verification: all nine setup tests pass. Unchanged full offline gate/coverage reused.
- Review: focused source/document consistency plus independent architecture/UI/provenance
  review passed with no findings; screenshot/fixture/helper hashes and restoration verified.
- Native: readable/unreadable and fresh normal restoration pass with native pixels plus readback;
  [evidence](../native-acceptance/evidence/library-picker-actions-2026-10-07.md). Installed package
  matches 390 files; original preferences preserved and fixture unmodified; no human action needed.
- Acceptance scope: the issue's current-host look; no new release/platform claim.
- Next: signed evidence commit, PR, dual-Ruby CI, merge and verified branch cleanup, then #41.
