# B1 spike: PHX inside Pyodide

DATE: 2026-09-18
STATUS: Complete. Result: PHX 1.57.1 converts a synthetic multi-Room HBJSON to METr JSON inside
the pinned Pyodide 0.24.1 in Chromium 88, identical to the native reference. Route viable with the
conditions under "Disposition".
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft); upstream PHX#157 open

## Question

Can the METr exporter call PHX in the shipped Pyodide runtime, without Excel-only dependencies,
within the payload budget and with a complete license record (A16)?

## Inputs

- **PHX:** PHX#157 (make `xlwings` optional) is open. Selected revision: PHX 1.57.1, the PyPI wheel
  (`phx-1.57.1-py3-none-any.whl`). Local `PHX` main is at `c8580db` ("Bump version: 1.57.0 → 1.57.1"),
  the same as `origin/main`. PHX 1.57.1 still declares `xlwings`, `pydantic>=2.0`, `rich` and `lxml`.
- **Runtime:** the shipped Pyodide 0.24.1 core (CPython 3.11.3), unchanged from P0-F. Pyodide
  0.24.1 bundles pydantic 1.10.7 and lxml 4.9.3, has no pydantic-core, and its core files do not
  include micropip.
- **Wheels:** nine, installed without dependency resolution.

| Wheel | Bytes | SHA-256 | Declared license | Source |
| --- | ---: | --- | --- | --- |
| `ladybug_geometry-1.35.3` | 204,922 | `e7cce5e1…9f8b4` | AGPL-3.0 | Frozen pin |
| `ladybug_geometry_polyskel-1.7.52` | 38,765 | `c31d5a59…330a1` | AGPL-3.0 | Frozen pin |
| `ladybug_core-0.44.56` | 275,103 | `21383318…a7603` | AGPL-3.0 | Frozen pin |
| `honeybee_core-1.64.65` | 196,266 | `e5aa2e66…b04ea` | AGPL-3.0 | Frozen pin |
| `honeybee_standards-2.0.7` | 11,109 | `194245b5…54679` | GPL (classifier) | Frozen pin |
| `honeybee_energy-1.123.23` | 586,381 | `384ff755…e34e0` | AGPL-3.0 | Frozen pin |
| `ph_units-1.5.38` | 32,177 | `ee9963cf…d4dbd` | GPL-3.0-or-later (`License-Expression`) | Frozen pin |
| `honeybee_ph-1.33.65` | 223,367 | `b9b44a76…1cece` | GPL-3.0-or-later | PyPI; replaces the frozen 1.33.48 |
| `phx-1.57.1` | 469,903 | `26157782…be173` | GPL-3.0-or-later | PyPI |
| Total | 2,037,993 | | | |

The seven frozen pins match the predecessor manifest's hashes. honeybee-ph moves from the
frozen 1.33.48 to 1.33.65, the lowest version PHX 1.57.1 accepts.

Declared dependencies left out, none of which the METr path imports: `xlwings`, `pydantic`, `rich`,
`lxml` (PHX), `honeybee-schema` (honeybee-core), `click` (ladybug-core).

- **Model:** `tools/spikes/phx_pyodide/make_hbjson.py`, run in the native environment below. Two
  adjacent boxes, 5 × 4 × 3 m and 4 × 4 × 3 m, sharing one building segment, with ground floors, a
  solved interior partition and a 30 percent window in the west Room's south wall. Explicit
  constructions: `b1_wall`, `b1_roof`, `b1_floor`, `b1_partition` and `b1_window` (simple glazing
  system, U 0.8, SHGC 0.5). All ids are stable. The output is byte-reproducible over three runs:
  67,078 bytes, SHA-256 `9acfba4b…fec206ab`. Two sources of run-to-run change had to be removed first.
  honeybee writes shared resources in set order, so the generator sorts them by identifier.
  honeybee-ph gives its default site, climate and team objects random UUIDs, so the generator numbers
  them. Before that, each Room carried its own default segment and PHX made one variant per Room.

## Runs

1. **Native reference.** An isolated uv environment, CPython 3.11.13, holding exactly the nine
   wheels with `--no-deps`. Importing the METr path (`from_HBJSON`, `to_METr_JSON`) loaded no
   `xlwings`, `pydantic`, `lxml`, `rich`, `openpyxl` or `numpy`. Import 177 ms, conversion 7 ms.
   METr JSON: 54,610 bytes, SHA-256 `92fc3b88…e0498a`.
