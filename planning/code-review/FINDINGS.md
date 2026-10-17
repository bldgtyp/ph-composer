# Findings register

Baseline: `60982fc73af6841f0c2bc5f55136dd21cad20930`, 2026-10-17.

P1 means a gate before supported external access, not a claim of present remote exploitation.
P2 means a concrete correction or follow-up needed for reliable agent workflows. A planned gap is
not a regression. Reproductions use the offline SketchUp stub unless explicitly stated otherwise.
No native corruption, release readiness or external-client compatibility is claimed.

| ID | Priority | Classification | Finding | Workstream |
| --- | --- | --- | --- | --- |
| A01 | P1 before external support | Planned delivery gap | No supported external connection | W3/W4 |
| A02 | P1 before external support | Planned authority gap | No named, revocable connection grant | W3 |
| A03 | P1 before external writes | Direct readiness gap | Host-safe execution remains a caller assumption | W3 |
| A04 | P2 | Reproduced defect | Connection authority retains mutable caller values | W1 |
| A05 | P2 | Reproduced contract defect | Pending retry skips payload comparison | W1 |
| A06 | P2 | Reproduced correctness defect | Filtered Spaces read changes model-wide totals | W2 |
| A07 | P2 | Reproduced contract gap | Spaces pagination does not bound nested detail | W2 |
| A08 | P2 | Reproduced workflow gap | First-Space creation lacks Zone context entry and root exit | W2 |
| A09 | P2 | Direct read/write coverage gap | Unmarked internal Faces cannot be discovered semantically | W2 |
| A10 | P2 | Direct metadata gap | Discovery omits host context, grants and useful preconditions | W1/W2 |
| A11 | P2 | Planned capability gap | Export has no supported artifact read-back operation | W5 |
| A12 | P2 | Planned capability gap | Visual context has no public capture/provenance contract | W5 |
| A13 | P2 | Maintenance / operating-guide gap | New Spaces access and client guidance are incomplete | W2/W4 |
| A14 | P2 | Reproduced behavior, unresolved policy | Revoking a location does not stop an in-flight export | W3/W5 |

## A01: no supported external connection

