# Phase 06: bounded reads, export task descriptions, registration validation

DATE: 2026-09-30
STATUS: Blocked
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)
MERGE SET: No; recommended before faster feature development
BLOCKED ON: Phase 03; R-D5 for the branch

## Scope

| ID | Outcome | Review |
| --- | --- | --- |
| A02 | Entity inventories take explicit ID/path/Zone filters, field projections and bounded, revision-bound pagination, keyed by occurrence where UUIDs can be ambiguous. Unsupported arguments refuse. Cursors bind session, query/filter and revision; tighten the inherited catalog cursor to match. A separately named complete panel projection may remain if the panel needs it | [A02](../review/AGENT-INTERFACE-REVIEW.md#a02-bound-and-focus-entity-owned-reads) |
| A04 | Shell export task capabilities (preflight, start, status, cancel, latest) are describable: destination, replacement consent, task states, progress, results, cancellation, expired handles. Not modelled as a model mutation; export grant unchanged | [A04](../review/AGENT-INTERFACE-REVIEW.md#a04-make-export-task-methods-describable) |
| A06 | Registration validates the supported JSON-Schema subset itself (bounds, required/property consistency), checks handler callability, requires descriptions and examples with narrow exceptions, and deep-freezes published declarations | [A06](../review/AGENT-INTERFACE-REVIEW.md#a06-strengthen-registration-validation-without-building-a-framework) |

No plugin loader, no framework. Keep the registered contracts small.

## Source

`src/ph_composer/shell/{api,dispatch,record_queries,registry,registry_validation}.rb`,
`src/ph_composer/core/json_schema.rb`, envelope feature list operations, the Overview panel if it
moves to the named complete projection.

## Tests (write first)

- A02: more rows than the page maximum; explicit overflow state; stable order; deleted and
  duplicate identities; cursor refused after revision, filter or session change; `fields: ["name"]`
  returns no geometry or metadata; `{"limit":1,"fields":["name"]}` on two Zones returns one
  projected row (today: both complete records). Measure traversal and payload separately.
- A04: `API.describe(name: "start_export")` returns a description (today: nil). A client
  generated from the declarations preflights, starts at an authorized destination, polls,
  cancels and reads latest, panel closed. Status embeds no canonical bytes; no automatic
  overwrite.
- A06: malformed schema values, inconsistent `required`, non-callable handler, missing example
  each refuse at registration; mutating a published declaration raises.

## Ledger screen

Expect A03, A09 (if the panel projection changes), A12. Extend R06 with bounded reads and export
polling.

## Done when

- Tests pass; generated API reference from Phase 03 includes the new read and task schemas.
- STATUS rows A02, A04, A06 set to `Implemented on branch`.

## Result

(Fill on completion.)
