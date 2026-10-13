# Example feature: `example.foundation`

A complete feature built only from PH-Composer's public contracts, for contributors to read and copy.
It is development only: the shipping composition root does not list it and the RBZ builder refuses
any `examples` path.

## Files

| File | What it shows |
| --- | --- |
| `example_foundation.rb` | The feature: two record kinds, one structured extension, one query, four actions, one snapshot section and two export contributors, all declared in `install(registry)` |
| `example_translation.py` | The feature's translation sections: definitions, and parts that require definitions by durable id |
| `example_doors.py` | An attaching translation section: Doors that join the Faces another feature translates, with no edit to that feature (`tests/python/test_example_doors.py`) |
| `load.rb` | The development composition entry: registers the feature and hands the editor to the panel |
| `walkthrough.rb` | Two clients driving the feature through `PhComposer::API` with the panel closed |
| `editor.js` | The synthetic editor: a panel section for the parts, built from the shared unit field, record form and request channel |

The offline tests are `tests/example_foundation_test.rb`, `tests/example_editor_test.js`,
`tests/export_test.rb` and `tests/python/test_example_translation.py`; the browser preview
(`tools/ui-preview/`) loads the editor too. `tests/fixtures/foundation/{extraction,result}.json`
is one extraction the export contributors produce and the result the sections translate it to.

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
   proposal, opens one native Undo step and applies it, or writes nothing. Each names `refuses:`,
   the codes it can refuse with beyond its kind's common set; the engine's codes count, since they
   reach the caller unchanged.
4. **Registration.** `install(registry)` declares everything under the feature's own namespace.
   The registry validates the declarations together and publishes nothing if any is wrong.
5. **A panel section.** `PhComposerUI.get("panel").section(name, render)` mounts a section in a
   pane. `render(root, state, send)` reads the feature's snapshot section through `snapshot.js` and
   sends edits through a `request.js` channel; the panel supplies the session and the revision it
   showed, and shows a refusal as a warning. Unit-bearing values go through `unit_field.js`, which
   keeps SI in storage and follows the display preference. A shipping feature declares its section
   as a module in `html/`; this development editor is a plain script the panel runs after the kit
   starts.
6. **Export.** `feature.export_contributor(name, section_version:, result:, report:) { |reader|
   records }` adds a section to the export extraction. The block reads through `reader.records(kind,
   extensions: { namespace => fields })`, which exports declared values and the named extension
   fields only, leaves `user_data` out with a finding, and blocks on data it cannot safely leave
   out. `result` declares the result fields the translation adds, which the privacy check then
   admits; `report` renders them. The matching Python `Section` (`example_translation.py`) reads
   the section one record at a time and declares the other sections it requires with a typed
   `Requirement`; a build lists it in `python/ph_composer_translation/composition.py`.

## Keyboard and lifecycle in the editor

The New part dialog shows who owns what in a form built from the kit.

- **Field commit versus form submit.** The length `UnitField` owns its draft: it parses, keeps an
  invalid entry with its message, and on Enter commits and swallows the key. The form owns submit.
  So the form takes Enter while the event travels down to the length input, with a capture listener
  on the form, and calls the one `submit` the Create button and Enter in the label also reach.
  `submit` parses the length and checks the label; an invalid draft sends nothing and stays on
  screen until it is corrected or cancelled. The Assembly builder's dimension fields are the
  shipping precedent.
- **Pending.** `RecordForm.run` allows one request in flight, so a repeated Enter or Create sends
  nothing more; the result settles once and a completed create closes the dialog.
- **Withdraw versus dispose.** `withdraw` forgets the pending request and closes the dialog; the
  form stays usable. `dispose` is permanent and runs when the panel shows another Model: the form
  withdraws, removes its Enter route and disposes the length field it built, which ends that
  field's unit-preference subscription. Afterwards its `submit`, `run` and `show` do nothing, and
  the header button opens only the form it was painted with. A form disposes the children it built.

## Try it in a host

With PH-Composer installed and the development bridge running:

```sh
uv run tools/hostkit/host_bridge.py eval \
  'load "/absolute/path/to/ph-composer/tools/examples/foundation/load.rb"; ExampleWalkthrough.run'
```

The result lists each step, what happened and whether it matches the contract. The steps: create
two parts, read, update with expected values and metadata, read back, a second client refused on a
stale revision, a retry that returns the first outcome, a duplicate that remaps an internal
reference and keeps the shared definition, and a summary query.
