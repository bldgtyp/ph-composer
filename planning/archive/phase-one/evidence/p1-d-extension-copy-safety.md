# P1-D host evidence: extension copy safety

DATE: 2026-09-29
STATUS: Copy refusal and supported catalog-reference preservation verified; native split identity recovery remains open.
ISSUE: none (local implementation packet)

## Scope and reproduced defect

SketchUp Pro 26.1.188 on macOS, embedded Ruby 3.2.2, source base `8b59517`. Synthetic fixtures
and JSON snapshots are gitignored under `_private/host/`. The installed correction uses the
shared architecture rubric and the accepted copy policy in `context/EXTENSIBILITY.md`.

A paired box fixture was translated by 1 m along its shared wall, producing a partial overlap
that requires a cut on each side. Public Solve committed the cuts and created two new Face
identities, carrying `unavailable.fixture.face_reference` values naming the original Face UUIDs.
The operation had no installed rules for interpreting or copying that payload. This violated the
accepted pre-write refusal rule; preserving an unknown payload verbatim did not make copying it
onto a new identity safe. The prior copied-Zone repair also rewrote identities while carrying
unknown payloads with a warning. Its earlier preservation evidence is historical behavior,
not accepted reference-copy behavior.

## Correction

Catalog record duplication, copied-Zone repair and plugin-owned Face cuts now share extension
copy checks. A copy requires an understood payload with an installed `:remap` rule. The helper
copies detached data, remaps declared references, validates the resulting payload and, for
entity-owned records, checks declared catalog targets through the normal record engine.
Unavailable, unsupported, outdated, invalid or explicitly non-copyable data refuses before a
host operation opens. Unknown data remains preserved through unrelated edits and save/reopen.

Copied-Zone repair allocates the entire Zone/member identity mapping before proposing writes.
It preserves ordinary metadata and applies declared copy rules, without warning-only carriage of
unknown data. A Face cut preflights only sides that produce new pieces; an uncut Face keeps its
payload untouched. The existing rule for original-PID survival and all-fresh identities when no
original PID survives remains intact. No public action schema or normal target resolver changed.

Installed hashes:

- `core/records/extension.rb`: `3658f0d7b0eb6ad900152917b2e441f71146646ffd6b98d73e8d9750a2832ca3`
- `features/zones/install.rb`: `b9c9ce3e21a55be57a3eb6fd20aeea7b2d8e5b06321b53e50bb5b7d1ed2ed691`

## Native controls and acceptance

Geometry, fixture payloads and selection are prepared through the development bridge. Clipboard
Copy and Paste In Place, and all Undo/Redo checks, use native controls through computer use.
Make Unique uses SketchUp's native Group method inside a named fixture-preparation operation.
All production mutations use public preview/invoke operations with the panel closed.

The saved partial-overlap fixture with unknown Face-reference payloads now refuses both preview
and invocation with `copy.rule_missing / none`. Exact full snapshots prove that no Face cut,
pair retirement, record rewrite or stamp change occurred.

A synthetic feature then registers a valid versioned extension through the public Registry. It
declares a reference to a real Attached-zone catalog record created through the public save
operation. An untyped marker resembling a Face UUID is deliberately kept unchanged, because it
is not a declared reference. Solve completes with seven Faces in each Zone. Every resulting
payload remains understood, the actual Attached-zone reference remains unchanged, and all
metadata survives. Both reciprocal Surface endpoints read current.

An injected exception after the third actual Face-store write, after retirement has begun,
returns `operation.failed / rolled_back` and restores the complete snapshot exactly, including
geometry. A subsequent successful invocation has a read-only preview. One native Undo restores
its exact before snapshot; Redo restores its exact after snapshot. Save, quit and fresh reopen
preserve that after snapshot and both current reciprocal endpoints exactly.

The copy case starts with native clipboard duplication of west, followed by native Make Unique
and placement clear of the original. Its unavailable Face-reference data now refuses both
preview and invocation with `copy.rule_missing / none`; the full snapshot stays unchanged.
With the registered Attached-zone payload on Zone and Face records, explicit repair succeeds.
Original Zone/Face records, geometry and both pair envelopes remain exactly unchanged. The copy
receives a fresh Zone id and six fresh member ids/stamps, and its copied Surface pair is removed.
The declared external reference and all ordinary metadata remain unchanged. A failure after the
third actual Face write rolls back every Zone/Face/stamp write. Native Undo/Redo restore exact
snapshots; fresh reopen preserves the repaired snapshot and the original current pair.

Fixtures: `p1d-split-safety-before.skp`, `p1d-copy-safety-before.skp`,
`p1d-copy-safety-known-before.skp`, `p1d-copy-safety-split-known.skp`,
`p1d-copy-safety-repair-known.skp`. Snapshots: `native-references-split-safety-before.json`,
`native-references-split-safety-after.json`, `copy-safety-split-known.json`,
`copy-safety-repair-known.json`.

## Verification and remaining boundary

Full `make ci`, `make coverage` and Ruby 2.7.2 pass: 487 Ruby tests / 2,094 assertions,
170 JavaScript tests, 84 Python tests and 9 hostkit tests. Coverage: Ruby 96.6%, JavaScript 98.2%,
Python 97.46%. Focused copy/repair suites pass 93 tests / 392 assertions on both Rubies.
RuboCop and RBZ validation pass. No shipped Python or panel assets changed.

The independent architecture review found no actionable issue. Additional probes verified
Zone-level unavailable data refusal and a cut whose original native PID does not survive.
Some older offline failure injections attach singleton methods to entities, which can fail in
the stub's Marshal snapshot before any write. They are not the evidence for post-write rollback;
the native gates above counted three real writes before raising and checked exact restoration.

Successful native split identity recovery is still open. The current public Registry accepts
reference targets for catalog record kinds, but Face and Zone entity identities are not catalog
reference targets. No registered Face/Zone UUID reference-copy capability is claimed. The native
split fixture carries unavailable actual Face UUID references and cannot safely reidentify its
pieces under the accepted policy. Its successful forward repair requires an explicit identity
repair contract and supported reference declarations; an automatic observer repair is excluded.

The paired split also yields two 6 m² Faces against one 12 m² Face. Phase 1 currently reports
one Face matching multiple neighbours rather than cutting and pairing it with each neighbour.
Identity repair alone therefore would not restore two current pairs. This solver boundary and
the reference-target contract must be resolved before A06 is closed. P1-D remains open.