2. **Pyodide.** `tools/spikes/phx_pyodide/pyodide_run.py`: the shipped Pyodide core under the
   isolation headers (`crossOriginIsolated` true) in headless Chromium 88.0.4324.0. The nine wheels
   were unpacked with `pyodide.unpackArchive` in the table's order, and the same `convert.py` ran.
   Python 3.11.3. No heavy module loaded, and nothing appeared on the console.
   - Timings: Pyodide boot 1,889 ms, wheel fetch and unpack 247 ms, first import 1,346 ms, first
     conversion 39 ms. That is about 3.5 s from page load to the first METr text. A warm conversion
     took 27 ms, with output identical to the first.
   - Output: SHA-256 `92fc3b88…e0498a`, **byte-identical to the native reference**.

   PHX stamps the METr project date from `datetime.now()`. In an earlier run that crossed a minute
   boundary, that minute was the only difference among 3,104 values.

## What the output contains

Checked against hand values from the input:

- One variant and one zone, both named `b1_segment`. Gross volume 108.0 m³ (60 + 48).
- Four components:
  - floor 36.0 m² on assembly `b1_floor`, exterior id −2 (ground);
  - roof 36.0 m²;
  - wall 73.5 m² net (26 m perimeter × 3 m − 4.5 m² window);
  - window `b1_window_0`, 4.5 m², azimuth 180°, normal (0, −1, 0).
- The partition does not appear as a component; its assembly is listed.
- Assemblies `b1_floor`, `b1_wall`, `b1_partition` and `b1_roof`. Material conductivities as
  authored (0.2, 0.04, 1.8, 0.035, 0.15, 0.035, 0.5 W/mK).
- The window's Uw is 0.8073 for the authored simple-glazing U of 0.8. PHX's conversion gives the
  same value both ways; its meaning is not assessed here.
- The zone's room list is empty and its floor-area fields are zero, because the synthetic Rooms
  carry no honeybee-ph Spaces. The Room identifiers do not appear in the METr output.

## Payload and licenses

- Installed size would be 19,491,177 (P0-F) + 2,037,993 = 21,529,170 bytes plus manifest growth,
  under the 22,000,000-byte target and the 24,000,000-byte ceiling, if the wheels ship as files the
  way the predecessor shipped them.
- Licenses are AGPL-3.0 and GPL-3.0-or-later, as `docs/LICENSING.md` expects.
- `ph_units` 1.5.38 declares `License-Expression: GPL-3.0-or-later` in its wheel metadata. The
  predecessor's manifest recorded "NONE DECLARED", so its reader missed that field. `docs/LICENSING.md`
  is corrected.
- `honeybee_standards` declares only a GPL classifier; the frozen manifest records GPL-3.0.

## Disposition

The PHX route stands for Phase 1's METr exporter, under these conditions, which belong to the
validation-and-export plan:

1. **Install without dependency resolution** while PHX#157 is open. The vendor manifest pins
   exactly the nine wheels, and the loader unpacks them. PHX's `xlwings`, `pydantic>=2`, `rich` and
   `lxml` requirements are never installed. When #157 lands, the pins can move to a PHX release that
   declares only what the METr path needs. No PHX change was made for this spike.
2. **honeybee-ph moves to 1.33.65** (or a later pin reviewed at the time) from the predecessor's
   1.33.48. This is the one wheel newer than the frozen evidence. It needs Ed's acceptance as a pin
   change.
3. **The exporter supplies Spaces or accepts an empty room list.** Without honeybee-ph Spaces, PHX
   leaves METr zone rooms empty and floor areas zero. Whether METr accepts such a file, and where a
   Phase 1 two-Zone model gets its floor area before Spaces arrive in Phase 3, is for the Export
   interview. It is not a runtime failure.
4. **The accepted payload** is the nine wheels, about 2.04 MB; the budget holds.

## Limits

- Ran in headless Chromium 88, not in a SketchUp `HtmlDialog`, and through a spike page, not the
  shipped runtime page. P0-F measured the shipped page on the host at 1.3 s cold without wheels.
  This run adds about 1.6 s of wheel unpacking and imports.
- A simple synthetic model: no Spaces, ventilation, shading or thermal bridges.
- METr has not opened the output. That is a later consumer gate; JSON conversion is not it (Q6 in the
  validation-and-export PRD).
- Wheel sizes count the compressed files. Unpacked in Pyodide's memory file system they are
  about 9.0 MB.
