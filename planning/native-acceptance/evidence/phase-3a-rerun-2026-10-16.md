# Phase 3a acceptance rerun, 2026-10-16

Ed's answer to P3a-12's first two items: rerun the Spaces host rows and every earlier case the ledger
screened stale, under the full procedure (an `acceptance_run.py` baseline before each case, an observation
receipt after it, and a ledger result). R05 is superseded and not rerun.

Build: `main` at `e6059fa9` (branch `acceptance/phase-3a-rerun` adds catalog entries only). Normal RBZ
SHA-256 `28bac2c81a3f7dd3f3a35ccc860b285d05614227f31e5ec4dfce3be0685d6d63`, 454 files, installed package
matching (`acceptance_run.py package`). SketchUp 2026.1 build 26.1.188, Ruby 3.2.2, macOS 26.6.2. Each case
starts from a fresh copy of a base fixture whose SHA-256 is recorded in its result. Raw baselines,
receipts, scripts and captures are in gitignored `_private/host/acceptance-3a/<case>/`.

## R06, panel-closed API client

Fresh copy of `blank-template.skp`; setup by bridge: Suggest-on-Make off, one 4 x 3 x 3 m box Group drawn and
selected, a save destination approved in an empty folder (bridge stand-in for the Libraries dialog). The
PH-Composer panel was never opened: the window list showed only the document window before and after, and
`Panel.open?` read false at the end. Every step of `docs/API_QUICKSTART.md` ran as written:
- Make, classify (Wall, Outdoors) and edit ("North Zone") each completed and committed; the Zone read back
  equal to the edit; the classify result named the Face with its new record id.
- The stale write refused `revision.stale`, effect `none`; resending sequence 4 returned the identical
  outcome, as did `API.outcome`.
- Step 7 (Material, Assembly, Layer-Segment Material, assign) committed each write; the Wall carries the
  Assembly id. The Edit menu read "Undo Assign Assembly", the last write.
- Paged read: 4 rows then 2, each `reference` and `values` only, `next_cursor` null on the last page; the
  cursor under another field list refused `params.invalid`, effect `none`.
- Preflight: 5 `face.unclassified` findings blocking, 2 `material.thermal_mass_defaulted` not blocking. The
  export task finished, outcome failed `face.unclassified`, effect `none`; its status carries only
  `task_id, stage, count, cancellable, outcome`; `latest_export` names the task; the destination stayed empty.

## A02, Make Zone and occurrence identity

Fresh copy of `blank-template.skp`, Suggest-on-Make off, `AuthoringWalkthrough.setup` and `run`.
- Make Zone made both Zones, 12 Faces, and the walkthrough classified one Face in each.
- The walkthrough's Zone edit refused: it sends raw `building_segment` and `level` strings, which schema v2
  replaced with option ids, and the walkthrough still reports `passed: true`. That is a defect in the
  example, filed separately. The same edit made through the public API (`zones.options.create` for
  "Walkthrough" and "L1", then `zones.update` with their ids and a 150 mm ground depth) committed.
- Each classified Face's stamp, read directly from its dictionary, carries its Zone's id, Building Segment id and
  Level id.
- After a save and a fresh-process reopen, `verify` and the direct stamp read were identical to before.

## A05, adjacency boundaries and reciprocal references

Fresh copy of `blank-template.skp`, Suggest-on-Make off, `AdjacencyWalkthrough` (west 5 m and east 4 m boxes,
plus the plane and normal tolerance fixtures), each step in its own call:
- Make, classify by suggestion and Solve committed, with both Surface ends `current`. A repeat Solve completed
  with effect `none`.
- Moving the east Zone made both ends `stale`; Retire committed and removed the Surface; restoring the position
  and solving again committed with both ends `current`.
- Plane offsets of 0.0254 mm and normals 0.1 degree apart match; 0.0255 mm and 0.101 degree do not.
- The two Surface records share `pair_id` `adj_186812f7a3e2`, and each one's `self` is the other's
  `counterpart`, with matching 12 m2 geometry digests. Both Zones' sections extract 12 Faces with no findings.

## A11, normal construction refusal

Fresh copy of `blank-template.skp`; two walkthrough boxes made into Zones with Suggest-on-Make on, so all 12
Faces were classified; no Assembly; an empty destination approved (bridge setup stand-in). The preflight
listed 12 blocking `construction.missing` findings. The export finished refused `export.blocked`, effect
`none`, and the destination stayed empty. The required Spaces section did not change the outcome for a Model
with no Spaces.

