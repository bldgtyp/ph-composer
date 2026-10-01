# P2-10: window product and Window Type records

DATE: 2026-09-30
STATUS: In progress. Authorized 2026-10-01; preceding stage gates remain required.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/14

## Entry and scope

Requires P2-01 and D2-4. Independent of the assemblies stages and of Zones' behavior. Owns the `ph_composer.windows`
feature without any screen and without a placed unit: the four record kinds, the grid
operations, the display thermal values, the Installs commit, the model defaults and the
registered operations.

Behavior owner: [window-types PRD](../window-types/PRD.md), sections Records, "Carried over
unchanged" and the definition half of Validation rows. Names: [CONTRACTS](../CONTRACTS.md)
sections 2, 3 and 5.

Paths are relative to `src/ph_composer/`. Predecessor paths are relative to
`../ph-navigator-sketchup/src/ph_navigator_sketchup/` at `f358ebf`.

## Steps

1. **Feature skeleton.** `features/windows/install.rb`, `requires: ["ph_composer.zones"]`, added
   to `FEATURES` after `Zones`. The requirement exists for the unit and placement in P2-12.
   Everything in this stage is the definitions layer (D2-1): put it under `products/` and
   `types/`, and add a dependency-direction test that fails if a file in those folders names
   `Zones` or a Face. The predecessor's `tests/windows/window_dependency_direction_test.rb` is
   the model.
2. **Settings primitive (G4).** Promote the single-value-on-the-Model pattern of
   `features/zones/faces/settings.rb` to `core/`: a schema, defaults, read, and a proposal step
   and scope. Move the Zones settings onto it with its stored dictionary name and value
   unchanged, so a saved Model still reads. Then register the windows settings
   (`default_psi_install_id`, `default_install_depth_m`) on it.
3. **Product kinds.** Frame, Glazing and Psi-Install Type as `RecordKind`s per CONTRACTS, adapted
   from `features/windows/model/constituents.rb`. "Frame segment" is Frame everywhere. A Frame
   never carries a psi-install. Guarded delete with replacement rewrites every Window Type
   element naming the record in one proposal; port `model/library_guards.rb`.
4. **Window Type kind.** Adapt `model/types.rb`: `rows_m`, `columns_m`, `elements` with `wel_`
   ids, spans, `kind` glazed or empty, `glazing_id`, four `frames`, four `installs`, `operation`,
   and `install_depth_m`, absent meaning the model default. Drop `preview_id` and the adoption
   source kind.
5. **Grid operations.** Port `model/operations.rb`, `model/grid.rb`, `model/edge_resolution.rb`
   and `model/graph.rb` as pure functions: insert and delete band, merge, split, Empty, Flip,
   edge classification, and which Psi-Install Type applies to an edge (painted, model default,
   or derived zero on a shared internal edge).
6. **Thermal display values.** Port `model/thermal.rb`: per element and per type, U-w without
   installation and the installed value beside it. An incomplete element is reported as
   incomplete and never counted as zero.
7. **Installs.** The staged session lives in the panel. Port the pure parts of
   `reviews/install_draft.rb` (Apply to all edges, Copy to other Window Types) as functions and
   register `types.installs.save` as one action for the whole session.
8. **Operations.** Register the queries, sections and actions of CONTRACTS section 3 for
   products, types, grid and settings. `types.update` in this stage changes the record only; the
   definition rewrite joins it in P2-12.
9. **Walkthrough and reference.** `tools/examples/authoring/windows_walkthrough.rb`: panel
   closed, create a Glazing, Frames and a Psi-Install Type, build a two-element type, paint
   installs, read the thermal block. Regenerate the API reference.

## Source

| Predecessor file | Lines | Disposition |
| --- | --- | --- |
| `features/windows/model/{types,constituents}.rb` | 462 | Adapt to `RecordKind` |
| `features/windows/model/{operations,grid,edge_resolution,graph,thermal,anchors,library_guards}.rb` | 548 | Port |
| `features/windows/reviews/{install_draft,install_review}.rb` | 416 | Port the pure parts; the session moves to the panel |
| `features/windows/registration.rb`, `snapshot.rb`, `model/library_snapshot.rb` | 127 | Replace with declarations |
| `features/windows/model/constituent_library.rb` | 115 | Wait for P2-15 |
| `tests/windows/model/*_test.rb`, `tests/support/window_product_fixture.rb`, `tests/fixtures/input/windows/thermal-proof.json` | about 760 | Port |

## Tests (write first)

1. Schema round trips for the four kinds; every dangling product reference is reported.
2. Grid operations against the predecessor's characterization cases.
3. Thermal: the proof fixture produces the predecessor's asserted values
   (`tests/windows/model/window_types_test.rb`); a missing input reports incomplete.
4. Edge resolution: painted, inherited default, derived zero, and no install with no default.
5. Product delete with replacement rewrites every use in one proposal and rolls back whole.
6. Zones settings read unchanged from a Model saved before the primitive moved.
7. `user_data` survives edit and Duplicate type. Stale `expected_values` refuses.
8. Every operation has schemas and a validating example; the walkthrough runs as written, in a
   Model with no Zone.
9. The dependency-direction test for `products/` and `types/`.

## Host gate

Fresh process, panel closed: run the walkthrough, native Undo and Redo, save, reopen, read back.
Open a Model saved by the current `main` build and confirm its Zone settings are intact.

## Out of scope

Any screen (P2-11). The unit, the definition, placement (P2-12). Export (P2-14). Library import
of the three kinds (P2-15).

## Done when

- E10 has evidence in `evidence/p2-10-window-records.md`.
- `context/CONTRACTS.md` describes the settings primitive. `make ci` passes on both Rubies.
