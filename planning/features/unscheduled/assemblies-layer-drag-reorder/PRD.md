# Assembly Layer drag reordering

DATE: 2026-10-07
STATUS: Requested
ISSUE: none (local planning draft)

## Problem and accepted visual direction

Ed approved the contextual gear beside each Layer's thickness and a six-dot reorder grip beside
it. A grip promises dragging. The current `layers.move` action only swaps adjacent Layers by
`direction: outward|inward`; arbitrary drops cannot be implemented by chaining those commands
without producing multiple requests, partial outcomes and multiple Undo entries.

This packet owns real dragging and its atomic Model operation. The hover gear is implemented
separately on `codex/assemblies-ui-ux-refactor`. No grip appears until its promised behavior works.
Move outward/inward remain useful alternatives.

## User behavior

- A six-dot handle appears beside thickness on Layer hover/focus, alongside the gear. Revealing
  controls does not move the drawing or labels. Thin and membrane Layers remain reachable.
- Drag a whole Layer to any insertion position in the Assembly. A clear line shows the proposed
  position; no geometry or Model data changes until release.
- A valid changed drop makes exactly one atomic action and one native Undo step. No-op, outside
  drop, Escape, host/window blur, lost release, disposal, Model switch and stale snapshot write nothing.
- Keep Layer/Layer-Segment identity, Material assignments, widths, thicknesses, steel metadata,
  air-barrier references, orientation and selected segment. Only Layer ordering changes.
- Pending/refused actions retain a truthful drawing and a clear outcome. Do not accept another
  drag while a dimension/record draft, Material drag or Model write is active.
- The menu's Move outward/inward actions remain available; the handle does not become a menu-only
  substitute. Fit/zoom and horizontal scroll retain their existing rules.

## Proposed contribution boundary

Keep the operation in `features/assemblies`, using the existing declaration, request, expected-values
and native transaction contracts. Prefer a single `layers.reorder` action taking a Layer id and its
final zero-based index after removal; resolve naming/schema in the implementation design review.
Extend `layers.move` only if that yields a clearer compatible public contract. These are proposals,
not implemented APIs. The UI must not mutate Ruby-owned records or chain directional actions.

Drawing order currently follows the stored Layer array; orientation identifies which end is
outside. The drop operation must preserve that flag and translate the visible insertion position
explicitly. Command validation rejects missing identities, out-of-range destinations and stale
expected Layer order. An unchanged destination produces no operation/revision/Undo change.

## Implementation and acceptance checkpoint

1. Settle the action/schema and pointer lifecycle against the architecture rubric; add command and
   declaration tests before the gesture. Verify a single transaction with unchanged references.
2. Implement the gesture with threshold, preview line and complete cancellation/cleanup. Reuse the
   existing pointer conventions where their semantics fit; do not force Material assignment drag
   into a reorder abstraction.
3. Browser tests: first/middle/last positions, multiple-Layer jumps, membranes, uneven thicknesses,
   reversed exterior orientation, narrow views, scroll/zoom, stale refusal, busy/drafts, Escape,
   blur, disposal and release outside. Assert action count and final identities.
4. Required repository gates, one coherent independent architecture/UI review, and a fresh native
   fixture proving drag, one Undo restoring exact order/references and Redo restoring the result.
   Preserve the user's working Model; use a disposable fixture for mutation acceptance.

## Open decisions

- Action name and destination schema, settled before implementation.
- Drop behavior while the canvas auto-scrolls and the minimum thin-Layer target reach.
- Whether a grab preview moves only a ghost or temporarily reserves space. Recommend a lightweight
  ghost and insertion line, keeping the drawing still until acceptance.
