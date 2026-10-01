# P2-15: Frame, Glazing and Psi-Install library kinds

DATE: 2026-09-30
STATUS: Scoped. Not authorized.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## Entry and scope

Requires P2-11 and P2-08. Owns three more kind adapters on the seam from P2-07. The measure of
success is what does not change: no file under `library/` and no file in the sidebar's shared
modules is edited to add a kind.

Behavior owner: [libraries PRD](../libraries/PRD.md), Q2 and "The two contracts". The
predecessor's detail is in
`../ph-navigator-sketchup/planning/archive/window-types/phases/phase-8f-frame-glazing-libraries.md`.

Predecessor paths are relative to `../ph-navigator-sketchup/src/ph_navigator_sketchup/` at
`f358ebf`.

## Steps

1. **Three adapters.** `features/windows/library_kinds.rb`: Frame, Glazing and Psi-Install Type,
   each with its wire fields in SI with units in the key names, wire schema version, mapping,
   fingerprint, In this file projection, reverse mapping and the callbacks onto the P2-10
   actions. Adapt `features/organization_library/kinds/window_products.rb` and
   `features/windows/model/constituent_library.rb`. The Psi-Install Type adapter is new.
2. **Assign callbacks.** Frame assigns to one side of one element; Glazing to one element;
   Psi-Install Type to a perimeter edge or as the model default. Copy plus assign is one Undo
   step.
3. **Sidebar.** Register the three panel adapters. Frames and Glazings group by manufacturer.
   The sidebar appears beside the Builder's element cards and beside each Library subtab. The
   aggregate line reads "units", not "placements".
4. **Format page.** Add the three kinds' wire fields to `docs/LIBRARY_FILE_FORMAT.md` and to the
   synthetic library file fixture. Add a few generic rows to the starter library only if they
   meet its public-source rule.
5. **Export model library.** The three kinds join the export through their reverse mappings.

## Source

| Predecessor file | Lines | Disposition |
| --- | --- | --- |
| `features/organization_library/kinds/window_products.rb` | 190 | Split as P2-07 split Materials |
| `features/windows/model/constituent_library.rb` | 115 | Adapt into the callbacks |
| `tests/windows/model/window_library_import_test.rb`, `tests/fixtures/input/library/{frame-types,glazing-types}-catalog_fixture.json` | about 240 | Port, rewriting fixtures to the neutral format |

## Tests (write first)

1. Each adapter's map, fingerprint, In this file projection and reverse mapping.
2. The shared copy cases from P2-07 run unchanged against each new kind.
3. Copy plus assign rolls back together for each assignment target.
4. A diff check in the stage's evidence: no file under `library/` changed.

## Host gate

Fresh process: copy a Frame and a Glazing from a library file by drag onto an element card, set
a Psi-Install Type from the sidebar in an Installs session, Undo each once, export the Model's
library with all four kinds and read it back.

## Out of scope

Window Type, Assembly and equipment libraries. The connection.

## Done when

- E15 has evidence in `evidence/p2-15-window-library-kinds.md`.
- The libraries packet STATUS records 2.4 as delivered.
- The D2-8 decision point is reached: check whether the PH-Navigator endpoint serves the neutral
  envelope, and record in the packet STATUS whether P2-16 runs now or moves to Phase 5.
