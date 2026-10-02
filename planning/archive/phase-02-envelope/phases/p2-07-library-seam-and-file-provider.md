# P2-07: library seam and the library file provider

DATE: 2026-09-30
STATUS: Implemented on branch; named acceptance passes with qualified retained evidence; Phase 2 integration remains open.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/14

## Entry and scope

Requires P2-02. Owns the library provider seam without any screen: the two contracts, their
registration, the library file provider, the Materials kind adapter, the catalog, the resolver
and the copy coordinator. When it closes, a script with the panel closed lists a library file,
previews a copy, applies it and reads the record back.

Behavior owner: [libraries PRD](../../libraries/PRD.md), sections "The two contracts",
"Registration and mutation ownership", "The library file" and "Copy, reuse and replacement
rules". Names: [CONTRACTS](../CONTRACTS.md) sections 1, 3 and 5.

Paths are relative to `src/ph_composer/`. Predecessor paths are relative to
`../ph-navigator-sketchup/src/ph_navigator_sketchup/` at `f358ebf`.

## Steps

1. **Registrations.** Add `FeatureScope#library_provider` and `#library_kind` with their
   declarations and validation: stable id, contract version, kinds served, duplicate ids, a kind
   adapter whose record kind is not registered, an unsupported contract major. Each failure is a
   `registration.*` diagnostic and refuses the batch. Nothing in `shell/` names a provider or a
   kind. Register the seam itself as `ph_composer.library` in `FOUNDATION_FEATURES`.
2. **Provider contract.** `library/provider.rb`: `id` (the configured-provider id, never a path),
   `provider_kind` (a stable registered identifier), `label`, `kinds`, `list(kind)` returning
   every field of every row, and `freshness`. A provider returns immutable catalog values and
   never reads or writes a Model dictionary.
3. **Kind adapter contract.** `library/kind_adapter.rb`: the wire field list with types and SI
   units in the key names, the supported wire schema version, a pure `map(row)`, a `fingerprint`
   with a declared version, the In this file projection, the reverse mapping P2-09 uses, and the
   owning feature's `create`, `replace` and `assign` callbacks, which add steps to the
   coordinator's proposal. The adapter never learns which provider a row came from.
4. **Envelope reader.** `library/library_file.rb`, adapted from
   `features/organization_library/catalog_file.rb`, reading the PRD's envelope
   (`format: "ph-composer.library"`, `schema_version` 1, `kind_schema_versions`, `library`,
   `exported_at`, `kinds`). Envelope validation precedes row normalization. Give each of these a
   distinct outcome: unsupported envelope version, unknown kind, unsupported kind version,
   malformed required field, absent optional field, a value in IP or without a unit, duplicate
   record ids within one library and kind. A row with a bad required field is skipped with a
   structured warning and never becomes a usable record with a null.
5. **File and folder provider.** One file, or every immediate JSON file of a folder. Duplicate
   record ids are checked across the folder's files and refuse that library and kind. Different
   library ids keep separate provenance. Limits: 32 MB per file as the PRD states; propose
   64 MB and 20,000 rows aggregate per provider, confirm both with a measurement on the host, and
   test the exact limit and one above. An over-budget catalog is refused, never truncated.
6. **Catalog.** `library/catalog.rb`, adapted from `store.rb`, keyed by provider and kind. A new
   immutable generation is published only after validation. A failed refresh keeps the last valid
   generation with its age and failure state. An empty successful result is distinct from a
   failure. Session memory only; nothing is cached to disk.
7. **Setup store.** `library/setup.rb`: configured providers per machine, in SketchUp defaults
   under the library's own key as one base64 JSON value (the reason is in
   `context/TECH_STACK.md`, "Display units"). Each configuration has its own id. The path lives
   here and nowhere else: never in the SKP, a snapshot, a log, an outcome or an export.
8. **Resolver.** `library/resolver.rb`, pure: exact source identity first (zero, one, or
   ambiguous), then the same-name rule (create, reuse on equal mapped values, review on
   different values, explicit resolution on several matches). The In this file projection uses
   the same resolver.
