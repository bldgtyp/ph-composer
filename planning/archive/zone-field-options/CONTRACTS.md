# Managed Zone options: implementation contracts

DATE: 2026-10-05
STATUS: Complete local implementation and current-host acceptance; unmerged
AUTHOR: Ed May, BLDGTYP, with Codex
ISSUE: [#78](https://github.com/bldgtyp/ph-composer/issues/78)

## Model authority and feature ownership

Zones owns the two option collections and their assignments. Use the existing model-owned record
engine, identity, reference-target and retarget contracts. Keep names out of shell/session/core;
no generic custom-field framework is required. The shared chip, dialog, picker and Colour-by Entry
are UI/rendering primitives; they do not read Zone stores or decide domain rules.

Each option has stable identity, schema version, nonempty display name and validated `#RRGGBB`
colour, plus normal user/extension metadata. Segment records carry immutable `export_identifier`,
unique across the final Segment collection.
`ph_composer.zones.option_settings` selects the default Segment and retains source-model identity.
The declarations are in `options/definitions.rb`: Segment `bsg_`, Level `lvl_`, settings `zop_`.
Options are local editable records, not a provider dependency.

Zone schema v2 references `building_segment_id` and nullable `level_id`;
resolved names/colours are exposed for presentation. Avoid competing authoritative string and ID fields.
Queries remain read-only. Required references must resolve before assignment or export. IDs remain
unchanged through rename/colour edits. Normalized name uniqueness is enforced by Ruby public writes,
not just the HtmlDialog. Missing choices produce actionable findings and replacement routes.

## Public operations and consistency

The `ph_composer.zones.options.*` namespace declares all/list/detail/usage and adoption-preview
reads, and guarded create/update/merge/remove/manage/adopt writes. A management batch
validates the complete resulting collections before any write: names, colour, default, references,
shared storage, and Model/session revision. Revalidate server-side, return declared refusals and
preserve drafts on refusal. Do not implement the dialog as a series of partially committing writes.
The panel and scripts share these public operations; API reference/examples are regenerated.

Rename and colour edits update one option, leaving assignments intact. Merge/removal uses registered
reference discovery and retargeting. Discover live Zones and recoverable orphan membership stamps.
Refuse ambiguous/conflicting recovery evidence rather than guessing. Preserve Zone IDs, Face IDs,
metadata, adjacency references and occurrence semantics. Shared definition storage is updated once;
one occurrence cannot acquire an independent assignment without the existing uniqueness rules.

## Migration, recovery and copy

Zone schema/stamps v1 contain category strings; v2 references managed IDs and carries
`choice_evidence`. The Zone validator explicitly accepts these versions and refuses others.
The record engine's extension migration does not perform this base-record conversion: the
Zones-owned `adopt` action uses normal proposal/transaction ownership. Older-reader refusal,
rollback and preservation remain acceptance requirements.

The preview must inventory live Zone values and orphan stamps, not just table-visible rows. Preserve
null Level and nonempty required Segment semantics. Apply choice creation, Zone conversion, stamp
conversion and defaults atomically. No records are dropped because a label is unfamiliar. Conflicting
stamps or equivalent names require explicit resolution. Undo restores the complete original state.

Versioned `choice_evidence` travels on Zone Groups and member stamps, including detached choice
records and source-model identity. Reads do not import choices. Explicit destination adoption maps
to existing local choices or creates records; copy identity repair remains a separate action.
Adopted Segment export-key collisions require survivor mapping, not silent re-keying.

Portable option extension copying allocates destination identities first, remaps declared references
with source-origin-scoped Segment/Level maps, and checks installed copy rules plus all destination
references through the projected engine. Missing destination references refuse before writes.
Mapping to an existing survivor retains that survivor's record and metadata.

The accepted older-call adapter resolves only existing unambiguous names for managed Zones. Unknown
names refuse; v1 category changes require explicit adoption. An old string write cannot create choices.

## Colour, filtering and export

Colour-by projections resolve option IDs to names and custom colours through declared reads, then
supply Entry colours. Keep render core independent of these fields. Chip fills, menu swatches and
HUD colours agree; native selection edges, viewport masks and missing-value treatments retain their
current rules. Filters store option IDs and survive rename/colour changes; merge/removal reconciles
held filters without leaving an invisible stale restriction.

The Zone export contributor is version 2; Python accepts supported v1/v2 sections. Resolve human-readable names for
existing HBJSON `ph_composer.level` and `ph_composer.building_segment` metadata. Group Segments by
stable managed identity, not display spelling. Existing `_segment_identifier(name)` hashes must be
preserved as adopted Segments' immutable export identity; newly created Segments receive a key at creation that remains stable through later name edits. A rename changes display text without changing the exported Segment identifier.
Supported legacy bundle reads and actual HBJSON grouping/references are covered by round-trip tests.
See [implementation review](evidence/implementation-review.md); required current-host native gates passed.
