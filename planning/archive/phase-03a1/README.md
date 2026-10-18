# Phase 3a1: agent access

DATE: 2026-10-17
STATUS: Complete 2026-10-18, archived. Every stage merged (#222 to #243); evidence in [STATUS](STATUS.md) and [the stage 16 receipt](evidence/p3a1-16-integrated-acceptance.md).
ISSUE: [#221](https://github.com/bldgtyp/ph-composer/issues/221)
BASELINE: `main@60982fc73af6841f0c2bc5f55136dd21cad20930`

This phase turns the [post-Spaces agent-access review](../../code-review/README.md) into five
implementation workstreams and sixteen bounded stages. The folder name `phase-03a1` is Ed's
explicit choice. Stage IDs are `P3a1-01` through `P3a1-16`.

The intended result is supported local access for Codex and Claude Code through the application's
public operations, with explicit user grants, reliable recovery and a complete semantic Spaces
workflow. Existing hand authoring remains complete. The review's fourteen findings are all assigned;
none is marked fixed by the existence of this plan.

## Read order

1. [PRD.md](PRD.md): user journeys, proposed behavior, scope and failures.
2. [STATUS.md](STATUS.md): authorization, decisions and the one stage/evidence ledger.
3. [PLAN.md](PLAN.md): stage graph, delivery order, ownership and verification.
4. [DECISIONS.md](DECISIONS.md): recommendations, unresolved choices and the stages each gates.
5. [CONTRACTS.md](CONTRACTS.md): proposed operation/data/state boundaries and compatibility rules.
6. [ACCEPTANCE.md](ACCEPTANCE.md): synthetic fixtures, failure matrix and evidence requirements.
7. [CLEANUP.md](CLEANUP.md): removal/replacement work and ownership.
8. The relevant [workstream](workstreams) and [stage](phases) document.
9. [Planning review](PLANNING_REVIEW.md): independent consistency review and documentation validation.
10. [Architecture review](ARCHITECTURE_REVIEW.md): verdict on the plan's shape, the proposed
    Ruby-hosted connection, generic tool surface and vertical delivery order; the decisions it revised.

## Workstreams

| Workstream | Stages | Result |
| --- | --- | --- |
| [W1: API integrity and discovery](workstreams/w1-api-integrity.md) | 01, 02 | Immutable authority, correct retries and useful machine contracts |
| [W2: Zones/Spaces semantic workflow](workstreams/w2-spaces-access.md) | 03, 04, 05 | Correct totals, bounded reads, candidate Faces and context navigation |
| [W3: connection authority and host execution](workstreams/w3-connection-authority.md) | 06, 07, 08, 09 | Tokens issued in SketchUp, a loopback HTTP ingress served from Ruby, a main-thread executor, acknowledged revocation |
| [W4: protocol surface, client configuration and operating guide](workstreams/w4-clients-and-packaging.md) | 10, 11, 12 | MCP methods and verb tools in Ruby, client snippets and diagnostics, tested operating guide |
| [W5: artifacts and visual context](workstreams/w5-artifacts-and-visuals.md) | 13, 14, 15 | Artifact path and hash disclosure, trustworthy viewport context and capture |
| Integrated handoff | 16 | Both clients pass the complete scenario; findings have evidence-backed dispositions |

## Authorization and boundaries

Ed authorized detailed planning on 2026-10-17 and explicitly excluded implementation. The same day
he answered every decision in the register (D3a1-01 to 15) and the packet was rewritten to the
accepted direction; stages are
delivered in the order V1 to V9 of [PLAN](PLAN.md). On 2026-10-18 Ed authorized implementing the
whole phase, one branch and pull request per stage, with host automation and computer use as the
stages need them; [STATUS](STATUS.md) records each stage's state and evidence.

This is the next planned insertion after Spaces and before resuming the roadmap sequence. Thermal
bridges remains its own packet; it has no invented agent-access dependency. Shared-file changes must
be coordinated. Phase 3's existing envelope-release boundary and the SketchUp 2023, Windows, METr
and public-distribution gates are unchanged.

The connection is an MCP server served from Ruby inside SketchUp over token-authenticated loopback
HTTP, with the public API verbs as its tools; there is no companion process and the RBZ is the
installation. Every decision in the register was answered the same day; the D3a1-12 starting bounds govern
every bounded store.

## Source and evidence

The review's [findings](../../code-review/FINDINGS.md),
[retained probes](../../code-review/evidence/README.md) and
[client research](../../code-review/CLIENT_INTEGRATION.md) are inputs, not new acceptance receipts.
Durable authority remains in [AGENT_INTERFACE](../../../context/AGENT_INTERFACE.md),
[CONTRACTS](../../../context/CONTRACTS.md),
[EXTENSIBILITY](../../../context/EXTENSIBILITY.md) and
[TECH_STACK](../../../context/TECH_STACK.md). Proposed changes are folded into those authorities
only when the owning stage settles and implements them.
