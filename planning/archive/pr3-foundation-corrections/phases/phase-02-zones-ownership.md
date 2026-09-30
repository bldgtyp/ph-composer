# Phase 02: `zones` ownership, entity descriptors and internal refactors

DATE: 2026-09-30
STATUS: Merged to main (abd86f4, PR #3)
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/4
MERGE SET: Yes

## Scope

One feature, `zones`, owns the Zone, Face and adjacency lifecycle; entity schemas and references
are declared once; shared export holds no Zone policy; and the `zones` code merges in its final
shape. Decisions: [R-D1](../DECISIONS.md#r-d1-authored-geometry-ownership) (one owner, cleanest
final state over smallest diff), [R-D8](../DECISIONS.md#r-d8-the-owning-feature-is-zones) (name),
[R-D9](../DECISIONS.md#r-d9-phase-order-under-cleanest-final-state) (refactors folded in here).
Read [ARCHITECTURE.md, ownership](../review/ARCHITECTURE.md#resolve-authored-envelope-ownership-before-more-features-depend-on-it),
[schema and references](../review/ARCHITECTURE.md#declare-schema-and-references-once) and
[refactor table](../review/ARCHITECTURE.md#refactor-responsibilities-where-the-measurements-support-it)
first, and load the architecture-review skill.

| ID | Outcome |
| --- | --- |
| OWN | `features/zones/` owns Zones, Faces and adjacency. `features/face_assignment/` no longer exists. The registry dependency graph is truthful and acyclic, and no other feature reaches a `zones` private store |
| DESC | A shared descriptive contract for entity values, identity, occurrence references and outgoing core references, composed with entity-owned inventory. The engine gains no authority to create or delete geometry |
| M3b | The generic incoming-reference scan reads core references from entity descriptors, so catalog and entity deletion enforce one invariant without feature branches |
| SNAP | `GeometrySnapshot#zone_owner` moves into the `zones` export projection; the shared snapshot keeps only generic record, occurrence and path-prefix reads. See [review](../review/PIPELINE-UI-REVIEW.md#p2-the-shared-export-snapshot-owns-zone-policy) |
| CAT | `SplitAndPairStep` receives its catalog/reference guard from the prepared operation instead of `Registry.current.catalog` |
| REF-Z | The `zones`-internal refactors listed in step 7 |
| RP | The unused `revision` parameter on `Repair.restore_plan` and its callers are removed |

Cleanest final state is the goal, not the smallest diff. Behavior is preserved except where a
finding says otherwise; the 01a tests and the existing suites are the net.

## Target layout

A starting proposal, to be confirmed against the architecture rubric before moving files:

```
features/zones/
  install.rb            # readable entrypoint: registers declarations and handlers
  declarations/         # descriptors, schemas, action and reference-target registrations
  zone/                 # Zone schema, occurrences, index, make/update steps, repair, split identity
  faces/                # Face and Attached-zone schema, classify/reverse steps, suggestions,
                        # Classify tool, menu, Locate, reference targets
  adjacency/            # pure overlap and pair validity, face split, native split/pair steps
  export.rb             # Zone and Face projections, including zone ownership (SNAP)
  colour_modes.rb       # Zone, face type and boundary condition modes
```

Pure geometry and pure pair validation stay separate from SketchUp write steps. Action IDs:
Zone actions keep `ph_composer.zones.*`. Every `ph_composer.face_assignment.*` ID (classify,
reverse, auto_classify, list, locate, palette, choose, classify_tool, stop_classifying,
attached_zone.*, export.faces and any others registered) becomes `ph_composer.zones.faces.*`.
The existing adjacency actions (`solve_adjacency`, `retire_adjacency`, `retire_pairs`) keep
their IDs unless `ph_composer.zones.adjacency.*` reads clearly better once the layout is in
place; decide once and record it in **Result**. Panel section IDs follow the same rule.

## Steps

1. **Descriptor contract.** Add the entity descriptor beside `core/records/reference_target.rb`:
   values schema, schema version, identity field, occurrence-reference schema, declared outgoing
   core references. Typed occurrence keys internally; plain JSON at the public boundary. Test with
   a synthetic entity kind and no Zones code.
2. **Core-reference scan (M3b).** Extend `core/records/reference_resolution.rb` and `engine.rb` to
   read declared core references from entity descriptors, as for catalog kinds. Test: a synthetic
   entity core reference blocks catalog deletion; readable extension references still block.
3. **Move into `zones`.** Move `face_assignment/*` and the adjacency files into the layout above.
   Split both old `install.rb` files into declarations and handlers.
4. **Register descriptors** for Zone, Face and Attached zone. `attached_zone_id` is a declared
   core reference. 01a's refusal (R-D11) stays as the user-facing check, M3b as the backstop.
5. **Rename Face action IDs** in one commit with every caller: panel modules under `html/`,
   `extension.rb`, examples, fixtures, hostkit walkthroughs and tests. No aliases.
6. **SNAP and CAT.** Move `zone_owner`; inject the catalog guard into `SplitAndPairStep`. CAT test:
   an alternate registered catalog with an incoming extension reference refuses after a
   no-survivor cut.
7. **Internal refactors (REF-Z).** Each its own commit, behavior-preserving. Skip one only when it
   does not reduce what a reader holds in mind, and record why in **Result**.
   - One reciprocal-pair validity predicate shared by `Adjacency.state`, `current_pair?`,
     snapshot validation and retirement; live resolution stays separate from detached comparison.
   - `PartitionAndPairStep#cut_partition`: native splitting separate from post-cut
     identity/reference projection, one transaction owner.
   - `SplitIdentityRepair.keeper_path`: endpoint proof named separately from explicit keeper
     selection; conservative ambiguity refusal kept.
   - `Overlap.partition`: polygon validation separate from region construction, if it helps.
   - `validate_make_target!` and the retirement helpers if the shared predicate leaves them simpler.
8. **RP** and removal of any module, constant or re-export the move orphans.

## Tests

- 01a regression tests keep their intent after the move (update only IDs and paths).
- New: descriptor contract on a synthetic kind; M3b catalog-delete refusal through an entity core
  reference; CAT alternate-catalog refusal; registry graph test asserting `zones` has no
  undeclared dependency and no feature depends on a removed `face_assignment` ID.
- Two-Zone extraction golden unchanged; nested and wrong-Zone refusals; shared occurrences.
- An outside contributor test uses only the neutral snapshot interface.

## Out of scope

Public schemas and examples (Phase 03, built on these descriptors). Non-`zones` refactors
(Phase 08). Product behavior or UI changes beyond renamed action IDs.

## Ledger screen

Most Zones, Faces and export cases will flag (expect cases A01, A02, A04 to A08, A10, A11).
Update `planning/native-acceptance/cases.json` dependency patterns from `face_assignment/` to the
new paths in this phase, so the screen stays meaningful.

## Done when

- Registry discovery shows `zones` with truthful dependencies; `features/face_assignment/` is gone.
- No reference to a `zones` private store constant outside `features/zones/`.
- Shared export code names no feature.
- Focused suites and the extraction golden pass on both Rubies.
- `context/EXTENSIBILITY.md` and `context/TECH_STACK.md` describe `zones` as the owner of Zones,
  Faces and adjacency, and the entity descriptor contract. No new glossary term (R-D8).
- `features/zones-and-adjacency/` and `features/face-assignment/` each gain one line naming
  `features/zones/` as the code owner; both stay product packets.
- STATUS rows OWN, DESC, M3b, SNAP, CAT, REF-Z and RP set to `Implemented on branch`.

## Result

Commits, in order: `907817c` DESC and M3b, `e9c6f87` move only, `4e9e187` one owner and id
rename, `eeac00c` declarations split from handlers, `98fd918` Zone and Face descriptors, `7196475`
SNAP, `020328a` CAT, `ba20aed` `062b308` `d64d2c4` REF-Z, `97cd90a` RP, then the docs commit.

Decisions made here (the phase left them open):

- **Ids.** One prefix substitution, `ph_composer.face_assignment.` to `ph_composer.zones.faces.`,
  for every registered name, including the Face and Attached-zone kinds, the snapshot sections and
  the export section (`ph_composer.zones.faces.export.faces`). A literal rule means any old id maps
  to its new id without a table. The adjacency actions keep `ph_composer.zones.solve_adjacency`,
  `retire_adjacency` and `retire_pairs`: they already sit under the owner, and a third prefix level
  would not read better. Affected rows say `"kind": "face"`, matching `"zone"`.
- **Storage names stay.** `ph_composer.face_assignment` (Face records) and
  `ph_composer.face_assignment.attached_zone` (Attached zones) are persistence, not API. Renaming
  them would orphan every record in existing host fixtures and Phase 1 evidence models; each is
  now a named constant with a comment saying so. Ed can overrule this at the Phase 05 review.
- **Golden.** `two_zones_extraction.json` changes only by its section key and that key's sorted
  position; a semantic comparison with the key renamed is identical.
- **Layout.** As proposed, with `declarations/{zone,faces,adjacency,repair}.rb` and one
  `operations.rb` per part. The Face registration is `Zones::Faces::Registration` so bare constant
  lookups resolve to the Face schema, colour modes and export projection rather than the Zone ones.
- **Descriptor.** `Records::Descriptor` (values schema, identity field, occurrence-reference schema,
  core references). `RecordKind#descriptor` derives one; `ReferenceTarget` takes optional
  `schema_version:`, `values:`, `occurrence:` and `references:`. Occurrence keys stay plain arrays
  internally: no caller confused root and relative paths once the key is always root-relative.
  `FACE_VALUES` is now what the Face validator checks fields against.
- **M3b.** The engine refuses deleting an Attached zone any Face names. `propose_delete` takes a
  `reference_plan`, and the feature's own delete passes its planned reassignment. R-D11's refusal
  stays the user-facing check.

REF-Z taken: the reciprocal-pair rule (`reciprocal?` and `geometry_current?`, shared by `state`,
`current_pair?`, `snapshot_pair_current?` and both retirement checks; `state` cyclomatic 17 to
11); `cut_partition` split into the native cut, region matching, area conservation and identity
projection (cyclomatic 18 to under 7 each); `keeper_path` split from `proved_keeper` (17 to 9
and 8). One deliberate tightening: `retire_records` now applies the full reciprocal rule instead of
pair id plus one counterpart id. REF-Z skipped: `Overlap.partition`, one straight sequence of
guards on one geometric argument that splitting would scatter; `validate_make_target!`, untouched
by the shared predicate.

Tests added: `tests/entity_descriptor_test.rb` (5, synthetic kinds only), a registry refusal for an
unregistered core-reference target, `test_the_engine_refuses_deleting_an_attached_zone_a_face_still_names`,
`test_zones_owns_every_zone_face_and_adjacency_registration` (loader), `tests/geometry_snapshot_test.rb`
(neutral outside-contributor read and a private-store source scan), and
`test_no_survivor_cut_checks_the_dispatching_registrys_catalog`. The 01a tests kept their intent;
only ids and constants changed. Full Ruby suite 628 runs on 2.7.2 and 3.2.2, JS 191, Python 96,
hostkit and fixtures green.

Ledger screen: every case A01 to A16 and R01 to R05 (the `core/*` patterns flag everything).
`cases.json` path patterns moved from `features/face_assignment/*` to `features/zones/faces/*`.
