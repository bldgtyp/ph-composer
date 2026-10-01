# P1-C adjacency and HBJSON evidence

DATE: 2026-09-20
STATUS: Complete on the implementation branch; merge pending.

## Scope proved

P1-C adds the whole-wall adjacency slice and the first canonical-model proof. Zones now register
public solve and retire actions. A solve records reciprocal face and Zone references plus detached
geometry stamps. Reads distinguish current, stale and unresolved endpoints. Reclassifying either
side away from Surface retires both sides in the same compound operation. A second unchanged solve
does not open a SketchUp operation.

One shared export snapshot now supplies detached SI face loops and entity records to the Zone and
face contributors. The Python Face section produces typed specifications. The Zone section declares
that dependency, builds all Rooms and Faces, then resolves reciprocal Surface targets after the
emitted set is known. The normal composition has no construction provider and therefore withholds
the canonical model. The deterministic provider used by this proof exists only under
`tools/examples/phase_one/` and is absent from the RBZ.

Collection blocks an orphaned or wrong-Zone face stamp and a deleted, stale or nonreciprocal
Surface endpoint. The Python seam also turns a missing or nonreciprocal Surface target into a
blocking object finding. It never reinterprets the face as Outdoors. The development provider
refuses every non-null authored assembly id instead of treating the fixture as a fallback.

This stage implements full-face matches only. Partial overlap, split/repair behavior, holes,
transformed overlap cases, copied identity repair and explicit scope refusal remain P1-D. The
destination-first HBJSON/report workflow, shipped Pyodide wheels and export task lifecycle remain
P1-E. METr remains deferred.

## Deterministic two-Zone proof

`make phase-one-proof` translated the checked-in synthetic extraction with these direct pins:

| Package | Version |
| --- | --- |
| honeybee-core | 1.64.65 |
| honeybee-energy | 1.123.23 |
| honeybee-ph | 1.33.65 |
| honeybee-standards | 2.0.7 |
| ladybug-core | 0.44.56 |
| ladybug-geometry | 1.35.3 |
| ladybug-geometry-polyskel | 1.7.52 |
| ph-units | 1.5.38 |

The exact serialized HBJSON reloaded through that stack with 2 Rooms, 12 Faces, one reciprocal
Surface pair and no omitted face. Durable Zone and face identifiers survived the round trip. One
shared honeybee-ph Building Segment was present. Hand checks passed at 36 m2 of external floor,
36 m2 of external roof, 78 m2 of external wall and 108 m3 geometric volume.

These pins prove the native development composition. They do not select the final shipped wheel
set or prove Pyodide execution; P1-E owns that decision and manifest.

## Current-host acceptance

Host: SketchUp 26.1.188 on macOS, embedded Ruby 3.2.2. Model:
`_private/host/p1c-adjacency.skp`, excluded from Git.

- Independent probes accepted a 0.0254 mm plane offset and rejected 0.0255 mm. They accepted a
  0.1 degree normal-angle deviation and rejected 0.101 degree.
- A fresh two-box model authored 2 Zones and 12 classified faces. Solve produced 2 current
  Surface endpoints and 12 extractable faces. A repeated solve reported no effect.
- Moving one Zone by 1 mm made the pair stale without repair. Explicit retirement removed both
  endpoints. Restoring the geometry and solving recreated one reciprocal pair.
- Native Undo removed the pair and Redo restored it. Save, clean quit and fresh reopen retained
  two current endpoints and a clean extraction.

## Offline verification

- Ruby: 260 tests, 1,175 assertions; coverage 95.6 percent.
- JavaScript: 116 tests; coverage 97.7 percent.
- Python: 84 tests; coverage 97.5 percent. The deterministic fake-stack test covers the section
  contract; `make phase-one-proof` separately exercises the real pinned Honeybee stack.
- The runtime manifest contains 41 assets, zero wheels and 19,329,471 installed bytes. Zero wheels
  is intentional until P1-E selects and vendors the HBJSON runtime payload.
- The RBZ inventory excludes the development fixture provider and private host model.

SketchUp 2023, Windows and public distribution remain separate gates.
