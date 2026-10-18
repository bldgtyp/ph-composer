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
| P3a1-01 | V1 | W1 | Merged to main ([#222](https://github.com/bldgtyp/ph-composer/pull/222), Codex gpt-6.1-sol review: one P3 docs finding fixed) | Implementation authorization | C01 | Three regression tests in `tests/api_test.rb` fail before and pass after; review probes rerun (alias refused, pending mismatch conflicts, session id frozen); `make ci` green; native N/A (value and digest correction, no native dispatch change) |
| P3a1-06 | V2 | W3 | Merged to main ([#223](https://github.com/bldgtyp/ph-composer/pull/223), Codex gpt-6.1-sol: two P2 findings fixed, export pump and discovery bound measured) | 01 | C06 | [Receipt](evidence/p3a1-06-connection-design.md): M1 no Ruby thread runs under a native modal (1 tick in 11.8 s), workers run under long Ruby work; M2 largest pump gap 87.6 ms on 26.1.188; M2b a real export (integrated fixture, not FX3) held the main thread at most 7.49 ms per pump with a largest gap of 87.8 ms, FX3 deferred to C03; M3 Claude Code 2.1.300 `initialize` 2025-11-25, Codex 0.163.0 2025-06-18, `codex exec` loads `mcp_servers`; M4 response budget lowered to 24 KB; M5 discovery over MCP becomes a 9.7 KB index plus per-owner pages. Docs-only: `make ci` green |
| P3a1-07 | V2 read, V5 write | W3 | Read slice merged to main ([#224](https://github.com/bldgtyp/ph-composer/pull/224); two Codex gpt-6.1-sol passes, six P2 findings fixed: duplicate and incomplete stored rows, revocation order, decoded size, feedback inside the modal, a scrolling list); write slice Scoped | 06; write slice in V5 (D06 and D13 consent copy) | C07 | Read slice: `tests/agent_access_tokens_test.rb` (12) and `tests/agent_access_dialog_test.js` (7); `make ci` green. Host, SketchUp 26.1.188, installed RBZ from the branch: Agent Access opened from the native Extensions menu (System Events) with the panel closed; through the page DOM (bridge-driven clicks), a token was issued, shown once (48 hex, digest in the store, secret not stored), dismissed, revoked with its confirmation, with the panel then open and the Model unmodified at revision 1; a restart restored the list. Not observed: the Copy button, which needs a native click (computer-use was declined) and stays an open host check; a draft open in the panel while issuing. `agent_access.port` deferred to 08, which first reads it |
| P3a1-08 | V2 read, V5 write | W3 | Read slice merged to main with 10's ([#225](https://github.com/bldgtyp/ph-composer/pull/225); one PR because neither runs without the other; two Codex gpt-6.1-sol passes, eight findings fixed: the pump survives a raising call, UTF-8 and media-type and id checks, bounded errors, running calls never answered busy, pending counted across a batch, and preview, preflight, paging and the exact budget tested); write slice Scoped | 06, 07 (same slice); D12 from 06 | C08 | `tests/agent_access_server_test.rb` (16) through a real socket under the stub, which now refuses any Sketchup or UI call off the main thread: every wire refusal (401 missing, unknown and revoked token, 403 `Origin` and wrong `Host`, 404, 405, 413 declared before the body, 415, JSON-RPC parse, batch, invalid, method not found, bad `tools/call`), a starved pump answering `session.busy` with the entry never run, a full queue, an expired entry dropped, a queued call running on the session it named after another Model became active and refusing `session.unknown` after its Model closed, the listener's start, port-in-use and stop; Ruby 2.7.2 and 3.2.2. Host, installed RBZ in a fresh process: token issued in the dialog started the listener on 46110; curl refusals 401/403/405/401; `discover` through the pump in 166 ms; under a native `UI.messagebox` the client timed out at 5 s and the next call answered in 48 ms; revoking the last token stopped the listener. Changed: open connections 8 to 16 (D3a1-12). Not observed on the host: native activation of another Model window between enqueue and execution (needs a native click), covered offline |
| P3a1-10 | V2 read, V5 write | W4 | Read slice merged to main with 08's ([#225](https://github.com/bldgtyp/ph-composer/pull/225)); write slice Scoped | 08 (same slice), D09/D13/D14 | C10 | `initialize` (revisions 2025-11-25 and 2025-06-18, newer otherwise), `ping`, `tools/list` (5 read tools, 2,589 bytes), empty resource and prompt lists, notifications 202; `discover` index 9.4 KB on the host fixture with per-owner pages; `describe` equal to `API.describe`; FX7 (`tests/support/test_feature.rb`) discovered, described and queried with no adapter change. M1 pilot on the host, read token issued in the dialog, fixture SHA-256 `8d23fc20…2aeb`, RBZ `d0e8d13b…f14e`: Claude Code 2.1.300 (`claude -p`, HTTP config with a bearer header from an environment variable) and Codex 0.163.0 (`codex exec`, `bearer_token_env_var`) each listed the open Model and its two Zones with floor areas using `discover`, `describe` and `query` with the panel closed |
| P3a1-11 | V2 | W4 | Merged to main ([#226](https://github.com/bldgtyp/ph-composer/pull/226); two Codex gpt-6.1-sol passes, ten findings fixed: live last calls kept per token, busy answers counted, port checked before issuing and no token kept for a dead port, the Claude Code environment form, the export line run in the current terminal, probe timeouts) | 07, 08, 10 read slices, D11 | C11 | Golden snippets per client and a changed port (`tests/agent_access_client_config_test.rb`); port conflict reported and a new port binding through `Listener.port=` (offline); each token's latest call from the diagnostics ring, without params. Host, RBZ `a5d47368…efa1`, fresh process: token issued in the dialog; the Claude Code command run verbatim (`claude mcp get` reported Connected) and the Codex block pasted verbatim into `~/.codex/config.toml` (`codex mcp get` listed it); `tools/hostkit/agent_access_probe.py` ran `claude -p` 2.1.300 and `codex exec` 0.163.0, each calling `discover`, `describe` and one `query` (transcripts in `_private/host/agent-access/p3a1-11-gate2/`, token absent); entries then removed and both configurations compared equal to their snapshots. Finding: `codex mcp add` and `remove` rewrite the whole config file, dropping comments (another tool's generated-section markers); the first gate's file was restored byte for byte and the Codex snippet changed to a pasted block |
| P3a1-02 | V3 | W1 | Implemented on branch `feat/phase-03a1-p3a1-02` | 01, 10 read slice, D10 | C02 | One capability table (`Declarations::CAPABILITIES`) read by dispatch, `describe` (`capability`, `preview_capability`) and the reference, replacing the reference's hand-kept map; `tests/model_context_test.rb` (8) calls every registered operation without and with its described capability. Optional declared terms with registration checks: a view command's `side_effects`, `preconditions`, a query's `response` (the eleven `.all` snapshot reads name their `.list`). `discover` gains the outcome and request schemas, validated against outcomes of every status. `ph_composer.context.read` and the `context` tool: session with file name and path, revision, a new session view generation (selection changes), readiness, the edit path by persistent id, the selection in pages that expire on a selection change. `API::MINOR` 1 with the first row of the reference's API changes table. Citation guard checked with a scratch `P3a1-02`/`D3a1-10` line (rejected) and the current tree (clean). Host, installed RBZ, panel closed: root read (revision 1, view generation 1, SelectionTool); after opening Zone `west` the edit path named it by persistent id at revision 3; selecting two Faces moved the view generation to 2 with the revision still 3 and nothing moved by the read; two open `house.skp` Models from different folders read with distinct ids and paths. Selection pages use the shared page bounds (100 default, 500 maximum) rather than a separate 200 |
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
| A01 | 07, 08, 10, 11, 12 | Both CLIs use the token-authenticated loopback connection from an installed RBZ, read-only at M1 and with writes at M2 | M1 shown: both CLIs connect from the dialog's snippets and read (08, 10 and 11); the write scope remains (M2) |
| A02 | 06, 07, 09 | Named tokens with capability sets and revoke, acknowledged at the pump and before an export's commit, with lifecycle evidence | Planned |
| A03 | 06, 08 | Main-thread executor and worker-side busy answer proved under modal, activation and close | Planned |
| A04 | 01 | Mutable-input/context regression tests pass | Fixed, merged in #222 |
| A05 | 01 | Pending/completed mismatched payloads conflict | Fixed, merged in #222 |
| A06 | 03 | Whole-model aggregates invariant under focused reads | Planned |
| A07 | 03, 08 | Bounded reads set from the clients' measured output caps; the ingress refuses over budget and never truncates; legacy behavior clearly labeled | Planned |
| A08 | 05 | Root-start and root-exit/move workflow public-only through the foundation context commands (D04) with declared lock effects (D13) | Planned |
| A09 | 04, 05 | Existing unmarked/loose candidates discovered, authored and read back | Planned |
| A10 | 02, 04 | Grant/context/envelope metadata and typed editable fields agree with runtime; `context` tool live | Grant, context and envelope parts on branch (02); typed editable fields remain (04) |
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
