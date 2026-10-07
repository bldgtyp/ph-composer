# UI refinement native acceptance

DATE: 2026-10-07
STATUS: The six bounded refinement cases passed on the current macOS host
SOURCE: `main@1356fc9`; shipping source unchanged during this run

This closes the native follow-ups in [UI and UX refinements](../../archive/ui-ux-refinements.md).
It does not rerun or close the broader historical Phase 1 cases.

## Host, build and baselines

SketchUp 26.1.188, Ruby 3.2.2, macOS, native Codex `cua_repl` controls and separate development
bridge readback. Ed opened the prepared synthetic Model after welcome-screen automation could not
open it. The bridge then reported a clean Model at edit depth 0. The process had freshly loaded
the normal installed extension; no shipping Ruby files were live-reloaded, patched or replaced.
Normal composition was Assemblies, Zones and Windows.

The installed package matched all 387 RBZ entries, with no mismatches or extras, both before and
after the run. RBZ SHA-256:
`97d30a432c31ac7132d853e52fe94bade8f8cbddb130ccbc86aac49c5be95f2c`.

Session: `3401b493-c291-48af-9266-98f2240f881b`. Two immutable source/host baselines preceded
their respective acceptance actions:

| Stage | Fixture SHA-256 | Run ID |
| --- | --- | --- |
| Two touching six-Face Zones | `b0a02a85e2577077a4a4bcdac6fa24a835b818dfd99b2f2f41c8347a5038d4ee` | `5f65d1be-9ebf-4074-a5b3-98f10da50a49` |
| Added nested Face and two shared Face occurrences | `625a4bfbb33b3a52267b14061df68bf59539bbb2f5b91cba9aed5e6746e22a4a` | `5fdb5ef0-1054-471a-99d0-a2ef0ee6d44c` |

The source fingerprint was
`2167edfeae90af37264cbfa16b9e7a57785aff0366af51cb869d4f9b4b8fbabc`.
Raw Models, helper bytes, recipes, readbacks, native window captures and observation receipts are
ignored under `_private/host/ui-ux-acceptance-20261007/`. The first saved fixture is retained as
`run-baseline.skp`; the extended fixture remains `run.skp`.

Synthetic geometry setup used development-only Ruby. Zone creation, classification and creation
of one empty synthetic Assembly used public product actions. Paint and Solve acceptance actions,
Undo/Redo, selection, column checklists, menus and Escape used actual native controls. No tool
callback was invoked directly. Public view commands exercised mode/off retention and explicit
occurrence masks. A harmless native paint click and exact native Undo established the controls
before the first immutable acceptance baseline.

## Assertion observations

| Case | Observed result |
| --- | --- |
| UXR-SOLVE | Check-all qualified two Zones. Unchecking one Face left one complete Zone and disabled Solve; restoring that check enabled it. Clicking the selection-bar action created two Surface Faces whose counterpart references resolved reciprocally. One native Undo restored every prior Zone/Face record and reference; native Redo restored the exact solved state. |
| UXR-FILTER | Native Type Show checkboxes excluded Floor and Roof, leaving eight Wall occurrence paths. Native pixels showed coloured walls and washed roofs. The same mask persisted in Zone mode, through Colour-by off, and into Boundary mode. Combining Boundary and Type filters produced an explicit empty mask and native mute-all pixels. Clearing Boundary restored the Type mask; clearing Type restored unrestricted scope while its menu stayed open. Exact records and revision remained unchanged. Native Edit still offered Undo Solve Zone Adjacency, proving no filter Undo entry was added. |
| UXR-HATCH | A native click selected West. Assembly None rendered its hatch while native blue Zone selection edges remained visible. Readback showed 1,144 cached hatch entries and zero unclassified solid outlines. Assembly assignments were absent at this observation; no record mutation occurred. |
| UXR-PAINT | The native Type icon set only RoofCeiling. One actual drag across the two front Faces changed exactly those two Face types, retained both boundaries, and advanced revision once. Native Undo/Redo restored exact before/after records and references. Switching through the Ground icon reset the palette to Boundary only; a native click changed one boundary while preserving its RoofCeiling type. The local Assembly's native paint icon subsequently assigned exactly one Face without changing its Type or Boundary, with exact native Undo/Redo. Surface and Assembly None had no paint icon. Native panels at 420 px and the 360 px minimum kept wrapped selection/Solve controls and open Type menus within the window; menus rendered above the selection bar. Native narrow-menu painting started and Escape stopped the tool. |
| UXR-COLOUR | Native Type, Boundary and Assembly choices selected their matching Colour-by modes. Native Escape stopped Boundary painting and retained Boundary Colour-by. Assembly painting stopped with Assembly Colour-by retained. A later native Face type palette override during Assembly painting survived stopping through the active Assembly header glyph; readback showed the tool idle, Face type mode retained and revision unchanged. |
| UXR-FILTER-OCC | A nested Group Face and two occurrences of one shared Component Face resolved to three distinct full paths; the shared paths ended in the same Face persistent ID. In Zone Colour-by, masking the nested and West shared paths coloured exactly those panels and washed the East shared panel. Masking only East reversed their treatment. Native pixels confirmed both directions. The cache held four coloured triangles initially, then two, with 26/28 wash triangles respectively. Clearing restored 30 coloured triangles and zero wash triangles. Attributes, revision, modified flag, native selection, tags, material inventory and Scenes remained exactly equal to the post-setup baseline. |

For narrow menu positioning, the bridge set the existing table container's horizontal scroll
offset as development-only layout setup. Native clicks exercised the resulting menus. A native
horizontal-wheel attempt did not move that container; this run does not claim native wheel-scroll
acceptance. Existing browser checks own horizontal scrolling at smaller widths, including 280 px.

## Normal restoration and verification

The fixture was saved before the extended mask checks. After all checks, native input cleared
selection, public view commands cleared the mask and turned Colour-by off, and the native panel
was closed. The three fixture/DOM helper modules were removed; reopening built a new normal panel
without the temporary DOM callback or test styles. Separate readback confirmed exact Zone, Face
and Assembly query results, helpers absent, paint idle, Colour-by off, mask null, empty selection,
edit depth 0 and an unmodified Model. Native pixels confirmed the normal panel rendered. It is
left open beside the clean synthetic `run.skp`.

No private provider, fault override, shipping monkeypatch or runtime reload was used. Cleanup
rebuilt the normal panel in the same process; it is not an additional fresh-process reopen claim.

`make rbz-check` and the installed-package comparisons passed. The earlier audit's 119 focused
JavaScript checks passed on unchanged source. The owning packet's existing offline, browser and
independent-review receipts remain applicable; no full suite was repeated for this evidence-only
closeout. Ledger validation, immutable observation receipts and affected documentation links are
checked at closeout. No product defect or shipping fix was found.

These results close this refinement's current-host acceptance. They do not establish SketchUp
2023 native compatibility, Windows support, release, public distribution or certification acceptance.
