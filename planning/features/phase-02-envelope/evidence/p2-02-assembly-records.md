# Material and Assembly records: implementation checkpoint

DATE: 2026-10-01
STATUS: Implemented in the working tree; review and integrated/native gates open
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
retain the reference values. No further material findings were reported. No source is committed
or installed from this checkpoint yet.

## Native steps and resume

Run `tools/examples/authoring/assemblies_walkthrough.rb` with the panel closed in a fresh process
after building and installing the stable package. Capture actual catalog records after each
committed gesture. Native Undo and Redo must reproduce those records at every step, followed by
save and exact public readback after a fresh reopen. Verify two Models with identical synthetic
record ids remain isolated.

The private helper `_private/host/envelope/e02-journal.rb` observes public API outcomes and
readbacks only. It has been prepared but not run. Its prepend observer is development-only;
restart normally before any final restoration attestation. The running SketchUp fixture still
belongs to the preceding groundwork regression observations; do not treat it as this build.

No manual step is requested yet. The held-gesture checks that native automation cannot reach
remain in the final batch tracked by the groundwork evidence.
