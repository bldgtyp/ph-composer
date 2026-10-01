# P2-14: aperture export

DATE: 2026-09-30
STATUS: Implemented, independently reviewed and dual-Ruby offline-gated; E14 passes on current host.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/14

## Entry and scope

Requires P2-13, P2-06 and D2-10. Owns the windows contributor, the two Python sections, the
Aperture to Face join, the windows preflight rows, the report and the net opaque area read.
Closing it is milestone M3.

Behavior owner: [window-types PRD](../window-types/PRD.md), "Export mapping" and "Validation
rows", Q23, Q24 and Q26. Names: [CONTRACTS](../CONTRACTS.md) section 6.

Paths are relative to `src/ph_composer/`. Predecessor paths are relative to
`../ph-navigator-sketchup/src/ph_navigator_sketchup/` at `f358ebf`.

## Steps

1. **Contract fixture first.** `tests/fixtures/windows/`: one extraction section and its expected
   result, read by Ruby and Python.
2. **Ruby contributor.** `features/windows/export.rb`: units projected from the export snapshot's
   instance entries and their accumulated transforms, never from a second Model walk. Each glazed
   element becomes one aperture record with its world polygon from the unit's outline, its host
   Face id, its resolved products and its resolved psi-install per side, the model default
   included. The area is computed from the outline. `Face#area` is never read. Adapt
   `export/export_contract.rb`; drop shading provenance.
3. **Host resolution.** The host Face id comes from P2-12's geometric check run on snapshot
   geometry. A unit that is not hosted produces no aperture and one blocking row.
4. **Windows preflight.** A registered query with one row per PRD validation row, each with its
   `locate` and, where the PRD names one, its repair action: placed type incomplete; perimeter
   edge with no install and no default; unhosted; host Face unclassified or not Outdoors; unit on
   a Surface Face; shared id; detached definition; unknown Window Type; size, handedness or
   geometry differs; leaves its host or overlaps; dangling product reference. All block. Frame
   and operation mismatch does not.
5. **Python records and sections.** Typed records in `contract/`. A window constructions section:
   one `WindowConstruction` per distinct combination of glazing, four Frames, four resolved
   installs and translated thermal values (including size-dependent U-w), with `ph_glazing` and `ph_frame`, each frame element carrying its side's
   `psi_install`, and a deterministic identifier from the record ids. An apertures section that
   requires it. Adapt `phn_windows.py` and the contract sections; drop `window_shading.py`.
6. **Join.** `ZoneSection` declares the apertures `Requirement` and adds each aperture to its
   parent `Face` as a sub-face. The parent `Face` is written with its gross polygon.
   `Aperture.properties.ph.install_types` stays empty (Q24). `variant_type` carries the Window
   Type name, `install_depth` the type's or the default, `is_operable` is true for swing and
   slide. Nothing is authored for shading.
7. **g-value 0 and 1.** Write the value the user entered. Name each such construction in the
   Export report, state the deviation in `docs/`, and carry it in local conformance as the one
   documented schema exception (Q23). Never write a nearby number.
8. **Report.** Window Types with their installs by name, units per type and per Zone, the
   statement that PH-Composer sets no shading, and the exception list.
9. **Net opaque area (D2-10, confirmed 2026-09-30).** `units.glazed_area_by_face`: glazed area per host Face reference.
   The Window Schedule and the Export report show net area. The Zones / Faces table and the
   assembly usage keep gross area and say so.
10. **Runtime.** Real translation in the HtmlDialog runtime, pinned native comparison, manifest
    refresh, footprint recorded. Confirm no new wheel.
11. **Docs.** `docs/PRODUCT.md` and the g-value statement.

## Source

