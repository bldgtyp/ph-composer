# Phase 3a1 decision register

DATE: 2026-10-17
STATUS: All fifteen decisions accepted 2026-10-17 (receipts below). Implementation authorized 2026-10-18.
ISSUE: none (local planning draft)

Existing architecture/grant/atomicity rules retain their authority. This register identifies new
choices. Engineering choices are resolved from evidence in the owning stage; product choices
require Ed's answer before dependent implementation. Independent authorized stages need not wait.

| ID | Choice and recommended default | Status / resolver | Blocks |
| --- | --- | --- | --- |
| D3a1-01 | MCP served from Ruby inside SketchUp over token-qualified loopback HTTP (Streamable HTTP, POST and JSON only), reusing the asset server's `LoopbackHttp` and thread/pump pattern; no companion process in v1. Alternative, the plan's original: a stdio companion outside Ruby with its own runtime. See [ARCHITECTURE_REVIEW](ARCHITECTURE_REVIEW.md) 1 | Accepted by Ed 2026-10-17 (receipt below). Both clients' HTTP and bearer-header support verified 2026-10-17 | 06, 08, 10, 11 |
| D3a1-02 | Host transport is loopback HTTP on a fixed configurable port; the main-thread executor is the development bridge's queue-and-pump pattern with `eval` replaced by an API-verb allowlist. No new runtime or dependency. An optional stdio shim for port/token discovery is a later convenience, not a gate | Accepted 2026-10-17 as D01's engineering default (receipt with D01), from in-repo evidence (`runtime/asset_server.rb`, `tools/hostkit/host_bridge.rb`); 06 becomes a design receipt confirming it | 08, 10 |
| D3a1-03 | Fix `spaces.list` in place: totals computed before filtering; rows become summaries (reference, editable and derived fields, child and finding counts) with a `fields` projection; children and findings move to `spaces.volumes.list`, `spaces.floor_segments.list` (scoped to an explicit Space or Volume) and `spaces.findings.list`. `spaces.all` stays whole for the panel. A minor API version bump under D10; `spaces_reads_test.rb` rewritten to the new shape. Rejected: five additive reads beside a labelled legacy `.list`; totals-only fix | Accepted by Ed 2026-10-17 (receipt below). Consumer audit 2026-10-17: `spaces.list` has no production caller; `spaces.all` is the panel snapshot section plus two walkthroughs | 03, 10 |
| D3a1-04 | A foundation capability owns edit-context navigation: `ph_composer.context.open(path)` and `ph_composer.context.root`, view commands registered beside `RecordQueries`, `ColourBy`, `Library` and `LocationCommands` in `FOUNDATION_FEATURES`. They take an explicit root-to-occurrence persistent-id path, refuse a locked entity on it (`target.locked`), run through `EditContext.enter` so every registered boundary fires, and declare the Volume-lock side effect under D13. Spaces' `context.open`/`close` remain as reference-aware conveniences. Rejected: Zones-owned navigation (a copy per feature as 3b and Phase 4 arrive); widening Spaces to open Zones it does not own | Accepted by Ed 2026-10-17 (receipt below) | 05, 02 (`context` read supplies the current path) |
| D3a1-05 | A token is the connection: a native dialog issues a random bearer token with a label, a capability set (read-first) and a revoke control, and shows the exact client config to paste. Sessions are discovered and named explicitly by the agent, as the API already requires; "this Model only" is an optional tightening on a token, not the default. Alternative, the plan's original: pairing nonces, session-bound grants and re-pairing on every reopen | Accepted by Ed 2026-10-17 (receipt below); see [ARCHITECTURE_REVIEW](ARCHITECTURE_REVIEW.md) 4 | 07, 08 |
| D3a1-06 | Commit-time recheck. Revoke ends admission, and the export task rechecks connection and location immediately before `pair.commit`, beside the existing generation and destination checks; a failed recheck ends the task `refused` (`export.revoked`, effect `none`) and writes nothing. The acknowledgment boundary is the main-thread tick that processes the revoke; work the main thread is already inside finishes, and the UI says so. Connection revoke and location revoke are tested separately. Disconnect is not revoke. Revoke never undoes committed actions, deletes output or lets a revoked connection read a completed run's path. Rejected: admission-only; cancel-on-revoke | Accepted by Ed 2026-10-17 (receipt below) | 07 consent copy, 09, 13 |
| D3a1-07 | After a run completes to an approved location the connection was allowed to use, the `export` grant discloses that run's HBJSON and report paths and hashes to that connection; the agent reads the files with its own tools. No byte retrieval through MCP and no unrelated file access. Alternative, the plan's original: chunked byte retrieval with hash reassembly, needed only for a remote client, which is out of scope | Accepted by Ed 2026-10-17 (receipt below); see [ARCHITECTURE_REVIEW](ARCHITECTURE_REVIEW.md) 5 | 13 |
| D3a1-08 | Geometry-only capture under a separate `capture` grant: `ph_composer.view.capture` calls `View#write_image` at the current camera (no zoom, selection or path change), writes a PNG to a per-session temp folder and returns path, hash, dimensions and provenance (session, revision, camera, edit path, selection digest) with `overlays: "not_included"` stated; the agent reads the file with its own tools as D07 does for HBJSON. Framing stays `locate`. Panels are not captured: the PH-Composer panel is a projection of the same queries, and SketchUp's panels show host state reachable through the `context` read and declared queries. Rejected: semantic context only; OS window capture in the extension | Accepted by Ed 2026-10-17 (receipt below) | 14 (spike shrinks to hidden-window and modal behaviour of `write_image`), 15, 12 guide table |
| D3a1-09 | The tool surface is the public API verbs, about fifteen tools with small fixed schemas (`discover`, `describe`, `context`, `query`, `preview`, `invoke`, `view`, `setup`, `export_file`, `outcome` and the five export task methods); operation schemas arrive through `describe` when needed. Generated per-operation typed tools are the experiment, run only if a client chooses operations badly from discovery. Evidence: 194 operations, 1.2 MB generated reference, 52 KB discovery | Accepted by Ed 2026-10-17 (receipt below); measured against both clients in V2, not at 10. See [ARCHITECTURE_REVIEW](ARCHITECTURE_REVIEW.md) 2 | 10 tool surface, 12 |
| D3a1-10 | Until the first public release the API changes freely under major 1: any shape change, additive or not, bumps `MINOR` once and adds one line to an "API changes" table in the generated reference. `discover` and the MCP `initialize` result both report `extension.version` and `api.major/minor`; there is no separate envelope version, MCP negotiates its own protocol version. The first public release gate freezes shapes; after it a reshape is a major bump that keeps the old operation for one minor as deprecated, and `describe` says so. Rejected: strict semver now; no versioning until release | Accepted by Ed 2026-10-17 (receipt below), with the words "Until a first release we change anything we want" | 02, 03 and every stage that changes a published shape |
| D3a1-11 | Initial proof targets the current macOS host with the Claude Code CLI and the Codex CLI at exact versions, because both run headless (`claude -p`, `codex exec`) so acceptance is scriptable; desktop surfaces follow and are claimed separately | Accepted by Ed 2026-10-17 (receipt below); whether `codex exec` loads MCP config is confirmed at V2 | Supported-client claims |
| D3a1-12 | Starting bounds fixed in the "Starting bounds" table below; a stage changes one only by recording the measurement that justified it. Rejected: measure first with no defaults | Accepted by Ed 2026-10-17 (receipt below) | Every bounded store: 02, 03, 08, 10, 13, 15 |
| D3a1-13 | Disclosed exception: navigation stays `view`. The contract reads "view writes no authored data and creates no Undo entry of its own; it may trigger the Model's own protection boundaries, which each command declares". `ViewCommand` gains `side_effects`; `context.open`, `context.close`, `locate` and the new Zones navigation declare the lock; the `view` consent copy names it. Rejected: requiring `model_write` for navigation, refusing when a lock would follow, skipping protection for API callers | Accepted by Ed 2026-10-17 (receipt below); C05 still measures lock/path/revision/Undo for a `view`-only caller | 05 public navigation, 07 consent, 10 external navigation exposure |
| D3a1-14 | The ingress assigns mutation sequence numbers. `invoke` takes an optional client idempotency key; the ingress maps the key to the caller's next sequence, keeps the mapping for the outcome retention window and returns the sequence in every result. A repeated key replays through the existing retained-outcome path; a repeated key with different input is `request.sequence_conflict`; a key whose outcome has expired or been evicted is `request.outcome_unavailable` and is never reassigned to a new sequence, so the key store forgets a key no sooner than the caller's sequence memory does. The in-process API contract is unchanged | Accepted by Ed 2026-10-17 (receipt below); see [ARCHITECTURE_REVIEW](ARCHITECTURE_REVIEW.md) 7 | 08, 10, 12 guide |
| D3a1-15 | Deliver vertically in the order V1 to V9 of [PLAN](PLAN.md), "Revised delivery order": a read-only MCP connection proven in both clients is the second deliverable, before the Spaces workstream. Alternative, the plan's original: the horizontal W1 to W5 order, first client contact at stage 12 | Accepted by Ed 2026-10-17 (receipt below); see [ARCHITECTURE_REVIEW](ARCHITECTURE_REVIEW.md) 3 | Stage order and milestones |

