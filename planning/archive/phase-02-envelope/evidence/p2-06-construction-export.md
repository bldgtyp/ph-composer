# P2-06 evidence: authored constructions

DATE: 2026-10-01
STATUS: Implemented and independently reviewed. Integrated gates and current-host export/reopen proof pass; complete native attestation open.

Assemblies contributes self-contained construction records. Zones references those records for
emitted Faces and reports actual usage. Normal composition uses authored constructions without a
development construction provider. Pinned-stack proof produces two Rooms, twelve Faces and one
reciprocal Surface pair; every emitted Face carries the authored construction reference.

The affected Ruby gate passes 130 tests and 1119 assertions on Ruby 2.7.2 and 3.2.2. The Python
conversion gate passes 105 tests, including 24 new construction cases. Ruff, mypy over 17 files and
Rubocop over thirteen affected Ruby files pass. Tests cover mixed layers, steel spacing, repeated
grids, orientation, membranes, defaults, actual shared object identity, unused incomplete definitions,
and independent Zone survival when another Zone has a failed Face dependency.

Dependency failure retains the accepted Zone-record translation boundary: one invalid assigned
Face omits its whole Zone. Independent Zones still translate. Face identity accompanies the failure.
A missing reciprocal Surface endpoint may withhold canonical output under the existing validation.
No partial Room or additional Face assembly seam has been introduced.

Pinned Honeybee requires specific heat at least 100 J/kgK and at most ten thermal materials per
OpaqueConstruction. Named preflight conditions disclose these export constraints, retain authored
values and layers, and become blocking through assigned emitted Faces. Membranes do not count toward
the thermal layer limit. Missing thermal mass uses 600 kg/m3 and 1000 J/kgK with disclosure.

A synthetic native reference is saved at `_private/host/envelope/reference.skp`: two Zones,
twelve classified Faces, floor area 36 m2, roof area 36 m2, outdoor wall area 78 m2, and both
Surface endpoints totaling 24 m2. It contains mixed wall and roof constructions, a membrane,
shared partition, floor and unused incomplete Assembly. Independent arithmetic is saved beside it.
Integrated assignment, runtime export and fresh-reopen evidence are recorded below.
These individual checks do not award E05.

Independent review reproduced and closed an emissivity conversion mismatch. Authored emissivity,
including zero, now becomes thermal absorptance in single and grid constructions; 27 construction
tests pass. Report defaults and the membrane conversion limitation are disclosed once per Model.
The affected report gate passes five tests and 62 assertions on both Rubies. The reviewer compared
geometry, identifiers, Face types and reciprocal Surface endpoints against the checkpoint golden
and confirmed them unchanged. Native reference thermal queries match the independent arithmetic
to the displayed six decimals: wall 0.980247, roof 0.195816, floor 0.130378 and partition 1.515152 W/m2K.

## Integrated checkpoint and current-host proof

Checkpoint `6a7e08f` has dual-Ruby `make ci` passes from an immutable source archive: 818 Ruby
tests and 4667 assertions, 281 JavaScript tests, 127 Python tests, hostkit nine Ruby tests and
30 assertions plus 21 Python tests, and mypy over 32 files. Logs: `/tmp/phc-envelope-immutable-ci32.log`
and `/tmp/phc-envelope-immutable-ci27.log`. The Chromium 88 runtime proof passes in
`/tmp/phc-envelope-p206-runtime.log`. The installed RBZ is 235 files, 7,202,356 zipped bytes and
22,242,825 installed bytes, below the 24 MB ceiling but above the 22 MB target. SHA-256:
`35a7c2a90f87acb58b54c2ca4721cfce59b7ecf61ab85c0f8951172cece3b245`.

A fresh normal SketchUp 26.1.188 process exported the actual assigned reference SKP through the
public API and the installed runtime HtmlDialog. Artifacts contain two Rooms, twelve Faces, one
reciprocal Surface pair and four referenced constructions. Six wall Faces total 78 m2; floor and
roof each use two Faces totaling 36 m2; partition uses both endpoints totaling 24 m2. The unused
incomplete Assembly produces a nonblocking finding and no emitted construction. Both partition
Faces resolve to the same serialized construction identity. Private files: `reference.hbjson`,
`reference-export-report.html`, `reference-export-outcome.json`, `reference-assigned.skp`.

Four native Undo and four native Redo gestures each match the exact public Face journal state,
including geometry/classification/adjacency. Evidence: `reference-assignment-journal.json` and
`reference-native-roundtrip.json`. The full E04 UI gesture set and E05 attestation remain open. Do not infer Windows, SketchUp 2023, certification or public distribution from this proof.


After a fresh normal process reopened `reference-assigned.skp`, the complete public Face list
and Assembly catalog matched the saved baselines exactly. A second actual runtime export to
`reference-reopen.hbjson` preserved every Room, geometry/classification/adjacency reference,
and every energy construction/material exactly. Evidence: `reference-reopen.json`.
Whole HBJSON text is not deterministic: Honeybee-PH regenerates identifiers and display names for
its default site, climate, setpoint and certification metadata. The comparison isolates the authored
references and energy data rather than treating those generated defaults as authored record loss.

All five integrated browser scripts pass after their final corrections. Log:
`/tmp/phc-envelope-p206-ui-final.log`. This does not replace the remaining native UI gestures.

## P2-17 dependency refusal consolidation

The current normal RBZ is `bcb9c024e20ce686b52e0b851e13fd2e762e97aa25d61551b838e6aaaf75c018`,
latest shipping source `e11a767`, on fresh SketchUp 26.1.188 / Ruby 3.2.2 process PID 26980.
Current reference exports and fresh SKP readback are also covered by [E14](p2-14-aperture-export.md).
No development construction provider is present. On `p214-integrated.skp`, development-only SDK
fixture edits give east Wall 4 an absent Assembly id or the existing incomplete Assembly id.
Public preflight names `construction.dangling` or `construction.incomplete` on that exact Face,
and the normal canonical Export workflow refuses `export.blocked` / effect `none` before opening
a destination dialog. The native operations are aborted and exact public Face, Window Unit and
area values return to the baseline. The unused incomplete Assembly's `segment_without_material`
finding is nonblocking; the restored reference has no blocking finding and extracts normally.
Private evidence: `p214-p217-construction-guards.json` and the restored journals beside it.

Extraction itself intentionally collects dependency findings for translation; its success does
not authorize committing a canonical output pair. The first probe incorrectly expected extraction
to refuse, then was corrected to assert the documented canonical-workflow boundary. No shipping
change was needed. These checks supply the remaining dependency outcomes; E06 closure still awaits
the assertion-level consolidation and its preceding stage gates.
