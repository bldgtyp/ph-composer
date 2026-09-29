# P1-D host evidence: native cut/paste and Face splits

DATE: 2026-09-29
STATUS: Native preservation and unique-identity path recovery verified; split identity repair remains open.
ISSUE: none (local implementation packet)

## Host and fixture

SketchUp Pro 26.1.188 on macOS, embedded Ruby 3.2.2. Fresh processes were used for the baseline,
installed fix and reopen checks. Source base: `2e51e89`, with the two-file adjacency-state fix
recorded by this continuation. Installed `adjacency.rb` SHA-256:
`5f7d5b15781bf2f5468a568c3f6b3d19e2f09433cfb79566acf02d71839eae71`.

A synthetic 5 x 4 x 3 m west box and 4 x 4 x 3 m east box share a 12 m² wall. The fixture uses
the development-only box helper in `tools/examples/authoring/repair_walkthrough.rb`. Make Zone,
Auto-classify and Solve use the public operations, with the panel closed. Every Face has a
synthetic `user_data.marker` and an unavailable-extension payload containing its original Face
UUID. A separate neutral Group provides the wrapper destination. Models and full JSON snapshots
remain gitignored under `_private/host/`.

The bridge prepares selection, active edit context and camera, and reads full records and geometry.
Cut, Paste In Place, Draw Line, Undo and Redo use native keyboard/menu/viewport controls through
computer use. No scripting operation substitutes for those native edits.

## Cut and Paste In Place through a wrapper

Starting from a current reciprocal pair, native Cut removes east. West reads unresolved without
changing its stored Surface record. Enter the neutral wrapper and choose Edit > Paste In Place.
The pasted Zone occupies the same world geometry, with the same Zone UUID and all original Face
UUIDs, records and stamps. The Zone path changes from `[48913]` to `[48945, 48975]`; its Surface
Face persistent ID changes from `48938` to `48969`. Unknown payloads, including actual embedded
Face references, survive verbatim. UUIDs remain unique.

The old read reported west unresolved but pasted east **current**. This was a confirmed defect:
it checked geometry and counterpart UUID without checking its own stored endpoint path or the
full reciprocal references. The correction resolves the local stored endpoint, including UUID
uniqueness, checks it against the actual occurrence, and requires both complete reciprocal
references and Surface records before geometry may establish current state. Geometry-only changes
continue to read stale; unresolved identity or reference relationships read unresolved.

Installed-code checks in a fresh process report both endpoints unresolved. Whole-scope Solve
refuses `target.changed / none`; exact before/after snapshots prove no writes. Fresh reopen
preserves every path, record, stamp, transform, loop and area, and keeps the pair unresolved.

Native Undo Paste restores exactly the post-Cut snapshot; Redo restores exactly the pasted
snapshot. Undo Paste, Undo Open and Undo Cut restore the complete baseline and both current
endpoints. Redo Cut restores exactly the cut-only snapshot. The original baseline is left restored
and saved. Opening and closing native edit contexts are separate SketchUp Undo entries.

Fixtures: `p1d-native-references.skp`, `p1d-native-pasted.skp`; snapshots
`native-references-baseline.json`, `native-references-pasted.json`, `native-references-cut-only.json`
and `native-references-pasted-undo-after.json`.

## Native split of a classified, non-Surface wall

Draw Line between opposing edge midpoints inside west. SketchUp divides its outer Outdoors wall
into two Faces. One retains the original persistent ID; the other receives a new persistent ID.
Both carry the full original record and stamp, including the same copied Face UUID, Outdoors
condition, Wall type, user data and unavailable-extension payload. No observer reidentifies or
rewrites either Face. The separate paired wall is unchanged.

Native Undo Draw Line restores the full baseline snapshot exactly. Redo restores the split
snapshot exactly. This establishes native dictionary survival; it does not establish valid,
independent authored identities for the copied Face UUIDs.

Fixture: `p1d-native-split.skp`; snapshot `native-references-split.json`.

## Native split of the shared Surface wall

Hide east for viewport access, enter west and view its actual shared wall from the east side.
Read the pick path before drawing to establish that the visible Face is the paired Face.
Native Draw Line divides the 12 m² wall into two 6 m² Faces. The original Face keeps persistent
ID `48910`, the second receives `48958`. SketchUp copies the complete Surface record, including
Face UUID `fac_91240ce03565`, both adjacency references, geometry stamps, Zone membership stamp,
user data and unavailable-extension payload onto both pieces. This is ambiguous Face identity.

