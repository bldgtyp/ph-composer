# Production support: planned contracts

DATE: 2026-10-19
STATUS: Complete 2026-10-20, archived
AUTHOR: Ed May, BLDGTYP, with Codex and Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/245

These were the planned contracts. PS-01 to PS-04 implemented them and the implemented rules now live
in CONTRACTS "Diagnostic log" and TECH_STACK "Help & Diagnostics"; where this file and context
differ, context governs. Existing authorities remain
[CONTRACTS](../../../context/CONTRACTS.md),
[TECH_STACK](../../../context/TECH_STACK.md) and
[EXTENSIBILITY](../../../context/EXTENSIBILITY.md).
PS-01 confirms concrete fields and folds implemented rules into context. The log it writes is the
one source for the support report and the separate developer reader. Public clients must not
infer that a new diagnostics API exists from this plan.

## Ownership

| Owner | Responsibility |
| --- | --- |
| `core/diagnostics.rb` | The existing logger, extended: validate and bound events, redact, rotate, retain its own health and the last storage error |
| Ruby execution boundaries | Capture operation identity, outcome, rollback certainty and correlation without copying params |
| Shell support capability | Native entry point, independent support window, report preview and explicit file/clipboard actions |
| Panel and runtime JavaScript | Capture owned exceptions and uncaught errors/rejected promises; submit bounded structured events through a validated channel |
| Python translation | Preserve failure stage/code and sanitized source frames through the existing runtime result path |
| Feature owners | Explain their own recovery through existing outcomes; no new per-feature health hook |
| Development tools | Read the same log file; keep eval, fault injection and raw development tracing outside the RBZ |

The shell names no feature. There is no second registry, telemetry framework or event store.
Register support commands through the existing composition and permission mechanisms. Diagnostics
must work with the panel closed. Native file consent remains explicit.

## Diagnostic event

PS-01 extends the existing allowlist. Proposed additions: `schema` (an integer, bumped when a
field's meaning changes), `severity`, `stage`, `effect`, `build`, `incident`, `frames`, and
non-authorizing `session`, `request` and `run` correlation references. Values preserve JSON types.
Unknown keys keep today's behavior: refused in strict tests, dropped with a bounded
`diagnostics_field_dropped` line in production. The dropped-field line must not echo untrusted
values.

A field allowlist alone does not protect its string values. Event, operation, stage and code come
from trusted declarations or fixed enumerations, not arbitrary request text or record labels.
Validate values as well as keys. Construct frame data explicitly: extension-relative file, method
and line, never absolute paths or source snippets. Regex path redaction alone does not authorize
copying an exception message; messages are never logged.

References cannot be tokens, API caller handles or persistent installation identities. A short
user-visible incident reference identifies evidence, never grants authority. The correlation
follows the panel request through Ruby execution and, for exports, the Python run and artifact
result. It does not replace mutation sequences or change retry semantics.

Keep existing public Outcome meanings and strict client schemas. An incident reference travels in
the outcome's existing `detail` field, with a strict-schema test for current clients. Never replace a domain refusal's code or structured detail
with a logging envelope. Preserve original stage/code across runtime boundaries even when the
user-facing message stays generic.

## Starting bounds

PS-01 verifies these against the proving host; they are starting defaults, not capacity claims.

| Resource | Starting limit |
| --- | --- |
| Local files | The existing 512 KiB log plus one archive, as today |
| Local age retention | Seven days, pruned on extension load |
| Event | 8 KiB, with at most 20 frames |
| Support report | The header plus the last 256 KiB of log lines, with explicit truncation markers |

A record larger than its bound is reduced before writing. Duration uses a monotonic clock; UTC
wall-clock time is for human correlation. Measure write overhead on the synthetic host case before
choosing whether frames are captured for every event or only for failures.

File failures leave authoring available. Keep the last storage error class and a bounded in-memory
tail so the support view can report degraded logging and still show recent events. Do not
recursively log a logger failure.

## Health and recovery

The support window reads build identity, manifest identity and logger health when it opens. Reading
them does not repair configuration, mutate a Model, start Python or open an agent listener. A
failed read is shown as unavailable, never as passed.

The Ruby-side deadline covers silence before `runtime.ready` and lost replies after startup. A
page-only boot timeout is insufficient. Choose deadlines from the proving-host measurements and the
existing runtime manifest gates; show a recoverable waiting state rather than guessing whether an
operation committed.

Recovery uses existing task/outcome APIs and verified read-back. A missing or expired mutation
outcome preserves uncertainty until state can be established; automatic re-execution is prohibited.
An unknown Model effect must never become a success or a claim that nothing changed.
Configuration writes check the host's return value and read back the result. Future or unreadable
stored formats refuse alteration rather than silently replacing their data.

A bootstrap record retains load failure information without allowing partial feature composition
to proceed as success. It is written by the loader before the full logger is required.

## Report and access boundary

Build one detached plain-text report, render its preview, then copy or write those exact bytes.
The header carries a report schema version, capture time, build and manifest identity, host
versions, logger health, the selected incident reference, the included event range and the list
of omitted fields. The body is the bounded log tail.

The HBJSON Export report remains an authored-model artifact and is never relabelled or
automatically attached as diagnostics. Save uses a native-approved destination and the existing
registered local-file command rules. Report overwrite, cancellation and failed writes honestly.
Never leave an apparently complete partial report after a failed write.

Agent tokens gain no new access implicitly. Detailed log retrieval is outside this packet's public
agent interface. Never expose an arbitrary read-file path.

## Compatibility

Preserve Ruby 2.7 and Chromium 88. Refresh generated panel lists and the runtime manifest for
changed shipped assets. Diagnostic-only actions add no Undo entry, no SKP attributes, no revision
advance and no save. Recovery cannot discard a draft, alter another Model or restart an active
runtime without the user-visible consequences required by the PRD.
