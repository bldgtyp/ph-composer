# P2-05 evidence: Assembly assignment

DATE: 2026-10-01
STATUS: Implemented and reviewed. Integrated gates and exact native assignment Undo/Redo pass; full UI attestation open.

Zones owns optional Face `assembly_id`, selection/table assignment, Clear, usage counts, Locate,
Paint and replacement on Assembly deletion. Assemblies owns its records without a Zones dependency.
Assignments retain geometry and reciprocal Surface relationships. A pair warning requires two
present, different Assembly ids; a missing endpoint remains an ordinary incomplete assignment.
Selection writes use frozen occurrence targets and expected values, and refuse the complete batch
when any target changed. The G11 table contribution adds usage and actions without feature vocabulary
in the owner inventory or table kit.

The reviewed Ruby assignment gate passed 26 tests and 279 assertions before the final pair-rule
correction. The combined conversion and assignment affected gate subsequently passed 130 tests and
1119 assertions on Ruby 2.7.2 and 3.2.2. Snapshot queries are memoized only within one build, with
detached values; two regression tests passed 13 assertions on both Rubies. Independent root checks
for isolated snapshot refusal and resetting Paint to only the Assembly field passed four tests and
41 assertions on both Rubies.

The focused UI gate passed 93 tests and scoped ESLint. Browser selection, table Clear, filter,
Locate, Paint reset and explicit replacement passed at 1280, 900, 420 and 280 CSS pixels. Evidence:
`ph-composer-assignment-DldWRj` in the local temporary evidence directory. It exposed an Assembly
inventory SI/IP mismatch: headers switched while numeric cells stayed SI. The root corrected the
unit profile and added a display regression; all 22 inventory tests and scoped ESLint pass.
A four-pixel column-resizer overhang remains contained in the table, also present without G11.

Checkpoint `6a7e08f` contains the assignment UI and passes dual-Ruby CI and all five browser
scripts. It is installed. Four guarded assignments, four native Undo gestures and four native
Redo gestures reproduce every exact public Face journal state; fresh reopen preserves those
references. See [construction evidence](p2-06-construction-export.md). The remaining native UI
gestures and complete E04 attestation were open at that checkpoint.

## P2-17 current-host route verification

Normal packaged RBZ `bcb9c024e20ce686b52e0b851e13fd2e762e97aa25d61551b838e6aaaf75c018`,
SketchUp 26.1.188 / Ruby 3.2.2, fresh process PID 26980, saved synthetic
`_private/host/envelope/p214-integrated.skp`: all four native UI assignment routes now pass.
The Face table changed east Wall 4; native right-click, selection-panel Apply Assembly and
inventory Paint each changed west Wall 4. Native double-click entered the west Zone edit path
for right-click and selection. Every operation changed only `assembly_id`, preserved explicit
Wall/Outdoors values and the reciprocal Surface pair, and one native Model Undo restored exact
public Face, Window Unit and glazed/net area values. Table Redo also reproduced exact values.
The expected Assembly exterior-condition mismatch finding appeared after assignment.
Native inventory usage displayed Floor 2 / 36 m2, Roof 2 / 36 m2, partition 2 / 24 m2,
Wall 6 / 78 m2 and unused Assembly 0 / 0 m2, matching the reference calculation.
Paint's public palette contained only the chosen Assembly and Escape stopped Classify.

Private before/after/Undo journals are `p214-p217-*-assign*.json`; assertion summaries are
`p217-{table,context,selection-confirm,paint}-assignment-check.json`. An initial selection-picker
attempt made no write because Apply Assembly had not been clicked; it is not counted
as a successful assignment. No shipping methods were patched for these observations.
E05 remains open for the other register assertions, including ceiling, stale/unreachable targets,
replacement across occurrence shapes, hint precedence, pair mismatch and Assembly Colour-by.

The subsequent current-host public-action checks close the stale/unreachable and ceiling assertions.
Two-target batches refuse atomically with `target.changed` and `target.not_found`; exact public
Face, Window Unit and area values remain unchanged. A temporary native 251-Face Zone refuses
251 targets with `gesture.too_large`, commits exactly 250 targets, and one native Undo restores
all public values. Two further native Undo gestures remove Make Zone and the fixture geometry;
the original reference values match exactly. Journals: `p214-p217-assignment-guards.json`,
`p214-p217-limit-results.json`, `p214-p217-limit-one-native-undo.json` and
`p214-p217-limit-cleaned.json`. Replacement, hint precedence, pair mismatch and Assembly Colour-by
still need their remaining current-host evidence.

The current reference's real reciprocal Surface pair also passes the mismatch assertion: changing
one endpoint's Assembly produces `assembly.pair_mismatch` at both endpoints while adjacency remains
current. One native Undo restores exact Face, Unit and area values. Journals are
`p214-p217-pair-{before,mismatch,undo}.json`.

Native Assembly Colour-by activation showed the correct legend and viewport counts. Editing the
Wall Assembly colour saved the chosen value but switched Colour-by Off. This is a confirmed failed
redraw, not a passed colour check. The shared dispatcher correction and pending fresh-host recheck
are tracked in [P2-17](p2-17-acceptance.md#assembly-colour-redraw-correction-in-progress).
