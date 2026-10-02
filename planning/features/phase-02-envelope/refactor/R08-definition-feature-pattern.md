# R08: the definition-feature pattern is copied, forked by kind and driven by positional tables

DATE: 2026-10-01
STATUS: Requested
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft; review of PR #15, issue #14)
CLASS: Optional improvement, readability and contributor cost. No correctness defect found.
PRIORITY: 5.

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
     gesture with its own description (this also serves R05 item F).
   - Name `MATERIAL_REFERENCE`. Spell out the abbreviated locals. Keep one name for the Psi-Install
     collection.
   - Add unit suffixes to thermal display fields (`u_effective_w_m2k`, `rsi_m2k_w`) and to the Python
     dataclass fields. This changes result schemas and the panel. **Decided 2026-10-01 by Ed:** do it
     now, in one pass with R06's code rename, before any release.
2. **One schema builder in the foundation.** Move `object`, `list`, `with`, nullable and id-pattern
   helpers to a single `core/` module that Zones, Assemblies, Windows and Library all use. This is
   justified on its own: six copies of one four-line function, already drifting in keyword names
   (`required:` and `optional:`).
3. **Optional, decide after Phase 3's first definition kind:** a small `CatalogInventory` helper
   offering the standard list, all, create, update, duplicate, delete registrations for one
   `RecordKind`, with hooks only for defaults and row display. Trace the contributor task before and
   after; adopt it only if the after is shorter to read, not just shorter to write.

## Verification

- `grep -n "== MATERIAL_KIND\|== \"types\"" features` returns nothing in operations and snapshot
  files.
- `make fixtures-check`: `docs/API_REFERENCE.md` changes only in descriptions and, if the unit
  renames are taken, in the named fields.
- Existing operation and schema tests pass with no assertion changes other than renamed fields.
