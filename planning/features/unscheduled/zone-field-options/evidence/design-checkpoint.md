# Design checkpoint evidence

DATE: 2026-10-05
BRANCH: `codex/zone-field-options`
BASE: `627b4f7`
SCOPE: Proposal and development-only synthetic interaction study

## Current-source trace

- `zone/schema.rb` and `declarations/zone.rb`: v1 string fields and single-version descriptor;
  stamps copy strings, without option identity or portable definitions.
- `core/records/record_kind.rb`: one declared base schema version; extension-payload migration is
  not a Zone base-schema upgrade. Keep v1/v2 handling in the Zones owner.
- `zone/repair.rb:129`: Restore inventory suppresses stamps whose Zone ID exists anywhere live.
  Adoption must inspect all stamps separately, including collisions and non-restorable evidence.
- `zone/occurrences.rb:310`: Group copies can share member storage; preserve current uniqueness
  refusals. All stamp writers need explicit choice evidence during the v2 change.
- `faces/reference_targets.rb`: inventory includes orphan Face assignments, but not membership
  stamps. Add a declared stamp reference target for option deletion/retargeting.
- `model_sections.py:354`: legacy Segment identifier is `bseg_` plus 16 SHA-256 hex characters
  from the exact UTF-8 name. Capture it during adoption; resolve names independently thereafter.

A bounded independent source investigation verified the copy/Restore/reference paths. Main-agent
source checks confirmed the inventory and shared-storage points above. These are current code facts,
not v2 behavior or new native-host evidence.

## Prototype verification

Browser: Playwright browser tooling, loopback repository-root server on port 8766.
Data: two synthetic Zones, one Segment and two Levels; memory only, reset by reload.

| Check | Result |
| --- | --- |
| Cancel discards typed rename | PASS; reopen shows original name |
| Equivalent `level-1` versus `Level 1` rejects Save | PASS; dialog and reason remain |
| Invalid hex rejects Save | PASS; draft retained |
| Save rename/colour keeps assignment ID | PASS; Zone 1 remains assigned to `l1` |
| Escape cancels management | PASS; dialog removed |
| Used Level removal with explicit Not set | PASS; assignment cleared only after Save |
| Default Segment removal without replacement | PASS; Remove disabled |
| 420 px dialog bounds/page width | PASS; dialog x=16, width=388; page width=420 |
| 1280 px dialog bounds | PASS; dialog x=300, width=680 |

The study reuses shared dialog/menu controls. It does not implement the declared public API,
revision guards, adoption preview, orphan usage, full palette, native picker acceptance or host
Undo/save/copy. Acceptance O1–O9/H1–H3 is NOT RUN. No shared-kit changes need Design System sync.

## Review and checks

Independent migration/reference design review: identified a cross-Model export-key collision
(two exact legacy labels produce the same Segment hash even when local option IDs differ). The
proposal now requires export-key uniqueness and an explicit existing-survivor mapping; a distinct
import with an occupied key refuses. The reviewer also found that stamps lack the `id` Engine needs for diagnostics/reference resolution.
The proposal now specifies the detached stamp adapter's diagnostic ID, exact occurrence key,
validator, full preimage correspondence and removal of the synthetic field before persistence.
The same independent reviewer checked these corrections and found both design gaps closed,
with no further blocker in those changes. This is design review only; production review and
required implementation/native gates remain outstanding.
`node --check` and `pnpm exec eslint` cover the prototype JavaScript; link checks and `git diff --check`
cover this design checkpoint. Full `make ci`, coverage, version-floor and native gates are reserved
for production implementation; no shipping assets or manifests changed.
