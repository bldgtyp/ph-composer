# Phase 3a1 acceptance register

DATE: 2026-10-17
STATUS: All cases planned, none run for this phase.
ISSUE: none (local planning draft)

Passing review probes from the earlier investigation are baseline reproductions, not phase passes.
Each case below needs a receipt naming exact source/build/fixture/client/host identities and actual
assertions. Offline, native, merged and client-supported states remain separate in [STATUS](STATUS.md).

## Synthetic fixtures

| Fixture | Contents and purpose |
| --- | --- |
| FX1: semantic model | Two independently identified Zones with authored Assemblies, classified envelope Faces, one Window Type/Unit, loose Zone Faces, a stamped Space with loose root Faces and a Volume with an unmarked Face. Construct through test/native fixture helpers before the public client starts |
| FX2: aggregate reference | Reuse the Spaces reference calculation: whole-model floor area 34 m2, weighted area 32 m2, net volume 95.6 m3; selected Loft 12/12/36. Include explicit IDs and expected Zone/Building-Segment membership |
| FX3: response stress | 300 Spaces plus one Space/Volume with 600 Floor Segments, many unrelated Zones/stray findings, large optional metadata and long Unicode labels. Verify limits by measured bytes/CPU, not row count alone |
| FX4: competing targets | Two open Models with identical basenames, nested/locked/shared/stale paths, two connections with different grants, and a concurrent user edit |
| FX5: export recovery | Approved isolated destination, existing pair, interrupted-journal fixtures, replacement and symlink/target-change cases. Synthetic HBJSON/report only |
| FX6: visual states | Known cameras/selections, native tool, Colour-by HUD/overlay, hidden/obscured/modal states and view changes during capture |
| FX7: outside feature | Independently registered synthetic query/action/record with units, refusal and optional grant/bounds metadata. No adapter source edits permitted |

Reuse `tests/support/space_fixtures.rb` and existing synthetic export fixtures where appropriate.
Retain raw licensed data and real project models outside the public repository. Create no fixture
or native model during this planning-only task.

## Stage cases

