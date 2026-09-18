# Contributor architecture

DATE: 2026-09-18
STATUS: Accepted architectural direction. No implementation yet.

PassiveBuilder exists to support an open-source community in the Phius sphere. A contributor
should be able to understand and extend one part without understanding the whole application.
Optimize for the amount a reader must learn before making a safe, useful change. Prefer explicit
code and stable boundaries even when they take more work or modestly more runtime resources.
Correctness, native host behavior and usable response times remain requirements.

This document owns contributor-facing architecture. [TECH_STACK.md](TECH_STACK.md) owns runtime
and host mechanics; [CODING_STANDARDS.md](CODING_STANDARDS.md) owns code-level readability rules.
The contribution contracts below are requirements for their future implementation, not claims
that an API already exists. Feature scope and delivery order remain with the owning packets.

## Organization and dependencies

Start with a modular application in one repository. Extract separately distributed packages when
a concrete adopter or independent release lifecycle justifies the additional maintenance.

Within the existing Ruby Model layer, separate pure domain records, calculations and validation
from SketchUp integration. Domain calculations accept explicit values and run without SketchUp.
Host adapters own geometry access, dictionaries, transactions and observers. Keep domain behavior
inside its owning feature unless several features need it and no feature owns it.

The application shell supplies registration, commands and transport. Feature packages own their
operations and optional UI. The UI kit depends only on its published contracts, with no domain
calculation or honeybee dependency. Python translation consumes the authored snapshot; downstream
exporters consume HBJSON. Preserve the existing four-layer boundaries.

Built-in features use the same public interfaces available to external contributors. A private
hook needed by a built-in feature exposes a missing public capability. Fix that contract before
presenting it as a supported extension point. Cross-feature access uses declared public contracts;
neither a global service locator nor an event bus should conceal business dependencies.

## Contribution contracts

Use several small contracts. A contributor implements only the capabilities their contribution
needs. One explicit registration entrypoint declares its dependencies and capabilities; class
names, monkey-patching and incidental load order must not discover behavior.

| Contribution | Owns |
| --- | --- |
| Record kind | Schema, identity and reference rules, validation and persistence behavior |
| Feature | Cohesive operations, optional UI and registrations |
| Importer | Source parsing and a proposed set of model changes |
| Library provider | Catalog definitions through the neutral library contract |
| Export contributor | Feature-owned data for canonical translation and its findings |
| Exporter | Conversion of HBJSON to another format |
| Colour-by mode | Values, colouring and legend information |

An importer does not write raw model dictionaries. The application validates its proposed
changes and applies accepted changes through normal model operations and Undo. A model importer
and a library provider have distinct contracts even when both read JSON.

Feature action schemas register with the action interface. The shell owns common transport
envelopes; ordinary feature actions do not require new feature-specific message types in a central
table. Registries must diagnose duplicate registrations, missing dependencies and incompatible
contract versions. Keep supported public APIs distinguishable from implementation details.

A composition-root registration or generated build inventory is permitted. Requiring a new
feature branch inside shell, session, export orchestration or UI-kit internals is a contract
defect. Explicit registration does not promise dynamic plugin loading, a marketplace or separate
installation in the MVP.

## Metadata and structured extension data

Every authored domain entity supports a JSON-compatible `user_data` mapping, including definitions
and assignment records where applicable. Contributors use namespaced keys, for example:

```json
{"user_data": {"example_org": {"review_status": "needs_site_check"}}}
```

Ordinary edits and supported persistence round trips preserve this metadata. Public operations
read and update it without requiring raw dictionary access; updates participate in Undo. Core
calculations do not silently interpret arbitrary metadata. Absence in an older record is valid.

Export inclusion is deliberate. Specify mappings for supported outputs and disclose omissions;
local metadata is not automatically admitted through the export privacy allowlist. Do not promise
lossless round trips through formats that cannot preserve it.

Maintained extensions can register structured extension data with a namespace, schema version,
validator and migrations. Preserve payloads belonging to unavailable extensions during ordinary
edits and save/reopen. Preserved data is not necessarily understood or validated. Report the
missing capability explicitly when it affects export correctness. An unsupported schema must
not be silently rewritten or dropped.

Before implementing this storage contract, settle copy/duplicate behavior, unknown-version edits,
reference ownership, export mapping and migration failure behavior. Test the relevant round trips
and actual references. Arbitrary metadata is not a substitute for a typed core domain field.

## Scripting as an entry point

[AGENT_INTERFACE.md](AGENT_INTERFACE.md) extends this interface to users' external agents,
including discovery, focused reads, visual context and reliable writes across host lifecycle changes.

Provide a small public interface for finding and reading entities, inspecting fields and
references, running validated operations, updating metadata, and requesting validation or export.
Reads return safe views or values. Writes use named operations with the same validation,
reference checks and transactions as the UI. Reading must not mutate or repair the model.

A script can become a reusable operation, then acquire a button or editor, then become a
maintained feature. Each stage uses the same business operation. A contributor should not need
to learn the UI framework to automate a model task.

## Evidence that the architecture is extensible

Prove implemented contracts with small synthetic examples and reusable contract tests:

- Update metadata through a console script.
- Register a record kind and a simple editor.
- Register an importer that proposes changes and applies them through model operations.
- Register an exporter that consumes only HBJSON.
- Register a Colour-by mode through the shared overlay interface.

Each example has a short walkthrough identifying the entrypoint, relevant contract and required
files. A newcomer should be able to trace one request through validation, mutation and its result.
Check that these examples require no private hooks or special cases for their feature names.
Persistence examples exercise metadata preservation, references, Undo/Redo and save/reopen;
unavailable-extension examples distinguish retained data from validated behavior.

Land each example with its owning capability. The foundation packet starts with a synthetic
feature and record; this list does not authorize implementing later features during transplant.
Do not claim an extension point is ready until its example and required host gate pass.

## Decisions still needed before API implementation

The owning implementation plans must settle the exact scripting methods and mutation contract,
metadata and extension-data lifecycle, and registration schemas and compatibility policy. These
are unresolved API details within the accepted direction, not a reason to reopen the community
goal or to invent all interfaces in advance.

## Development review

Use the repository-local
[architecture review skill](../.agents/skills/passive-builder-architecture-review/SKILL.md)
when designing an affected boundary and as the rubric for the existing coherent-diff review.
Review findings cite the rule, source evidence and contributor consequence. Readability concerns
need a concrete explanation; metric scores do not replace judgment.
