"""PH-Composer's translation package: the export extraction in, typed objects and a result document out.

The same pure-Python package runs under pytest and inside the extension's Pyodide runtime, which
embeds CPython 3.11.3: no 3.12 syntax. Every module imports without honeybee, ladybug or PHX; the
stack is reached only through `stack`, on first use.

Modules:

    contract.py     the JSON value type, the readers every record is built through, and ContractError
    sections.py     what a translation section declares: id, versions, typed requirements, read, translate
    coordinator.py  orders sections by their requirements and runs them, one record at a time
    result.py       findings, per-section results and the result document
    exporters.py    exporters: HBJSON and explicit options in, one output file out
    stack.py        the one place honeybee and ladybug are imported
    composition.py  the sections and exporters this build carries
    entry.py        `translate_json(str) -> str`, the call the runtime page makes
"""

from __future__ import annotations

#: The extraction document version this package reads, and the result document version it writes.
DOCUMENT_SCHEMA_VERSION = 1
RESULT_SCHEMA_VERSION = 1