| Predecessor file | Lines | Disposition |
| --- | --- | --- |
| `features/windows/export/export_contract.rb`, `export_report.rb` | 354 | Adapt: reads window units, not designPH rows |
| `features/windows/export/ppp_shading_parser.rb`, `python/ph_navigator_translation/window_shading.py` | 140 | Drop |
| `python/ph_navigator_translation/phn_windows.py`, `contract/sections/{windows,window_apertures}.py` | 423 | Adapt per Q24 |
| `python/ph_navigator_translation/apertures.py` | 269 | Reference only: the designPH-native path |
| `tests/windows/export/window_export_contract_test.rb`, `tests/python/test_phn_windows.py`, `tests/fixtures/windows_export_section.json` | about 1,220 | Port the cases that survive |

## Tests (write first)

Against the shared fixture, loading the produced HBJSON in honeybee:

1. A one-element unit, a three-element mulled unit with an Empty panel and a unit on a roof: one
   `Aperture` per glazed element, none for Empty, each a sub-face of the right parent `Face`.
2. psi-install resolves per side from the frame elements; a shared internal edge is 0.0; no
   aperture carries an install type.
3. Two types and four units yield exactly as many window constructions as distinct combinations,
   with identifiers stable across two exports.
4. A g-value 0 unit exports 0, the report names it, and conformance records the one exception.
5. Two units sharing an id block; aperture identifiers hold across save and reopen.
6. Every blocking row in step 4 blocks, and Frame and operation mismatch does not.
7. The parent `Face` polygon is gross; glazed and net areas equal the hand calculation.
8. A Model with no units yields an empty section, no finding and an unchanged HBJSON.

## Host gate

Fresh process, the installed normal RBZ, the reference model with its four units: preflight,
repair until clean, export, reload the exact HBJSON in the pinned native stack and reconcile
apertures, parents, constructions, frame elements and areas with the Schedule and the report.
Repeat the export cases the ledger screens.

## Out of scope

METr and every "Through PHX" check, including the two-type four-unit PHX read-back. Shading.
Explicit `Door` export.

## Done when

- E14 has evidence in `evidence/p2-14-aperture-export.md`.
- The window-types and validation-and-export packets record the delivered scope. `make ci`
  passes on both Rubies with the manifest fresh and the footprint inside budget.

## Historical implementation start checkpoint, 2026-10-01

E13 passes on the current SketchUp 2026 host. Ruby snapshot projection/preflight and Python
typed sections are being implemented against the shared synthetic
`tests/fixtures/windows/aperture_export_section.json`. The pure net-area read and Schedule
column are implemented with focused tests; public registration and combined gates are pending.
No installed P2-14 package or E14 native export evidence exists yet. Current focused checks,
independent review corrections and the exact remaining gate are in the
[P2-14 evidence checkpoint](../evidence/p2-14-aperture-export.md).

The product-ID-only deduplication rule needed a correctness clarification: a simple glazing
system carries the actual element U-w, which can differ for two sizes using the same products.
Deduplication therefore includes the full numeric translated construction signature and product
IDs, including resolved psi-install and U-w. Presentation labels do not define identity. This
preserves actual authored thermal values instead of sharing one size's U-w with another.
The shared fixture includes same-products/different-U-w and exact g-value endpoint cases.

The generic declared-section read gains `Inputs.all(requirement)` for the Aperture join. The
public detached Face contexts provide occurrence paths and authoring state without Window
export reading another feature's private dictionaries. Core snapshots carry generic native
component/definition facts; contributors still consume one detached geometry traversal.
Window report metadata is explicitly allowlisted, including Psi-Install names that do not
travel in HBJSON. Exact schema, combined review, both-Ruby full gates, runtime manifest,
footprint and native pinned-stack roundtrip remain required before E14 closes.

## Delivery

E14 passes on the current SketchUp 2026 host. Both full offline Ruby gates, independent review,
normal-package native endpoint/blocking tests, canonical two-Zone export, pinned native comparison,
Schedule areas and clean native close/reopen are recorded in the
[E14 evidence](../evidence/p2-14-aperture-export.md). Milestone M3 is delivered on branch;
Phase 2 consolidated acceptance remains open.
