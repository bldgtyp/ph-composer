# B1 spike: PHX inside Pyodide

Development only, never shipped. Reproduces the P0-B B1 investigation
(`planning/archive/phase-00-foundation/evidence/spike-phx.md`): a synthetic two-Room HBJSON converted to
METr JSON by PHX, first in native CPython, then in the pinned Pyodide 0.24.1 under Chromium 88.

| File | Does |
| --- | --- |
| `make_hbjson.py` | Writes the synthetic HBJSON: two adjacent boxes, explicit simple constructions, one window, one shared building segment, stable ids. Byte-reproducible |
| `convert.py` | The conversion both runs share: HBJSON text in, METr JSON text plus timings out |
| `pyodide_run.py` | Serves the shipped Pyodide core and the wheels with the isolation headers, boots it in Chromium 88 (`tools/runtime/browser_check.py`), unpacks the wheels, converts, compares with the native result |

## Work folder

Everything the scripts read or write lives in one folder outside the repository, for example in
`_private/`. It holds a `wheels/` folder with exactly these files:

| Wheel | Source |
| --- | --- |
| `ladybug_geometry-1.35.3`, `ladybug_geometry_polyskel-1.7.52`, `ladybug_core-0.44.56`, `honeybee_core-1.64.65`, `honeybee_standards-2.0.7`, `honeybee_energy-1.123.23`, `ph_units-1.5.38` | The frozen predecessor pins (SOURCE_INVENTORY), or PyPI at those versions |
| `honeybee_ph-1.33.65` | PyPI. PHX 1.57.1 requires at least this version; the predecessor pinned 1.33.48 |
| `phx-1.57.1` | PyPI |

```sh
W=<work folder>
uv venv --python 3.11 "$W/.venv"
uv pip install --python "$W/.venv/bin/python" --no-deps "$W"/wheels/*.whl
"$W/.venv/bin/python" tools/spikes/phx_pyodide/make_hbjson.py "$W/two_rooms.hbjson"
"$W/.venv/bin/python" tools/spikes/phx_pyodide/convert.py "$W/two_rooms.hbjson" "$W/native_metr.json"
uv run tools/spikes/phx_pyodide/pyodide_run.py "$W"
```

`--no-deps` is deliberate: PHX 1.57.1 still declares `xlwings`, `pydantic>=2`, `rich` and `lxml`
(PHX#157), and the METr path imports none of them. Chromium 88 comes from the shared cache
`tools/runtime/browser_check.py` uses; run that once with `--download-chromium` if it is absent.

Spike tooling is checked by ruff only; it is outside the mypy file list because it imports the
honeybee stack, which the development environment does not install.
