# W1: API integrity and discovery

DATE: 2026-10-17
STATUS: Scoped; planning only. No implementation authorized.
ISSUE: none (local planning draft)
FINDINGS: A04/A05 and foundation A10
STAGES: P3a1-01, P3a1-02

This workstream makes the existing public boundary dependable before another process uses it.
It corrects reproduced defects without redesigning feature operations. Model session/caller authority
and operation schemas stay owned by the foundation.

## Stages

| Stage | Deliverable | Acceptance |
| --- | --- | --- |
| [01](../phases/p3a1-01-authority-and-retries.md) | Immutable capability/identity values and pending digest comparison | C01 |
| [02](../phases/p3a1-02-discovery-and-schemas.md) | Grants/effects, public host context and envelope schemas | C02 |

The stage files own implementation steps. Shared policy/data are in [CONTRACTS](../CONTRACTS.md),
product choices in [DECISIONS](../DECISIONS.md), evidence in [ACCEPTANCE](../ACCEPTANCE.md), and
progress only in [STATUS](../STATUS.md).

## Ownership and architecture

Own shell API/dispatch/declaration/registry changes and session caller/outcome contracts. Preserve
trusted in-process connect defaults, outcome lifetimes and explicit Model targeting. Describe the
current host-thread assumption honestly until W3 supplies its executor. No feature dependency or
transport SDK enters the record engine.

## Dependencies and handoff

01 requires only implementation authorization. 02 consumes 01 and the compatibility decision for
any schema break. W2 needs bounded metadata/context; W3 needs the request/outcome/identity contract;
W4 consumes schemas rather than inventing another catalog. Export task and normal operations must
use the same grant vocabulary even though their result mechanisms differ.

## Acceptance and failure boundaries

Mutating either caller inputs or returned connection values cannot change authority. Pending retries
compare full intent before reporting pending. A schema-driven client can identify permissions and
current context, serialize requests and distinguish refused, failed, pending and unknown effects.
Additive metadata must not break old clients or make an unsupported state appear available.

## Verification and cleanup

Standard profile for the immutable-value/totals-sized changes; use stronger review if dispatch
authorization semantics expand. C01 is deterministic with native N/A; C02 has a bounded panel-closed
host context read. Run required dual-Ruby/schema/reference gates once per coherent delivered head.
CL01 removes duplicated grant/authority maps; context and generated reference are updated together.

## Out of scope

No MCP implementation, connection UI, new persistence format, retention change or speculative
proposal-framework rewrite. Existing atomicity/Undo machinery is retained.
