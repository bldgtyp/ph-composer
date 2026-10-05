# Managed Zone options: proposed contracts

DATE: 2026-10-05
STATUS: Proposed; no implemented contract changes
AUTHOR: Ed May, BLDGTYP, with Codex
ISSUE: [#78](https://github.com/bldgtyp/ph-composer/issues/78)

## Model authority and feature ownership

Zones owns the two option collections and their assignments. Use the existing model-owned record
engine, identity, reference-target and retarget contracts. Keep names out of shell/session/core;
no generic custom-field framework is required. The shared chip, dialog, picker and Colour-by Entry
are UI/rendering primitives; they do not read Zone stores or decide domain rules.

Each option has stable identity, schema version, nonempty display name and validated `#RRGGBB`
colour, plus normal user/extension metadata. Segment records also need an immutable export identity.
A model-owned setting selects the default Segment. The exact declarations remain to be designed.
Options are local editable records, not a provider dependency.

Recommend a versioned Zone schema referencing `building_segment_id` and nullable `level_id`, with
resolved names/colours exposed for presentation. Avoid competing authoritative string and ID fields.
Queries remain read-only. Required references must resolve before assignment or export. IDs remain
unchanged through rename/colour edits. Normalized name uniqueness is enforced by Ruby public writes,
not just the HtmlDialog. Missing choices produce actionable findings and replacement routes.

## Public operations and consistency

Declare list/detail/usage reads and guarded create/update/merge/remove writes. A management batch
validates the complete resulting collections before any write: names, colour, default, references,
shared storage, and Model/session revision. Revalidate server-side, return declared refusals and
preserve drafts on refusal. Do not implement the dialog as a series of partially committing writes.
Expose the same public operations to the panel and scripts; regenerate API reference/examples.

Rename and colour edits update one option, leaving assignments intact. Merge/removal uses registered
reference discovery and retargeting. Discover live Zones and recoverable orphan membership stamps.
Refuse ambiguous/conflicting recovery evidence rather than guessing. Preserve Zone IDs, Face IDs,
metadata, adjacency references and occurrence semantics. Shared definition storage is updated once;
one occurrence cannot acquire an independent assignment without the existing uniqueness rules.

## Migration, recovery and copy

Current Zone schema/stamps are version 1 and contain strings. The current
[record engine](../../../../src/ph_composer/core/records/engine.rb) has `propose_migration` for
structured extension namespaces; it does not provide a base Zone-record migration.
[RecordKind](../../../../src/ph_composer/core/records/record_kind.rb) validates one declared schema
version, and the separate Zone validator currently accepts only version 1. Design an explicit
Zones adoption operation using ordinary transaction ownership, with deliberate v1/v2 read handling.
Do not treat extension-payload migration as an already implemented Zone upgrade. Version handling,
older-reader refusal and rollback are acceptance requirements.

The preview must inventory live Zone values and orphan stamps, not just table-visible rows. Preserve
null Level and nonempty required Segment semantics. Apply choice creation, Zone conversion, stamp
conversion and defaults atomically. No records are dropped because a label is unfamiliar. Conflicting
stamps or equivalent names require explicit resolution. Undo restores the complete original state.

Define versioned recovery stamps and the portable evidence needed for Zone copy/paste between Models.
A destination may lack the source's model-owned choices. Missing references must remain visible and
repairable; reads may not invent records. Determine whether existing native copy/reference hooks can
carry choice definitions or whether an explicit adoption action is needed. Do not broaden unrelated
copy policy or introduce a global observer migration shortcut.

Preserve older public callers deliberately: choose a documented adapter that resolves only existing
unambiguous names, or a versioned refusal/upgrade path. An old arbitrary string write must not bypass
the managed-list rules. The owner decision is required before implementation.

## Colour, filtering and export

Colour-by projections resolve option IDs to names and custom colours through declared reads, then
supply Entry colours. Keep render core independent of these fields. Chip fills, menu swatches and
HUD colours agree; native selection edges, viewport masks and missing-value treatments retain their
current rules. Filters store option IDs and survive rename/colour changes; merge/removal reconciles
held filters without leaving an invisible stale restriction.

Version the export contributor/translation boundary as needed. Resolve human-readable names for
existing HBJSON `ph_composer.level` and `ph_composer.building_segment` metadata. Group Segments by
stable managed identity, not display spelling. Existing `_segment_identifier(name)` hashes must be
preserved as adopted Segments' immutable export identity; newly created Segments need a stable key
independent of name. A rename changes display text without changing the exported Segment identifier.
Retain supported legacy bundle reads and prove the actual HBJSON grouping/references through round trips.
