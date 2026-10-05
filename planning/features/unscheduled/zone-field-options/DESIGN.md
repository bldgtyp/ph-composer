# Managed Zone options: implementation design

DATE: 2026-10-05
STATUS: Complete local implementation and current-host acceptance; unmerged
ISSUE: [#78](https://github.com/bldgtyp/ph-composer/issues/78)

Ed accepted D2–D10 and the older-call/destination-adoption policies on 2026-10-05.
The independent design review closed the export-key and stamp-adapter gaps before schema work.

## Record and projection boundary

Zones owns `ph_composer.zones.building_segment` (`bsg_`) and `ph_composer.zones.level` (`lvl_`)
record kinds. Both use the existing model DictionaryStore and schema version 1, with required
`name` and `colour`; Segment also requires immutable `export_identifier`. Preserve normal
`user_data` and `extension_data`. Colour is six-digit `#RRGGBB`, normalized on write. Name keys
trim, collapse whitespace and separators, and compare without case; display spelling remains
editable. Ruby owns validation, including non-ASCII cases and duplicate comparison. Segment export
identifiers must also be unique across the final collection, independently of display-name uniqueness.
Two source Models may have adopted the same exact name into different local IDs with the same legacy
hash; destination adoption must report that collision and require mapping to the existing survivor.
Creating a distinct choice with an occupied export identifier refuses. Never silently re-key an
adopted Segment to make import succeed; a future explicit fork/re-key policy would need its own
owner decision. New native choices derive their initial key from Model identity, revision and initial name;
that stored key is immutable through later name edits, and collection validation checks uniqueness.

A separate model setting carries the default Segment ID and a stable source-model identity for
portable evidence. Seed these only during an explicit write. A fresh read returns an empty list
and the existing suggested Model-name default; it creates no dictionaries. First Make creates
the required default and Zone together. Managing an empty Model can also create its first Segment.
The settings declaration uses the existing record/reference mechanism, so removing its default
cannot bypass incoming-reference checks.

Zone v2 replaces authoritative `building_segment`/`level` with required `building_segment_id`
and nullable `level_id`. Keep `id`, `name`, `ground_depth_mm` and metadata. `Schema.problems`
explicitly validates v1 and v2 and refuses unknown versions. The entity descriptor publishes the supported input fields; the Zone validator checks complete
v1/v2 shapes. Catalog RecordKinds retain their single declared schema version. Public
projection retains resolved names for table labels/search and adds assignment IDs and colours. Presentation labels are outside the authoritative update values.

Retain v1 reads and legacy export support until adoption. Name/ground-depth edits can preserve v1
values. Category assignment and management require explicit adoption. For managed Zones the
accepted older-call adapter resolves a supplied exact or normalized name only when it names
one existing option; unknown or ambiguous names refuse. It never creates an option. Ed accepted this adapter in D10.

## Public entry points

Implemented operation namespace: `ph_composer.zones.options.*`.

| Operation | Contract |
| --- | --- |
| `list` | Collection (`building_segment` or `level`), paging; IDs, values, metadata and read-only usage (`all` also returns the default) |
| `detail` / `usage` | Explicit option ID; complete record and live/recoverable usage counts |
| `create` / `update` | Validated values, immutable identity/export key, expected values, normal metadata rules |
| `merge` / `remove` | Explicit source/target or nullable Level clear; default replacement and incoming reference checks |
| `manage` | One complete collection draft, expected collection/default, temporary new-option keys and explicit replacement map; validate final state, commit one proposal |
| `adoption_preview` | Exact legacy values, portable evidence, orphan/conflicting stamps, collision clusters and affected references; no mutation |
| `adopt` | Explicit per-source mapping to existing choices or new definitions; revision/expected-state guards, one atomic proposal |

Create/update/merge/remove and management reuse the same owner operations. The panel submits one
`manage` batch rather than multiple committing actions. Preview uses the existing proposal route;
Save revalidates the whole final state. Publish params/results/examples and every refusal, including
copy/recovery failures, in discovery and generated API docs. Unknown versions refuse as
unreadable/invalid records; missing choices and duplicate names have separate reference/domain
refusals.

## Reference, adoption and portable evidence

The live Zone reference target declares its outgoing choice references. The additional
membership-stamp target inventory covers all occurrences, including orphan Faces and shared storage.
Existing stamps lack the `id` that Engine expects. The adapter projects a detached complete stamp
with diagnostic `id` equal to its `zone_id`, and a root-to-member path as ReferenceEntry key.
Its validator checks `id == zone_id`, then validates the underlying stamp with that synthetic field
removed. Neither inventory nor writes add `id` to the stored stamp. A final-state plan uses the same
projection; any removal preimage includes every projected field, while write guards compare the
complete original stored stamp. Repeated diagnostic IDs across members are intentional; callers
must use occurrence paths, and trying to resolve a stamp by that ID alone can refuse as ambiguous.
The adapter provides outgoing choice-reference discovery, not a new durable identity per member.
Retargeters produce typed final ReferenceEntries and rewrite steps, then the existing engine checks
deletions against the projected final inventory. Preserve outgoing references in extension data.

Separate occurrence discovery from actual storage writes: count affected occurrences accurately,
write each entity store once, refuse locked or conflicting storage, and preserve the current
Make Unique requirement for an independent Zone assignment. The default setting participates in
the same proposal. Validate every scope before opening a native transaction.

Adoption inventories exact v1 labels and every stamp, including stamps that cannot currently be
Restored. Suggested normalized collision clusters require explicit survivor mappings; no automatic
merge or spelling choice. Each exact Segment's pre-adoption export key is
`bseg_` plus the first 16 hex digits of SHA-256 over its UTF-8 name. An explicit merge retains the
survivor's key. Convert records, stamps, settings and options together; preserve IDs, paths, metadata,
Face assignments and adjacency. Refusal writes nothing; Undo restores the complete v1 state.

Portable evidence must travel on the Zone Group as well as member stamps, because a Zone can be
copied before any Face has been classified. The schema-validated v2 `choice_evidence` capsule contains
source-model identity and detached choice definitions (IDs, names, colours, immutable Segment
export key and metadata). The capsule is recovery evidence, never a second assignment authority.
Choice resolution is explicit in owner operations; pure Schema functions do not read the Model.
Reads never import missing choices. New destination option identities are allocated before portable
extensions are copied. Source-origin-scoped typed Segment/Level maps remap declared references;
installed copy-rule checks and the read-only projected engine validate all destination references
before any write. Missing destination references refuse the entire adoption. Existing survivor
records and metadata remain authoritative when a source maps to them.

Accepted destination policy: show missing/foreign choices with their source label and colour;
explicit adoption maps them to existing destination choices or creates new local records. Keep
same-model identity repair separate from choice adoption and preserve its occurrence-specific Face
ID remapping. Matching names alone never establish common identity. Same IDs with inconsistent
portable evidence require a conflict finding and explicit mapping. Refresh evidence during relevant
management/assignment writes so the clipboard reflects current labels/colours.

Current `Repair.orphans` suppresses stamps whenever their Zone ID exists anywhere in the live
inventory. The new adoption inventory must still surface copied/orphan members with such collisions;
do not use the current Restore offers as the entire migration source. Restore continues to refuse
mixed contexts, conflicting stamps and shared edges, and discloses unrecoverable Zone fields.

## UI and export integration

[Interaction prototype](../../../../tools/spikes/zone-field-options/index.html) uses the existing
menu/dialog components with synthetic, memory-only data. It demonstrates assignment selects,
name/hex/picker edits, usage, Add, replacement-based Merge/Delete, default selection and Save/Cancel.
The shipped component now includes usage, palette, pending/refused/stale states, draft navigation
and model-switch handling, and adoption preview. Offline tests and the real Chrome preview verify
these states; native HtmlDialog acceptance passed on the current macOS host.

Reuse one dialog component for both collections. Keep the table stationary. ID-based filters survive
rename; merge/removal reconciles IDs from the returned replacement map. Text search and checked-Face
selection stay independent. Colour modes supply resolved option IDs, labels and custom Entry colours;
missing Level remains unclassified. No feature logic moves into Colour-by or the shell.

Zone export contributor section version 2 emits resolved names and stable Segment identity/export key.
Python accepts supported v1/v2 sections: v1 keeps existing name hashing; v2 groups by managed identity
and sets the supplied immutable key. Check actual Room Segment references, display names and
`ph_composer` metadata after serialization/reload, including distinct categories and explicit merges.
A renamed option changes its display text but never its exported identifier.

## Checkpoints and gates

- D2–D10 accepted; design review closed before schema work.
- Identity/adoption, presentation and export integration implemented locally at `941166a`.
- Combined stronger independent architecture/UI review closed its reproduced findings after fixes.
  API/goldens and runtime manifests were regenerated. Verification and corrections are recorded in
  [evidence/implementation-review.md](evidence/implementation-review.md).
- Final `make ci`, required current-host O7/H1–H3 and host portions of O1–O9 passed.
  Installed-build, exact Undo/Redo, save/reopen and copy evidence is recorded in STATUS.md.

No push, PR, merge or release authorization is inferred from the local implementation request.
The completed packet is archived; remote delivery and post-merge synchronization remain separate.
