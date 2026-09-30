# Phase 02: envelope ownership, entity descriptors and core references

DATE: 2026-09-30
STATUS: Blocked
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)
MERGE SET: Yes
BLOCKED ON: [R-D1](../DECISIONS.md#r-d1-authored-envelope-ownership); Phase 01a landed

## Scope

Give the coupled Zone/Face/adjacency lifecycle one owner, declare entity schemas and references
once, and remove feature policy from shared export. Read
[ARCHITECTURE.md](../review/ARCHITECTURE.md#resolve-authored-envelope-ownership-before-more-features-depend-on-it)
and [Declare schema and references once](../review/ARCHITECTURE.md#declare-schema-and-references-once)
before starting. This plan assumes R-D1 option A; if Ed picks B or C, rewrite steps 1 and 2
before starting.

| ID | Outcome |
| --- | --- |
| OWN | One registered envelope feature with Zone, Face and adjacency submodules. Registry dependency graph is truthful and acyclic. No module reaches into another feature's private store |
| DESC | A shared descriptive contract for entity values, identity, occurrence references and outgoing core references, composed with entity-owned inventory. Engine gains no authority to create or delete geometry |
| M3b | The generic incoming-reference scan reads core references from entity descriptors, so catalog deletion and entity deletion enforce the same invariant without feature branches |
| SNAP | `GeometrySnapshot#zone_owner` moves to the envelope feature's snapshot projection; the snapshot keeps only generic record, occurrence and path-prefix reads. See [review](../review/PIPELINE-UI-REVIEW.md#p2-the-shared-export-snapshot-owns-zone-policy) |
| CAT | `SplitAndPairStep` receives its catalog/reference guard from the prepared operation instead of `Registry.current.catalog` |

## Steps

1. **Descriptor contract first.** Add the entity descriptor type beside `core/records/reference_target.rb`.
   Fields: values schema, schema version, identity field, occurrence-reference schema, declared
   outgoing core references. Typed occurrence keys internally; plain JSON at the public boundary.
   Tests with a synthetic entity kind, no Zones code.
2. **Core-reference scan (M3b).** Extend `core/records/reference_resolution.rb` / `engine.rb` to
   read declared core references from entity descriptors as it already does for catalog kinds.
   Test: a synthetic entity with a core reference blocks catalog deletion; readable extension
   references still block.
3. **Create the envelope feature** under `src/ph_composer/features/<name>/` with `zones/`,
   `faces/` and `adjacency/` submodules. Move files; keep pure geometry and pure pair
   validation separate from SketchUp write steps. Split each old `install.rb` into declarations
   (registration, descriptors, schemas) and operation handlers. One readable entrypoint.
4. **Register descriptors** for Zone, Face and Attached zone. `attached_zone_id` becomes a
   declared core reference; the M3a feature-level refusal from 01a stays as the user-facing
   check, M3b as the backstop.
5. **Rename action IDs** coherently if the feature prefix changes. Update examples, fixtures,
   hostkit walkthroughs, panel callers and `extension.rb` in the same commit. No aliases.
6. **Move `zone_owner`** into the envelope export projection (SNAP). Keep export orchestration
   free of feature names.
7. **Inject the catalog guard** into `SplitAndPairStep` (CAT). Targeted test: an alternate
   registered catalog with an incoming extension reference refuses after a no-survivor cut.
8. **Remove** any now-empty modules or re-exports this move leaves behind.

## Source

`src/ph_composer/features/zones/**`, `src/ph_composer/features/face_assignment/**`,
`src/ph_composer/core/records/{reference_target,reference_resolution,engine}.rb`,
`src/ph_composer/export/geometry_snapshot.rb`, `src/ph_composer/extension.rb`, the panel callers
under `src/ph_composer/html/`, and every test, fixture and hostkit script naming the moved actions.

## Tests

- All 01a regression tests pass unchanged in intent after the move.
- New: descriptor contract (synthetic kind), M3b catalog-delete refusal via entity core
  reference, CAT alternate-catalog refusal, registry graph has no reciprocal edge.
- Two-Zone extraction golden unchanged. Nested and wrong-Zone refusals, shared occurrences.
- An outside contributor test uses only the neutral snapshot interface.

## Out of scope

Public schema/example publication (Phase 03, built on these descriptors). Responsibility
refactors inside moved methods (Phase 08). The move is a move, plus the named corrections.

## Ledger screen

Most Zones/Faces/export cases will flag (expect A01, A02, A04 to A07, A10, A11). The catalog
fingerprints change with the paths: update `cases.json` dependency patterns to the new folder in
this phase so the screen stays meaningful.

## Done when

- Registry discovery shows the envelope feature with no undeclared dependency.
- `grep` finds no reference to another feature's private store constant outside the owner.
- Shared export code names no feature.
- Focused suites and the extraction golden pass on both Rubies.
- `context/EXTENSIBILITY.md` and `context/TECH_STACK.md` describe the envelope owner and the
  entity descriptor contract.
- The feature name is a new domain term: add it to `context/UBIQUITOUS_LANGUAGE.md` via the
  `ubiquitous-language` skill (externally readable; client-facing register, no dashes). Zone and
  Face remain product concepts with their existing entries.
- `features/zones-and-adjacency/` and `features/face-assignment/` stay as product packets (they
  own behavior, not code layout); each gains one line naming the shared code owner.
- STATUS rows OWN, DESC, M3b, SNAP, CAT set to `Implemented on branch`.

## Result

(Fill on completion.)
