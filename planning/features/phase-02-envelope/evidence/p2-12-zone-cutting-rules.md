# P2-12 Slice B evidence: cutting components

DATE: 2026-10-01
STATUS: Implemented source and focused checks; independent review and native replay open.

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

The dependency screen was run before the replay. It reports Phase 1 A01 to A06, A08 to A16,
R01 to R04 and R06 for the occurrence/snapshot/overlap boundary; A15 remains deferred. The full
changed-file screen and bounded current-host replay remain required. A09's held modifier and
context workflow is already a batched manual item. Raw screen output is kept in
`/tmp/phc-p212b-ledger-screen.json`. No case is awarded by the screen.

Slice A still lacks native Move-copy. Slice C remains blocked on that observation. This independent
Slice B work implements no Window unit, placement tool, Schedule or Aperture export.
