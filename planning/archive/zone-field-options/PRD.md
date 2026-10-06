# Managed Zone field options: product requirements

DATE: 2026-10-05
STATUS: Complete local implementation and current-host acceptance; unmerged
AUTHOR: Ed May, BLDGTYP, with Codex
ISSUE: [#78](https://github.com/bldgtyp/ph-composer/issues/78)

## Problem and requested outcome

Free-text fields let a user create separate categories accidentally, such as `Level-1` and
`level 1`. Both fields should instead select a defined option. Users must be able to add options,
edit their names and set their colours. Names and colours belong to this SKP and must survive reopening.

## Implementation evidence

| Source | Observed behavior | Consequence |
| --- | --- | --- |
| [Zone schema](../../../src/ph_composer/features/zones/zone/schema.rb) | Reads v1 text and v2 option assignments; managed records/stamps carry portable choice evidence | Older data remains readable; adoption is explicit |
| [Zone editors](../../../src/ph_composer/html/features/zones/zone_cells.js) and [dialog](../../../src/ph_composer/html/features/zones/option_dialog.js) | Guarded ID selects and one collection draft with Save/Cancel | Ruby validates and commits the complete batch atomically |
| [Zone creation](../../../src/ph_composer/features/zones/zone/operations.rb) | First Make seeds the managed Segment/default in the same proposal; Level is null | Reads do not create settings or options |
| [Colour modes](../../../src/ph_composer/features/zones/colour_modes.rb) | Managed IDs resolve labels and custom Entry colours | Rendering remains independent of Zone storage |
| [Option inventory](../../../src/ph_composer/features/zones/options/inventory.rb) | Includes live Zones, orphan stamps and shared occurrences; writes deduplicate storage | Adoption and removal include recovery references |
| [Export](../../../src/ph_composer/features/zones/export.rb) and [translation](../../../src/ph_composer/python/ph_composer_translation/model_sections.py) | Contributor v2 supplies managed identity/export keys; Python retains v1 support and checks identity collisions | Rename preserves exported identity; real HBJSON reload cases verify grouping and Room metadata |

Implementation is local at `941166a`. Offline and browser evidence is recorded in
[evidence/implementation-review.md](evidence/implementation-review.md). Required current-host native acceptance passed; see STATUS.md and its linked native receipt.
This is not a release or broader host-support claim.

## User stories

- Assign a Zone to an existing Level or Building Segment without typing a category name.
- Define the Model's Levels and Segments before creating or assigning Zones, including an empty table.
- Rename an option once and see its new name on every assigned Zone without losing assignments.
- Pick a colour once and see the same colour in its chip and Colour-by overlay.
- Merge accidental duplicates deliberately, with affected usage visible before saving.
- Open an older Model without silent data changes or guessed category merges.

## Accepted interaction

Each Zone cell uses the existing select-chip pattern, with an inset chevron, option name and a
readable tint derived from its stored colour. Picking an existing value commits one guarded Undo step.
Level offers Not set; Building Segment always requires a valid option. Name and Ground depth keep
their existing editors. Row selection, checked-Face actions and filtering keep their current scopes.

Each column's ellipsis adds Manage Building Segments… or Manage Levels… after sorting/filtering
choices. It is available with no Zones and with Colour-by off. Both routes use one management
dialog component, opened directly on that collection. A separate global settings screen would
make these frequently edited lists harder to find; duplicate management surfaces are unnecessary.

The dialog shows each option's name, colour swatch/picker and usage. It offers Add, Rename,
Change colour, Merge and Delete. Changes stay in a draft until Save; Cancel/Escape discard them.
Saving a management batch is one atomic Model operation and one Undo step. Keep Save/Cancel visible,
and guard navigation while a management draft exists. Do not stack a second modal for rename or colour.
The picker offers a palette and exact hex entry, with accessible names and contrast-safe chip labels.

Rename retains identity and assignments. Merge chooses a surviving option and explicitly reassigns
all source references. Delete of an unused option is straightforward; used options require a
replacement, or Not set for Levels. Show live and recoverable-Zone usage; never delete a dangling
reference into existence. A default Segment cannot be removed without choosing its replacement.

## Duplicate names and old values

Use unique comparison keys within each collection: trim, collapse repeated whitespace,
compare without case, and treat spaces/hyphens/underscores alike. Preserve the chosen display spelling.
Reject equivalent new names with a message naming the existing choice. This prevents the example
above, while stable IDs keep identity separate from spelling. Ed accepted the separator policy in D4.

For an older Model, show an adoption preview listing every distinct stored value, affected Zones,
and suggested equivalent-name clusters. Preserve distinct categories unless the user explicitly
merges them. A collision cluster must be resolved before completing managed adoption; do not silently
choose a spelling or colour. Opening, inspecting and cancelling the preview write nothing. The accepted D10 adapter resolves older string writes only to existing unambiguous options.
Legacy category changes and management require adoption; unchanged v1 categories can accompany
Name/Ground depth edits. Unknown names refuse without creating options. Do not silently
fall back to a free-text editor that bypasses these rules.

## Scope and limits

In: two model-owned collections; assignment chips; create/rename/colour/merge/delete; managed
default; migration; recovery; reference safety; public operations; filtering; Colour-by; export.
Out: arbitrary user-defined columns, accounts/providers, a mandatory setup wizard, cross-project
option libraries, automatic semantic equivalence such as L1 versus First floor, and changes to
Zone geometry, adjacency or calculation behavior.