Whole-scope Solve refuses `target.ambiguous / none` and leaves the exact split snapshot unchanged.
The installed state fix reports both split Faces and the east counterpart unresolved. Native
Undo restores the exact pre-split snapshot; Redo restores the exact split snapshot. Save, quit
and fresh reopen retain all geometry, records, stamps and the unresolved state. Another refused
Solve after reopen writes nothing. No geometry match silently chooses which duplicated UUID is
its intended target.

Fixture: `p1d-native-paired-split.skp`; snapshots `native-references-paired-split-before.json` and
`native-references-paired-split.json`.

## Initial state-fix verification and disposition

The two-file correction adds regressions for moved Zone paths, duplicated local Face UUIDs and
corrupt reciprocal paths with unchanged UUIDs. Focused scope tests: 31 tests / 132 assertions on
Ruby 3.2.2 and 2.7.2. The final full gate passes `make ci`, `make coverage` and the Ruby 2.7.2
suite: 468 Ruby tests / 1,972 assertions, 170 JavaScript tests, plus Python and hostkit checks.
Coverage: Ruby 96.6%, JavaScript 98.2%, Python 97.46%. RBZ validation passes. No shipped Python or
panel assets changed. Independent architecture review found no actionable issue in the state fix.

These cases establish preservation, truthful unresolved state, safe mutation refusal and exact
native Undo/Redo/reopen. They do **not** close all A06 behavior. Forward recovery remains open:
Solve does not re-anchor cut/paste paths and cannot independently identify the two Faces that
SketchUp stamped with one UUID. The existing copied-Zone identity repair does not apply to an
otherwise unique Zone containing a native Face split. Returning via Undo works. An explicit
forward repair needs to preserve payloads, disclose unremapped unavailable-extension references,
refuse ambiguity and establish only valid new reciprocal endpoints. It must not be inferred from
this read-state correction.

## Explicit Solve path recovery continuation

The subsequent correction, based on `4b40b19`, recovers changed stored endpoint paths during
explicit Solve planning only. The public reference resolver remains strict. Each old endpoint
must have one authored Zone identity and one globally unique authored Face identity, including
orphan Faces and repeated component occurrences. The old reciprocal records must agree on the
pair id and both complete directed references. Actual candidate paths pass the normal mutable
resolver, and every surviving counterpart must be in the explicit caller scope. Geometry does
not select identities. UUID counts are collected once per planning run when fallback is needed.

Installed `adjacency.rb` SHA-256:
`8d88f90b821e78ae46bbb1143c8a32267a73d2d158b18772e2cbb251dfac8edb`.
Fresh SketchUp opened the saved native-pasted fixture. Public preview proposed retiring and
recreating the same pair on the actual paths without writing anything. A single-Zone invocation
refused `scope.incomplete / none`, with the full snapshot unchanged. An injected exception after
the third Face write, the first new pair write after both retirements, returned
`operation.failed / rolled_back`; the entire original snapshot was restored exactly.

Whole-scope Solve then committed both endpoints, preserving the original Zone and Face UUIDs,
stamps, geometry, user data and unavailable-extension payloads byte-for-value. Only adjacency
records changed. Both endpoints read current. Repeat Solve returned `completed / none` and
left the full snapshot unchanged. One native Undo restored the exact pasted snapshot; native
Redo restored the exact recovered snapshot. Save, quit and fresh reopen preserved the recovered
snapshot exactly and both endpoints still read current. Fixture: `p1d-native-recovered.skp`;
snapshot: `native-references-recovered.json`, both gitignored under `_private/host/`.

A separate fresh process reopened the native paired-split fixture against the same installed
solver. Solve still refused `target.ambiguous / none`, wrote nothing, and all three Surface
occurrences read unresolved. Unique-path recovery does not select among duplicated Face UUIDs
or rewrite extension references. Forward native-split identity repair remains open. The subsequent
[extension-copy correction](p1-d-extension-copy-safety.md) verifies pre-write refusal for unsafe
identity-changing payload copies and documents the missing Face/Zone reference-target contract
and the one-to-many solver boundary.

Focused scope tests pass 39 tests / 191 assertions on Ruby 3.2.2 and 2.7.2. Full `make ci`,
coverage and the full Ruby 2.7.2 suite pass: 476 Ruby tests / 2,031 assertions, 170 JavaScript
tests, 84 Python tests and 9 hostkit tests. Coverage remains Ruby 96.6%, JavaScript 98.2% and
Python 97.46%. The independent architecture review found no actionable issue and added three
read-only probes for orphan component duplicates, counterpart deletion after recovery and
locked descendants. No shipped Python or panel assets changed.