## Decision receipts

Each resolved row records date, accepted alternative, evidence, scope and affected contracts/stages.
Resolve product choices against concrete state diagrams/UX copy or measurement reports. No decision
is confirmed merely by elapsed time or by starting a stage. Unanswered choices do not prevent the
current planning deliverable from being complete.

| Decision | Date | Accepted | Evidence | Affects |
| --- | --- | --- | --- | --- |
| D3a1-01, D3a1-02 as its engineering default | 2026-10-17 | MCP served from Ruby over loopback HTTP; no companion in v1 | [ARCHITECTURE_REVIEW](ARCHITECTURE_REVIEW.md) 1; `runtime/asset_server.rb`, `tools/hostkit/host_bridge.rb`; client HTTP and bearer support verified 2026-10-17 | Stages 06, 08, 10, 11; CONTRACTS 5 and 9; the source review's companion recommendation is superseded |
| D3a1-05 | 2026-10-17 | A token is the connection; sessions chosen explicitly; "this Model only" optional | Review 4 | Stages 07, 08; CONTRACTS 4 |
| D3a1-07 | 2026-10-17 | Path and hash disclosure under `export` to the producing connection | Review 5 | Stage 13; CONTRACTS 7 |
| D3a1-09 | 2026-10-17 | Tool surface is the API verbs; typed tools are the experiment | Review 2 | Stage 10; CONTRACTS 9 |
| D3a1-11 | 2026-10-17 | Claude Code CLI and Codex CLI first | Review 8 | Stage 12 and supported-client claims |
| D3a1-14 | 2026-10-17 | Ingress-assigned sequence via idempotency key; expired key is `request.outcome_unavailable` | Review 7 | Stages 08, 10, 12; CONTRACTS 5 |
| D3a1-15 | 2026-10-17 | Vertical order V1 to V9 | Review 3; [PLAN](PLAN.md) "Revised delivery order" | Stage order, milestones, STATUS dependencies |
| D3a1-13 | 2026-10-17 | Option A, disclosed exception: navigation stays `view`, declares its lock side effect, consent copy names it | `protection.rb` `leaving`/`protect`; `model_session.rb` already advances revision on `active_path_changed`; `ViewCommand` lacks `side_effects` today | Stage 05 (declarations and C05 matrix), 02 (`side_effects` on view commands), 07 consent copy, context/AGENT_INTERFACE and CONTRACTS view sentence |
| D3a1-03 | 2026-10-17 | Option A: reshape `spaces.list` in place, add three scoped child/finding reads, keep `spaces.all` whole | grep of `src`, `tools`, `tests`, `docs` 2026-10-17: `.list` called only from `tests/spaces_reads_test.rb` and the generated reference; `.all` is the panel section at `declarations/spaces.rb:155`; Claude Code `MAX_MCP_OUTPUT_TOKENS` default 25,000 | Stage 03 steps 2 and 6, C03, CL02, CONTRACTS 2 (drop the "preserve legacy `.list`" sentence), D10 minor bump |
| D3a1-04 | 2026-10-17 | Option C: foundation-owned `ph_composer.context.open` and `.root`; Spaces conveniences kept; no Zones navigation | `session/edit_context.rb` names no feature and runs all boundaries; `extension.rb:43` lists the foundation capabilities; `features/zones` has no `EditContext.enter` today; P3b-03 needs the same step | Stage 05 (declarations, C05 recipe uses the foundation command), 02 (`context` read), CONTRACTS 3 rewritten from Zones-owned to foundation-owned |
| D3a1-10 | 2026-10-17 | Option B: free change under major 1 until first release, one `MINOR` bump and one changelog line per shape change; freeze at the release gate | `api.rb:20` (`MAJOR 1`, `MINOR 0`), `declarations.rb:10`, CONTRACTS "exact major compatibility"; no external consumer exists; MCP `initialize` carries protocol negotiation | Stages 02, 03, 05, 10; context/CONTRACTS "Public interface" gains the minor-bump and changelog rule; CONTRACTS 1 of this packet |
| D3a1-06 | 2026-10-17 | Option B: commit-time recheck of connection and location in the export task; admission ends at once; in-flight main-thread work finishes | `export/task.rb:126` `commit` already rechecks generation and destination on its own tick; `tasks.rb:22` resolves the location once; retained revocation probe | Stage 09 (one predicate in `commit`, code `export.revoked`, race tests per point), 07 consent copy, 13 path recheck, C09 |
| D3a1-12 | 2026-10-17 | Option B: starting values now, ratchet from measurements | Existing limits (`outcome_store`, `export/tasks.rb:7`), asset server and bridge constants, Codex `tool_timeout_sec` 60, Claude Code `MAX_MCP_OUTPUT_TOKENS` 25,000 | The table below; stages record measurements beside any change |
| D3a1-08 | 2026-10-17 | Option B: geometry-only `write_image` capture under a `capture` grant, path returned, overlays declared absent; no panel capture, panel state comes from the snapshot-section queries | `SKETCHUP_HOST_BEHAVIOR.md:53` (`write_image` renders geometry only, measured 26.1.188); `host_helpers.rb:30` `shot`; snapshot sections bind the panel to `spaces.all`, `zones.all`, Colour-by and tool-state queries | Stages 14, 15, C14, C15; V6 guide gains a "panel view to query" table; CONTRACTS 8 |

