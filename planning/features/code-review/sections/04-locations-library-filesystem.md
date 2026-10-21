# 04 Locations, the library provider and the filesystem

Files: `src/ph_composer/shell/{approved_locations,location_commands}.rb`,
`library/{file_provider,library_file,file_writer,setup,setup_commands,export_workflow,export_projection,admission,catalog,coordinator,provider,state,callback_invoker}.rb`.

## Where paths come from

Three sources only: a native dialog (`UI.openpanel`, `UI.select_directory`, `UI.savepanel`), an
approved location the user chose in one of those dialogs earlier, or a library configuration the
user added through one of them. No public operation takes a path in params; registration adds a
`location` object with an id to every operation that declares an approval, and `NativeApproval.admit`
resolves it and strips it before the handler runs.

## Approved locations

The store is base64 JSON in SketchUp's defaults, read on every call, 256 KiB cap, 100 tombstones.
Rows validate on read with an exact key set, a minted id pattern and non-empty strings; an invalid
store is reported unreadable and refuses writes until the user resets it in the Libraries dialog.
Public rows are `id, kind, label, use, approved_at, last_used_at, available`: a label defaults to a
generic noun and a number, never the file name.

`grant` refuses `replace: true` without `expected_destination`, for every handler, so consent is
always to a reviewed state. `consuming` retires a single-use location before the operation runs and
puts it back only if the operation raises; a reusable one records the use afterwards, best effort.
`available?` checks the kind's expectation on disk (`File.file?`, `File.directory?`, or a parent
directory plus a regular file or nothing). The export task re-resolves the location immediately
before writing and compares expanded paths (`still_permitted?`).

Any caller holding the grant may use any approved location (D3a1-05). Recorded in FINDINGS as
accepted.

## Library files and folders

`FileProvider#candidate_files` reads one file, or the immediate children of one folder with a
`.json` extension that are regular files (`File.file?`, which follows symlinks; F11). No recursion.
`read_documents` checks every size against 32 MiB and the sum against 64 MiB before reading, reads at
most 32 MiB plus one byte per file, and refuses the aggregate again as bytes accumulate. In a folder,
a malformed file costs only itself and becomes a warning by code; in a single file it refuses.

`LibraryFile.parse` uses `JSON.parse` with defaults (nesting 100, no `create_additions`), checks the
envelope's format, schema version, library id and name and an ISO 8601 timestamp, then each kind's
rows against the adapter's wire schema. Unknown fields are dropped; invalid declared values cost the
row. Everything that leaves is a `DeepCopy` under `Provider.immutable`.

`Setup` stores `id, label, path` rows with the same base64 JSON pattern, 256 KiB cap, ids matching
`[a-zA-Z0-9_.-]+`. `SetupCommands.public_label` names a library by the file's own `library.name`,
or a generic fallback for a folder, never the folder name.

Error handling never carries filesystem text: `SystemCallError`, `IOError` and `EncodingError` become
fixed-message `library.file_unreadable` with `:cause => nil`, and `Catalog#refresh` copies neither the
message nor the cause of a provider exception into state.

## Writing a library file

`FileWriter.state` refuses a symlink or a non-regular destination and answers the SHA-256 of what is
there. `write` stages beside the destination as `.ph-composer-library-<32 hex>.tmp` with
`O_WRONLY|O_CREAT|O_EXCL` and mode 0600, writes, flushes, fsyncs, reads back and compares, re-checks
the destination state, renames, and deletes the stage on any failure. `ExportWorkflow.run` refuses a
destination without `.json`, requires `replace` for an existing file, and for an approved location
requires both the reviewed destination state and the projection digest the preview reported.

What a library file contains: the adapter's wire fields for each record and, for records copied from
a library, a `record_origins` map of provider kind, library id and record id, each checked against
`[a-zA-Z0-9_.-]{1,200}`. Extension payloads, `user_data`, provider configuration and any other field
are omitted and reported as omissions by field name.

## Copying from a catalog into a Model

`Coordinator.copy` maps a catalog snapshot through the adapter, validates the mapped values against
the mapped schema, resolves against local records by source identity then label, and calls only the
record owner's registered callbacks inside the caller's proposal with an engine projected to that
owner's kinds (`proposal.foreign_write`). A `use_library` replacement needs the reviewed
`expected_values`. The attribution written onto the local record carries the source identity, a
fingerprint checked against `[0-9a-f]{64}` and the mapped snapshot fields only.
