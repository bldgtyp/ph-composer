# P2-12 Slice B evidence: cutting components

DATE: 2026-10-01
STATUS: Native replay exposed a gross-area defect; correction reviewed, full gates and fresh replay pending.

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
passes 1 test / 2 assertions. Full gates and fresh installed-host replay remain pending.
Private evidence: `p212b-before-area-fix.json`, the native probe and
`/tmp/phc-p212b-geometry-glue.json`; no licensed or client data is involved.
