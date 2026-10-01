# Library file format

The library file provider reads a UTF-8 JSON file, or the immediate JSON files in a folder. A
library supplies definitions that the user copies into the SKP and edits locally. The implemented
wire kind is `materials`. The connection provider remains proposed.

## Envelope

```json
{
  "format": "ph-composer.library",
  "schema_version": 1,
  "kind_schema_versions": { "materials": 1 },
  "library": { "id": "example.synthetic", "name": "Synthetic Materials" },
  "exported_at": "2026-10-01T12:00:00Z",
  "kinds": {
    "materials": [{
      "id": "example-insulation",
      "name": "Synthetic insulation",
      "category": "insulation",
      "conductivity_w_mk": 0.04,
      "density_kg_m3": 40.0,
      "specific_heat_j_kgk": 1000.0,
      "emissivity": 0.9,
      "color": "#c8d8b0",
      "notes": "Synthetic example, not a product specification.",
      "datasheet_links": []
    }]
  }
}
```

Every envelope field shown above is required. `library.id` and `library.name` contain nonempty
text. `exported_at` is an ISO 8601 timestamp with a timezone. Each `kinds` entry is an array with
a version in `kind_schema_versions`. A row's `id` is the provider's stable record identity;
PH-Composer gives a copied record its own local identity.

Exporting local definitions publishes each local id as the wire record id. The optional
`record_origins` object groups informational origins by wire kind and exported record id.
An origin contains `label`, `provider_kind`, `library_id` and `record_id`. The label is a sanitized
provider-kind label. Origins contain no configured path, credentials or raw source snapshot;
the reader ignores them and they do not affect semantic fingerprints.

The export form defaults to all supported local definitions. Selected scope uses explicit record
ids and never derives its scope from a filter. New identity creates a library UUID; update keeps
the validated destination identity. A native review lists omitted local metadata and unsupported
records before a staged write replaces the destination. Cancellation or failure preserves its bytes.

## Materials version 1

Only `id` and `name` are required on a wire row. Supply SI numbers directly; PH-Composer never
guesses a unit or converts a differently named IP field. Missing optional fields produce a
structured warning and use the defaults below. A value that violates a declared wire field schema skips the row. Copy also checks the mapped
Material value contract, including hexadecimal color syntax.

| Field | Type and unit | Missing value |
| --- | --- | --- |
| `id` | Nonempty string, unique within a library and kind | Row skipped |
| `name` | Nonempty string | Row skipped |
| `category` | Category id string | Uncategorized, stored as `""` |
| `conductivity_w_mk` | Positive number in W/mK, or null | null |
| `density_kg_m3` | Positive number in kg/m3, or null | null |
| `specific_heat_j_kgk` | Positive number in J/kgK, or null | null |
| `emissivity` | Number from 0 through 1, or null | null |
| `color` | Six-digit hexadecimal string, such as `#ffffff` | `#ffffff` |
| `notes` | String | `""` |
| `datasheet_links` | Array of strings | `[]` |

The thirteen category ids are:

| Id | Category |
| --- | --- |
| `insulation` | Insulation |
| `finishes` | Finishes |
| `woods` | Woods |
| `metals` | Metals |
| `masonry` | Masonry |
| `stud_layers_steel` | Stud-Layers (Steel) |
| `stud_layers_wood` | Stud-Layers (Wood) |
| `air_horizontal_heat_flow` | Air: Horizontal Heat Flow |
| `air_upward_heat_flow` | Air: Upward Heat Flow |
| `air_downward_heat_flow` | Air: Downward Heat Flow |
| `rainscreen_insulation` | Rainscreen Insulation |
| `doors` | Doors |
| `membrane` | Membrane |

An unknown category becomes Uncategorized locally. Its original text remains in the copied
source snapshot. PH-Composer omits undeclared row fields with a warning. Wire records do not
carry local `source`, `user_data` or extension payloads.

## Versions, identity and limits

Envelope version 1 and Materials wire version 1 are implemented. An unsupported envelope version
rejects that file. An unknown kind or unsupported kind version marks that library and kind
unavailable while other supported kinds can load. In folder mode, a malformed file produces a
code-only warning; valid neighboring files can load.

Record ids must be unique across all files sharing a library id and kind. A duplicate withholds
that entire library and kind. Different library ids may use the same record id. Files sharing a
library id must also agree on its name.

| Limit | Implemented maximum |
| --- | --- |
| One JSON file | 32 MiB, 33,554,432 bytes |
| All immediate candidate JSON files in a configured provider | 64 MiB, 67,108,864 bytes |
| Rows across their kind arrays, including unsupported kinds and skipped rows in parsed files | 20,000 |

The provider refuses an over-budget catalog rather than truncating it. These are implemented
bounds with exact-limit and one-above offline checks. Current-host measurements meet all three
limits; other hosts remain subject to their own acceptance checks.

## Copy and read back

The configured file or folder path stays in per-machine setup. Public catalog results and copied
source attribution contain stable ids, never that path. A successful load publishes an immutable
session generation; a failed refresh retains the last valid generation with its failure state.
Reconfiguring or removing a provider invalidates its session catalogs.

Copy resolves exact source identity first, then the local name. Equal mapped values permit reuse;
different values require an explicit choice. Replacement preserves the local id and references,
with guarded authored values and metadata preservation. Optional assignment shares the copy's
single Model transaction. Preview and invoke use the same revision-bound copy timestamp for that
gesture. The timestamp is excluded from the semantic fingerprint.

The [public API reference](API_REFERENCE.md) describes catalog reads and guarded copy operations.
The [panel-closed walkthrough](../tools/examples/library/materials_walkthrough.rb) uses the
[synthetic fixture](../tools/examples/library/materials.json) in a Model with empty Materials and
Assemblies inventories. It removes its temporary provider configuration after read-back and
leaves the copied Material in the SKP. Native Undo/Redo and save/reopen are separate acceptance
checks.
