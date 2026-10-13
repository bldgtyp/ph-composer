# Registration reliability acceptance

DATE: 2026-10-13
STATUS: Planned cases; none run.
PLAN: [PLAN.md](PLAN.md)

Case ids are kept from the first draft so cross-references stay valid. Rows the simplified design
makes moot are listed as withdrawn at the end. Every fixture is synthetic. A receipt records the
source SHA, the Ruby, the command and the observations.

Shared assertion for every refusal: capture the published feature ids, the owner map, one discovery
result, `Dictionaries.names` and the set of live host subscribers before the attempt; afterwards
assert all equal, no new capability callable, no ownerless kind, and one more event delivered to
nobody new. Invoke retained readers rather than comparing Hash equality alone.

## Successful installation

| Case | Stimulus | Required observation |
| --- | --- | --- |
| RR-A01 | Compose the foundation and built-ins | Maps and owners complete; discovery goldens unchanged; no Model write or Undo entry |
| RR-A02 | Install an outside synthetic feature after the built-ins | Same `install` calls; kinds, queries, actions, snapshot, extension and export declarations published; a dispatcher created earlier runs the new action |
| RR-A03 | `record_descriptor` of a same-batch kind, then of an installed one | Shape reused; provider's declaration unchanged |
| RR-A04 | Conforming duck-typed store with a permitted dictionary | Accepted without calling `ids`, `read`, `write`, `delete`; later create, read, edit, delete use it |
| RR-A05 | Attached zone legacy `DictionaryStore` | Registers and round-trips unchanged |
| RR-A06 | Registered core references and structured payload | Copy, remap and incoming-reference refusal use the published declarations |
| RR-A07 | Several feature subscriptions and one direct `Sessions.on_host_event` subscriber | Each receives each event once, in install order |
| RR-A08 | Empty batch; then a second valid batch | No duplicate subscriptions; old readers see the new entries |

## Refusal and diagnostics

| Case | Refused input | Required observation |
| --- | --- | --- |
| RR-A09 | Dictionary outside the prefix, bare prefix, nil, number, empty; getter raises | `registration.schema_invalid` names the kind and `dictionary`; adapter methods never called |
| RR-A10 | Store missing each of `dictionary`, `ids`, `read`, `write`, `delete` | Diagnostic names the missing method |
| RR-A11 | Malformed field, reference, identity or version; non-callable validator | Named diagnostic; nothing published |
| RR-A12 | Duplicate id, missing dependency, cycle, wrong major, bad schema, example or refusal | Existing diagnostics retained; whole batch refused |
| RR-A13 | Two features, second has a bad kind | Neither publishes; prior registrations unchanged |
| RR-A14 | Bad subscription kind beside valid declarations | Whole batch refused; no callback attached |
| RR-A15 | `install` raises after declaring | Named diagnostic; nothing registry-owned published; the receipt states that the callback's own side effects are outside the guarantee |
| RR-A17 | `Registry.install` or `reset` called from a store getter during validation | `InternalError`; baseline unchanged; a later valid install succeeds |

## Value ownership

Install from mutable builders, mutate the originals, assert the published behaviour is unchanged
and that writing through the published object raises `FrozenError`.

| Case | Mutated after publication | Stable behaviour |
| --- | --- | --- |
| RR-A18 | Field schema `minimum`, `enum`, key, required; fields array | `problems` and discovery unchanged; contributor's own objects not frozen by install |
| RR-A19 | Reference key, target kind, cardinality; retained reference arrays | Incoming-reference refusal and copy remap unchanged |
| RR-A20 | Kind id, label, prefix; descriptor schemas | Lookup, identity validation, occurrence discovery unchanged |
| RR-A21 | Feature id and requires; operation strings, schemas, examples, refuses | Discovery and dispatch unchanged |
| RR-A22 | Snapshot params; export result, user_data_keys, requires | Snapshot and privacy contract unchanged |
| RR-A23 | Extension references, relevance, migration map | Status, copy and version decisions unchanged; migrations callable and not invoked by publish |
| RR-A24 | Library adapter schemas, fingerprint fields, callback schemas and refusals | Discovery and copy validation unchanged |
| RR-A25 | Colour mode, menu item, code, retargeter, participant and subscription strings | Values and owners unchanged |
| RR-A27 | `view_schema`, `patch_schema`, `to_h`, `API.describe` results | Editable detached copies; next read unchanged |
| RR-A28 | A handler's closure counter; a custom store's runtime state | Still mutable and working: behaviour objects are not frozen |

## Lifecycle

| Case | Event | Required observation |
| --- | --- | --- |
| RR-A34 | Dispose a direct subscriber after a later batch published | Only that subscriber removed; others and order intact |
| RR-A35 | Dispose twice; then `Registry.reset` | Idempotent; registry-owned subscribers removed once |
| RR-A36 | Reinstall an installed feature with a subscription | Duplicate diagnostic; existing callback still fires once |
| RR-A37 | A subscriber raises at runtime | Existing propagation retained; the contribution is not removed |
| RR-A38 | Bad compose at fresh start versus bad additive install | Compose fails loudly as today; additive keeps prior state; no last-good promise added |
| RR-A39 | Query, snapshot and export contributor collections after an additive install | Complete next state visible through the same registry object |

## Outside contributor

| Case | Walkthrough | Required observation |
| --- | --- | --- |
| RR-A40 | Register, discover, read, preview, invoke, read back, Undo, Redo | Same contracts as built-ins; one Undo unit |
| RR-A41 | Mutate retained builders, repeat discover, preview, invoke | Admitted values govern |
| RR-A42 | Malformed second contribution, then use the first | Named diagnostics; first usable; no leaked dictionary or event |
| RR-A43 | Guarded `load.rb` repeat; unguarded duplicate install | Guarded adds nothing; duplicate refused; one event delivery |

## Gates

```sh
make lint-ruby
"$RUBY" -Itests -rregistry_test -rsessions_test -rrecords_engine_test -rfeature_composition_test \
        -rentity_descriptor_test -rlibrary_registration_test -e ''
make coverage
make ci
make ci RUBY="$(rbenv prefix 2.7.2)/bin/ruby"
```

Native smoke (RR-H01): fresh current host, compose, outside example load with the panel closed, one
selection change delivered once, guarded reload, still once. Record host version, source head and
RBZ hash. SketchUp 2023 and Windows gates stay with their own packets.

## Withdrawn

| Case | Reason |
| --- | --- |
| RR-A16 | Cyclic-container diagnostics dropped as pathological; see the plan's deviations |
| RR-A26 | Registry maps stay live Hashes; declaration immutability is RR-A18 to RR-A25 |
| RR-A29 to RR-A33 | Fault injection between reference replacements: there are no replacements. `commit` performs only assignments after validation, so there is no intermediate state to restore. RR-A17 covers the one remaining reentrancy fault |
| RR-H02 to RR-H04 | The subscription mechanism is unchanged; the native smoke RR-H01 is sufficient. Model switch and Undo lifecycle remain covered by the existing session tests and their host evidence |
