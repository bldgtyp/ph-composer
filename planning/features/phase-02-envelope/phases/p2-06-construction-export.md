# P2-06: construction export

DATE: 2026-09-30
STATUS: Scoped. Authorized 2026-10-01; preceding stage gates remain required.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/14

## Entry and scope

Requires P2-05. Owns the first real export: the assemblies contributor, the Python constructions
section, the Face to construction join, the rewritten Face preflight rows and the report. It
retires the tools-only construction provider. When it closes, the normal packaged build exports
the reference model, which is milestone M1.

Behavior owners: [assemblies PRD](../assemblies/PRD.md), "Export mapping" and "Validation rows";
[face-assignment PRD](../face-assignment/PRD.md), the assembly matrix under "Export mapping";
[validation-and-export PRD](../../cross-phase/validation-and-export/PRD.md). Names:
[CONTRACTS](../CONTRACTS.md) section 6.

Paths are relative to `src/ph_composer/`. Predecessor paths are relative to
`../ph-navigator-sketchup/src/ph_navigator_sketchup/` at `f358ebf`.

## Steps

1. **Contract fixture first.** Write `tests/fixtures/assemblies/` with one extraction section and
   its expected result, read by both the Ruby and the Python tests, covering the cases in Tests.
2. **Ruby contributor.** `features/assemblies/export.rb`: `export_contributor` for
   `ph_composer.assemblies.export.constructions`, section version 1, with
   `user_data_keys: ["ph_composer.assembly_id", "ph_composer.membrane_layers"]`. The block reads
   Materials and Assemblies through `Export::RecordReader` and projects only exported fields.
   `air_barrier`, `photo_collections`, `ventilated_cladding`, the hints and the records' own
   `user_data` stay out. Adapt from `features/assemblies/export_contract.rb`.
3. **Assemblies preflight.** A registered query returning `Export::PREFLIGHT_RESULT`. Assemblies
   knows nothing about assignment, so its rows describe records only and none of them blocks on
   use: Assembly incomplete, Material incomplete and membrane in a mixed Layer are non-blocking
   here; missing density or specific heat is a non-blocking row that names the default; an
   unreadable record blocks.
4. **Face preflight.** In `features/zones/faces/export.rb` replace the unconditional
   `construction.missing` and `construction.unavailable` rows. Zones requires assemblies, so it
   asks the registered Assembly read whether each named Assembly is complete. An emitted bounded
   Face with no `assembly_id` blocks; an `assembly_id` that does not resolve blocks as its own
   code; a Face naming an incomplete Assembly blocks, with a `locate` to the Face and the
   Assembly's own reason. That is how an assigned incomplete Assembly blocks export while an
   unused one does not. A Face
   omitted under the adjacency rules adds no block for a missing Assembly alone. Remove the
   "scheduled for the next phase" text.
5. **Python records.** Typed records for Material, Assembly, Layer and Layer-Segment in
   `python/ph_composer_translation/contract/`. Adapt `contract/sections/assemblies.py` and
   `assembly_records.py`. Drop the push records.
6. **Python builder.** A constructions package that returns constructions keyed by Assembly id,
   following the PRD's Export mapping table row by row. Adapt `phn_assemblies/layered.py`,
   `values.py`, `context.py` and `resolve.py`. Drop `declared.py` and the designPH tiers under
   `constructions/`. Do not port `phn_assemblies/thermal.py`: the PRD exports layers and claims
   no number. honeybee and honeybee-ph are imported only through `stack.load`.
7. **Section and join.** Add the constructions `Section` to `composition.py`. In
   `model_sections.py` remove `ConstructionProvider` and the constructor argument from
   `ZoneSection`, declare the constructions `Requirement`, and assign each Face's construction
   from `inputs`. A Face whose Assembly did not build gets `dependency.unavailable` and no
   substitute. Faces naming one Assembly share one construction object.
