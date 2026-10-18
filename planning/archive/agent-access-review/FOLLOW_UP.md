# Follow-up investigations and implementation boundaries

STATUS: Recommendations only, 2026-10-17. No implementation phase is authorized by this review.
DETAILED PLANS: [Phase 3a1](../phase-03a1/README.md) now owns stage scheduling, decisions,
acceptance and cleanup. The recommendations below remain the review rationale; use the phase's
[ledger](../phase-03a1/STATUS.md) for current delivery state. No implementation is authorized.

Use findings A01 to A14 in [the register](FINDINGS.md) as the problem statements. Create issue-backed
owning packets when work is selected; this review is not a second feature ledger.

## W1: public API integrity and machine-readable discovery

Owns A04, A05 and the foundation portion of A10. Small bounded corrections should precede transport.

Freeze authority-owned IDs/handles and deep-copy/freeze capabilities. Compare pending retry payloads
before returning pending. Generate required-grant and verb-effect metadata; publish the request,
context and outcome envelope schemas for adapter use. Keep existing operation names and reference
semantics unless an intentional versioned change is needed.

Acceptance: original input/context mutation cannot alter grants or targeting; all pending and
completed retry combinations preserve identity; schema descriptions match dispatch; a client can
determine required capabilities without a private lookup table. Run focused tests, required offline
gates and one coherent-diff review. No native lifecycle claim follows from these pure boundary fixes.

## W2: complete the Zones/Spaces semantic workflow

Owns A06 to A09, Spaces schema usability in A10, and the Spaces documentation in A13.

Correct model totals independently of the pagination redesign. Add compact/projected Space reads
and explicit child/finding pages. Add Spaces-owned candidate Face reads and guarded Zone context
entry/root exit using existing EditContext protection boundaries. Decide whether the context commands
belong to Zones or a shared host-context capability; the adapter must not own that choice.

Acceptance:

- Public-only client starts at root with pre-existing synthetic geometry, discovers eligible Faces,
  enters Zone, creates first Space and another Volume, marks/unmarks a floor, updates height/airflow,
  returns to root, moves the Space and reads all affected records back.
- Candidate reads preserve ownership, report locked/shared/invalid targets, and remain read-only.
- Paging one large Space and many unrelated Zones/findings suppresses unrequested detail. Totals
  retain a declared invariant scope under filtering and cursors expire truthfully on revision changes.
- Native checks cover protection, context transitions, pending reconciliation, concurrent user edits,
  Undo/Redo and save/reopen. Reuse unchanged acceptance only where the dependency screen permits it.

This does not authorize a generic CAD automation layer. Raw geometry creation/transform/copy and
solid discovery need separate workflow decisions if users need them through agents.

## W3: connection authority and host executor

Owns A02/A03 and the policy portion of A14. This is the highest-consequence design boundary.

Resolve these product and runtime decisions before implementation:

| Decision | Recommended starting point | Investigation |
| --- | --- | --- |
| Local host transport | Authenticated local socket or loopback ingress | Compare packaging/platform costs, discovery, permissions and origin handling. Do not reuse asset-server/eval credentials |
| User grant | Named connection, explicit Model scope and read-first consent | Native enable/inspect/revoke controls; grants persist for an agreed lifetime, ordinary covered calls need no new prompt |
| Host scheduling | One bounded executor on the native thread | Measure modal/tool/model-transition readiness; reject unsupported states with structured recovery |
| Caller lifetime | Stable host-owned caller per approved connection/session | Bound abandoned callers; reconnect/outcome recovery without duplicate mutation |
| Revocation | Block queued and pre-commit external writes | Decide accepted work/export semantics and what the user sees when work is already irreversible |
| Diagnostic history | Bounded operation identity/outcome/reference history | Define retention and redaction; omit full model payloads, keys and private paths |

Acceptance: wrong host/session, denied grants, revoked/expired connections and queued stale work
write nothing. Two independent clients plus a user edit cannot silently overwrite each other.
Disconnect does not imply cancellation; reopen/restart invalidates old contexts. Native gates exercise
model activation, modal/native tools, close during queued work, Undo/Redo and fresh process behavior.
Do not keep a transaction open while waiting for the client or user.

## W4: shared local MCP adapter and client operating guide

Owns A01/A13. Depends on the authority/executor before write support. A read-only pilot can be
developed earlier if it uses a deliberately bounded grant and does not claim mutation support.

Spike a companion outside SketchUp Ruby. Measure packaged size/startup, install/update/removal,
protocol negotiation, tool/schema generation and discovery cost. Select Node versus Python or another
runtime from those measurements; the repository's development `uv` setup is not an end-user runtime
distribution plan. Use pinned dependencies and installed executables, not install-on-every-request
commands or arbitrary downloaded code.

Prefer generated typed operation tools with focused discovery. Keep the transport contract usable
by an optional thin CLI. Test whether each client can use deferred discovery reliably before selecting
a final tool surface. MCP request IDs correlate protocol messages; application sequences remain
necessary for duplicate-write prevention. Preserve them across lost replies and companion reconnects.

Build one concise operating guide and separate client installation examples. Its recipes must work
without source checkout or development eval. Plugin packaging is optional after standalone support.
See [CLIENT_INTEGRATION.md](CLIENT_INTEGRATION.md) for verified documentation and test scope.

Acceptance: independently run the same discovery/edit/recovery scenario in exact recorded Codex and
Claude Code versions, with panel closed and native Undo/read-back. Register an outside synthetic
feature and confirm it appears/works without adapter edits. Include malformed envelopes, incompatible
versions, no host running, multiple hosts, stale revisions, response loss, revoke and restart.

## W5: artifact and visual context

Owns A11/A12 and the export portion of A14. Artifact retrieval can precede visual capture.

Expose artifact handles with provenance, declared format, hash/size and bounded retrieval. Bind reads
to the approved connection and produced run; never turn it into arbitrary filesystem access. Keep
normal polling compact and define expiration/replacement/revocation behavior. Reconcile cancellation
with the existing export stage contract and adopted revocation policy.

For visual context, first expose semantic selection/camera state, then prove native capture behavior
including overlays and obscured/modal states. Separate read-only capture from intentional framing.
Support image delivery in both clients only after exact-client verification; a text-only fallback can
report the unsupported state honestly.

Acceptance: exported data is retrieved by handle and round-tripped to the authored IDs/values; wrong
connection/expired/replaced artifacts refuse. Capture carries Model session/revision/camera/selection,
changes no view state, and never labels an old or overlay-free image as a current complete viewport.

## Delivery and cleanup

Use W1/W2 first, then W3/W4, then W5. Split further only where ownership or acceptance differs.
Apply [CLEANUP.md](CLEANUP.md) in the owning slice. Synchronize context, client docs, generated
reference and status with verified capability as it lands. Keep implemented, host-verified and
client-supported statuses separate. External issues, code changes and distribution require their
own selected work; none were created by this review.
