# 05 Export: the task, privacy allowlist, report and artifact pair

Files: `src/ph_composer/export/{task,tasks,workflow,collection,geometry_snapshot,record_reader,report,report_html,privacy,artifact_hygiene,hbjson_metadata,artifact_pair,result_view,preflight_result}.rb`,
`features/{zones,zones/faces,assemblies,windows,spaces}/export.rb`, `features/assemblies/source_report.rb`.

## What leaves the Model

`RecordReader` is the one reader for export. A record's declared values leave; `user_data` leaves
only where the contributor passes it through (`user_data: true`), and then only if it does not use a
reserved top-level key (`ph_composer` and every namespace a contributor declares it writes). An
extension envelope leaves only when a contributor names its namespace and fields and the installed
extension understands it; an unknown envelope that declares `required` or `unknown` relevance blocks
the export, and `local_only` is omitted with a finding. Nothing guesses from a payload's text.

The extraction is detached: `GeometrySnapshot` copies dictionaries and geometry and holds no live
entity, so a contributor cannot write during export.

## The privacy gate

`Privacy.validate!` runs on the translator's result before the report renders and again in the
task before writing. It refuses any field no declaration names (the shell's own plus each
contributor's declared `result` fields), any key in `ArtifactHygiene::PROHIBITED_KEYS` (`user_data`,
`extension_data`, `path`, `source_path`, `file_path`, `model_path`, `username`) at any depth of the
result document, any string matching `Diagnostics`' absolute-path patterns, and in the canonical
HBJSON any undeclared leaf under a declared `user_data` namespace, any prohibited key, and any
path-like string or key. `HbjsonMetadata` compares keys as keys so a dot or bracket in a key cannot
hide it. The user's own `user_data` keys pass through and are counted in a finding
(`export.user_data_passed`) so the report says what travelled.

This is the strongest privacy control in the codebase and it is well tested
(`tests/hbjson_metadata_test.rb`, `tests/export_test.rb`, `tests/export_tasks_test.rb`).

## The report

`ReportHtml.h` is `CGI.escapeHTML`; `section`, `table` and `paragraph` escape every title, heading,
cell and paragraph. The embedded result JSON replaces `<`, `>` and `&` with unicode escapes so a
`</script>` inside a value cannot close the element. Contributor reports build from the same
helpers; the Windows report has one interpolation without `h` (F04), bound today to a number.
`Report.render` reads the stylesheet from the extension folder and inlines it.

The blocked-run report is rendered without the canonical model and shown in the panel inside
`<iframe sandbox="">`: no scripts, no same-origin, no forms. Even an escaping defect could not reach
the panel's `sketchup` bridge from there.

When the user opens the written report in a browser it runs from `file://`. A stored XSS there would
be limited by modern browsers' file-origin isolation; with the escaping above it has no route.

## Writing the pair

`ArtifactPair::Transaction` requires a `.hbjson` extension, derives the report path from it, refuses
half a prior pair, recovers from a prior journal first, then: writes the journal, stages both files
with `O_EXCL`, verifies staged bytes and that the HBJSON parses and the report names the run, moves a
prior pair aside, renames both into place, verifies final bytes, marks the journal committed and
cleans up. Every failure before commit restores from the journal and deletes only files this run
owned. The journal accepts only basenames that start with `.` and contain `.ph-composer-export-`,
never a path, and must name the same final files. Final files take the user's umask; stage and
backup names carry 48 random bits.

`Export::Task` re-checks the destination state against what the caller reviewed before writing
(`export.destination_changed`), re-checks the owner's access and the approved location
(`still_permitted?`), and refuses to write for a revoked token. The result for the starting caller
carries each file's path, SHA-256 and size; any other caller sees the location label.

Tasks are per session, owned by the starting caller handle, retained 20 and 30 minutes, cancelled
when the session detaches.

## Preflight findings

Finding messages are built from fixed sentences and record ids, plus Zone and Type names and
Assembly names from the Model. They are shown in the panel through `textContent` and in the report
through `h`. `features/spaces/export.rb` and `features/windows/export_assessment.rb` interpolate
names into messages only.
