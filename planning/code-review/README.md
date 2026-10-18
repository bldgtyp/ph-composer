# Agent access architecture review

DATE: 2026-10-17
STATUS: Review complete; recommendations only. Implementation is not authorized by this packet.
ISSUE: none (local review requested by Ed)
BASELINE: `main` at `60982fc73af6841f0c2bc5f55136dd21cad20930`

FOLLOW-UP: Ed requested detailed plans on 2026-10-17. All findings now have owners in
[Phase 3a1](../archive/phase-03a1/README.md); its [ledger](../archive/phase-03a1/STATUS.md)
tracks implementation. Planning has fixed none of the findings.

PH-Composer has a useful application API for agents, but users cannot yet connect Codex or Claude
Code through a supported external interface. The next investment should be a small local connection
layer over the existing API, together with the specific API corrections this review identifies.
Keep feature behavior in Ruby and generate adapter contracts from registration.

The new Spaces feature mostly follows that architecture. Its records, metrics, floor marking,
copy repair and export have public operations. Two steps still break a public-only workflow:
entering the Zone context required to create the first Space, and discovering unmarked Faces
inside a Space or Volume. Its paged read also needs correction before agents can use it reliably
on larger models.

## Read this packet

1. [Findings](FINDINGS.md): 14 findings, classified by evidence and delivery consequence.
2. [Architecture and request flow](ARCHITECTURE.md): existing boundaries, recommended connection,
   permission ownership and failure behavior.
3. [Workflow coverage](WORKFLOW_COVERAGE.md): what a semantic client can do today, by subsystem.
4. [Codex and Claude Code integration](CLIENT_INTEGRATION.md): current official sources and the
   recommended use of MCP, a CLI and operating skills.
5. [Follow-up work](FOLLOW_UP.md): logical workstreams, research questions and acceptance checks.
6. [Cleanup](CLEANUP.md): stale guidance to reconcile and working components to retain.
7. [Evidence and reproduction](evidence/README.md): inventory, focused suites, probes and limits.

## Review outcome

Three code defects are reproduced: mutable connection authority, mismatched pending-retry handling
and filtered Spaces totals. Additional probes establish workflow and response-bound gaps, including
the first-Space workflow's missing context-entry operation. Other findings identify planned access
components, a revocation-policy risk and documentation work. The register distinguishes them
instead of treating every missing future component as a shipped-code bug.

Recommended order: correct authority and retry handling; complete Spaces reads and targeting;
define grants and host execution; prove a shared local adapter with both clients; then add artifact
retrieval and visual context. [FOLLOW_UP.md](FOLLOW_UP.md) records dependencies and the narrower
read-only pilot that can precede write support.

This review does not reopen the [archived general architecture review](../archive/code-review/README.md).
Its completed refactors remain the baseline. Existing geometry-contribution work and release gates
retain their owners.

## Method and limitations

The review inspected the registered interface and traced discovery, focused reads, preview, mutation,
retry, read-back, export and lifecycle boundaries. Two bounded reviewers covered dispatch/session
contracts and feature workflows; the main reviewer checked the material source evidence, export,
development tooling, client integration and final recommendations. The review uses the repository
architecture rubric. It does not claim to prove every geometry algorithm or screen.

Existing focused Ruby suites passed. Retained probes expose uncovered cases. Native SketchUp was
not launched or changed, and neither client was connected to a new adapter. There is no adapter
to test yet. Existing Spaces native acceptance is historical evidence for that feature, not evidence
of external-client support. See [the evidence limits](evidence/README.md).

Only review documents and reproducible evidence were added, with a router in
[planning status](../STATUS.md). Shipping source, normal tests and generated API reference are
unchanged. No commit, issue, PR, installation or release was performed.