## A04 and R01, on the corrections fixture

Fresh copy of `blank-template.skp`, Suggest-on-Make off, `CorrectionsWalkthrough.handoff_setup`, `handoff_paste` and
`handoff_finish`: three Zones, R01's child Group pasted in place in Zone 1, R03's Garage deleted.

**R01.** The setup's copy used menu commands sent through the bridge, so it was repeated natively: the child
Group selected inside the open Zone 1, Cmd+C, Edit > Paste In Place ("Undo Paste"). Three placements then share
one definition and Face 48922. Classify and Reverse, previewed and invoked on a placement, all refused
`target.shared_definition`, effect `none`, naming Make Unique; nothing changed and no Face record was written.
`r01_check`'s own `shared_storage` flag reads false with three placements because it compares two; the shared
definition was confirmed directly.

**A04.** Paint started from the Faces view's Type column menu (the Wall paint icon; the old palette chip is
gone). The header showed the pressed glyph and the status bar "Classify: face type Wall. Click or drag over
Faces". One native held drag across Zone 3's two walls reported "Classified 2 Faces."; the revision moved 40 to
41; two new Wall records (`fac_d485b61b1ed6`, `fac_1ee0fe016e8f`). Escape returned native Select and
`classify_tool` read inactive.

## R03, Attached zone delete with orphaned Face references

A fresh rebuild of the corrections fixture, with the Garage delete committed through the public action.
- Native Edit > Undo, labelled "Undo Delete Attached Zone", restored the Garage definition with its two assigned
  Faces; native Redo removed it again.
