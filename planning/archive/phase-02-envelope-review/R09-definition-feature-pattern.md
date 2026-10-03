# R09: the definition-feature pattern is copied, forked by kind and driven by positional tables

DATE: 2026-10-01
STATUS: Merged to main 2026-10-02 (PR #26); dual-Ruby `make ci` passes; no host gate named
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft; review of PR #15, issue #14)
CLASS: Optional improvement, readability and contributor cost. No correctness defect found.
ORDER: 9 of 11. See the packet README, Sequencing.

Paths are relative to `src/ph_composer/`.

## Governing rules

- `context/CODING_STANDARDS.md`: "Prefer explicit control flow... Do not compress several decisions
  into a clever expression or hide business behavior in dynamic method construction."
- Same file: "Justify abstractions by what the reader can stop knowing. Similar syntax is
  insufficient."
- Same file: "Name the domain meaning."
- `context/EXTENSIBILITY.md`: "A contributor should be able to understand and extend one part without
  understanding the whole application."

## Observed

Assemblies owns two catalog kinds and Windows owns four. Both features implement the same set:
list, all, create, update, duplicate, delete with replacement, a snapshot row with findings and uses,
name uniqueness, a library kind adapter.

1. **One generic path forked by kind at every step.** Assemblies: `operations.rb:33,48,63`
   (`if kind == MATERIAL_KIND`), `snapshot.rb:26,30,34,38,45`, `declarations/records.rb:36,51,62`,
   `declarations/shapes.rb:46,52`, `declarations/inventories.rb:29,32`. Windows:
   `operations.rb:24,49,68,87,106,111` (`collection == "types"`), `snapshot.rb:29,31,33,35,38`,
   `library_assignment.rb:13,14,31,37,38`. To follow "create a Material" a reader steps through code
   shared with "create an Assembly" and discards half of each branch.
2. **Kinds built from a positional table.** `features/windows/products/schema.rb:15-25`:
   `"uf_w_m2k" => ["W/m2K", 0]`, `"g_value" => ["fraction", 0, 1]`, read back as `spec.first`,
   `spec[1]`, `spec[2]`. `features/windows/declarations/grid.rb:11-29`: nine actions generated from
   `COMMANDS = { name => [properties, example] }`, dispatched through a `case` on a string in
   `types/grid_operations.rb:17-28`.
3. **The same helpers exist two to six times.**

   | Helper | Copies |
   | --- | --- |
   | Closed-object schema builder `object(properties, ...)` | 6: `Records::AuthoringFields.object`, `Assemblies::Shapes.object`, `Windows::Shapes.object`, `Library.object`, `Library::Schemas.object`, `Zones` `Shapes.object` |
   | `list`, `with`, `view`, `list_params`, `UNREADABLE`, `RESULT`, `FINDING` shapes | 2 each (Assemblies, Windows) |
   | Read records, collecting unreadable ones | 2: `Assemblies::Snapshot.read_records`, `Windows::Snapshot.read` |
   | `unique_name!`, `duplicate_name` | 2 each, with different refusal messages |
   | Deterministic nested-id allocator | 2: `Assemblies::Operations.identity_allocator`, `Windows::Operations.allocator` |
   | Library adapter scaffolding (`map`, `reverse`, `fingerprint`, `schema`, `wire_schema`, `local_read`, `replace`) | 2: `assemblies/library_kind.rb`, `windows/library_kinds.rb` |

4. **Names that hide meaning.** `Assembly::Schema::KIND.references.first` is used three times to mean
   "the Material reference" (`operations.rb:83`, `validation.rb:41`, `snapshot.rb:56`). Block
   parameters `r`, `p` in `library/install.rb:55-103`. `gw`, `gh`, `r0`, `c1`, `a`, `b` in
   `features/windows/types/thermal.rb:113-136` and `types/grid_operations.rb:91-94`.
   `Windows::Snapshot` renames `psi_install_types` to `installs` in passing (`snapshot.rb:33`,
   `export.rb:40`).
5. **Display names without units.** Thermal blocks publish `u_effective`, `u_construction`,
   `r_construction`, `rsi`, `rse`, `u_w`, `psi` beside `gross_area_m2`, `width_m`, `h_install_w_k`.
   The schema carries `x-unit`, the name does not. Python dataclasses drop units the Ruby record
   carries: `Side.width`, `uf`, `psi_g`, `Glazing.ug`, `g`
   (`python/ph_composer_translation/contract/window_records.py`).
6. **A library callback reads a missing record with a different code.** Added 2026-10-02 from R07's
   review. Inside a library callback, `request.engine` is `Records::ProjectedEngine`, whose `find`
   resolves through the change set with `resolve_reference`. A missing or staged-deleted record
   refuses `reference.invalid`; the plain `Engine#find` refuses `target.not_found`. So a library
   `use_library` replace of a record deleted since review answers a different code from the same
   edit through the `update` action. Pre-existing (the old wrapper behaved the same).
   `context/CONTRACTS.md`, "Callback write ownership", promises the full read surface.
7. **The file provider factory reaches the registry itself.** Added 2026-10-02 from R02's
   follow-ups. The `library_provider` factory block in `library/install.rb` takes no arguments, so it
   reads `Registry.current` to list the registered library kinds and their adapters. The provider
   contract hides what the factory depends on. Pre-existing.
8. **Operations do not publish the codes they refuse with.** Added 2026-10-02 from R04's
   follow-ups. R04 made every feature declare its codes (`feature.code`), but they appear only under
   "Feature codes" in `docs/API_REFERENCE.md`. `API.describe` does not say which codes an operation
   can answer. R04's optional item 7 (`refuses:` on operations) was not done.

## Consequence

Contributor task "add a definition kind with an inventory, for example a shading product": copy
about 150 lines of operations, 60 of shapes, 80 of snapshot and 100 of library adapter from one of
the two features, then delete the branches for the other kind. Phase 3 and 4 add more definition
kinds (thermal bridge psi types, seven equipment families).

## Proposed correction

Two steps, the second only if Ed wants the abstraction.

1. **Unfork and name (no new abstraction).**
   - Split `Operations` per kind: `Materials::Operations`, `Assembly::Operations`,
     `Products::Operations`, `Types::Operations`. Shared lines stay duplicated where they are short.
   - Replace the positional tables with explicit declarations: one `Fields.field(...)` line per
     product field with named `unit:`, `minimum:`, `maximum:`; one explicit `feature.action` per grid
     gesture with its own description (this also serves R03 item F).
   - Name `MATERIAL_REFERENCE`. Spell out the abbreviated locals. Keep one name for the Psi-Install
     collection.
   - Add unit suffixes to thermal display fields (`u_effective_w_m2k`, `rsi_m2k_w`) and to the Python
     dataclass fields. This changes result schemas and the panel. **Decided 2026-10-01 by Ed:** do it
     now, in one pass with R04's code rename, before any release. **Done with R04, PR #19** (see its
     Outcome): the thermal display fields and the Python window record fields carry their units.
