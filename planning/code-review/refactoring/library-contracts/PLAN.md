# Library contracts plan

DATE: 2026-10-13
STATUS: Implemented on branch `refactor/group-5-library-contracts` (LC-01 to LC-04 code and docs); native receipt pending. Stage ledger in [STATUS.md](STATUS.md).
ISSUE: [#111](https://github.com/bldgtyp/ph-composer/issues/111)
BASELINE: `cfe01a6aad99a0e09d5ecf0de5659c606d7ba4f9`
FINDINGS: [F05](../../sections/03-services.md#f05-a-registered-library-kind-can-be-valid-yet-fail-because-sorting-requires-name), [RF-04](../../sections/04-ruby-features.md#rf-04-material-library-replacement-repeats-the-ordinary-persistence-pipeline)
DEPENDS ON: [Registration reliability](../../../archive/registration-reliability/PLAN.md) RR-02 for the new adapter
value. LC-03 touches `CallbackInvoker` only through its existing call; if
[cross-feature composition](../../../archive/cross-feature-composition/PLAN.md) C-03 lands first, LC-03 uses the
migrated invoker.

## Goal

A registered library kind whose authored vocabulary has no `name` lists, resolves, copies, replaces,
assigns and exports. Material library replacement calls the ordinary Material update with its
provenance as a separate trusted argument.

## Verified at the baseline

| Where | What it does now | Consequence |
| --- | --- | --- |
| `shell/registry_validation.rb`, `LibraryValidation#check_library_kinds` | Checks wire and mapped schemas are objects, the three pure methods and four callbacks | No required `id`, no label contract |
| `library/library_file.rb`, `parse` row sort | `row.dig("snapshot", "name").to_s.downcase` | Tolerates absence with `to_s` |
| `library/library_file.rb`, `normalize_row` | Treats `id` and `name` as text-required only when the wire schema lists them as required | A schema can omit both |
| `library/file_provider.rb`, `merge` | `row.dig("snapshot", "name").downcase` | `NoMethodError` on nil: the F05 failure |
| `library/admission.rb` | Normalizes and semantic-checks rows; no label | Provider rows reach the catalog without a label |
| `library/resolver.rb`, `resolve` and `result` | `row.fetch("mapped").fetch("name")` for collision grouping; candidate `"name"` | `KeyError` for a name-free kind at copy time |
| `library/schemas.rb`, `resolution` | Candidate shape requires `name` | Public schema hard-codes the vocabulary |
| `library/coordinator.rb` | Maps, resolves, calls callbacks; attribution snapshot uses mapped keys | Needs the label only through the resolver |
| `html/library/adapters.js` line 7 | `name: function (row) { return row.values.name \|\| row.id; }` | Shared UI default assumes `name` |
| `html/library/rows.js` (lines 44, 76, 81 to 85, 116, 126), `drag.js` line 68 | Call `adapter.name(row)` | Migrate the default, not each caller |
| `html/library/copy.js` lines 30 and 38 | `row.values.name` for the title; `candidate.name` in the selector | Two direct reads |
| `features/assemblies/library_kind.rb`, `replace` callback | Repeats find, unique name, `Commands.update_material`, `changed_values`, then `propose_update` with `source` merged into values | The RF-04 duplicate of `Materials::Operations.update` |
| `features/assemblies/commands/material.rb`, `MATERIAL_EDITABLE` | Excludes `source` | The allowlist to preserve |
| `features/assemblies/materials/operations.rb`, `update` | `find`, unique name, `update_material`, `changed_values`, `propose_update(values:, expected_values:, user_data:)` | Gains a `source:` keyword |
| `features/windows/library_kinds.rb`, `replace` callback | Calls `Products::Operations.update` with values that include `source` | Products admit `source` in their patch; the Windows path already reuses its operation |
| `docs/LIBRARY_FILE_FORMAT.md` | Public wire envelope | Needs the identity and label sentences |

## Target design

### Label contract

`Declarations::LibraryAdapter` gains `display_label`, a required callable
`->(mapped_values) { "text" }`. Registration requires it callable and requires the wire schema's
`properties` to include `id` as a required non-null string. Built-ins return `mapped.fetch("name")`.

```ruby
# library/admission.rb
def label_for(adapter, mapped)
  label = adapter.display_label.call(DeepCopy.call(mapped))
  label.is_a?(String) && !label.strip.empty? ? label.strip : nil
rescue StandardError
  nil
end
```

Admission attaches `"display_label"` to each admitted row after the semantic check; a nil label
omits the row with a `library.row_label_invalid` warning (new code, declared in `FOUNDATION_CODES`
and the CONTRACTS table). `LibraryFile.parse` computes the same label for its sort and no longer reads
`name`; `FileProvider#merge` sorts by `[library_id, label.downcase, label, record_id]`. Provider-supplied
label fields are ignored and recomputed, so file and outside providers have one authority.

The local read callback's rows gain the same `display_label`, computed by the coordinator from each
row's `mapped` through the adapter; contributors do not supply it.

`Resolver.resolve(source:, mapped:, locals:, label:)` takes the incoming label explicitly; locals
carry theirs. The sequence is unchanged: exact source identity, then `ambiguous_source`, then
case-folded trimmed label equality, then mapped equality for `reuse` versus `review_required`,
`ambiguous_name` for several label matches, `create` for none. Candidates carry `display_label` instead
of `name`. The outcome word `ambiguous_name` stays in this correction; renaming it is a separate
contract cleanup.

`Schemas.resolution` candidates: `display_label` replaces `name`. The `html/library/adapters.js`
default `name` reads `row.display_label`; a row without one never reaches the UI, so no fallback is
needed. `copy.js` reads `row.display_label` for the title and `candidate.display_label`
in the selector. Feature adapters that format a richer label keep doing so for their own rows.

Identity stays `provider_kind, library_id, record_kind, record_id`. Fingerprints stay on the owner's
declared mapped fields; the label is not added to them, the source snapshot or the wire export.

### Material replacement through the owner operation

```ruby
# features/assemblies/materials/operations.rb
# `source` is the coordinator's provenance, never a value a client edits: the editable allowlist
# in Commands excludes it, and only the library replace callback supplies it.
def update(request, proposal, id:, values:, expected_values:, user_data: nil, source: nil)
  record = request.engine.find(MATERIAL_KIND, id)
  Commands.unique_name!(values["name"], Definitions.records(request, MATERIAL_KIND), :except => id) if values["name"]
  result = Commands.update_material(record, :values => values)
  changes = Definitions.changed_values(Schema::KIND, record, result.record)
  changes["source"] = DeepCopy.call(source) unless source.nil?
  request.engine.propose_update(MATERIAL_KIND, id, proposal, :values => changes,
                                                            :expected_values => expected_values, :user_data => user_data)
  { "id" => id }
end
```

The replace callback becomes: extract `source` from the validated params, call
`Materials::Operations.update(request, proposal, id:, values: values_without_source, expected_values:, source:)`.
The ordinary Material action never passes `source`; `MATERIAL_EDITABLE` is unchanged. Absence versus
null follows the existing `source` schema.

## Stages

### LC-01: adapter label declaration and admission

State: Implemented on branch.

Files: `shell/declarations.rb`, `shell/registry_validation.rb`, `shell/registry.rb` (`VALUE_MEMBERS`
entry for the adapter if RR-02 is in), `library/admission.rb`, `library/library_file.rb`,
`library/file_provider.rb`, the three built-in adapters (`features/assemblies/library_kind.rb`,
`features/windows/library_kinds.rb`, the Attached zone kind if it registers one),
`tools/examples/library_provider/`; tests `tests/library_registration_test.rb`,
`tests/library_admission_test.rb`, `tests/library_file_test.rb`, `tests/file_library_provider_test.rb`,
`tests/example_library_provider_test.rb`.

1. Add `display_label` to the adapter struct; validation requires it callable and requires wire `id`.
2. Built-ins supply `->(mapped) { mapped.fetch("name") }`.
3. Add `label_for`, the row field, the warning code, the file sort and the provider sort.
4. Add a synthetic name-free kind fixture under `tests/support/library_provider_fixtures.rb`: wire
   `id` plus `designation`, optional and null designations, equal labels with distinct ids, mixed
   case and whitespace.
5. Tests, one each: name-free kind registers; missing `display_label` and missing wire `id` refuse
   with a diagnostic naming the adapter; file and provider rows for the same input get the same
   label; nil, number, object and raising projections omit the row with the code and leave other
   rows usable; sort order is deterministic across folder merge and reload; equal labels with
   distinct ids all remain.
6. Focused suites above, `make lint-ruby`, `make fixtures` if discovery changes.

Exit: F05's `NoMethodError` cannot occur; tests pass.

### LC-02: resolution, schemas and the shared UI

State: Implemented on branch.

Files: `library/resolver.rb`, `library/coordinator.rb`, `library/schemas.rb`,
`html/library/adapters.js`, `copy.js`, `rows.js`, `drag.js`; tests `tests/library_resolver_test.rb`,
`tests/library_coordinator_test.rb`, `tests/library_copy_test.js`, `tests/library_store_test.js`,
`tests/library_sidebar_test.js`.

1. Resolver takes and reports labels; coordinator derives local labels; candidate schema migrates.
2. UI default `name` reads `display_label`; `copy.js` title and selector read it; grep for
   `values.name` under `html/library` afterwards must find only feature-specific adapters.
3. Tests, one each: source identity governs before label; one equal label with equal mapped values
   reuses; unequal mapped values require review; two equal labels are ambiguous; no label creates;
   a renamed label with the same source does not create a duplicate; the copy dialog shows the label
   and selector entries for a name-free kind; the sidebar sorts and searches by label.
4. `make fixtures` (API reference), `pnpm exec eslint`, JS suites, `make runtime-manifest`,
   `make runtime-check`.

Exit: a name-free kind lists, previews and copies end to end offline; no `values.name` read remains
in shared library UI.

### LC-03: Material replacement reuse

State: Implemented on branch.

Files: `features/assemblies/materials/operations.rb`, `library_kind.rb`; tests
`tests/material_library_kind_test.rb`, `tests/assembly_records_operations_test.rb`.

1. Add `source:` to `Materials::Operations.update`; the replace callback delegates.
2. Tests, one each: ordinary update and library replace with the same values produce the same
   changed fields apart from `source`; the ordinary action refuses `source` inside `values`
   (allowlist); replacement keeps `user_data`, an unavailable extension envelope and inbound
   Assembly references; `source` unchanged when not supplied.
3. Focused suites, `make lint-ruby`.

Exit: `library_kind.rb` `replace` holds no second persistence path.

### LC-04: outside walkthrough, docs, gates, native

State: Implemented on branch.

1. Extend `tools/examples/library_provider/` with the name-free kind end to end: list, preview,
   create, replace, assign, export, import into a fresh synthetic Model with typed references.
2. `docs/LIBRARY_FILE_FORMAT.md`: wire `id` required; label is a projection the adapter declares,
   not a wire field. `context/EXTENSIBILITY.md` "Library providers and kind adapters": the
   `display_label` member. `context/CONTRACTS.md`: the new code.
3. One stronger independent review; dual-Ruby `make ci`; `make coverage`.
4. Native, current host: copy and assign a Material from a file library, Undo, Redo; save, close,
   reopen with the provider removed, the local record intact and labelled.

Exit: both `make ci` runs pass; review has no open blocker; native receipt filed.

## Decisions and deviations

| Choice | Default | Alternative not taken |
| --- | --- | --- |
| Label policy | Adapter-declared `display_label` projection | Mandatory wire `name` on every kind: smaller, but imposes a storage word and contradicts the permissive registration promise. If Ed prefers it, LC-01 and LC-02 are rewritten together; do not mix |
| `ambiguous_name` outcome word | Kept | Renaming is a separate contract cleanup |
| New warning code | `library.row_label_invalid` | Reusing `library.row_semantic_invalid` would conflate two causes |
| Local record without a label (deviation, recorded at implementation) | Matches by source only; its candidate `display_label` is null and the copy dialog shows "Unlabelled" | Refusing the whole kind with `library.adapter_invalid` whenever one local record has no label: one hand-made record would block every copy of that kind. The incoming row still must have a label, since admission already required one |

The coding agent decides helper placement and names.

Escalate to Ed only if the mandatory-name alternative is preferred.

## Verification profile

High assurance for the public adapter and serialization seam: focused suites on both Rubies, the JS
suites, `make coverage`, one stronger review, dual-Ruby `make ci`, the LC-04 native receipt. See
[ACCEPTANCE.md](ACCEPTANCE.md).
