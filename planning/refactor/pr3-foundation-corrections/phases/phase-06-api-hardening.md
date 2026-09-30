# Phase 06: bounded reads, export task descriptions, registration validation

DATE: 2026-09-30
STATUS: Implemented on branch
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/5
MERGE SET: No; recommended before faster feature development

## Scope

| ID | Outcome | Review |
| --- | --- | --- |
| A02 | Entity inventories take explicit ID/path/Zone filters, field projections and bounded, revision-bound pagination, keyed by occurrence where UUIDs can be ambiguous. Unsupported arguments refuse. Cursors bind session, query/filter and revision; tighten the inherited catalog cursor to match. A separately named complete panel projection may remain if the panel needs it | [A02](../review/AGENT-INTERFACE-REVIEW.md#a02-bound-and-focus-entity-owned-reads) |
| A04 | Shell export task capabilities (preflight, start, status, cancel, latest) are describable: destination, replacement consent, task states, progress, results, cancellation, expired handles. Not modelled as a model mutation; export grant unchanged | [A04](../review/AGENT-INTERFACE-REVIEW.md#a04-make-export-task-methods-describable) |
| A06 | Registration validates the supported JSON-Schema subset itself (bounds, required/property consistency), checks handler callability, requires descriptions and examples with narrow exceptions, and deep-freezes published declarations | [A06](../review/AGENT-INTERFACE-REVIEW.md#a06-strengthen-registration-validation-without-building-a-framework) |

No plugin loader, no framework. Keep the registered contracts small.

## Source

`src/ph_composer/shell/{api,dispatch,record_queries,registry,registry_validation}.rb`,
`src/ph_composer/core/json_schema.rb`, `zones` list operations, the Overview panel if it
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

Commits `bbacbc4` (A06), `5ec7faf` (A02), `1b1f421` (A04), then the docs commit. Order changed to
A06, A02, A04 so registration validated the new declarations as they were written.

- **A06.** `JsonSchema.schema_problems` checks keyword values (whole-number counts, finite bounds,
  text, non-empty enums, `additionalProperties` form) and that a closed object requires only what it
  declares. Every query, action and view command needs a description, a callable handler and
  examples its params accept; one whose params accept `{}` may omit them. Participants, menu items,
  subscriptions and Colour-by projections must be callable. Published operations are frozen with
  deep-frozen schemas and examples. Colour-by `select_row`, the development example and the test
  fixture gained missing examples; two API tests now register a mismatched feature instead of
  mutating a published one.
- **A02.** `shell/pages.rb` pages by a stable key and binds a cursor to session, query, filter
  digest and revision; `records.list` moved onto it. `zones.list` (ids, paths, fields, limit,
  cursor) and `zones.faces.list` (zone_ids, zone_paths, ids, fields, limit, cursor) page in
  occurrence-path order with `next_cursor` and `total`; with `fields` a row is its reference and
  the named values only. Decisions: the panel reads new complete projections `ph_composer.zones.all`
  and `ph_composer.zones.faces.all` through the unchanged snapshot sections; `make_zone` and
  `restorable` stay whole on every Zones page (single object; bounded by exploded Zones), so the
  quickstart and walkthroughs need no second read. The Faces read measures and resolves only its
  page's rows; the Model walk itself is still one pass per read.
- **A04.** `export/task_contract.rb` describes the five task methods (grant, keyword params,
  result schema, example); `API.describe` answers them and discovery names `export_preflight`.
  Not modelled as actions. The generated reference has an Export tasks section.
- Quickstart step 7 and `api_client_test` cover paged reads and the export task methods (R06's
  extension); offline the task is cancelled before its runtime starts.

Tests: `registry_test` (4 new), `api_test` cursor binding, `tests/entity_reads_test.rb` (7),
`export_tasks_test` task-description client. Full Ruby suite 649 runs on 2.7.2 and 3.2.2.

Phase 09's review found one P1 this phase missed: the Split Face repair menu still read the paged
`faces.list` and saw only the first 100 Faces. Fixed in `0f77fff` (it reads `faces.all`), with the
walkthroughs; the same commit refuses a cursor whose position is the wrong kind of key, validates
records in the projected Faces read, and adds cursor-from-another-session and bound-check tests.

Ledger screen: every case (the `core/*` and `shell/*` patterns). Phase 09's native run extends R06
with paged reads and export polling on the host.
