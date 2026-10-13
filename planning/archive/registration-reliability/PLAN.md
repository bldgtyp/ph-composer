# Registration reliability plan

DATE: 2026-10-13
STATUS: Complete; merged to main 2026-10-13 in [PR #105](https://github.com/bldgtyp/ph-composer/pull/105) as `1ee60a7`, delivery group 2. Stage ledger in [STATUS.md](STATUS.md).
ISSUE: [#103](https://github.com/bldgtyp/ph-composer/issues/103)
BASELINE: `cfe01a6aad99a0e09d5ecf0de5659c606d7ba4f9`
FINDINGS: [F01](../../code-review/sections/01-foundation.md#f01-registration-can-fail-after-publishing-part-of-the-batch), [F02](../../code-review/sections/01-foundation.md#f02-published-record-field-schemas-remain-mutable-aliases)
DEPENDS ON: nothing. [Cross-feature composition](../cross-feature-composition/PLAN.md) and every packet
that adds a declaration family build on RR-02's ownership rule.

## Goal

An outside feature installs through the same `install(registry)` as the built-ins. A valid batch
becomes available whole; an invalid declaration publishes nothing of the batch. Once published, a
declaration's values cannot change through the contributor's retained builders or through anything a
reader gets back from the registry. Persistence names, record ids, schema versions and action
behaviour do not change in this packet.

## Verified at the baseline

| Where | What it does now | Consequence |
| --- | --- | --- |
| `shell/registry.rb`, `Registry.install` | `stage`, then `raise RegistrationError` on diagnostics, then `publish` | Correct shape; the defect is inside `publish` |
| `shell/registry.rb`, `Registry#publish` | Assigns features, operations, queries, actions, view/setup commands, file exports and record kinds into the live maps, then calls `Dictionaries.register(kind.store.dictionary)` per kind, then the remaining families, owners and subscriptions | `Dictionaries.register` raises `ArgumentError` for a name outside `ph_composer.`; everything assigned before it stays published with no owner |
| `core/dictionaries.rb`, `Dictionaries.register` | Prefix check raises; appends to a module-level array | The only raising call in `publish`; its check belongs in validation |
| `shell/registry_validation.rb`, `Validation#check_record_kinds` | Checks `values_schema` problems and references | Nothing checks the store: `dictionary`, `ids`, `read`, `write`, `delete` |
| `shell/registry_validation.rb`, `check_subscriptions` | Requires a known `Sessions::HOST_EVENTS` kind and a callable | `Sessions.on_host_event` therefore cannot raise at publish; subscriptions need no new machinery |
| `session/sessions.rb`, `on_host_event` | Appends to the persistent per-kind array in `host_event_subscribers`; returns `-> { subscribers.delete(block) }` | The disposer closes over an array that is never replaced; it is already stable. The earlier plan's token scheme solved a problem the fix must not create |
| `shell/registry.rb`, `freeze_operation`, `freeze_library_provider`, `freeze_library_kind` | Deep-freeze copies of schemas, examples and refusals and freeze the structs at publish | The ownership policy exists for three families and is missing for the rest |
| `core/records/record_kind.rb`, `RecordKind#initialize` | `@fields = fields.freeze`; keeps the contributor's `Field` structs and their schema Hashes | Editing a retained schema Hash changes `problems` and `values_schema` for the published kind (F02 probe) |
| `core/records/descriptor.rb` | Retains `values_schema` and `occurrence_schema` as given; `view_schema`, `patch_schema`, `to_h` return `DeepCopy.call` results | Published descriptors alias the contributor's Hashes; the detached read results are already right |
| `core/records/extension.rb`, `Extension#initialize` | `references.map { DeepCopy.string_keys }.freeze`; `migrations.freeze` | Outer containers frozen, inner Hashes shared with the contributor |
| `shell/registry.rb`, `FeatureScope#export_contributor` | `DeepCopy.call(result).freeze`, same for `user_data_keys` and `requires` | Shallow freeze: nested Hashes stay mutable |
| `shell/registry.rb`, `FeatureScope#snapshot_section`, `colour_mode`, `menu_item`, `code`, `reference_retargeter`, `proposal_participant` | Store the given strings and params as given | No copy, no freeze |
| `shell/registry.rb`, `Registry#stage` | Rescues a throwing `install` into a `registration.schema_invalid` diagnostic | A throwing install already publishes nothing registry-owned |
| `tests/registry_test.rb`, lines 77, 92 and 229 | `instance_variable_get(:@staging)` and mutate a staged declaration to make it invalid | Freezing must happen in `publish`, after validation; staged declarations stay mutable |
| `tests/assembly_assignment_registration_test.rb`, lines 44 and 62 | `Registry.current.queries[name] = replacement` to swap a handler | The one test that writes a live map directly; the earlier plan attributed this to `registry_test.rb` |
| Readers of registry maps (`shell/api.rb`, `dispatch.rb`, `handler_request.rb`, `library/*`, `export/*`, `colour_by/*`) | Call `registry.actions[name]`, `.fetch`, `.values` on each use | Nobody captures a map; additive install into the same Hash is visible to every reader |
| `tools/examples/foundation/example_foundation.rb` and `load.rb` | A complete outside feature installed through `Registry.install` behind `installed?` | The walkthrough fixture RR-03 extends |

The review probes in `../../code-review/evidence/foundation_probes.rb` reproduce F01 and F02.

## Target design

Three rules, each small.

**Validate the store, then publish without anything that can raise.** `Validation#check_record_kinds`
gains a store check. `Registry#publish` splits into a pure `prepare` that builds every frozen
declaration and the dictionary and subscription lists, and a `commit` that only assigns into the live
maps, appends to `Dictionaries` and calls `Sessions.on_host_event`. An exception inside `prepare` is an
`InternalError` naming the stage; nothing has been written. After validation the only operations in
`commit` are Hash assignment, Array append and a subscription whose kind validation admitted.

```ruby
# core/dictionaries.rb
def self.valid_name?(name)
  name.is_a?(String) && name.start_with?("#{DICTIONARY_PREFIX}.") && name.length > DICTIONARY_PREFIX.length + 1
end

def self.register(name)
  raise ArgumentError, "Dictionary #{name} must start with #{DICTIONARY_PREFIX}." unless valid_name?(name)
  # unchanged
end
```

```ruby
# shell/registry_validation.rb, inside check_record_kinds
STORE_METHODS = %i[dictionary ids read write delete].freeze

def check_store(owner, kind)
  store = kind.store
  missing = STORE_METHODS.reject { |method| store.respond_to?(method) }
  unless missing.empty?
    return add("registration.schema_invalid", owner, kind.id,
               "#{kind.id} store must answer #{missing.join(', ')}.")
  end

  name = begin
    store.dictionary
  rescue StandardError => error
    return add("registration.schema_invalid", owner, kind.id, "#{kind.id} store dictionary raised #{error.class}.")
  end
  return if Dictionaries.valid_name?(name)

  add("registration.schema_invalid", owner, kind.id,
      "#{kind.id} store dictionary #{name.inspect} must be a string starting with #{DICTIONARY_PREFIX}.")
end
```

The getter is read once at validation. Arity is not inspected; `ids`, `read`, `write` and `delete`
are never called at install. The default `ph_composer.records.<kind id>` suffix is not enforced: the
Attached zone store uses its legacy name on purpose, and shared dictionary use stays allowed.

```ruby
# shell/registry.rb
def publish(staging)
  prepared = prepare(staging)      # every frozen declaration, dictionary name and subscription; no live write
  commit(prepared)                 # assignments and appends only
  self
end
```

A reentrancy guard, `@installing`, makes `Registry.install` raise `InternalError` when called while
another install is staging or publishing, and is cleared in `ensure`.

**Own every declaration's values at publish.** One table in `Registry` names the value members of
each declaration struct; `prepare` deep-freezes copies of those members and freezes the struct.
Behaviour members (handlers, validators, factories, stores, locators, projections) are retained by
identity and never copied or frozen.

```ruby
VALUE_MEMBERS = {
  Declarations::Feature => %i[id requires],
  Declarations::Query => %i[name owner description params result examples refuses],
  Declarations::Action => %i[name owner description params result examples refuses undo_name side_effects confirmation],
  Declarations::ViewCommand => %i[name owner description params result examples refuses],
  Declarations::SetupCommand => %i[name owner description params result examples refuses],
  Declarations::FileExport => %i[name owner description params result examples refuses],
  Declarations::SnapshotSection => %i[name owner query params],
  Declarations::ExportContributor => %i[name owner section_version result preflight user_data_keys requires],
  Declarations::ColourMode => %i[name owner label entity_kind group],
  Declarations::MenuItem => %i[name owner label menu separator_after],
  Declarations::ReferenceRetargeter => %i[name owner target_kind],
  Declarations::ProposalParticipant => %i[name owner],
  Declarations::LibraryProvider => %i[name owner contract_version kinds],
  Declarations::LibraryKind => %i[name owner contract_version record_kind],
  Declarations::HostEventSubscription => %i[owner kind],
  Declarations::Code => %i[code owner description]
}.freeze

def own(declaration)
  VALUE_MEMBERS.fetch(declaration.class).each do |member|
    declaration[member] = DeepCopy.frozen(declaration[member]) unless declaration[member].nil?
  end
  declaration.freeze
end
```

`FeatureScope#code` already freezes its `Code` struct at declaration, so `own` returns a struct that
is already frozen unchanged (its members are literal strings; freeze them in the scope instead).
`Declarations::Approval` inside a setup command or file export is frozen through `to_h` round trip or
a dedicated branch; `LibraryAdapter` and `LibraryCallback` keep the existing `freeze_library_kind`
treatment, folded into the same table. A member whose value is not JSON-shaped (a Symbol host-event
kind, an Integer version, a `true`) passes through `DeepCopy.frozen` unchanged; `JsonWalk` already
leaves such leaves alone.

The three `core/records` classes that contributors construct outside staging detach their own values
at construction, because the registry never sees the contributor's `Field` objects separately from the
kind:

```ruby
# core/records/record_kind.rb
def initialize(id:, label:, schema_version:, id_prefix:, fields:, validate: nil, store: nil, references: [])
  @id = id.dup.freeze
  @label = label.dup.freeze
  @id_prefix = id_prefix.dup.freeze
  @fields = fields.map { |field| Fields.detached(field) }.freeze
  @nested_references = references.map { |reference| Fields.detached(reference) }.freeze
  # ...
end

# core/records/fields.rb
module Fields
  # A frozen copy of a declared Field or Reference whose schema and strings are the kind's own.
  def self.detached(declaration)
    copy = declaration.class.new(**declaration.to_h.transform_values { |value| DeepCopy.frozen(value) })
    copy.freeze
  end
end
```

`Descriptor#initialize` does the same for `values_schema`, `occurrence_schema` and its references.
`Extension#initialize` replaces `.freeze` on references with `DeepCopy.frozen` after `string_keys`,
and freezes `namespace` and `export_relevance`. `migrations` stays a frozen Hash of callables.

`ChangeSet`, `Proposal`, `ReferencePlan` occurrence data and stored records are not declarations and
stay mutable under their own contracts. `view_schema`, `patch_schema`, `to_h` and discovery JSON keep
returning mutable detached copies.

**Keep the maps live.** `Registry`'s maps remain ordinary Hashes behind the existing readers. Readers
see additive installs because they index the same Hash on each use. Freezing the maps is not needed
for F01 or F02 and would break the one test that swaps a handler; that test is rewritten (below) but
map freezing is recorded as a deviation from the earlier plan, not adopted.

## Stages

### RR-01: store admission and a publish that cannot raise

State: Scoped.

Files: `core/dictionaries.rb`, `shell/registry_validation.rb`, `shell/registry.rb`;
tests in `tests/registry_test.rb`, `tests/records_engine_test.rb` (if it holds dictionary tests) and
`tests/sessions_test.rb`.

1. Add `Dictionaries.valid_name?` and make `register` use it.
2. Add `check_store` to `Validation` and call it from `check_record_kinds` for every staged kind.
3. Split `Registry#publish` into `prepare` and `commit` as above. `prepare` builds: the frozen
   declarations (reuse the existing three freeze methods for now; RR-02 widens them), the list of
   admitted dictionary names, the owner map additions and the subscription list. `commit` assigns.
   `Dictionaries.register` is called in `commit` only for names `prepare` admitted.
4. Add the `@installing` guard in `Registry.install` with `ensure` clearing it; `reset` refuses while
   installing.
5. Tests, one per behaviour, in `tests/registry_test.rb`:
   - a kind whose store has every method and a dictionary outside the prefix: `RegistrationError`
     naming the kind and `dictionary`; `installed?` false; no query, kind, owner or dictionary name
     published; the store's `ids`, `read`, `write`, `delete` were never called (count them);
   - a conforming store missing each of the five methods in turn: a diagnostic naming the method;
   - a getter that raises: a diagnostic naming the kind, no exception escapes as `ArgumentError`;
   - the Attached zone's legacy dictionary name still registers (existing fixture);
   - a batch of two features where the second kind is bad: nothing of either feature publishes;
     a dispatcher created before the attempt still runs an existing action;
   - a batch with a valid subscription and a bad kind: the subscriber receives no later event;
   - a store getter that calls `Registry.install` during validation: `InternalError`, baseline
     unchanged, a following valid install succeeds;
   - the F01 probe scenario from `../../code-review/evidence/foundation_probes.rb`, inverted to assert refusal.
6. Run `make lint-ruby` and
   `"$RUBY" -Itests -rregistry_test -rsessions_test -rrecords_engine_test -rfeature_composition_test -e ''`.

Exit: the tests above pass; every existing registry, session and composition test passes unchanged.

### RR-02: owned declaration values

State: Scoped.

Files: `shell/registry.rb` (`VALUE_MEMBERS`, `own`), `core/records/fields.rb`, `record_kind.rb`,
`descriptor.rb`, `reference_target.rb`, `extension.rb`; tests in `tests/registry_test.rb`,
`tests/entity_descriptor_test.rb`, `tests/records_engine_test.rb`, `tests/library_registration_test.rb`.

1. Add `Fields.detached`; detach at construction in `RecordKind`, `Descriptor`, `ReferenceTarget`
   (label) and `Extension` as above.
2. Add `VALUE_MEMBERS` and `own`; `prepare` applies `own` to every staged declaration, replacing the
   three existing freeze methods. Keep `LibraryAdapter`/`LibraryCallback` handling by adding their
   value members to the table and copying the adapter struct as `freeze_library_kind` does today.
3. Fix the shallow freezes in `FeatureScope#export_contributor` by letting `own` do the work; the
   scope stores what it is given.
4. Rewrite `tests/assembly_assignment_registration_test.rb` lines 44 and 62 to install a stand-in
   feature whose query returns the failure, or to inject the failure below the registry (for example
   by stubbing the store the query reads). The live map write goes.
5. Tests, one per behaviour. Each builds a declaration from deliberately mutable nested values,
   installs, mutates the original, then asserts the published behaviour is unchanged and that a
   mutation through the published object raises `FrozenError`:
   - a `Field` schema's `minimum` and an `enum` member (the F02 probe, inverted);
   - a `Reference` key and target kind, top level and nested through `references:`;
   - `RecordKind` id, label and prefix; `Descriptor` values and occurrence schemas;
   - operation name, description, params, examples, refuses, undo name, side effects;
   - snapshot section params; export contributor result, user_data_keys and requires (nested);
   - extension references and export relevance; migrations remain callable and are not invoked;
   - library adapter wire schema, mapped schema, fingerprint fields and a callback's params;
   - colour mode, menu item, code, retargeter, participant and subscription strings;
   - `view_schema`, `patch_schema`, `to_h` and `API.describe` results are editable without affecting
     the next read;
   - a handler closing over a mutable counter still increments, and a custom store keeps its runtime
     state: the negative control that says behaviour objects are not frozen;
   - the contributor's own `Field` and schema objects are not frozen by installation.
6. Run the RR-01 command plus `-rentity_descriptor_test -rlibrary_registration_test`, then
   `make coverage`.

Exit: the mutation tests pass; `make fixtures-check` passes (discovery output must not change);
coverage thresholds hold.

### RR-03: outside walkthrough, canon and gates

State: Scoped.

Files: `tools/examples/foundation/walkthrough.rb` and `README.md`; `context/CONTRACTS.md`
"Registration"; `context/EXTENSIBILITY.md` where registration is described.

1. Extend the walkthrough with: a conforming custom store (not `DictionaryStore`) on one kind,
   nested references, and a mutable builder the walkthrough edits after install to show the
   published contract holds. Add a refused second contribution with a bad store and show the first
   contribution still works through the same `API`.
2. Add to `context/CONTRACTS.md` "Registration": store admission (five methods, `ph_composer.`
   prefix, getter read once), the no-raise publish order, the ownership rule (values copied and
   frozen, behaviour retained), and the limit that a throwing `install`'s own side effects outside the
   registry are not undone. One paragraph each.
3. Point the EXTENSIBILITY registration text at that section; add the "do not mutate your builders
   after install, it changes nothing" sentence for contributors.
4. Gates: `make ci` on the selected Ruby and `make ci RUBY="$(rbenv prefix 2.7.2)/bin/ruby"`;
   `make coverage`; one stronger independent review of the coherent RR-01 to RR-03 diff with the
   architecture rubric.
5. Native smoke, current host, bridge plus native controls: fresh launch, built-in compose, closed
   panel outside example load through `load.rb`, one selection change delivered to the example's
   subscriber once, repeat the guarded load, one event still once. Record host, source head and RBZ
   hash. The subscription mechanism is unchanged, so this is a smoke check, not a lifecycle campaign.

Exit: both `make ci` runs pass; the review has no open blocker; the smoke receipt is filed in the
packet; STATUS rows updated.

## Decisions and deviations

Deviations from the first draft, accepted by Ed on 2026-10-13:

| Earlier default | Now | Reason |
| --- | --- | --- |
| Prepare three framework-owned references and swap them atomically with a restoration coordinator | Validate everything first; `commit` performs only assignments and appends | After validation no call in `commit` can raise, so there is nothing to restore. Smaller surface, same guarantee |
| Stable disposal tokens for host subscriptions | Keep `Sessions.on_host_event` and its array-closing disposer | The per-kind array is never replaced; the disposer is already stable. Tokens would solve a problem only the swap design creates |
| Frozen public registry maps | Maps stay live Hashes | Readers index on each use and see additive installs; F02 is about declaration values. One test that writes a map is rewritten |
| Cyclic-container diagnostics (RR-A16) | Not attempted | A cyclic Ruby Hash as a JSON schema is pathological; `JsonWalk` recursion would surface in validation. Optional later |

The coding agent decides: method names (`prepare`, `commit`, `own`, `detached`, `valid_name?`), where
`VALUE_MEMBERS` lives, and test names.

Escalate to Ed if: a built-in declaration turns out to depend on mutating a published value (none
is known); a store must be copied to keep behaviour; or a callback must run during `commit`.

## Verification profile

High assurance for this public boundary: the focused suites above on both Rubies, `make coverage`,
one stronger independent review, `make ci` twice, and the native smoke in RR-03. The
[acceptance matrix](ACCEPTANCE.md) keeps the original case ids; rows the simplification makes moot
are marked withdrawn there rather than renumbered.