[AGENT_ACCESS.md](../../docs/AGENT_ACCESS.md#L3) accurately says no endpoint or client setup is
available. [API.connect](../../src/ph_composer/shell/api.rb#L96) issues a trusted in-process
context. The only development connection capable of arbitrary host control evaluates Ruby:
[host_bridge.rb](../../tools/hostkit/host_bridge.rb#L186). The shipped
[asset server](../../src/ph_composer/runtime/asset_server.rb#L8) serves pinned runtime assets
and explicitly says its token is not an agent credential.

**Consequence:** neither Codex nor Claude Code can use the application through a supported semantic
connection today. An agent developer can use the development bridge, but users would need private
Ruby knowledge and privileges that exceed the intended interface.

**Correction:** deliver one authenticated local application ingress and a shared MCP companion,
with explicit host/model targeting and generated operation mappings. Keep eval and runtime-asset
serving separate. [AGENT_INTERFACE](../../context/AGENT_INTERFACE.md#L21) already establishes this
separation. Validate with both clients and an outside synthetic feature; no adapter feature branches.

## A02: named connection grants and revocation are not implemented

[CallerRegistry](../../src/ph_composer/session/caller_registry.rb#L13) holds capabilities and
sequence state, with issue/fetch/count only. It has no connection identity, expiry or individual
revoke operation. [ApprovedLocations](../../src/ph_composer/shell/approved_locations.rb#L7)
is machine-local and grants are not bound to a caller. The current
[documented limitation](../../context/AGENT_INTERFACE.md#L228) is explicit: approved locations
are usable by callers holding the appropriate operation grant until connection work lands.

**Consequence:** trusted Ruby grants are useful dispatch checks, but cannot yet support the
visible, explicit and revocable external access promised by
[the authority](../../context/AGENT_INTERFACE.md#L254). An external adapter must not simply
forward client-requested capabilities to `connect`.

**Correction:** a host-owned connection authority maps authenticated identity to approved Models
and capabilities. Provide native inspection/revoke controls, enforce scope again when queued work
executes, and bind approved locations/tasks according to an explicit policy. Keep ordinary requests
within an existing grant free of repeated permission prompts. Test two clients with different grants,
revocation while queued, reopen/restart, and denial without side effects.

## A03: host-safe execution is assumed at the public entrypoint

[API methods](../../src/ph_composer/shell/api.rb#L111) enter dispatch synchronously.
[Mutation dispatch](../../src/ph_composer/shell/dispatch.rb#L166) executes on the calling Ruby
thread. [ModelSession.busy_reason](../../src/ph_composer/session/model_session.rb#L44) recognizes
exclusive mutations and feature-deferred work; it has no main-thread, modal or model-transition
readiness check. The retained thread probe commits on a worker in the stub.

**Consequence:** a network callback cannot safely be forwarded directly to this API. The native
consequence is untested; the probe does not establish a SketchUp crash. The development bridge's
timer routing protects its own call path, not arbitrary API callers.

**Correction:** define one host executor and readiness contract before external writes. Refuse or
schedule off-thread calls, bound queued work, and recheck target/grant/readiness/revision at execution.
Document the existing caller-thread precondition until then. Native checks must cover modal conflicts,
active tools, model activation/close during queued work, concurrent user edits and fresh-process
Undo/Redo. Governing rule: [host lifecycle](../../context/AGENT_INTERFACE.md#L151).

## A04: connection authority retains mutable caller values

[CallerRegistry.issue](../../src/ph_composer/session/caller_registry.rb#L21) freezes a shallow
copy of the capability array. Its strings remain shared with the input. Connecting with
`cap = String.new("read")` and then calling `cap.replace("model_write")` changes the stored grant.
A create operation then completes and commits, because
[dispatch](../../src/ph_composer/shell/dispatch.rb#L252) reads the altered capabilities.

[API.connect](../../src/ph_composer/shell/api.rb#L107) also returns the exact mutable session ID
from [ModelSession](../../src/ph_composer/session/model_session.rb#L18). Calling
`context.session_id.replace(...)` changes the authority's ID, invalidating previously discovered
detached IDs. The caller handle shares the same ownership pattern by source inspection.

This is an integrity defect in a trusted in-process API. Such a caller can already request broader
grants through `connect`; this is not evidence of an external privilege escalation. It violates
the [authority ownership rule](../../context/CONTRACTS.md#L122) and makes a future adapter harder
to reason about.

**Correction:** own and deeply freeze capability strings, freeze IDs and handles when minted, and
return immutable or detached connection values. Verify mutation of original arrays/strings and
returned context values cannot alter effective grants, session lookup or retry identity.

## A05: a different pending request is reported as the same running request

[retained_outcome](../../src/ph_composer/shell/dispatch.rb#L280) returns pending before comparing
the payload digest. The probe reenters with the same caller and sequence but different params;
the result is `request.pending`, where the [retry contract](../../context/CONTRACTS.md#L246)
requires `request.sequence_conflict`.

**Consequence:** no second write occurs, but the client is told its different intent is running.
Polling that sequence can retrieve an outcome for another payload, obscuring a client sequencing bug.

**Correction:** compare the digest first, then return pending only for an identical request.
Test differences in operation, params, expected revision and proposal digest while pending; retain
same-payload pending and completed replay behavior.

## A06: ID filtering changes a field documented as whole-model totals

[Spaces.list](../../src/ph_composer/features/spaces/reads.rb#L21) filters rows before calling
`totals`. [totals](../../src/ph_composer/features/spaces/reads.rb#L150) computes model sums from
those filtered rows, while Zone and Building-Segment aggregates use all Spaces.
[The schema](../../src/ph_composer/features/spaces/declarations/spaces.rb#L99) says model totals
cover every Space.

The reference fixture reads model floor area **34 m2** unfiltered. Filtering to the Loft gives
**12 m2** as `model.floor_area_m2`, while the returned Zone totals still sum to **34 m2**. Volume
and weighted area have the same scope mismatch. `ids: []` can return zero model totals beside
nonzero Zone totals.

**Correction:** compute whole-model aggregates before filtering and page/filter only the returned
rows. If scoped totals are useful, give them a separate explicit name. Verify model, Zone and
Building-Segment totals stay invariant under ID filters, page size and cursor.

## A07: paging Spaces does not bound the response

[Reads](../../src/ph_composer/features/spaces/reads.rb#L22) assembles complete Spaces, Volumes and
Floor Segments before filtering. [The row builder](../../src/ph_composer/features/spaces/reads.rb#L52)
embeds all children. [The result](../../src/ph_composer/features/spaces/declarations/spaces.rb#L93)
also carries global Zone/Building-Segment collections and stray findings. Params provide only
IDs, limit and cursor, with no fields or child paging.

The probe returns **238,481 bytes**, including **600 Floor Segments**, for `limit: 1`, with
`next_cursor: null`. Lowering the top-level limit cannot reduce it. This directly misses the
[focused-read requirement](../../context/AGENT_INTERFACE.md#L69). Full assembly also implies
unnecessary read work; native timing was not measured.

**Correction:** compact/projected Space summaries, separately paged child records and findings,
and explicit aggregate reads or opt-in aggregate inclusion. Preserve `.all` for its panel consumer.
Test one Space with more than 500 children, many unrelated findings/Zones, revision-bound cursors,
and projection that actually suppresses geometry/metadata. Define response budgets by payload type.

## A08: semantic clients cannot enter the Zone for the first Space or generally exit to root

[Spaces.create](../../src/ph_composer/features/spaces/authoring.rb#L38) requires the Zone's exact
open edit context. [context.open](../../src/ph_composer/features/spaces/declarations/context.rb#L51)
accepts a Space or Volume, so it cannot enter a Zone that has no Space. No registered Zone or generic
context-entry command supplies the missing step. The root-start probe refuses `space.context_required`.
The [walkthrough](../../tools/examples/authoring/spaces_walkthrough.rb#L33) satisfies the precondition
with host traversal and its private `open` helper.

The reverse route is incomplete too: [context.close](../../src/ph_composer/features/spaces/context/navigation.rb#L47)
stops after leaving a Space/Volume at its Zone, while `move_to_zone` requires closed context.

**Correction:** guarded Zone entry and root/parent exit through the established EditContext boundary,
or one shared explicit-reference navigation contract. Do not make adapters set `model.active_path`.
Test root -> first Space -> open Space -> root -> move to another Zone, with the panel closed and
no private host navigation after the client begins. Preserve protection and pending-work checks.

## A09: eligible unrecorded internal Faces have no semantic discovery route

[Zones traversal](../../src/ph_composer/features/zones/zone/occurrences.rb#L367) stops at stamped
authoring containers, as ownership requires. [Spaces scanning](../../src/ph_composer/features/spaces/scan/occurrences.rb#L94)
only returns Faces already carrying Floor Segment records. A correctly stamped Space fixture with
an unmarked Volume Face returns zero Zone Faces, zero explicit `host_context` rows and zero Floor
Segments. Supplying its native-known path to `spaces.floors.mark` nevertheless commits successfully.

**Consequence:** agents cannot discover an existing unmarked internal Face to mark it, or loose
Space-root Faces for `volumes.create`. Picking and raw host traversal know these paths, but semantic
reads do not. Drawing initial geometry is a separate host workflow; this finding concerns reading
already-present geometry for existing operations.

**Correction:** Spaces-owned candidate reads scoped to a Space/Volume, with bounded paths,
eligibility/refusal and geometry summaries. Retrieve full geometry explicitly. Test discover -> mark
-> read-back, loose Face -> new Volume, and unmark -> rediscover. Keep Zone ownership intact.

## A10: discovery lacks some facts needed to choose a valid operation

[Session summary](../../src/ph_composer/shell/api.rb#L166) omits edit path and readiness reason.
[Operation descriptions](../../src/ph_composer/shell/api.rb#L179) omit required grants,
non-action side effects and declarative preconditions. Task descriptions carry grants, creating
an avoidable inconsistency. A client must carry an out-of-band kind/method-to-grant mapping and
cannot inspect the first-Space context requirement as structured metadata.

**Correction:** generate grant/verb effects from the operation kinds; expose revision-bound model
context and readiness; add only useful operation-specific preconditions rather than duplicate
validation code. Publish the transport outcome/context/request schemas as well as each `value`
schema. Preserve the [existing discovery contract](../../context/AGENT_INTERFACE.md#L43).

Optional related improvement: [Spaces edit schemas](../../src/ph_composer/features/spaces/declarations/operations.rb#L24)
leave `values`/`expected_values` as arbitrary objects and target-kind keys optional. Runtime
validation exists and record descriptors are typed. Reuse typed editable-field schemas with units
and null-clearing rules, so agents can construct valid Space, Volume and Floor Segment edits without
mining prose. This is schema usability, not evidence of unsafe persistence.

## A11: completed export is not yet a supported semantic artifact read-back

[Task status](../../src/ph_composer/export/task.rb#L147) intentionally strips canonical bytes.
Successful output identifies an approved location and run, never its local path. That preserves
privacy and keeps polling small. There is no public API artifact retrieval method in
[API](../../src/ph_composer/shell/api.rb#L138) or [TaskContract](../../src/ph_composer/export/task_contract.rb#L49).
The quickstart tells a script to read the approved files, but an external caller holding only opaque
location/task IDs cannot do that through the supported interface.

**Correction:** approved artifact handles with format, size/hash, source session/revision and bounded
retrieval through the same grant authority. Define retention, revoke behavior and replacement binding.
Keep HBJSON out of ordinary status and do not introduce arbitrary-path filesystem tools. Test model
change, destination replacement, expired handle and denied cross-connection reads.

## A12: visual context remains a planned capability

The 23 view commands offer useful locate/select/Colour-by/tool controls; there is no public camera
snapshot or viewport capture operation. The [development shot helper](../../tools/hostkit/host_helpers.rb#L30)
zooms extents and writes an image, so it is not a side-effect-free public capture. The
[agent authority](../../context/AGENT_INTERFACE.md#L99) requires capture provenance and explicit
unsupported states. Existing host evidence also distinguishes viewport images from native overlay/HUD
captures; do not imply one captures the other.

**Correction:** first define semantic camera/selection context and a read-only capture contract with
explicit model/session/revision/camera/selection provenance. Keep framing as a `view` operation.
Investigate overlay inclusion and obscured/modal states on the host. Return an explicit unsupported
result where no trustworthy capture exists. Test that reads never move the camera or selection.

## A13: Spaces and client guidance lag the implemented interface

[AGENT_INTERFACE](../../context/AGENT_INTERFACE.md#L306) inventories Phase 2 operations but has no
equivalent Spaces workflow/limitations section. [The quickstart](../../docs/API_QUICKSTART.md)
predates Spaces and starts with a prepared selection. The generated reference is current but
**47,774 lines / 1,218,285 bytes**; discovery is **52,390 JSON bytes** in the synthetic session.
Those are useful references, not sufficient operating guidance for a first-time client.

**Correction:** add concise Spaces recipes and explicit host-required steps, keep generated detail
behind focused description calls, and deliver a shared end-user operating guide with client wrappers.
Do not repurpose development architecture/native-acceptance skills as end-user automation skills.
Test public-only recipes as executable clients and measure discovery with both real clients.
See [cleanup](CLEANUP.md) for specific stale guidance and preservation rules.

## A14: in-flight location revocation needs an explicit contract

[Tasks.start](../../src/ph_composer/export/tasks.rb#L20) resolves the approved location once;
[Task](../../src/ph_composer/export/task.rb#L17) retains its destination. Commit checks model
generation and destination state, but [does not resolve the location again](../../src/ph_composer/export/task.rb#L126).
The retained probe starts translation, revokes the location, then completes translation. It still
writes the HBJSON/report pair and reports `export.complete`.

This behavior is reproduced. Whether revocation should cancel already-accepted work is not settled
by the current location contract, so this is a policy risk, not a confirmed violation. It matters
when visible connection revocation is introduced: the user needs a truthful account of pending work.

**Correction:** choose admission-only versus commit-time revocation and state it in UI/API contracts.
Recommended default: prevent queued or pre-commit external file writes after revocation, while
reporting a completed/irreversible write truthfully. Recheck the connection and approved location
before commit if that policy is accepted. Test revoke before start, while translating, before writing,
after writing, and disconnect without revoke. Never conflate client loss with revocation/cancellation.
