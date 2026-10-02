# P2-12 Slice B evidence: cutting components

DATE: 2026-10-01
STATUS: Slice B and gross-area correction pass full gates and fresh current-host replay. E12 remains partial because Slice A/C are unfinished.

Cutting ComponentInstances are excluded from Zone and Face occurrence discovery, including picks
and explicit references. Their panes are absent from Face lists, counts and Suggest. The shared
export snapshot retains the instance entry and dictionaries but excludes its descendants.

Face snapshots carry a detached glue flag outside the serialized geometry and its digest.
Overlap remains pure. Solve reports `adjacency.glued_instances` when a glued side would actually
be split. Full matches pair; a wholly covered glued side is also preserved while the counterpart
may split. Proposal descriptors carry cut permissions. A glue change with unchanged geometry and
revision refuses a stale preview, and live step guards check both sides before the first cut.

Both Ruby versions pass 203 affected tests and 852 assertions; eleven files pass scoped RuboCop.
The registered read/classification and export tests are in `zone_cutting_components_test.rb`.
`zone_solve_scope_test.rb` proves glue refusals, full/no-cut matches, unchanged-state preview
refusal and direct-step guarding. These are offline checks, not native replay.

The independent review found no actionable defects. Its focused probe passes eight tests and
58 assertions on both Rubies, plus a separate partition probe that refuses late glue before any
cut. The first combined full gate found a missing behavior API on the Group-definition test
double used by an existing shared-occurrence Colour-by test. The stub now exposes that SDK-shaped
API; the shipping predicate is unchanged. FileExport cancellation inheritance and underscore
recognition in the message-agreement test were also corrected against the existing contracts.

The dependency screen was run before the replay. It reports Phase 1 A01 to A06, A08 to A16,
R01 to R04 and R06 for the occurrence/snapshot/overlap boundary; A15 remains deferred. The full
changed-file screen and bounded current-host replay remain required. A09's held modifier and
context workflow is already a batched manual item. Raw screen output is kept in
`/tmp/phc-p212b-ledger-screen.json`. No case is awarded by the screen.

Slice A still lacks native Move-copy. Slice C remains blocked on that observation. This independent
Slice B work implements no Window unit, placement tool, Schedule or Aperture export.

## Native replay and gross-area correction

Fresh normal SketchUp 26.1.188 against installed source `1dae77d` observes cutting-descendant
exclusion from public Face reads, counts and Suggest, retained instance dictionaries in the
export snapshot, and explicit-reference refusal. Both partial-overlap directions refuse before
cutting and preserve geometry, assignments, glue and revision. Full matches pair without cutting;
a wholly covered glued side remains intact while its unglued counterpart splits. These are
partial E12 observations, not complete acceptance.

A real 0.25 m² glued cutter reduces SDK `Face#area(transform)` from 12 to 11.75 m² while
the host retains one unchanged outer loop, normal, plane and geometry digest. Public Face reads
consequently report 11.75 m² as gross area. The stale-preview probe exposed this mismatch.
Shared geometry now computes world-space outer-loop area minus actual inner-loop areas.
Cutter openings remain the responsibility of the later Window layer.

The correction passes 110 affected tests / 534 assertions on both Rubies, including holes,
concavity, reversed/cyclic winding and oblique mirrored/nonuniform transforms. Two-file lint
passes. Independent review found no actionable defects; an independent oblique-shear probe
passes 1 test / 2 assertions. Full gates and fresh installed-host replay now pass.
Private evidence: `p212b-before-area-fix.json`, the native probe and
`/tmp/phc-p212b-geometry-glue.json`; no licensed or client data is involved.

## Corrected installed replay

Source `7932856`, exact 296-file installed package SHA-256
`0c178acbf39842fe9d2206186e27051ba379c72fea6ce0d2fa62b0fa3751bf08`, runs in fresh
SketchUp PID 21117, bridge 61720. The synthetic reference fixture is copied before actions;
E12 source baseline and fixture/package provenance are retained privately. All read/exclusion,
partial refusal (both directions), full/no-cut pairing, covered-side preservation and
glue-only stale-preview refusal probes pass. Public glued full-match Face area is 12.0 m².
Native menu-key Undo/Redo for both pairing and counterpart splitting restores the captured
Face geometry, dictionaries and glue exactly. The original reference fixture remains unchanged.
The private report records 141 assertions, including helper reads and safety assertions; this
is not a claim of 141 separate acceptance cases.

Both full CI gates pass: 995 Ruby tests / 6725 assertions, 346 JS and 135 Python tests,
plus hostkit and package checks. Coverage is 96.6% Ruby / 94.9% JS / 94.98% Python.
The extraction golden changes only fourteen area values within 1e-14 floating-point tolerance;
all loops, digests, references and other values are identical. Existing Chromium 88 and eight
browser checks remain applicable: this correction changes no panel or Python runtime assets.

Private proof: `e12-slice-b-7932856-baseline.json`,
`e12-slice-b-7932856-provenance.json`, `e12-slice-b-7932856-host.json`,
`p212b-7932856-result.json` and `p212b-7932856-observed.skp`.
Complete E12 and the consolidated affected Phase 1 case ledger are still open.
