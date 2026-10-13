# 01. Composition, records and common primitives

Reviewed source: `extension.rb`, `core/`, registry declarations and validation. Baseline and
verification are in [the review README](../README.md). This is a review, not an accepted redesign.

## Responsibility map

| Section | Actual responsibility | Architecture assessment |
| --- | --- | --- |
| Composition root | Loads foundation directories; explicitly installs Assemblies, Zones and Windows | Correct place to name concrete built-ins. A registration entry is permitted, not a violation of extensibility |
| Registry | Stages declarations, checks names/dependencies/contracts and publishes capabilities | Strong central seam; publication and immutability need tightening |
| Record kinds, fields, descriptors | Authored values, schema, identity shape and references | Validation is pure; a RecordKind also carries its persistence adapter |
| Catalog and Engine | Model-scoped reads; validated create/edit/delete/copy/migration proposals; final reference checks | Application service rather than a pure domain entity |
| DictionaryStore / EntityStore | JSON persistence on Model or explicitly resolved entity | Host adapters, despite residing under `core/` |
| ChangeSet / Proposal | Catalog writes, host steps, scope capture, preview digest and affected references | Good separation of planning from apply; both are intentionally mutable builders |
| Extension / ReferencePlan | Versioned payload status, copy/remap and final occurrence inventories | Valuable community contract; entity-backed access remains less complete than catalog access |
| JsonSchema / JsonValue / CanonicalJson / DeepCopy | Pure boundary validation, deterministic serialization and copies | Suitable inner utilities |
| Vector3 / FaceGeometry | Geometry calculations, plus native Face capture in FaceGeometry | Pure mathematics and native capture share a module |
| Pick / ViewFraming / DragSet / ModelOperation | Selection, viewport, host gestures and native operations | Shared host support, not the innermost domain |
| Units / ModelSettings / Diagnostics | Formatting; guarded settings persistence; sanitized diagnostics and log destination | Three distinct services; keep their host dependencies visible |

The repository implements a modular feature architecture with domain/application/host separation
inside it. It is not a strict onion organized into separate physical rings. In particular,
`core/` means common foundation, not pure domain. That naming alone is not a defect. A useful
refactor would make the distinction explicit before someone treats everything in `core/` as
portable business code.

## F01. Registration can fail after publishing part of the batch

**Classification:** reproduced defect. **Planning priority:** high, before inviting contributors.

At [Registry#publish](../../../src/ph_composer/shell/registry.rb#L97), features and operations are
published first, then record kinds, then each store dictionary is registered. The dictionary prefix
check raises from [Dictionaries.register](../../../src/ph_composer/core/dictionaries.rb#L11).
[Record-kind validation](../../../src/ph_composer/shell/registry_validation.rb#L218) does not
validate that persistence contract before publication.

The synthetic probe registers a kind with a custom store whose dictionary is `outside.records`.
`Registry.install` raises `ArgumentError`, yet the feature, query and kind remain in the live
registry; the kind has no published owner because publication stopped before the owners step.
This contradicts [CONTRACTS, Registration](../../../context/CONTRACTS.md#registration): a bad batch
must publish nothing. This is an invalid contributor declaration, not a failure in the shipped
default DictionaryStore, but diagnosing bad contributions is the purpose of this seam.

**Smallest adequate correction:** validate store protocol and dictionary constraints while staging;
prepare the complete published state before replacing the live state. Make the distinction between
validation errors and publication/subscription failures explicit. Do not merely rescue this exception
and continue with partial registration.

**Verification:** valid built-ins and outside stores still register; malformed stores produce named
registration diagnostics with the previous registry and dictionary inventory unchanged; inject a
publication failure and assert no partly available contribution. Existing host subscriptions must
not duplicate on retry.

## F02. Published record-field schemas remain mutable aliases

**Classification:** reproduced contract-stability defect. **Planning priority:** high.

[RecordKind initialization](../../../src/ph_composer/core/records/record_kind.rb#L22) freezes the
fields array but retains the Field instances and their nested schemas. Registry publication stores
the same kind. In contrast, operation schemas and library adapters are copied and frozen.

The probe registers a number field with minimum 0, validates a value of 2, then changes the retained
schema's minimum to 10. The already-published kind now rejects the same record without another
registration. Schema reuse or a contributor mutating its own builder changes the contract under
every consumer. This undermines validation and discovery as a stable registration boundary.

**Smallest adequate correction:** give published record descriptors and reference declarations
detached immutable value state, with a clear boundary around behavior-bearing callbacks and stores.
Apply the same publication policy to feature/dependency metadata, snapshot and export declarations.
Do not deep-copy arbitrary host objects or Proc closures; define which declaration values are owned.

**Verification:** mutate original schema builders, fields, reference paths and declaration strings
after registration; discovery and validation must remain unchanged. Reading published descriptors
must not give consumers mutable aliases. A new registration, rather than mutation, changes a contract.

## F03. The common foundation mixes pure and native geometry responsibilities

**Classification:** optional structural improvement, directly evidenced. **Planning priority:** later.

[FaceGeometry.capture](../../../src/ph_composer/core/face_geometry.rb#L34) reads native Faces,
transforms vertices and obtains glue state. Its sibling functions compare planes/loops and calculate
areas from explicit values. Records::Engine similarly coordinates persistence while RecordKind
validation is pure. These are useful seams already, but a newcomer cannot infer purity from the
directory or module name.

**Recommendation:** retain cohesive algorithms; separate native capture/storage/viewport adapters
from pure values and rules when preparing a reusable foundation package. Start with a documented
dependency map and isolated pure-domain tests. A mass move of every file would create churn without
changing dependency direction. Do not introduce a repository/service interface for every helper.

**Acceptance:** importing or exercising portable rules does not require the SketchUp stub; capture
produces the same geometry value and digest; normal authoring/export fixtures remain unchanged.

## What should be retained

The engine does not guess which strings are references. Core and structured references are declared,
incoming references are checked against a proposed final state, and catalog duplication allocates
identities before validating copied relationships. Metadata is preserved independently of authored
values. These are stronger foundations than generic CRUD and should survive any restructuring.

The synthetic foundation example is small enough to trace and covers real operation/refusal behavior.
Its frontend example has defects documented in [05](05-javascript.md); that reduces its value as a
contributor template, not the validity of the record engine itself.
