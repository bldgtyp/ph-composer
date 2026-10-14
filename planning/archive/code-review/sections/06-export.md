# 06. Extraction, translation, report and artifacts

The requested review is Ruby and JavaScript. The Python coordinator/composition and runtime bridge
were also inspected to verify the boundary those layers produce, not to perform an exhaustive
Python domain audit. See [the export diagram](../ARCHITECTURE.md#6-export-to-canonical-hbjson).

## Section-by-section assessment

| Section | Responsibility | Assessment |
| --- | --- | --- |
| Collection / GeometrySnapshot / SnapshotReader | One coherent traversal and registered feature extraction/projections | Good contributor orchestration; Edge facts and entity extension projections are incomplete |
| RecordReader | Allowlisted authored data, local metadata omissions and blocking unknown required payloads | Strong conservative export policy; catalog/entity asymmetry matters |
| Preflight / Workflow | Owner-declared findings/repair actions, native consent, revision recheck | Repairs use public actions; each selected repair is its own Undo operation |
| Tasks / Task | Session-owned asynchronous run, timer checkpoints, cancellation and content-generation checks | Export independent of the panel; late results bound to run/session |
| Privacy / HbjsonMetadata / ArtifactHygiene | Composed result and canonical metadata allowlists and sanitization | Deliberate admission; arbitrary metadata is not permission to export |
| ResultView / ReportHtml / Report | Own section plus declared lower-section results, escaped HTML and embedded result | Report extensions have a useful, narrow read surface |
| ArtifactPair | Destination state, durable pair replacement/recovery | Correct place for IO transaction policy rather than feature handlers |
| Python composition / Section / Inputs / coordinator / assembly | Explicit concrete section list, dependency order, typed requirements and attachments | Extensible translation orchestration; feature sections are plugged in at composition |
| Python entry / stack / conformance / exporters | Lazy runtime stack, canonical reload, artifact-only exporter input | No shipped exporter registered; METr remains deferred |

Export's generation counter differs usefully from the authoring revision: navigation can make an
edit stale without invalidating canonical content. Collection advances in bounded host slices;
the task rechecks content coherence before translation/check/write. Do not replace that with a
single synchronous feature-owned export function.

## F07. Entity extension payloads have no supported allowlisted export projection

**Classification:** reproduced extension-seam asymmetry. **Planning priority:** high with the entity
metadata work, before offering company customization on geometry entities.

[RecordReader.records](../../../../src/ph_composer/export/record_reader.rb#L44) accepts an
`extensions: { namespace => fields }` mapping for catalog records and validates installed payloads.
[RecordReader.entity_record](../../../../src/ph_composer/export/record_reader.rb#L50) has only `fields:`;
it sends every structured envelope to `leave_out`. SnapshotReader forwards only that signature.

The probe registers an understood `required` extension, gives it an entity record and sees
`extension.unavailable`, even though the extension is installed. Asking the entity method for an
allowlisted extension projection raises `ArgumentError`. Catalog contributors have a supported
way to perform this job; entity contributors must reach into raw stored envelopes or reconstruct
the policy themselves. Existing built-in contributors use the safe method and therefore block
required custom payloads on their entity records.

This does not mean all outside export contributions are impossible: an outside contributor can
traverse detached dictionaries and construct its own section. The problem is that the standard
entity path cannot express its payload mapping and the built-in contributor still independently
refuses the same required envelope. Preserve the conservative refusal until an explicit cooperating
projection contract is designed.

**Smallest adequate correction:** give catalog and entity projection a common allowlisting/status
mechanism, and settle how a namespace's exporting owner declares support that the entity-owning
contributor can recognize. Keep feature section ownership, declared translation fields and the
canonical privacy allowlist. Do not resolve this by exporting all `user_data` or trusting payload text.

**Verification:** installed required entity payload translates only declared fields and produces a
declared result/HBJSON mapping; absent, invalid, old, unavailable and unknown-relevance envelopes
remain distinct; local-only data is omitted with a finding. Check edit/copy/save/reopen preservation
and canonical reload with synthetic references. Coordinate with [RF-01/RF-03 in the Ruby review](04-ruby-features.md).

## F08. Some operation schemas incorrectly promise verbatim metadata export

**Classification:** directly evidenced public-contract wording defect. **Planning priority:** medium.

The Attached-zone [USER_DATA schema](../../../../src/ph_composer/features/zones/declarations/faces.rb#L34)
and Window [USER_DATA schema](../../../../src/ph_composer/features/windows/declarations/shapes.rb#L19)
describe local metadata as `exported verbatim`. The actual RecordReader omits arbitrary user_data
with a finding, and [EXTENSIBILITY, Metadata](../../../../context/EXTENSIBILITY.md#metadata-and-structured-extension-data)
requires deliberate mappings. Operation schemas feed generated API documentation, so a company
writing a script could reasonably rely on the false promise.

**Smallest adequate correction:** describe preservation in the Model and deliberate export mapping
accurately at the declaration source, then regenerate the API reference through its existing owner.
Keep this wording correction separate from the new entity projection contract.

**Verification:** generated descriptions and quickstart/example expectations agree with actual
omission findings and declared mappings; no licensed or client metadata enters fixtures.

## Explicit limitations and design frontiers

The Python section list is a composition root, not dynamic runtime plugin discovery. New shipped
translation logic must be included in the pinned runtime payload. Similarly the generic exporter
contract has synthetic tests, but the native export task currently delivers HBJSON/report only.
`EXPORTERS` is empty. Treat additional output-format selection/delivery as the deferred exporter's
feature work, not proof that a production third-party exporter can already be installed independently.

GeometrySnapshot entries and cached `SnapshotReader.section` projections are detached but not
deeply immutable. A callback can mutate shared returned geometry or projections and affect a later
contributor. No present built-in corruption was reproduced. Define a read-only callback contract,
then choose frozen values or detached per-consumer results and test isolation before relying on
many outside contributors. This is an optional seam-hardening item related to F02.

The artifact boundary remains the right design: translation sees detached authoring data; exporters
see HBJSON and explicit options. There is no reason to let an exporter query SketchUp or private
feature stores.