2. **One schema builder in the foundation.** Move `object`, `list`, `with`, nullable and id-pattern
   helpers to a single `core/` module that Zones, Assemblies, Windows and Library all use. This is
   justified on its own: six copies of one four-line function, already drifting in keyword names
   (`required:` and `optional:`).
3. **Item 6: one `find` refusal.** `ProjectedEngine#find` answers as `Engine#find` does:
   `target.not_found` for a record absent from the projected state (including a staged delete),
   `record.unreadable` for one that fails its kind. One focused test in
   `library_callback_invoker_test.rb`. Do it with the per-kind split, since the replace callbacks
   are the callers.
4. **Optional, decide after Phase 3's first definition kind:** a small `CatalogInventory` helper
   offering the standard list, all, create, update, duplicate, delete registrations for one
   `RecordKind`, with hooks only for defaults and row display. Trace the contributor task before and
   after; adopt it only if the after is shorter to read, not just shorter to write.
5. **Item 7: the factory receives what it needs.** The provider factory is called with the registry
   (or the registered library kinds), so `library/install.rb` no longer reads `Registry.current`. A
   contract change to `library_provider`; record it in `context/EXTENSIBILITY.md`. Do it with the
   library adapter scaffolding in item 3.
6. **Item 8, optional: operations declare `refuses:`.** Each operation names the declared codes it
   can answer, registration refuses an undeclared one, and `API.describe` publishes the list. Do it
   while the per-kind split rewrites the declarations, or record that it stays optional.

## Verification

- `grep -n "== MATERIAL_KIND\|== \"types\"" features` returns nothing in operations and snapshot
  files.
- `make fixtures-check`: `docs/API_REFERENCE.md` changes only in descriptions and, if the unit
  renames are taken, in the named fields.
- Existing operation and schema tests pass with no assertion changes other than renamed fields.
- A library callback's `find` of a missing record refuses `target.not_found`.
- `grep -n "Registry.current" src/ph_composer/library` is empty.
- If item 8 is taken: `API.describe` of a Windows Type operation lists its refusal codes, and a test
  refuses registering an operation that names an undeclared code.

## Outcome

Implemented 2026-10-02 on `refactor/r09-definition-feature-pattern`, cut from `main` at `4f69240`.
Merged as PR #26.
Correction steps 1, 2, 3 and 5 were taken (observed items 1 to 4, 6 and 7). Step 4
(`CatalogInventory`) waits for Phase 3's first definition kind, as planned. Step 6 (item 8,
`refuses:` on operations) stays optional: it is a shell, registry and `API.describe` contract change
that this branch did not need.