| Case | Stage | Required checks | Evidence class |
| --- | --- | --- | --- |
| C01 | 01 | Mutate original capability array/elements and returned authority strings; grants/session lookup unchanged. Matching and mismatched pending/completed payloads behave correctly, including name/revision/digest changes | Deterministic; no native gate for immutable-value correction |
| C02 | 02 | Descriptions match effective grants/effects; context has exact session/path/readiness; serialized schemas/examples validate. Selection/view generation distinct from Model revision; panel closed | Deterministic plus bounded current-host context read |
| C03 | 03 | FX2 totals invariant under `ids`, empty `ids`, `limit` and cursor; FX3 `list` summaries under the 24 KB response budget with children and findings on their scoped reads; `fields` omits geometry and metadata; cursors expire as declared; `spaces.all` byte-identical; `MINOR` bumped with its changelog line | Deterministic plus native timing and read-only observation through the live connection |
| C04 | 04 | `candidate_faces.list` finds the unmarked Volume Face and the loose Space-root Face; mark, unmark, rediscover; eligibility shared with the actions; typed `values` and `expected_values` agree with runtime, units and null clearing; no read mutation | Deterministic and native candidate and read-back through the live connection |
| C05 | 05 | Root -> `ph_composer.context.open` (Zone) -> first Space -> new Volume -> floor mark and edit -> `ph_composer.context.root` -> move Zone -> read-back, public only after fixture setup. Locked, stale, busy and user-tool paths refuse with path and Model unchanged; leaving a Volume locks it as declared in `side_effects`; the lock, path, revision and Undo matrix recorded for a `view`-only caller with exact Undo labels; Undo, Redo and reopen preserved | Fresh native process plus offline public client, through both CLIs |
| C06 | 06 | The design receipt names transport, port, thread model, reply path, executor, busy answer, lifecycle, storage and the frozen D12 budgets, each with its in-repo precedent. Two bridge probes answer whether the acceptor runs under a native modal and the pump ceiling under a long operation; client protocol revisions, output caps and `codex exec` MCP loading are recorded at exact versions | Design review plus two bridge measurements on the current host |
| C07 | 07 | Issue, list, revoke and tombstone tokens; `read` fixed in V2 and the four other capabilities with their consent copy in V5; the token is shown once and its hash is absent from every public row, outcome and log; the dialog opens with the panel closed and with a draft open and leaves the draft untouched; `API.discover` lists nothing about tokens; a Model-only token's `discover` omits other sessions and equal-basename Models (V5) | Deterministic, browser checks for the dialog, native dialog use and restart |
| C08 | 08 | Through a real socket under the stub: wrong, missing and revoked token, `Origin` present, wrong `Host`, `GET`, another path, wrong content type, oversized body, malformed JSON, a batch, an unknown method, a full queue and an expired handoff all refuse before acceptance; a cancelled entry never executes; no `Sketchup.*` or `UI.*` call leaves the main thread. Starved pump: with a native modal open, the worker answers `session.busy` within the bound if 06 found the acceptor runs, otherwise the recorded client timeout is the documented behavior. Model close and activation between enqueue and execution. V5: D14 replay, conflict, unavailable and never-reassigned; a lost reply recovered by sequence or key; two tokens plus a user edit produce one valid mutation | Protocol adversarial tests plus fresh native lifecycle |
| C09 | 09 | Cross-caller `export_status`, `cancel_export` and `latest_export` refuse or omit; a native-started task is invisible to an agent. Revoke before admission, while queued, during translation, before commit and after commit, by token and by location independently: after acknowledgment no pair is written and the task finishes refused; after commit `export.complete` stands. No path, token or hash in any outcome or log | Deterministic race control plus a native revoke during a live export |
| C10 | 10 | Protocol methods and the result shape under the stub; the tool list equals the verb table filtered by capability (D09); `describe` through the tool equals `API.describe`; FX7 works unchanged; participants, `eval` and the asset routes are unreachable. Measured with both CLIs at exact versions: `tools/list` and `discover` bytes; which of `content` and `structuredContent` each client shows the model, which settles the content policy and the response budget; operation choice from `discover` and `describe` on FX1, the trigger for the typed-tool experiment; Codex `tool_timeout_sec`; the A07 payload against Claude Code's output cap. V5: D14 through the tools, the three lost-reply recoveries by reading state, MCP cancellation implying no rollback | Ruby protocol tests under the stub, plus the headless CLI runs that are M1 |
| C11 | 11 | Golden snippets per client at the pinned versions, including the environment-variable forms; a port conflict is reported and a changed port binds; the diagnostics line holds no params, path or token; both CLIs connect from the pasted snippet alone, the check commands report the server, `codex exec` loads the MCP config; the removal commands leave each client without the entry and the configuration snapshots compare equal | Deterministic plus a packaged current-host run with both CLIs |
| C12 | 12 | Exact Codex and Claude Code independently complete the semantic workflow panel closed from the installed RBZ and the pasted snippet, with no repo/private helpers/eval; stale/retry/revoke/two-client behavior; useful tool-discovery measurements | Real clients and native host; partial milestone only |
| C13 | 13 | Paths, hashes and sizes disclosed only to the owning caller and only after commit; absent before commit, on refusal, on cancellation, for a second caller, for a native-started task and after `task.expired`; hashes equal the files and no longer match after replacement; FX5 recovery leaves the disclosed hashes consistent with the pair; no path in a non-owner's outcome, in `Diagnostics` or in the ingress ring; both CLIs read the file at the disclosed path with their own tools, compare the hash, parse the HBJSON and report authored references | Deterministic, exact HBJSON round trip from disk, and a current native export read back by both CLIs |
| C14 | 14 | The `context` read's camera and view generation change nothing; a camera or selection change advances the generation without a revision. `write_image` measured frontmost, behind the panel, hidden, minimized and with a modal open; overlay, tool drawing and selection absent in the image, screenshot beside it; the states 15 must refuse named | Native measurement from the bridge, not client image support |
| C15 | 15 | `capture` grant required through the `view` tool; PNG under 2 MB at the disclosed path with matching hash and dimensions; `overlays` reads `not_included`; camera, selection, path and focus unchanged; a view change mid-capture refuses; four kept per session for 15 minutes, nothing else touched; both CLIs read a real capture from the installed RBZ | Deterministic and native two-client evidence |
| C16 | 16 | Integrated FX1/FX4/FX5 scenario through both clients, final exact-head checks, native Undo/Redo/save/reopen, finding/cleanup disposition and capability/support documentation consistent | Final integrated receipt; reuse unchanged gates explicitly |

