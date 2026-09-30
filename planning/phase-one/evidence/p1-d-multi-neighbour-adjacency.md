# P1-D clean multi-neighbour adjacency

DATE: 2026-09-29
STATUS: Implemented and current-host verified. A06 remains open for Face/Zone extension-reference targets.
ISSUE: none (local implementation packet)

## Behavior and design

The Zones PRD requires clean partitions to solve; its multiple-neighbour warning applies when
the Face cannot be split cleanly. The previous solver discarded every contested Face. The saved
native split-recovery fixture reproduced this: two 6 m² Faces against one 12 m² counterpart
returned `adjacency.multiple_neighbours` and no pairs.

Solve now groups connected matches and plans all shared regions on each original Face together.
Pure SI geometry rejects overlapping regions, unsupported outlines and combined remainder
slivers before writes. It checks area conservation and the existing per-Face area/width floors.
One coordinated step resolves every original, draws the planned outlines using the captured
original plane and local normal, matches actual shared pieces, checks area conservation, assigns
one identity per piece, and writes reciprocal pairs. The native persistent-ID survivor keeps
the original Face UUID; new pieces use preview-allocated IDs and validated extension copies.
Retirement, scope, public action, revision/digest and transaction contracts remain unchanged.
The original one-to-one path remains in use for independent matches.

Same-normal equal outlines now report overlapping Zones, including holed and concave outlines.
Outline equality is separate from the opposite-normal and minimum-size requirements for pairing.
Unclean contested partitions still report without guessing a neighbour. This does not add partial
cutting of concave or holed original Faces.

## Native verification

SketchUp 26.1.188, Ruby 3.2.2, macOS. `make install` installed the final source diff after
`4cc124a`; installed source bytes match all six changed shipping files. The final RBZ contains
141 files, 5,417,845 bytes compressed and 19,891,176 bytes installed.
Fresh processes 16694 and 17014 exercised the partition writes; 18417 and 18497 reopened the
saved results with the reporting correction installed. Process 18543 exercised unsafe-copy
refusal. All synthetic Models, helpers and full fingerprints remain gitignored under `_private/host/`.

| Case | Result |
| --- | --- |
| Repaired native split: two 6 m² Faces against one 12 m² Face | Two reciprocal pairs; four current Surface endpoints, all 6 m². The counterpart becomes two Faces, bringing the Model from 13 to 14 Faces. Original native Face `[48937]` retains `fac_4de5dfe6926a`; new piece `[49026]` has `fac_f2dd69a10b10`. Both original split-side UUIDs remain unchanged. |
| One full-height Zone beside two stacked Zones | Two 6 m² wall pairs plus one 16 m² floor/ceiling pair, six current reciprocal endpoints. The Model has 19 Faces after the full-height wall partitions. Original wall `[48910]` keeps `fac_c48e0b42c4fe`; its new piece has its own UUID. |
| Supported payloads | Every resulting piece retains face type, non-Surface fields, user data, extension envelope and Zone stamp. The four split-fixture endpoints still resolve their declared external reference to live catalog record `atz_m580vOz2oUA4`; all six stacked-fixture endpoints resolve to `atz_1eF197LswWEO`. Literal original UUID markers are unchanged. IDs are unique and area is conserved per original Face. |
| Omit the upper stacked Zone from scope | Preview and invocation refuse `scope.incomplete`, name the omitted Zone and return the affected Zone references. Complete fingerprint, including modified state, remains exact. |
| Fail after the third actual Face-record write | In both fixtures the operation returns `operation.failed` / `rolled_back`. Geometry, topology, dictionaries, records, materials, assignments and modified state exactly match the saved pre-Solve baseline. |
| Repeat Solve | Returns `effect: none`, unchanged pair IDs, no findings and an exact complete fingerprint. |
| Native Undo/Redo | One Cmd-Z restores each complete saved baseline, including unmodified state. Cmd-Shift-Z restores the complete successful result exactly. The no-op repeat adds no Undo step. |
| Save and fresh reopen | Both solved files match every saved data field exactly; only the expected modified flag changes to false after saving. All endpoints remain current and reciprocal, external references resolve, and another Solve is an exact no-op. |
| Unavailable payload on the Face that needs partitioning | Preview and invocation refuse `copy.rule_missing` for `unavailable.fixture` before writes. Complete fingerprint including saved modified state remains exact. |

The initial candidate was reinstalled after the cached-original-normal adjustment and its
partition checks repeated in a fresh process. The later review correction changes only the
same-normal reporting path; final fresh reopen and refusal checks use that installed source.
One host restart delayed bridge availability while SketchUp remained responsive. Native menu
activation and opening the Ruby Console allowed startup to complete; no Console code, preference
or environment change was needed. No result from an unavailable bridge was counted as evidence.

## Offline gates and review

Final `make ci`, `make coverage` and the complete Ruby 2.7.2 suite pass: 558 Ruby tests /
2,451 assertions, 180 JavaScript tests, 84 Python tests and nine hostkit tests / 30 assertions.
Coverage: Ruby 96.8% of 5,633 lines in 88 files, JavaScript 98.2%, Python 97.46%.
Ruby lint/syntax, fixtures, runtime pins, manifest and RBZ checks pass. No panel or Python payload
changed. The focused tests cover two and three neighbours, separated remainder, overlapping
regions, aggregate slivers, connected 2×2 partitions, supported/unsafe payloads, runtime rollback
and repeat no-op, plus convex/holed/concave same-normal full outlines.

One independent architecture/simplify review found the same-normal branch incorrectly relying on
a helper that requires opposite normals. The fix reuses the core outline matcher through a small
direction-independent helper and adds holed/concave regressions. Both Rubies and the final full
gates pass. No other source-backed blocker was found in grouping, identity, copy-rule, reciprocal
reference or rollback paths. GPT-6 Sol was the available fallback for the skill's unavailable Terra
model. Native verification is recorded separately above; the 2×2 grid has offline evidence only.

## Remaining boundary

This closes A06's clean one-to-many solver boundary. Face/Zone UUID targets and incoming
extension-reference handling still need the owning contract and implementation before A06 or
P1-D closes. SketchUp 2023, Windows, distribution, large-project performance and certification
claims remain outside this run.