1. **Unfork and name.** Windows: `Products::Operations` (the three product kinds share one path,
   chosen by collection) and `Types::Operations` (create, update, duplicate, delete, grid) replace
   the collection-forked `Operations`. Assemblies: `Materials::Operations` and
   `Assembly::Operations`. Each feature's shared reads and naming rules live in its `Definitions`
   module (allocator, records, unique and duplicate names, `changed_values`); the reviewer pointed
   out that `Catalog` already names `Records::Catalog` and library catalogs. Snapshots read per
   kind (`Snapshot.types`, `.products`, `.materials`, `.assemblies`), and record and inventory
   registrations are declared per kind. The Materials category param's dropped enum is named
   (`Materials::Schema::LABELLED_FIELDS`, `Shapes.create(kind, labelled:)`) instead of a kind check.
   Products declare each field in one call with a named unit and bounds (`Products.number`,
   `.text`, `.color`); `Products.number_keys` answers which fields are thermal inputs. Each grid
   gesture is a public `GridOperations` function that returns detached values. Its registration
   names it through `Gesture#change`, and the string `case` is gone. Library assignment calls the
   frame and glazing functions directly. `Assembly::Schema::MATERIAL_REFERENCE` names the Material
   reference. Abbreviated locals are spelled out in `library/install.rb`, `types/thermal.rb` and
   `types/grid_operations.rb`. The Psi-Install products hash uses one key, `psi_install_types`, in
   thermal, snapshot, export and assessment inputs.
2. **One schema builder.** `core/schema_shapes.rb` (`SchemaShapes`: `object`, `list`, `with`,
   `described`, `id`) replaces six copies. Zones, Assemblies, Windows and Library `Shapes` and
   `Schemas` modules extend it. `AuthoringFields.object` and its `required:` variant are gone.
   `SchemaShapes` uses `extend self` so an extending module gets public methods.
3. **Item 6, one `find` refusal.** `Engine#find` takes an optional `change_set:`.
   `ProjectedEngine#find` reads through it, so a missing or staged-deleted record refuses
   `target.not_found` and a failing one `record.unreadable`. Recorded in `context/CONTRACTS.md`,
   "Callback write ownership".
4. **Item 7, the factory receives the registry.** `State` calls each provider factory with the
   published registry; `library/install.rb` no longer reads `Registry.current`. Recorded in
   `context/EXTENSIBILITY.md`, `context/TECH_STACK.md`, the declaration comment and
   `docs/LIBRARY_PROVIDER_EXAMPLE.md`. A lambda factory must take that argument.

`docs/API_REFERENCE.md`: every schema block is semantically identical to `main` (compared as
parsed JSON). Key order changed where Library's builder ordered keys differently, and parameterless
Zones schemas gained `"required": []`. One description changed: product duplicates no longer claim
to give new element ids, since products have no elements.

Tests: no assertion changes; setups and call sites changed: `window_records_domain_test.rb` and
`window_unit_flip_step_test.rb` call the named gesture functions; `window_export_test.rb` and the
thermal-proof fixture helper key products by `psi_install_types` (the fixture file itself is
unchanged); `window_library_kinds_test.rb` reads `Products.number_keys` and `KINDS` instead of
`SPECS`. New: a library callback's `find` of a missing and of a staged-deleted record refuses
`target.not_found` (fails on `main` with `reference.invalid`).

Verification greps: no `== MATERIAL_KIND` or `== "types"` under `features/`; no `Registry.current`
under `library/`.

Review: one Sonnet pass with the architecture rubric. Taken: the `Definitions` rename, stale
`TECH_STACK` and declaration comments, the `EXTENSIBILITY` example, the CONTRACTS line, the
lambda-arity note, a strict labelled-field lookup, a realigned call and a renamed block param. Not
taken: a uniform `(record, values, identity)` signature for every gesture, which trades twelve
adapter lambdas for unused params in every gesture and test. The two identical allocators
(`Windows::Definitions.allocator`, `Assemblies::Definitions.identity_allocator`) stay per feature,
as item 1 allows; see Follow-ups.

Gates: `make ci` passed on Ruby 3.2.2 and 2.7.2 (1371 Ruby runs, 172 Python, rubocop clean).

No host gate is named for this finding. No panel or Python asset changed, so the runtime manifest
was not refreshed.

## Follow-ups

Recorded 2026-10-02 where each one will be worked:

- One deterministic id allocator in core: [R11](R11-readability-and-lint.md) item 15.
- Remove the `Assemblies::SchemaFields` alias: [R11](R11-readability-and-lint.md) item 16.
- Item 8, `refuses:` on operations, optional: the unscheduled packet
  [operation-refusal-codes](../operation-refusal-codes/README.md).