Ed accepted the first seven in the planning session on 2026-10-17 with the words "Accept the revised
direction on D3a1-01, 05, 07, 09, 11, 14 and 15 as recommended", D3a1-13 and D3a1-03 as option A and
D3a1-04 as option C and D3a1-10, D3a1-06, D3a1-12 and D3a1-08 as option B in the same session. Every
decision in this register is now answered; D02 stands as D01's engineering default. Acceptance authorizes the stage rewrite, not implementation.

### Starting bounds (D3a1-12)

| Bound | Start | Why |
| --- | --- | --- |
| Model outcomes | 256 per session, 15 min | Unchanged |
| Export tasks | 20 per session, 30 min | Unchanged |
| Idempotency keys (D14) | Kept as long as the caller's outcomes; `request.outcome_unavailable` after | Follows the outcome store, no second lifetime |
| Request body | 1 MB | A batch edit is kilobytes; 4 MB was the bridge's eval ceiling |
| Pending handoffs | 8 per connection, 30 s lifetime, then `session.busy` | Transient, not durable; under the 60 s client timeout |
| Pump-starvation bound | 10 s without a main-thread tick answers `session.busy` off-thread | Six times the measured idle pump, one sixth of the client timeout; V2 measures whether the acceptor runs at all |
| Response size | 24 KB of `structuredContent` per tool result, else explicit continuation or refusal (started at 80 KB) | Changed 2026-10-18 by P3a1-06 M4: Claude Code 2.1.300 refuses 60 KiB and keeps 40 KiB; Codex 0.163.0 keeps about 10,000 tokens and counts `content` and `structuredContent` together. Drives P3a1-03 page sizes ([receipt](evidence/p3a1-06-connection-design.md)) |
| Page size | 100 default, 500 maximum, plus the byte cap | Row count alone was the A07 failure |
| Connections | 8 tokens per installation; no expiry, revoke only | Fits one dialog; expiry would reintroduce the ceremony D05 removed |
| Model-context read | 200 selected entities per page at most, 100 by default, and the 16 KB page byte bound | Selection paging under C02; 500 short-named Groups measured 31 KB, over the reply budget |
| Captures (if D08 lands) | 2 MB PNG, 4 retained per session for 15 min | Follows the outcome lifetime |
| Request headers | 16 KiB | Added by P3a1-06 from the asset server's `MAX_HEADER_BYTES` |
| Open TCP connections | 16 (started at 8) | Added by P3a1-06. Raised by P3a1-08: at 8 the connection cap closed one token's ninth call before the 8-pending limit could answer `session.busy` |
| Request read deadline | 5 s | Added by P3a1-06 from the asset server's `REQUEST_TIMEOUT` |
| Pump cadence | 50 ms while entries wait, 100 ms idle, 5 ms and 0.5 ms yield slices | Added by P3a1-06 from the bridge and asset server; M2 measured a largest tick gap of 87.6 ms |
| Port | 46110, configurable | Added by P3a1-06, below the macOS ephemeral range |

