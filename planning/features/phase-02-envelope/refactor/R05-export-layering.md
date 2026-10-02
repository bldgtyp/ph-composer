# R05: export and translation layering runs upward

DATE: 2026-10-01
STATUS: Requested
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft; review of PR #15, issue #14)
CLASS: Evidenced contract violation. Architecture change.
ORDER: 5 of 11. See the packet README, Sequencing.

Paths are relative to `src/ph_composer/` unless stated.

## Governing rules

- `context/EXTENSIBILITY.md`, "Organization and dependencies": "A lower layer never names a higher
  one." Definitions (Assemblies, window products) sit below Zones; Window units sit above Zones.
- Same section: "A feature that needs authored Face identity, such as window placement, depends on
  `zones` through its queries, actions, reference targets and descriptors, never through its stores."
- `context/CODING_STANDARDS.md`, "Readability and public interfaces": "Do not reach into another
  feature's internals."
- `context/CONTRACTS.md`, "Translation sections and artifacts": the coordinator "names no feature".
- Archived decision D2-10: "Windows owns [net opaque area]... Zones declares no dependency on windows."
- The archived Phase 2 `CONTRACTS.md` section 4 claims "Every arrow above points down a layer". The
  row "`ZoneSection` (Python) to Apertures section" in that same table points up a layer.

## Observed

1. **Zones translation requires Windows.** `python/ph_composer_translation/model_sections.py:21`
   imports `APERTURES, TranslatedAperture` from `window_sections`. `ZoneSection.requires` is
   `(FACES, CONSTRUCTIONS, APERTURES)` (line 164). It attaches apertures to Faces (lines 188-241),
   emits findings under the Apertures section id (`findings`, lines 254-272) and computes
   `construction_usage` and `window_face_areas` (lines 308-330).
2. **The Zones Ruby contributor declares Window result fields.** `features/zones/export.rb:17-19`
   declares the privacy allowlist for `construction_usage` and `window_face_areas`.
3. **Reports read fields another feature produced, with no declared dependency.**
   `features/assemblies/export.rb:89` reads `construction_usage` (produced by ZoneSection).
   `features/windows/export.rb:84` reads `window_face_areas` (produced by ZoneSection). Both go
   through one flat `result` hash keyed by bare strings.
4. **Windows export calls a Zones Ruby module directly.** `features/windows/export.rb:51` calls
   `Zones::Faces::ExportProjection.contexts(reader)`. It is the only cross-feature constant reference
   in `features/` (grep for `Zones::`, `Assemblies::`, `Windows::` across the three feature folders).
   `contexts` was added to Zones for this caller (`features/zones/faces/export.rb:11-23`).
5. **Shared translation entry names Windows.** `entry.py:38` passes
   `result.get("window_schema_exceptions", ())` into `conformance.check`, and `conformance.py:50-80`
   holds Window-specific checks (install types, PH glazing g-value, schema exceptions).
6. **Two matchers implement one geometry rule.** `features/windows/units/definition_geometry.rb`
   (`matches?`, live entities) and `features/windows/export_geometry.rb` (`matches?`, detached facts)
   each carry their own `on_segment?` and `close?`. `export_assessment.rb:101-108` repeats
   `DefinitionIndex.valid_mapping?`.

## Why it happened

Honeybee nests Apertures inside Faces inside Rooms. The section that builds Rooms therefore has to
receive every object that hangs off a Room or Face. With no contract for "contribute a child to the
object another section builds", the Room builder imports each contributor by name. An export
contributor also receives only a `reader`, not a request, so it has no declared way to read another
contributor's projection (item 4).

## Consequence

