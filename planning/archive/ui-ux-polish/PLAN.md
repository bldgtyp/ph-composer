# UI and UX polish: plan

DATE: 2026-10-04
STATUS: Complete. P1 to P7 implemented and merged through PR #71 on 2026-10-04.
ISSUE: none (local planning draft)

## Planning checkpoint

Preserve UX-001 through UX-022 in [REQUESTS.md](REQUESTS.md), group coherent changes into PRs,
and define investigations, decisions and acceptance before starting code. This checkpoint
organizes the requests; it does not claim reproduction, parity audit or settled mockups.

## P0: Investigate and settle affected design choices

Before code for an affected PR:

- Reproduce UX-007 with multiple Zones and contrasting Face values; determine sort scope.
- Compare Assembly commands, UI, tests and available predecessor evidence. Produce the UX-016
  parity matrix, covering insertion, dimensions/resize, deletion and all applicable affordances.
  Inspect both Ruby owners and browser UI; matching labels alone do not prove behavior parity.
- Reproduce the reported missing edge controls/resizing and library-picker completion flow.
- Inspect Colour-by filter targets and current shared inspector ownership. Compare nonmodal
  cards and other stable surfaces at representative widths, including interaction with drafts.
- Map library setup approvals to the existing authorization contract and immediate/staged
  mutations. Resolve user-visible steps without weakening consent or local-copy semantics.
- Inventory dialogs, table consumers, category tokens and Builder library surfaces. Settle
  the relevant [decisions](DECISIONS.md) using source and compact visual comparisons.

Investigations are bounded by these requests. Do not reopen unrelated closed phases.

## Proposed PRs

| PR | Area | Requests | Dependencies |
| --- | --- | --- | --- |
| P1 | Shared table presentation | UX-003, 004, 005, 011, 012, 013 | P0 decisions D3, D4 |
| P2 | Shared feedback and dialog behavior | UX-002, 010, 020 | P0 decisions D1, D5, D7 |
| P3 | Library setup and Builder library surfaces | UX-018, 019, 021; library portion of UX-020 | P2 shared dialog contract; P0 decisions D6, D7 |
| P4 | Zones / Faces workspace and tool grouping | UX-001, 006, 008, 009 | P1 chips, P2 contextual feedback; P0 decision D2 |
| P5 | Assembly Builder parity and composition | UX-014, 015, 016, 017 | Parity audit; P1 chips, P3 Library pattern |
| P6 | Windows toolbar polish | UX-022 | P1 chip language; P5 toolbar conventions where applicable |
| P7 | Zones / Faces sorting, if defective | UX-007 | P0 reproduction and decision D8; otherwise independent |

Shared foundations precede consumers; P7 can proceed independently after diagnosis. UX-016 is
an audit deliverable and closes only when its applicable gaps are resolved and verified. UX-018
and UX-021 belong to one Library workstream, not separate implementations. P2 owns modal
primitives; P3 owns the library completion flow that uses them.

PR boundaries may split if the parity audit exposes materially different model risks. Record
such changes here before code. Each PR should remain coherent and reviewable; do not combine
unrelated fixes simply because they use the same CSS file.

## Per-PR delivery

1. Record source diagnosis, affected shared consumers and accepted choices in this packet.
2. Implement only the authorized slice, preserving commands, data and transaction behavior.
3. Run the scoped checks and host evidence in [ACCEPTANCE.md](ACCEPTANCE.md).
4. Use the existing coherent-diff review with UI polish and architecture rubrics. Apply the
   repository review ladder; strengthen review for model lifecycle or public contract changes.
5. Update this ledger and affected authorities with docs-pass. Publish issues/PRs only within
   the subsequently authorized workflow; this local packet does not create external trackers.
6. For accepted shared kit changes, update the polish skill/patterns in the same work and
   synchronize the Design System from main after merge. Report any access limitation honestly.

## Handoff

A later implementation chat should start from this README and STATUS, then the next authorized
PR scope and its decisions. Implementation and creation of that chat require Ed's go-ahead.