A stage that changes a value records the measurement beside the new value in this table.

## Material tradeoffs

Additive bounded reads avoid breaking existing Ruby clients, at the cost of keeping a documented
legacy unbounded projection. The external surface must identify bounded alternatives generically
and enforce response budgets at ingress. Deprecation removal is separate from adding the new route.

Serving MCP from Ruby means hand-writing and pinning a small JSON-RPC surface in Ruby 2.7 instead
of taking an SDK, and it ties protocol upgrades to extension releases. In exchange there is one
process, one protocol and nothing to install beyond the RBZ. A companion would isolate protocol
dependencies but adds a runtime, packaging and a second local boundary that still needs its own
authentication into SketchUp. The in-repo asset server and bridge show the Ruby route works on the
proving host; the open risk is pump starvation during modal or long native work, which the
contract answers off-thread (CONTRACTS section 5).

Token-level grants let an agent see every open Model under one token; the API's explicit session
targeting and `discover`'s file names make a wrong-Model edit a visible choice rather than a silent
default. Session-bound grants prevent that at the cost of re-pairing on every reopen. Remembered
pairing across restarts is a token that persists; it is never permission to reuse a closed
session's identity.

Commit-time revocation makes the UI promise stronger than admission-only permission. Synchronous
native work cannot be retroactively interrupted; the acknowledgment boundary must say exactly when
the promise takes effect. Disclosing an artifact's path tells the connection where the user's
approved destination is; it is a disclosure the consent copy names, and it replaces streaming the
same bytes through MCP to an agent that already has file tools on the same machine.

Capture can reveal unclassified SketchUp geometry and other visible model content beyond ordinary
record projections. Permission and provenance must reflect that. A host that cannot capture required
overlays must report that limitation; all-host unsupported capture requires explicit deferral before
the phase can be called complete.

Existing `Spaces::Protection.protect` changes the native lock inside a transparent operation, while
the canonical view contract says view moves nothing in the SKP. The plan cannot resolve that by
calling every navigation effect harmless. D13 requires a measured admission/lock/path/revision/Undo
matrix for view-only versus view+model-write callers, an explicit compatibility decision for existing
Spaces context/open/close/locate, and matching descriptions/consent. No extra permission or canonical
exception is silently granted by this plan.