- `r03_assign_again` assigned a new Garage to two Faces. Then, natively: one Garage Face selected inside the
  open Zone 2, Cmd+X ("Undo Cut"), Edit > Close Group/Component, Edit > Paste In Place at the root ("Undo
  Paste"). The pasted Face (49032) sits loose and keeps the reference.
- Both delete modes refused `reference.in_use`, effect `none`. The message named 1 Face and said "Restore its
  Zone, or remove it"; the definition, both assignments and the revision were unchanged.
- Three native Undos (Paste, Close, Cut) returned the Face to Zone 2: no loose Face, both Garage Faces in the
  Zone, all three Zones `found`.

## R02, explicit Face path through a nested Zone

Fresh copy of `blank-template.skp`; `CorrectionsWalkthrough.r02_setup` and `r02_paste` cut the inner Zone and
pasted it in place inside the outer Zone (menu commands sent through the bridge; the case allows bridge
control). The inner Zone read `found` and `wrong_hierarchy`. Classify and Reverse through it on an explicit
outer-Zone path refused `target.wrong_hierarchy`, effect `none`, with the revision unchanged; the inner Face
carries no stamp; a Face in an ordinary nested non-Zone Group of the outer Zone classified and committed.

## R04, partial Attached zone cut and pairing

Fresh copy of `blank-template.skp`, `CorrectionsWalkthrough.r04_setup`: two Zones whose facing walls overlap for
half their length.
- One wall Attached zone: Solve gave 14 Faces, two `current` Surface pieces without `attached_zone_id`, and one
  6 m2 Attached-zone remainder keeping the reference. A repeat Solve had effect `none`.
- Native Edit > Undo ("Undo Solve Zone Adjacency") returned 12 Faces, no Surface, and the original 12 m2
  Attached-zone wall. Native Redo returned 14 Faces with both pieces current.
- Both walls Attached zone: two current Surface pieces without the reference, and two 6 m2 remainders keeping
  it; both reference the retained definition `atz_98ZtdVruNWwW`.
- After a save and a fresh-process reopen, everything read identical.

## E14, Window Aperture export and net opaque area

Two fixtures, both through public actions. The box probe came from `blank-template.skp` with
`P214Probe.setup`. The integrated model came from a fresh copy of `envelope/reference-assigned.skp` with
`P214Integrated.setup`: two Window Types, four Units (three placed, one SDK component copy whose Unit id a
normal settings write resolved), one g=0 element. The private helpers were brought up to date with the current
code: section results now sit under their section ids, and finding codes were renamed since Phase 2. The new
names are recorded below. No shipped code was patched.
- Probe export, to a bridge-approved location: the HBJSON reloads in the eight shipped wheels and equals the
  native Python translation of the same extraction, after the existing normalization of HB-PH uuid4 defaults:
  1 Room, 6 Faces, 6 Apertures, 3 constructions. A repeat export keeps the same Aperture, parent Face and
  construction ids.
- g set to 0 and to 1 through `windows.glazings.update`: each export completes and names its constructions as
  schema exceptions. g restored to 0.5 and saved.
- All 15 aborted adversarial edits block preflight and refuse collection. Two cases changed with the schema:
  an unclassified Face is now one with no Face record (refused `face.unclassified`), and a raw `Surface`
  write without adjacency is refused by Face validation (`validation.failed`). The Frame operation mismatch
  stays non-blocking (`window_type.frame_operation_mismatch`), and 6 Apertures are still collected.
- Integrated export through the panel: Export > Choose destination > native Save panel > Save. Reload: 2
  Rooms, 12 gross Faces, 6 Apertures on exact parents, 3 constructions, 4.22 m2 opening area, g-values 0 and
  0.5 with one named g=0 exception. Gross parent Faces equal the no-Window export, the reciprocal Surface pair
  is intact, and the empty Spaces section still exports.
- Net opaque areas: west Wall 15 - 0.99 = 14.01, east Wall 12 - 2.24 = 9.76, west Roof 20 - 0.99 = 19.01 m2.
  They agree in the export, the public read, the report and the native Schedule (Window Types > Schedule,
  "Net opaque host area m²").
- An aborted SDK move and glue of a Unit onto the real paired Surface gives exactly one blocking code,
  `window.surface_host` (formerly `window.host_boundary`).
- Native File > Close, then File > Open Recent: the first `API.discover` succeeds with a new session id, and
  every Unit, Face and area readback is identical. Nothing was logged in that window.

Seen during the run, filed separately: after the Close, with no document window active, the panel kept showing
the closed Model until another document was clicked. Separately, `container_added` and
`zone_container_listener` logged a `TypeError` once during the integrated setup and once on an Undo. Three traced
attempts did not reproduce it.

## E17, Phase 2 integrated authoring, lifecycle and export

A copy of the E14 integrated model, opened in a fresh process. Each assertion names the host clause of the
E17 register row it covers. The offline clauses (gates, coverage, footprint) are `make ci`. The "E01 to E11
reconciliation" the earlier run left `unknown` is a documentation step, not a host one.
- Authoring to export: a public `start_export` through the shipped Pyodide runtime. The reload in the
  pinned wheels matches E14: 2 Rooms, 12 Faces, 6 Apertures, net areas 14.01, 9.76 and 19.01 m2.
- Nested edit paths, Undo and Redo: the west Zone was opened by a native double-click. One public Assembly
  assignment, made from inside it, changed a Face in that Zone and a Face in the other one, and the path
  stayed. Native Undo ("Undo Assign Assembly") restored all ten public projections exactly, with the path
  still in the Zone. Native Redo restored the assigned rows.
- Two Models: a second Model came from native File > New, with its own session. A Material created there
  committed in that session only; the integrated session read the same Materials.
- Reopen: native Save, then native Quit and a fresh process. All ten projections were equal, with no field
  stripped, the Model unmodified and the edit path at the root.
- Staged restart: the shipped `ArtifactPair` fault hook stopped a commit after the HBJSON step. After a native
  Quit and a fresh process, a public `start_export` to that destination restored both prior files byte for
  byte and left no journal, stage or backup. The start itself refused `export.replace_required`, because an
  approved location without `replace` gives no consent to replace. The earlier handle refused `task.expired`.
  A consented start (`replace` with the preflight's `expected_destination`) was cancelled while queued and
  wrote nothing.

## GH41, export result names authored Materials and Layers

A fresh copy of `envelope/reference-assigned.skp`. The Materials and Assemblies of
`tests/fixtures/assemblies/authoring.json` were written by development eval, with the first Layer-Segment
Material of "Two wool thicknesses" removed. Export ran natively from the panel (Choose destination, Save
panel, Save). The HBJSON has 2 Rooms, 12 Faces and 1 Surface pair. "From the last export" says: Assembly
"Two wool thicknesses", Layer 1: choose a Material for each Layer-Segment. It also names Material "Synthetic
defaults" in Assembly "Default mass". `latest_export` returns the same eight messages. Neither the panel nor
the runtime result shows an internal sentence or a `mat_` id. Only the report's Object column carries object
ids, which is by design.

## A09, Zones tab keyboard, context and held gestures: fail on the narrow layout

Fresh copies of `envelope/reference-assigned.skp`: one for the panel clauses, one in its own fresh process for the
held gestures with the tools-only `HeldClassifyProbe` tracer. Panel DOM was measured through a temporary panel
callback (tools-only).
- **Fail, narrow layout ([#179](https://github.com/bldgtyp/ph-composer/issues/179)).** At 365 px the tabs
  wrap, but the Zones tab scrolls sideways as a whole: heading, toolbar and Actions column move together, and
  the sticky Actions column is lost. `section.phc-overview` is a grid whose implicit column grows to the table's
  1206 px, because the view wrapper P3a-06 added keeps `min-width: auto`. The table mount never scrolls. A
  one-rule fix, injected into the live panel, restores the Phase 1 behavior: `grid-template-columns:
  minmax(0, 1fr)`.
- Cell drafts: on a Zone's ground depth, Escape restored the Model value and wrote nothing. Enter wrote one
  operation, and native Undo ("Undo Edit Zone") restored the value exactly.
- Classify and the edit path: native menu Classify, then panel Escape, returned to Select. Inside an open Zone,
  the first viewport Escape stopped the tool and kept the path, and the second left the Zone. A concrete menu
  choice stays as the Colour-by mode by design; only an empty-palette start forces a mode that the tool then
  releases.
- Filter and tree: "1 of 2 Zones", then "0 of 2 Zones" with "No Zones match this filter." The filter survived a
  tab round trip. Native Left collapsed a Zone row, Right expanded it, and Down moved through its Faces.
- Cmd-N from the focused panel opened a new Model with zero Zones, the Select tool and Colour-by off. The panel
  followed it.
- Held, Model switch: a genuine button-down collected one Face. With the button held, Cmd-N opened a new
  Model, and the release arrived there. Revision, collection and the full dictionary/entity/material
  fingerprint were unchanged; the new Model ran Select.
- Held, edit context: the tracer timer entered the west Zone while the button was down. The release cleared the
  collection, wrote nothing and showed "The Classify gesture was cancelled. Nothing was written." Close
  Group/Component and native Save left the root, unmodified, with the exact fingerprint.

A09 is rechecked on the narrow clause once #179 ships.

## R11H and HGUI, library setup, library and HBJSON export, Window Type grid, navigation

One fresh process: a copy of `r11/r11.skp` for both cases, and for HGUI's HBJSON items a copy of the E17
integrated model opened beside it. The library setup was saved first and restored byte for byte afterwards.
- Adding a library: the file route opened the native picker and added `long-library.json` under its own
  library name. Menu Add Library Folder added the folder as "Library folder 4" ("Added library Library folder
  4."). A folder holding more than one library is labelled "Library folder N" by design, so a public result
  never carries a folder name. That replaces the folder-name label of the 2026-10-02 run.
- Paging: the 250-Material library opens with its group collapsed. Expanded, it shows 100, then 200 and 250 with
  Load more, after which Load more is gone.
- Library export over an existing file: one prompt, the macOS Replace sheet. The form lists Frame 1, Glazing 1,
  Material 0 and Psi-Install Type 1, with plain-word notes and no codes. The written file is a new "Model library"
  export, and the Model is unmodified.
- HBJSON export: over an existing pair, one Replace sheet and both files replaced. Onto a lone report: "Only one
  destination artifact exists. Move or rename it before replacing the coordinated pair.", with no question. Without
  `.hbjson`: "The export destination must end in .hbjson." In both refusals the files were unchanged.
- Window Type grid: Insert column right gave `[1.0, 0.5]` with two elements. Merge gave one; native Undo ("Undo
  Merge Window Elements") gave two back.
- Navigation: "Manage frames in Library" from the Top Frame picker opened Library on Frames. The Frame uses
  bubble reads "Used by 1 element" with "R11 type / Element" on "Top, right, bottom, left" (the side order of
  #42 is fixed), and Open type opened R11 type. Leaving an Installs session with one painted edge asked "Discard
  Installs changes?" with nothing written, and Discard opened Library.
- Unreadable stored setup: the dialog showed Reset and Done with no Add routes, and menu Add opened no picker.
  Reset gave a readable empty setup.
