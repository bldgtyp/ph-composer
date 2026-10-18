# Phase 3a1 tracking ledger

DATE: 2026-10-17
STATUS: In progress. Ed authorized implementation of the whole phase on 2026-10-18, delivered one stage per PR through the pr-loop with delegated merge.
ISSUE: [#221](https://github.com/bldgtyp/ph-composer/issues/221)
BASELINE: `60982fc73af6841f0c2bc5f55136dd21cad20930`

This is the one place delivery completeness is read from. The [review](../../code-review/README.md)
is complete; this phase is not implemented. Earlier review tests remain review evidence only.

## Entry gates

| Gate | State |
| --- | --- |
| Ed requests new phase and detailed workstream planning | Confirmed 2026-10-17; exact folder `phase-03a1` |
| Ed authorizes implementation scope | Confirmed 2026-10-18: the whole phase, one branch and PR per stage, Codex review, merge on green, GitHub issues for anything found along the way, computer use as needed |
| Issue-backed intake and branch/delivery workflow | [#221](https://github.com/bldgtyp/ph-composer/issues/221) created 2026-10-18; one `<type>/phase-03a1-p3a1-NN` branch and PR per stage |
| Product and delivery choices | All fifteen decisions accepted by Ed 2026-10-17: seven after the [architecture review](ARCHITECTURE_REVIEW.md), then D13, D03, D04, D10, D06, D12 and D08 one at a time, receipts in [DECISIONS](DECISIONS.md). Stages 06 to 11 and 13, W3 to W5, this ledger, [PLAN](PLAN.md), [ACCEPTANCE](ACCEPTANCE.md) and [CLEANUP](CLEANUP.md) were rewritten to the first seven the same day; a second pass folds in the rest (03 to 05, 14, 15, W2, CONTRACTS 2, 3, 7, 8) |
| Engineering transport/runtime/budget/schema decisions | Transport and executor settled by D01/D02; every bound starts from the D12 table and changes only with a recorded measurement |
| Current head and prior review findings remain applicable | Baseline recorded; recheck once at implementation entry and only affected surfaces thereafter |

## Stage ledger

All values below are planned, not completed checks. Stage links, the order and dependency details
are in [PLAN](PLAN.md); case definitions in [ACCEPTANCE](ACCEPTANCE.md).

| Stage | Order | Workstream | State | Depends on | Case | Offline / review / host / client evidence |
| --- | --- | --- | --- | --- | --- | --- |
| P3a1-01 | V1 | W1 | Implemented on branch `fix/phase-03a1-p3a1-01` | Implementation authorization | C01 | Three regression tests in `tests/api_test.rb` fail before and pass after; review probes rerun (alias refused, pending mismatch conflicts, session id frozen); `make ci` green; native N/A (value and digest correction, no native dispatch change) |
| P3a1-06 | V2 | W3 | Scoped | 01 | C06 | Not run |
| P3a1-07 | V2 read, V5 write | W3 | Scoped | 06; write slice in V5 (D06 and D13 consent copy) | C07 | Not run |
| P3a1-08 | V2 read, V5 write | W3 | Scoped | 06, 07 (same slice); D12 from 06 | C08 | Not run |
| P3a1-10 | V2 read, V5 write | W4 | Scoped | 08 (same slice), D09/D13/D14 | C10 | Not run |
| P3a1-11 | V2 | W4 | Scoped | 07, 08, 10 read slices, D11 | C11 | Not run |
| P3a1-02 | V3 | W1 | Scoped | 01, 10 read slice, D10 | C02 | Not run |
| P3a1-03 | V4 | W2 | Scoped | 02, D03/D10 | C03 | Not run |
| P3a1-04 | V4 | W2 | Scoped | 03 | C04 | Not run |
| P3a1-05 | V4 | W2 | Scoped | 02, 04, D04/D13 | C05 | Not run |
| P3a1-09 | V5 | W3 | Scoped | 07 write, 08 write, D06 | C09 | Not run |
| P3a1-12 | V6 | W4 | Scoped | 05, 09, 10 write, 11 | C12 | Not run |
| P3a1-13 | V7 | W5 | Scoped | 09, 10 write, D07/D12 | C13 | Not run |
| P3a1-14 | V8 | W5 | Scoped | 05, 08 | C14 | Not run |
| P3a1-15 | V8 | W5 | Scoped | 10 write, 14, D08/D12 | C15 | Not run |
| P3a1-16 | V9 | Integration | Scoped | 01 through 15 | C16 | Not run |

## Finding coverage

| Finding | Primary stage(s) | Completion condition | State |
| --- | --- | --- | --- |
| A01 | 07, 08, 10, 11, 12 | Both CLIs use the token-authenticated loopback connection from an installed RBZ, read-only at M1 and with writes at M2 | Planned |
| A02 | 06, 07, 09 | Named tokens with capability sets and revoke, acknowledged at the pump and before an export's commit, with lifecycle evidence | Planned |
| A03 | 06, 08 | Main-thread executor and worker-side busy answer proved under modal, activation and close | Planned |
| A04 | 01 | Mutable-input/context regression tests pass | Fixed on branch (01) |
| A05 | 01 | Pending/completed mismatched payloads conflict | Fixed on branch (01) |
| A06 | 03 | Whole-model aggregates invariant under focused reads | Planned |
| A07 | 03, 08 | Bounded reads set from the clients' measured output caps; the ingress refuses over budget and never truncates; legacy behavior clearly labeled | Planned |
| A08 | 05 | Root-start and root-exit/move workflow public-only through the foundation context commands (D04) with declared lock effects (D13) | Planned |
| A09 | 04, 05 | Existing unmarked/loose candidates discovered, authored and read back | Planned |
| A10 | 02, 04 | Grant/context/envelope metadata and typed editable fields agree with runtime; `context` tool live | Planned |
| A11 | 13, 16 | Paths and hashes disclosed to the producing caller, files read with the client's own tools, hashes verified and references round-tripped | Planned |
| A12 | 14, 15, 16 | `context` read with camera and view generation; geometry-only capture under the `capture` grant read from its disclosed path by both CLIs (D08) | Planned |
| A13 | 05, 11, 12, 16 | Tested vendor-neutral recipes, exact-client connection instructions and skills current | Planned |
| A14 | 06, 09, 13 | D06 accepted; acknowledged revocation and the pre-commit recheck tested | Planned |

## Current next step and handoff

The packet is rewritten to all fifteen accepted decisions: the first seven in one pass and D03, D04,
D06, D08, D10, D12 and D13 in a second (stages 03 to 05, 14 and 15, W2, CONTRACTS 2, 3, 7 and 8,
the PLAN ownership table), both on 2026-10-17. P3a1-01 is the first implementation stage and waits only on Ed's
implementation authorization; V2 (06, 07, 08, 10, 11 at `read` scope) follows it and is milestone
M1. No decision is open. No coding agent should treat this row or the stage text as an
implementation go.

When a stage or slice changes state, add branch/PR/exact head, gate outcomes and receipt links here
and update affected context/docs in the same pass. Keep root planning status and roadmap
synchronized. Archive the phase flat as `archive/phase-03a1/` only after its accepted scope closes;
keep unresolved deferrals in their owning active packets.