- Contributor task "add a feature whose objects attach to a Room or Face" (Spaces, shades, thermal
  bridges, an outside contributor's sub-face): today the contributor edits `model_sections.py`
  (imports, `requires`, attachment, findings, result fields), `features/zones/export.rb` (privacy
  fields), and possibly `entry.py` and `conformance.py`. That is four files in two other owners.
  `context/EXTENSIBILITY.md` calls a required branch inside export orchestration "a contract defect".
- Phase 3 Spaces attach to `Room.properties.ph`. The current shape puts `SPACES` into
  `ZoneSection.requires` next to `APERTURES`.
- A renamed result field breaks another feature's report at run time. Nothing checks the pairing.

## Proposed correction

The shape is decided (see Decisions). Implement in this order.

1. **Split model assembly from Zones.** A foundation section (working name `ModelAssembly`) owns
   building the Honeybee `Model`, pairing Surfaces and the canonical accounting. Zones contributes
   Rooms and Faces. This is where honeybee's nesting is honoured.
2. **Add an attachment contract in Python.** A section declares what it attaches and to which host
   kind, for example `attaches = Attachment(host=FACES, key="host_face_id")` with an `attach(host,
   obj)` method. The assembly step collects attachments by declaration. `ZoneSection` stops importing
   `window_sections`. Declare the Ruby half with the export contributor (`attaches_to:`), so
   registration can diagnose a missing host section.
3. **Namespace results by section id** (decided, see Decisions). Add `requires:` for a report's
   cross-section read and a registration diagnostic for an undeclared one. Update the report builder,
   the privacy allowlist composition and the Export pane reader together.
3a. **Move derived joins to the layer that owns them.** `window_face_areas` moves to a Windows-owned
   result (D2-10). `construction_usage` moves to Zones' own report section, or Assemblies' report
   declares a `requires:` on the Zones result field.
4. **Give export contributors a declared cross-contributor read.** `export_contributor(...,
   requires: [section_id])` plus `reader.section(section_id)` returning that contributor's detached
   projection. Windows then reads Face host contexts through the declaration, and
   `Zones::Faces::ExportProjection.contexts` becomes Zones' registered projection rather than a
   public-by-accident method. Registration refuses an undeclared read, as `request.query` does.
5. **Move Window conformance checks beside the Window sections.** Give `Section` an optional
   `conformance(model, result)` hook that `conformance.check` iterates. `entry.py` stops naming
   `window_schema_exceptions`.
6. **One geometry matcher.** Capture live definitions into the same detached facts the snapshot
   uses, and run one `matches?` over facts for both authoring and export.

Alternative considered and closed by Ed on 2026-10-01: keep `ZoneSection` as the assembler and accept
the upward requirement as one sanctioned exception. It leaves every later attaching feature editing
Zones.

## Decisions

- **Model assembly: decided 2026-10-01 by Ed.** A foundation model-assembly section, at the outside
  of the dependency onion, composes the Honeybee Model. Zones, Windows and later Spaces stay small
  and independent; each declares what it attaches and to which host, and the composer names none of
  them. Ed's stated principle: prioritize atomic, independent entities that higher-level composition
  entities then use. The alternatives (Zones stays the assembler with generic attachments; keep the
  upward requirement as a documented exception) are closed. Correction steps 1 and 2 above are the
  chosen shape.

- **Result fields: decided 2026-10-01 by Ed.** Export results are addressed by the section that
  produced them (`result[section_id][field]`). A report or panel reader that wants another feature's
  result declares that it requires that section; registration refuses an undeclared read, the same
  rule `request.query` applies between features. This changes the result contract read by the export
  report and the Export pane, so both change once. The alternatives (keep the flat hash with declared
  field names; leave it) are closed.

## Design

Written 2026-10-02 against the two decisions above, before code.

- **Python model assembly.** `assembly.py`, foundation, names no section. After every section has
  run, it builds the Honeybee `Model` from attachments, in honeybee's nesting order: `MODEL`, then
  `ROOM`, then `FACE`. A section declares `attaches = Attachment(host, key)` and implements
  `attach(host, items)`, called once per host with that host's objects in id order, so a host can
  validate all its children together. A missing host, or a `RecordError` from `attach`, becomes an
  `object.unavailable` finding on each attached object, blocking as `required_for_export` says;
  `AttachmentRefused` names only the refused objects.
  Zones attaches its Rooms to the Model; its `attach` sets building segments and pairs Surfaces,
  which `result_fields` used to do. Windows attaches Apertures to Faces; host eligibility and the
  owning-Zone check run in `ApertureSection.translate` against the Zones Face specification, a layer
  down, so one bad Aperture costs only itself. The canonical model is serialized when it holds a Room
  and no attachment was refused, as a failed Zone already allowed, for diagnostics.
- **Canonical accounting is the foundation's.** `canonical_model` is a shell field:
  `{hbjson, rooms, faces, surface_pairs}`, counted from the assembled Model. `omitted` leaves it;
  the Faces section's `surface_omissions` already lists every omission.
- **Result fields after assembly, namespaced.** The coordinator collects every section's
  `result_fields` after assembly, so a section can read where its objects were attached. The
  document carries them as `result[section_id][field]`; a section with no fields has no key.
  `window_face_areas` becomes the Apertures section's, read from each Aperture's parent Face.
  `construction_usage` stays with Zones, which knows Faces and the Assemblies they name.
- **Conformance per section.** `Section.conformance(model, fields)` runs after the foundation's
  reload check. The Aperture checks, including the schema exceptions, move to `ApertureSection`.
- **Ruby `requires:`.** `export_contributor(..., requires: [section_id], projection: ...)`.
  Registration refuses a required section that is not registered, or whose owner is neither the
  contributor's feature nor one its feature requires (`registration.missing_dependency`), the
  `request.query` rule. A contributor reads another section's extraction-time projection through
  `reader.section(id)` and another section's results through the `ResultView` its report receives;
  both refuse an undeclared section. Faces registers its host contexts as its projection; Windows
  names the Faces section id as a string.
- **Reports by layer.** Assemblies sits below Zones and cannot require a Zones section, so Zones'
  report renders construction usage, naming each Assembly from Assemblies' `construction_definitions`.
  Assemblies' report lists its translated definitions with their disclosures.
- **One matcher.** `GeometrySnapshot.definition_facts(definition)` becomes public. The live and
  export checks both run `Units::DefinitionGeometry.facts_match?` over those facts. The export's extra
  `cuts_opening` and `is2d` requirement stays in the export assessment, so authoring behaviour does
  not change. The assessment reuses `DefinitionIndex.valid?`.

## Verification

- `grep -n "window" python/ph_composer_translation/model_sections.py entry.py conformance.py` and
  `grep -n "window" features/zones/export.rb` return nothing.
- `grep -rn "Zones::" features/windows` returns nothing.
- A registration test: a report reading another section's result without declaring it is refused with
  a `registration.missing_dependency` diagnostic.
- A synthetic attaching section under `tools/examples/` adds a sub-face without editing
  `model_sections.py`, `composition.py` aside. Existing goldens stay byte-identical; do not
  regenerate a golden to pass.
- `make ci` on both Rubies; the E06 and E14 export readbacks repeat on the host because the
  translation composition changed.
