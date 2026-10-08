# Export result vocabulary

DATE: 2026-10-07
STATUS: Complete; merged; branches cleaned
ISSUE: [#41](https://github.com/bldgtyp/ph-composer/issues/41)

Translation messages name authored Materials and Assemblies. A missing or invalid segment Material
names its Assembly and authored Layer position and asks for a Material. Thermal-mass defaults name
the Material and Assembly; preflight defaults also name the Material. Codes, IDs, schemas, availability,
blocking policy and calculations remain unchanged. Names are plain text in the shared UI.

## Current execution receipt

- Source: `codex/issue-41-export-result-language`, based on `main@d5e7843`.
- Baseline: four missing/blank/wrong-type variants reproduced the internal segment-ID sentence.
- Focused: 31 construction tests include pinned-Honeybee round trips; 21 panel tests pass.
  A shared synthetic expected finding fixture connects actual Python output to panel rendering.
- Gates: final `make ci` passed after committing the new fixture required by fixtures-check.
  Ruby 97.0%, JavaScript 96.3%, Python 95.60% coverage; lint, types, manifest and RBZ checks pass.
- Review: independent architecture/UI review passed with no findings. No UI calculation or
  feature-specific Export-screen mapping introduced. No shared UI-kit pattern change to sync.
- Native: normal installed runtime, native Save and actual Export pane passed;
  [receipt](../native-acceptance/evidence/export-result-vocabulary-2026-10-07.md).
  Synthetic fixture saved clean; panel closed. No human action needed.
- Delivery: [PR #91](https://github.com/bldgtyp/ph-composer/pull/91) merged as `dd4aa89` after both Ruby CI jobs passed. Local/remote branches removed and absence verified.
