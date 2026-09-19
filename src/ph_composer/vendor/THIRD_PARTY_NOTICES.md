# Third-party runtime components

The files under `pyodide/` are the unmodified Pyodide 0.24.1 core release, which embeds CPython
3.11.3. Each file's size and SHA-256 are pinned in `manifest.json`.

| Component | Version | License | Source |
| --- | --- | --- | --- |
| Pyodide | 0.24.1 | Mozilla Public License 2.0 (repository `LICENSE`); the release's `package.json` declares Apache-2.0 | <https://github.com/pyodide/pyodide/releases/tag/0.24.1> |
| CPython, as built into Pyodide | 3.11.3 | Python Software Foundation License Version 2 | <https://www.python.org/downloads/release/python-3113/> |

The source code of both components is available at the addresses above. No Python wheels ship in
this build.