9. **Copy coordinator.** The `copy` action. Preview returns the resolver outcome with structured
   candidates and differences and writes nothing. Invoke takes the explicit choice, the catalog
   generation, an optional assignment target and `expected_values`, rechecks the generation and
   the session revision, and calls the adapter's callbacks inside one proposal. Copy plus assign
   is atomic. Use library copy replaces only the reviewed mapped fields, keeps the local id,
   references, `user_data` and extension payloads, and updates the attribution. No transaction is
   open during a read or a review.
10. **Materials adapter.** `features/assemblies/library_kind.rb`, adapted from
    `features/organization_library/kinds/materials.rb`: the mapping, the fingerprint (SHA-256 of
    the canonical JSON of the mapped semantic fields in declared order, version 1), the unknown
    category fallback to Uncategorized with the original kept in the snapshot, and the callbacks
    onto `materials.create`, `materials.update` and `segments.set_material`.
11. **Attribution.** Write the `source` object of CONTRACTS section 2. Add one Export report line
    per copied record naming the provider and record id, through the owning feature's report
    declaration.
12. **Contract tests and walkthrough.** A reusable provider contract test module under
    `tests/support/` that the file provider passes and P2-09's outside provider reuses. A
    panel-closed walkthrough under `tools/examples/`.
13. **Format page.** `docs/LIBRARY_FILE_FORMAT.md`: the envelope, the Materials wire fields with
    units, the thirteen category ids, versioning and limits. Client-facing register, no dashes.
    Fold the seam's durable rules into `context/TECH_STACK.md`, "The library provider seam", and
    `context/EXTENSIBILITY.md`.

## Source

| Predecessor file | Lines | Disposition |
| --- | --- | --- |
| `features/organization_library/catalog_file.rb` | 166 | Adapt to the neutral envelope |
| `features/organization_library/store.rb`, `organization_library.rb` | 181 | Adapt: keyed by provider and kind |
| `features/organization_library/kinds/{kinds,materials}.rb` | 138 | Split: mapping stays an adapter; provider name, library id, URL path and file kind leave it |
| The import parts of `features/assemblies/commands/material.rb` | part of 191 | Adapt into the adapter callbacks |
| `tests/catalog_file_test.rb`, `library_kinds_test.rb`, `organization_library_{store,actions,snapshot}_test.rb`, `material_import_test.rb`, `fixtures/input/library/materials-catalog_fixture.json` | about 790 | Port, rewriting the fixture to the neutral format |

## Tests (write first)

1. Registration diagnostics for each failure in step 1.
2. The provider contract module against a synthetic multi-kind file and a folder.
3. Every distinct envelope and row outcome in step 4, and both limits in step 5.
4. Catalog generations: failed refresh keeps the old one; empty is not failure; a copy cannot
   mix generations.
5. Resolver: each outcome, including two local records claiming one source identity after a
   duplicate and a rename, and two libraries sharing a record id.
6. Copy: create, reuse, review with each of three answers, ambiguity; copy plus assign rolls
   back together under an injected assignment failure; replacement keeps id, references,
   `user_data` and an unavailable extension payload.
7. Stale revision, wrong session, stale generation and a duplicate retry each refuse or return
   the retained outcome without a second copy.
8. A synthetic row carrying a path, an address and a token-shaped value: none reaches the record,
   the snapshot, an outcome or a log.

## Host gate

Fresh process, panel closed, through the bridge: configure a synthetic library file, list, preview,
apply with and without assignment, Undo, Redo, save, reopen on a profile with no provider
configured and edit the copy.

## Out of scope

Every screen and native dialog (P2-08). Library file export (P2-09). Frames, Glazings and
Psi-Install Types (P2-15). The connection (P2-16).

## Done when

- E07 has evidence in `evidence/p2-07-library-seam.md`.
- Adding the Materials adapter changed no file under `library/` after the contracts landed.
- `make ci` passes on both Rubies; the generated API reference is current.

Current consolidation and provenance: [P2-17](../evidence/p2-17-acceptance.md#register-consolidation-at-f4f6576).
