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
gestures and complete E04 attestation are still open.