## Cross-cutting failure obligations

All state transitions relevant to a stage must include successful, refused, failed and cancelled
endings from the [PRD](PRD.md). In particular, test lost replies at admission/execution/terminal
boundaries, same-sequence different intent, connection loss versus revoke, retention expiry, Model
close and host restart. Refusal before acceptance consumes no mutation sequence; accepted invocation
refusals retain the normal outcome. Transport receipt handling cannot weaken this rule.

No read may repair identities or change selection/camera/edit path. A new navigation view reports
the actual protection/revision consequences. No failure may label uncertain rollback `none`, and
no broad phase workflow may claim atomicity across independently invoked actions.

C02 also pages selection while the native selection changes without a Model revision: old cursors
must expire against selection/view generation. C05 tests view-only and view+model-write callers
leaving an unprotected Volume and asserts exact admission, lock/path/revision/Undo effects under
accepted D13. C07 and C10 must publish/enforce the same scope/effect in consent and tools. Existing
Spaces open/close/locate compatibility is part of that matrix, not assumed safe from a kind name.

## Integrated scenario and observations

Each client starts from a fresh copy of FX1. Record discovery and granted scope, summary/candidate
reads, preview, first-Space creation, Volume/floor edits, root exit and move, Assembly assignment and
Window placement using existing explicit-reference operations. After each mutation, read affected
references and current values. Native Undo/Redo checks target the expected single action boundary.
Save/reopen verifies values, metadata and references through fresh sessions.

Inject a competing user edit and demonstrate stale refusal, then lose a reply and recover its exact
outcome without a second Undo entry. Deny the second client access to an ungranted Model/location.
Start export, cancel one before writing, complete another, read both artifacts at their disclosed
paths and compare the exact HBJSON's IDs/references/values with the authored state. Exercise acknowledged revocation during
another pre-commit run. Capture and render a provenance-bound image where the selected host supports
it. Reopen/restart must reject old session/receipt/artifact handles as specified.

Use separate sessions/fixtures for failure injection so one corrupted scenario does not contaminate
later evidence. Native controls and the development bridge may prepare fixtures and observe host
Undo/save state; the client workflow itself may not use eval/private helpers. A bridge-only success
is not a supported-client pass.

## Receipt schema and closure

Each receipt names case/stage, commit and dirty-work scope, the installed RBZ hash, host/Ruby,
client surface and version, the pinned MCP protocol revision, fixture hash/session, effective
grants, observed assertions and artifacts. Codex CLI and desktop are distinct surfaces; a pass on one does not prove
the other. Freeze the target surface list under D11 before supported-client claims.
Include expected and actual failure codes/effects, revision/sequence/receipt correlations, limitations
and cleanup. Never record credentials or real project content. Register native cases in the existing
acceptance system when implementation begins; follow its dependency screen before reusing evidence.

The phase cannot close with missing required native/client gates. A capture route that is unsupported
on every tested host leaves C15/A12 open unless Ed explicitly accepts deferral and updates scope.
Passing cases do not imply Windows, SketchUp 2023, public distribution or certification support.
