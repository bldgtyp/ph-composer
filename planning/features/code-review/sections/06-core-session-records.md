# 06 Core, session and records: parsing untrusted Model data

Files: `src/ph_composer/core/{json_schema,json_value,json_walk,canonical_json,deep_copy,coerce,dictionaries,model_settings,build_identity}.rb`,
`core/records/{dictionary_store,entity_store,engine,metadata,extension,identity}.rb`,
`session/{caller_registry,outcome_store,sessions,model_session}.rb`.

## Parsing

Records are JSON strings in SketchUp attribute dictionaries. `DictionaryStore.read` and
`GeometrySnapshot::Entry#record` call `JSON.parse` with defaults: `create_additions` is off, so a
`json_class` key creates nothing, and nesting is capped at 100, which raises a `ParserError`
subclass the engine reports as `record.unreadable`. Every kind validates the parsed record against
its declared schema before use; an invalid record is refused, never repaired.

`DeepCopy` is a structural walk (`JsonWalk.map`) and the comment says why: stored payloads are
untrusted and a copy must never run code. `Marshal` does not appear in the shipping tree.

`JsonValue.problems` refuses non-string keys, non-finite floats, non-UTF-8 strings, cycles and any
non-JSON object. It runs on every params object at dispatch and on `user_data` and extension payloads
before they are written. `JsonSchema` implements a closed keyword subset; `pattern` must be anchored
`^...$` with no inner line anchors and is compiled to `\A(?:...)\z`, so a declared pattern cannot
be made to match a line of a multi-line string.

`Coerce` uses `Integer()` and `Float()` and raises `UserError` on anything else; no `eval` of typed
numbers anywhere.

## Extension data

`Records::Extension` keeps an envelope's declared references and relevance on the record so they
survive an uninstalled extension, and `status` answers `understood`, `invalid`, `outdated`,
`unsupported` or `unavailable` without ever running a payload. Validators are the installed
extension's, run inside `rescue StandardError` so a raising validator counts as a finding. `remap`
and `referenced_ids` walk only declared `$.` paths. Copy rules refuse any envelope that is not
understood with a remap policy.

## Metadata writes

`Metadata.updated` replaces `user_data` whole after `JsonValue` checks it; `check_expected!` makes
every metadata action a compare-and-set against what the caller read. There is no size cap on
`user_data` beyond what the SKP and `JsonValue` accept: a very large map bloats the Model, which is
the user's own file and excluded as resource exhaustion.

## Sessions and callers

`CallerRegistry.issue` returns a 128-bit random handle with a frozen capability copy; handles end
with the session and are remembered after revocation so a late call is refused by reason. The
`OutcomeStore` keeps at most 256 entries for 15 minutes, each a deep copy, so a caller editing a
returned outcome cannot change what a retry receives. The session id is a UUID and the revision a
plain counter; neither is secret, and a cursor from `Pages` is bound to session, query, filter digest
and revision so it cannot be replayed across any of them (a forged cursor can only choose a start key
within the same query).

## Build identity

`BuildIdentity` reads `build.json` from the extension folder and accepts only a 12-hex build and a
commit matching `[0-9a-f]{7,40}(-dirty)?`; anything else reads as `unavailable`. It is reported, not
enforced (F09).