8. **Retire the development provider.** Remove `DevelopmentConstructionProvider` from
   `tools/examples/phase_one/` and the inlined copy in `tools/runtime/browser_check.py`. Move
   `make phase-one-proof` and the browser check onto a fixture with authored Assemblies.
   Regenerate `tests/fixtures/phase_one/` through its owning test. The contract changed, which is
   the reason the golden changes; record that in the commit.
9. **Report.** Declare result fields and render the assemblies section: constructions written,
   envelope area per Assembly, and once per Model the fields that are local and not exported, the
   honeybee defaults written for roughness and absorptance, and any default density or specific
   heat. Add per-record source attribution lines here only if P2-07 has landed; otherwise P2-07
   adds them.
10. **Runtime.** Run the real translation in the HtmlDialog runtime and the pinned native
    comparison. Confirm no new wheel is needed. Refresh the vendor manifest and record the
    installed footprint.
11. **Docs.** Update `context/TECH_STACK.md`, "Pyodide and Export boundary", where it says the
    shipping composition has no authored construction provider. Update `docs/PRODUCT.md`.

## Source

| Predecessor file | Lines | Disposition |
| --- | --- | --- |
| `features/assemblies/export_contract.rb`, `export_report.rb` | 178 | Adapt. Drop push, difference and packed sections |
| `python/ph_navigator_translation/phn_assemblies/{layered,values,context,resolve}.py` | 415 | Adapt per Q21 and Q22 |
| `python/ph_navigator_translation/contract/sections/{assemblies,assembly_records}.py` | 354 | Adapt |
| `phn_assemblies/declared.py`, `thermal.py`, `constructions/` | 664 | Drop |
| `tests/assemblies_export_contract_test.rb`, `tests/python/test_phn_assemblies.py` | 873 | Port the layered cases |

Reference method for mixed and steel stud layers:
`../ph-navigator-v2/backend/features/gh_api/constructions_export.py`.

## Tests (write first)

Against the shared fixture, loading the produced HBJSON in honeybee and reading it back:

1. A single Layer-Segment Layer is one `EnergyMaterial` with the Layer's thickness.
2. A mixed Layer is one host material with a one-row division grid, one column per
   Layer-Segment, host conductivity equal to the grid's equivalent conductivity, density and
   specific heat from the base material.
3. A steel stud Layer carries the one spacing on its grid.
4. A membrane between two thermal Layers is absent from the material list and present in the
   `ph_composer` block with its `outside_index`; an all-membrane Assembly builds nothing.
5. One Material at two thicknesses is two materials with distinct identifiers; a stud, cavity,
   stud, cavity Layer keeps one identifier per column.
6. `orientation` reverses the written order.
7. Two Faces sharing an Assembly share one construction; a Face naming an absent id gets its
   finding and the rest translates; an unused Assembly is not in the HBJSON.
8. Missing density and specific heat export 600 kg/m3 and 1000 J/kgK with a non-blocking finding.
9. The metadata guard passes with the two declared keys and refuses a third.
10. Preflight per step 3 and step 4: an incomplete Assembly blocks only through a Face that names
    it, and the omitted-Face exception holds.
11. The packaged-build check shows no development provider in the RBZ or the composition.

## Host gate

Fresh process, the installed normal RBZ, the reference model: preflight shows the blocking rows
with working Locate; assign and repair until clean; export; reload the exact HBJSON in the pinned
native stack and reconcile identifiers, constructions, areas and the report. Repeat the Phase 1
export cases the ledger screens (A10 to A14, A16).

## Out of scope

METr and every "Through PHX" check. Apertures (P2-14). The SD assembly helper and its warning.

## Done when

- E06 has evidence in `evidence/p2-06-construction-export.md`. Phase 1's A11 note is superseded:
  the normal build exports and no synthetic provider exists.
- The validation-and-export packet records the change. `make ci` passes on both Rubies with the
  manifest fresh and the footprint inside budget.
