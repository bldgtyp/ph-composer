# 08 Python translation: the Pyodide package

Files: `src/ph_composer/python/ph_composer_translation/*.py`.

## Entry points

`entry.translate_json`, `probe_json`, `export_json` and `export_report_json` take one JSON string
and return one. `json.loads` with defaults; an unreadable document is a `failed` result with
`payload.contract`, never an exception to the page. `export_report_json` catches every exception
and reports the class and package-relative frames, not the message, because a message can carry
Model content; that report is what `Export::Task` logs after `Diagnostics.accepted` filters it.

## Imports and code execution

The only dynamic import is `stack.load`, which refuses any module whose top-level package is not in
a fixed frozenset (`honeybee`, `honeybee_energy`, `honeybee_ph`, `honeybee_energy_ph`, `ladybug`,
`ladybug_geometry`, `PHX`). No `eval`, `exec`, `pickle`, `marshal`, `yaml`, `subprocess`,
`os.system`, `__import__` or file `open` in the package. Wheels are installed by the runtime page
from manifest-listed files it fetched from the loopback server, unpacked with `zipfile.extractall`
into an in-memory filesystem; no `pip`, no resolver, no network.

## Input handling

`coordinator.read_document` checks the schema version, run id, sections object, that every section
present has a reader, each section's version and record list, and that each record is a mapping with
a unique non-empty string id, before any record is translated. Record-level problems become findings
and leave the other records alone. `exporters.run_exporter` deep-copies options and refuses unknown
option names; no exporter is registered yet.

## Output

`result.Translation.to_document` emits only the shell fields and each section's declared result
fields; the Ruby privacy gate then refuses anything undeclared. `conformance.check` reloads the
canonical HBJSON through honeybee and compares counts and reciprocal Surface targets, which is a
correctness control rather than a security one.

## Not reviewed in depth

The geometry and thermal translation in `model_sections.py`, `window_sections.py`,
`space_sections.py`, `constructions.py` and `assembly.py` was read for input and output shape only.
They operate on validated records and produce honeybee objects; nothing in them reaches the
filesystem, the network or dynamic code.
