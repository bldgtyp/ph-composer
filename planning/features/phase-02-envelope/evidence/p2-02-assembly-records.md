# Material and Assembly records: implementation checkpoint

DATE: 2026-10-01
STATUS: Checkpoint committed; dual-Ruby CI and native records proof pass; full attestation open
BRANCH: `codex/phase-02-envelope`
ISSUE: https://github.com/bldgtyp/ph-composer/issues/14

## Implemented scope

The definitions feature registers Material and Assembly kinds, inventory reads and 24 public
operations. Pure commands own the Layer and Layer-Segment gestures. The record engine and
dispatcher own persistence, guarded proposals and transactions. Assemblies names no Zones,
Face-assignment or window feature. The composition root loads it before Zones.

Material replacement rewrites the actual nested references and deletes in one proposal.
Duplicate rebuilds Layer and Layer-Segment identities, remaps the air barrier and clears photos.
The proposal-local identity allocator makes preview and invoke agree at the same revision;
successive committed gestures produce different identities. Unavailable extension payloads
survive edits and refuse Duplicate until their copy rules are available.

Thermal reads match the frozen predecessor reference cases to six places. Missing inputs and
all-membrane Assemblies withhold the value. Displayed total thickness excludes membranes,
matching the predecessor's existing display convention. Library source snapshots currently have
an authored-field ceiling; the provider adapter tightening belongs to P2-07.

## Verification so far

- Six focused Ruby files after review fixes: 42 tests, 402 assertions, no failures on Ruby 3.2.2
  and 2.7.2.
- Rubocop: 26 feature/test/example files, no offenses.
- Generated API reference and export fixtures: nine tests, 292 assertions, no failures.
- Integrated Ruby coverage run: 773 tests, 4,133 assertions, no failures; line coverage 96.6%
  across 7,930 lines in 130 files. The combined coverage target subsequently stopped at the
  inventory CSS selector check while P2-03 was still being edited; it has not passed yet.
- The first integration run found an obsolete loader feature-list expectation and provisional
  manifest hashes. The expectation was corrected and manifests refreshed. Full integrated gates
  wait for the inventory source to stabilize; no full-gate result is claimed for this checkpoint.

Independent review used the existing `simplify` reviewer and the repository architecture rubric.
It found unbounded Cartesian thermal paths and inconsistent whitespace in duplicate-name suffix
selection. Both were reproduced, corrected and closed by the same reviewer. Exact evaluation
allows at most 16,384 paths; larger records remain authored and editable, with
`calculation_limit` withholding the thermal value and marking completeness false. Uniform Layers
are collapsed into base resistance, bounding recursion depth. Boundary and deep-layer tests
retain the reference values. No further material findings were reported. The verified checkpoint and installation are recorded below.

## Verified checkpoint and native record proof

Checkpoint `35704bd` passed full CI on Ruby 3.2.2 and 2.7.2, coverage and browser checks.
The immutable package was checked against all 218 installed entries with no byte differences.
In fresh SketchUp 26.1.188, the public records walkthrough committed 14 gestures with the
panel closed. All 14 native Undo and 14 native Redo states matched the raw public catalogs.
Save and fresh normal reopen retained exact identities and actual references.

Two native Model windows containing identical record ids remained isolated: an update targeted
the inactive first Model, the second remained unchanged, and native Undo restored the first.
A further six-gesture public API sequence exercised nested user_data, duplication, fresh nested
ids and retained Material references. All six native Undo/Redo states and final fresh reopen
matched exactly (4 Materials, 3 Assemblies). Unknown-extension copy refusal is covered offline;
it was not separately injected in this native run.

Private evidence lives under `_private/host/envelope/`: `e02-record-journal.json`,
`e02-native-roundtrip.json`, `e02-two-models.rb`, `e02-metadata-journal.json`,
`e02-metadata-native-roundtrip.json` and `e02-metadata-reopen.rb`. The final normal restart
removed observers and API prepends. Current fixture: `e02.skp`, PID 50884, bridge port 57845.
The panel is open for inventory verification. Later Builder/assignment source is not installed.
Complete preceding native attestations, SketchUp 2023, Windows and distribution remain open.
