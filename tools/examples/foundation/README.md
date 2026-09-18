# Example feature: `example.foundation`

A complete feature built only from PH-Composer's public contracts, for contributors to read and copy.
It is development only: the shipping composition root does not list it and the RBZ builder refuses
any `examples` path.

## Files

| File | What it shows |
| --- | --- |
| `example_foundation.rb` | The feature: two record kinds, one structured extension, one query, four actions and one snapshot section, all declared in `install(registry)` |
| `load.rb` | The development composition entry, the only line outside the example's own files |
| `walkthrough.rb` | Two clients driving the feature through `PhComposer::API` with the panel closed |

The offline test is `tests/example_foundation_test.rb`.

## What a contributor writes

1. **Record kinds.** `Records::RecordKind` with fields declared as JSON Schema. SI numbers name
   their unit in the key and in `x-unit` (`length_mm`, `"x-unit": "mm"`). A `Records::Reference`
   names another kind; the engine checks the target exists and remaps it when a duplicated
   collection contains it.
2. **Extensions.** `Records::Extension` for versioned structured data on records: its reference
   paths, export relevance, copy rule, validator and migrations.
3. **Operations.** `feature.query(...) { |request| value }` reads. `feature.action(...) { |request,
   changes| value }` proposes record writes through `request.engine` into `changes` and returns a
   value. It never writes, opens an operation or shows a dialog: the dispatcher validates the
   proposal, opens one native Undo step and applies it, or writes nothing.
4. **Registration.** `install(registry)` declares everything under the feature's own namespace.
   The registry validates the declarations together and publishes nothing if any is wrong.

## Try it in a host

With PH-Composer installed and the development bridge running:

```sh
uv run tools/hostkit/host_bridge.py eval 'load "'$PWD'/tools/examples/foundation/load.rb"; ExampleWalkthrough.run'
```

The result lists each step, what happened and whether it matches the contract. The steps: create
two parts, read, update with expected values and metadata, read back, a second client refused on a
stale revision, a retry that returns the first outcome, a duplicate that remaps an internal
reference and keeps the shared definition, and a summary query.
