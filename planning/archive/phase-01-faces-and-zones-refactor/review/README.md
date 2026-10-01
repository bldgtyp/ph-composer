# PR #3 foundation review

DATE: 2026-09-30
STATUS: Review complete; modifications recommended before merge
ISSUE: none (local review draft requested by Ed)
PR: https://github.com/bldgtyp/ph-composer/pull/3
BRANCH: codex/phase-one-geometry-contracts
BASE: f1e9a9824fc6578fbe7baf0a4c877c3b9a492a62
HEAD: 99b6fc7b1dc6c80129c7467ebb5851c6cedb7c0c

## Recommendation

Hold the merge. The present branch contains four reproduced authoring defects, an editor draft-loss
defect and incomplete public building-operation contracts. The broad architectural direction is
sound. Keep the native Ruby layer, JavaScript UI and Python/HBJSON pipeline; correct ownership,
reference declarations and API completeness before adding features faster.

This review covers the entire PR inventory and traces the consequential source paths in depth.
It includes inherited foundation code when the new building features expose its limitations.
The diff has 261 changed files, 34,185 insertions and 489 deletions, including tests, evidence,
third-party licenses and binary wheels. This is a source/contract review with focused reproductions,
not a new native-host acceptance run or a line-by-line audit of third-party implementations.

## Merge corrections

| ID | Priority | Finding and concrete consequence | Evidence |
| --- | --- | --- | --- |
| M1 | P1 | Classifying one Face under shared child Groups writes both occurrences and reports one affected target | [Model review](MODEL-REVIEW.md#m1-p1-a-shared-child-group-bypasses-the-face-mutation-refusal) |
| M2 | P2 | An explicit Face path can cross an authored nested Zone and stamp its Face with the outer Zone identity | [Model review](MODEL-REVIEW.md#m2-p2-a-supplied-face-path-can-cross-into-another-authored-zone) |
| M3 | P2 | Attached-zone deletion commits while an orphan Face retains its deleted reference | [Model review](MODEL-REVIEW.md#m3-p2-attached-zone-deletion-leaves-orphan-face-references-dangling) |
| M4 | P2 | Single partial-overlap Solve fails during apply when an AttachedZone reference remains on a Surface piece | [Model review](MODEL-REVIEW.md#m4-p2-partial-adjacency-pairing-retains-an-invalid-attached-zone-reference) |
| U1 | P2 | Changing Overview selection silently discards unsaved Zone details | [Pipeline/UI review](PIPELINE-UI-REVIEW.md#p2-row-selection-silently-destroys-a-zone-details-draft) |
| A01 | P1 foundation | Zone/Face discovery lacks field/reference schemas; core results are unspecified objects without examples | [Agent-interface review](AGENT-INTERFACE-REVIEW.md#a01-publish-usable-schemas-for-the-actual-building-operations) |
| A03 | P2 | Non-JSON Ruby params escape invocation as exceptions and consume a sequence without a retained outcome | [Agent-interface review](AGENT-INTERFACE-REVIEW.md#a03-validate-before-computing-request-digests-or-consuming-sequences) |

M1 to M4 and U1 were reproduced with synthetic models using existing test helpers. The primary
reviewer independently replayed both model scripts and the UI script. A03 and ignored Zone list
filters were reproduced directly by the primary reviewer. None of these reproductions changes
tracked production code. A01 is an observed public contract gap, not a runtime crash.

Before calling the foundation ready for additional contributors, also resolve the domain ownership
choice and generic reference declarations described in [ARCHITECTURE.md](ARCHITECTURE.md).
M3 demonstrates why entity references cannot remain a feature-specific afterthought. Move
`GeometrySnapshot#zone_owner` out of shared export infrastructure in that same bounded change.

## Further foundation work

| Follow-up | Disposition |
| --- | --- |
| Bounded, projected Zone/Face reads and query-specific cursors | Recommended before faster feature development; A02 |
| Describable shell export task operations | Recommended in the same API-completeness pass; A04 |
| HBJSON-specific validation of opaque canonical bytes | Resolve policy and enforcement before treating arbitrary contributor output as privacy-checked; no current-model leak proved |
| Tighter registration/schema validation and immutable declarations | Small contributor-contract hardening; A06 |
| Repeated pair-state/cut logic and long installers | Focused responsibility refactor tied to the ownership correction; preserve pure geometry algorithms |
| Supported external transport, revocation and capture | Separate delivery packet, consistent with accepted scope; no MCP/eval workaround |
| Stale documentation and UI reference paths | Correct affected authorities before merge; details in ARCHITECTURE.md |

The ordered work and acceptance criteria are in [FOLLOW-UP.md](FOLLOW-UP.md). These are review
recommendations. No implementation, GitHub publication, new issue, commit or merge was performed.

## Verification

A fresh `make ci` passed locally on Ruby 3.2.2: 605 Ruby tests / 2,742 assertions, 184 JavaScript
tests, 96 Python tests, 9 Ruby hostkit tests / 30 assertions and 16 Python hostkit cases.
No test failures or skips. Ruby syntax, installed linters, fixture regeneration/comparison,
panel manifest, runtime manifest/pins, Python typing and RBZ checks passed.
RBZ installed footprint: 21,835,695 bytes. Both PR CI jobs, Ruby 2.7.2 and 3.2.2, report success
on the reviewed head. The fresh local complete gate was run once; focused checks supported the
specific reproductions. Existing passing tests were not mistaken for proof of these new cases.

The supplementary Ruby metrics audit examined 93 shipping Ruby files with ABC, cyclomatic,
perceived-complexity and existing size cops. It reported 324 advisory offenses under those
thresholds. This is an exploratory measurement, not a failure of repository-required lint.
The normal Ruby lint passed. Selected measurements and interpretations are in ARCHITECTURE.md.
JS/Python complexity was assessed by responsibility and source size; no numerical complexity
tool was introduced for them. Coverage was not rerun on unchanged code. The acceptance packet
records Ruby 96.4%, JS 97.7% and Python 94.0%; those are reviewed prior results, not fresh measures.

All 66 branch commits carry a `Signed-off-by` trailer. This mechanical check does not resolve
third-party licensing or authorize public distribution.

Current-host acceptance is recorded in `planning/archive/phase-01-faces-and-zones/ACCEPTANCE.md` and its evidence, including
the final P1-E/F continuation. These records describe their named cases on SketchUp 26.1.188/macOS.
They do not cover the newly found cases. Any repair to host ownership, references or geometry
requires its focused native checks before closure. SketchUp 2023, Windows, METr, authored
construction export and public-distribution gates remain distinct. The synthetic construction
provider is correctly excluded from shipping. Its deferred production counterpart is not itself
a Phase 1 merge defect.

## Review records

- [MODEL-REVIEW.md](MODEL-REVIEW.md): storage, occurrences, operations, reference integrity and exact reproductions.
- [AGENT-INTERFACE-REVIEW.md](AGENT-INTERFACE-REVIEW.md): discovery, bounded reads, invocation and adapter delivery.
- [PIPELINE-UI-REVIEW.md](PIPELINE-UI-REVIEW.md): translation/export/runtime, UI behavior and exact reproductions.
- [ARCHITECTURE.md](ARCHITECTURE.md): ownership alternatives, languages, data pipeline, simplification and dead-code assessment.
- [FOLLOW-UP.md](FOLLOW-UP.md): proposed work order, required decisions and acceptance.
- [DIFF-INVENTORY.md](DIFF-INVENTORY.md): complete changed-file inventory and review routing.
