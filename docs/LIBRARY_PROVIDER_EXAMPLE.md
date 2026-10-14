# A separate library provider extension

The development example at `tools/examples/library_provider/` registers two synthetic Materials
and two synthetic tags from a separate SketchUp extension. It changes no PH-Composer source file. The values illustrate
the contract and are not product specifications.

Copy `bldgtyp_example_library.rb` and the sibling `bldgtyp_example_library/` directory into the
SketchUp Plugins directory. Enable PH-Composer first, then enable BLDGTYP Example Library. If the
example loads before PH-Composer has composed, it prints a diagnostic and registers nothing.
Enable it again after PH-Composer finishes, or call `BldgtypExampleLibrary.activate` in the Ruby
Console. A duplicate registration is refused.

The loader registers a `SketchupExtension`. Its install file declares a feature requiring the
library foundation and the Materials owner. The feature registers a provider
factory through `feature.library_provider`; the factory is called with the published registry,
which this example does not need. The provider exposes `id`, `provider_kind`, `label`,
`kinds`, `list(kind)` and `freshness`; it never receives a Model or writes a record. `list` returns
an immutable `PhComposer::Library::Provider::Batch` with complete wire rows. Each row carries
library identity, record identity, the wire schema version and a detached snapshot.

Wire fields are defined in [the file format](LIBRARY_FILE_FORMAT.md). The shared contract test in
`tests/support/library_provider_fixtures.rb` checks batch shape and immutability. The example's
tests also prove early-load diagnostics, atomic registration refusal, unsupported kinds and a
panel-closed copy followed by read-back on Ruby 2.7.2 and 3.2.2.

For the public API walkthrough, open a synthetic Model and close the panel. Load
`tools/examples/library_provider/walkthrough.rb`, then run:

```ruby
proof = BldgtypExampleLibraryWalkthrough.run
raise "Example failed" unless proof.fetch("passed")
```

The script connects to the active discovered session with explicit grants, loads and lists the
provider, previews a copy, applies that proposal with its revision and digest, then reads the
local Material through the public API. It reuses an unchanged prior copy. A conflicting local
record requires review before the script proceeds. No file path is part of the provider's
identity or the returned proof.

The tags show a library kind whose records have no `name`. The example declares its own tag record
kind, a designation and a height, and a tag holder that names one tag by typed reference. Its kind
adapter declares `display_label`, the designation, which the library lists, sorts and resolves by.
Run `BldgtypExampleLibraryWalkthrough.tags` on a fresh synthetic Model: it lists the tags, copies
one while assigning it to a new holder, then replaces it from a changed provider edition after
review. The example's tests also export the tag to a library file and copy it into a fresh Model
with its holder reference.

Native installation and copying are separate acceptance checks. The example is currently kept
under development tools; its standalone repository and publication are pending.
