# Phase 3a acceptance rerun, 2026-10-16

Ed's answer to P3a-12's first two items: rerun the Spaces host rows and every earlier case the ledger
screened stale, under the full procedure (an `acceptance_run.py` baseline before each case, an observation
receipt after it, and a ledger result). R05 is superseded and not rerun.

Build: `main` at `e6059fa9` (branch `acceptance/phase-3a-rerun` adds and adjusts catalog entries: S05 to S11, S03 widened for D3a-19, and the A02, A04, A05 and A09 dependency paths; each ledger row's `commit` is the branch commit it was recorded on). Normal RBZ
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
  example ([#176](https://github.com/bldgtyp/ph-composer/issues/176)). The same edit made through the public API (`zones.options.create` for
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
definition was confirmed directly ([#177](https://github.com/bldgtyp/ph-composer/issues/177)).

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

Seen during the run: after the Close, with no document window active, the panel kept showing
the closed Model until another document was clicked. Separately, `container_added` and
`zone_container_listener` logged a `TypeError` once during the integrated setup and once on an Undo. Three traced
attempts did not reproduce it ([#174](https://github.com/bldgtyp/ph-composer/issues/174), [#175](https://github.com/bldgtyp/ph-composer/issues/175)). The case dependency patterns were also too broad to screen precisely ([#178](https://github.com/bldgtyp/ph-composer/issues/178)).

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

A09 is rechecked on the fixed build in the [#179 recheck](#179-recheck-a09-and-uxr-paint-on-the-fixed-build) below, and passes.

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

## PTAB, GH47 and GH43, library product tabs, the value bubble and the picker routes

The same process, each case on a fresh copy (`r11/r11.skp` for PTAB and GH47, `blank-template.skp` for GH43).
- PTAB: "+ New Frame" sits in the Library heading, and the tab body has no second title. Creating "Host frame"
  took one write. Native "Undo Create Frame" removed it alone, and Redo restored the same id. The depth bubble
  ("Default install depth") keeps "abc" with a length hint, closes on Escape with nothing written, and applies
  "120 mm" as "Depth: 0.12 m" in one write. Choosing "R11 install" in "Default Psi-Install" applied at once.
  Each default change was its own native "Undo Change Window Defaults". At 420 px the heading is one line and both
  defaults share a row with the bubble inside the panel. With a 59-character name, at 420 and 1280 px, the name
  ends in an ellipsis and both chevrons stay inside.
- GH47 (IP units; an r11 copy stands in for the original issue fixture): the Column width bubble kept "abc",
  accepted 4 ft = 1.2192 m on Enter, and cancelled 5 ft on Escape. The default depth bubble kept "xyz", accepted
  0.5 ft = 0.1524 m on an outside click, and cancelled 0.8 ft on Escape. Native "Undo Change Window Defaults"
  and "Undo Resize Window Band" restored 0 m and 1 m.
- GH43: a readable setup shows two equal route cards and Done, and the file picker's Cancel writes nothing. A
  stubbed unreadable setup shows Reset and Done with both routes absent; the real preferences are untouched. A
  fresh normal process then reads the setup readable with the original providers, an equal fingerprint, no
  helper, an unmodified Model and a new session.

## E15, Window product library copy and export

A copy of `envelope/p209-p211-native.skp`. The synthetic four-kind provider `tools/examples/library/materials.json`
was added through the native picker, and the library setup was restored afterwards. Native drags of the
provider's Frame and Glazing onto the selected element card each copied and assigned in one operation. Each time,
one native Undo ("Undo Copy Library Record") restored the four inventories and the Window Type references exactly.
A provider Psi-Install Type staged and painted in the Installs editor left the Model untouched. Save wrote one
library-attributed product with one perimeter reference, and native Undo restored the baseline. The Export
library review listed 4 Materials, 1 Frame, 1 Glazing and 1 Psi-Install Type. The written file reads back as 7
rows that map to the local records with no warnings.

## UXR-SOLVE to UXR-FILTER-OCC, Faces view refinements: PAINT fails on the narrow layout

One fresh process on a copy of `ui-ux-acceptance-20261007/run-baseline.skp` (two six-Face Zones), cases in the
recorded order. Counts were derived on this baseline.
- SOLVE: check-all qualifies two Zones; with one Face unchecked, one Zone qualifies and Solve is disabled.
  Solve wrote one reciprocal Surface pair. Native Undo and Redo ("Solve Zone Adjacency") are exact.
- FILTER: Type Show without Floor and Roof masks the eight Wall paths, and the mask holds through Zone, Off and
  Boundary. Adding a Boundary filter gives an explicit empty mask, with everything muted. Clearing one filter
  restores the other; clearing both, with the menu still open, restores the full scope. Nothing is written, and
  Edit still reads "Undo Solve Zone Adjacency".
- HATCH: Assembly None hatch with West's native blue selection edges visible; 1,144 hatch entries, no solid
  unclassified outlines, no write.
- PAINT, **fail on the narrow clause ([#179](https://github.com/bldgtyp/ph-composer/issues/179))**. Type paint
  by one drag changed exactly the two front walls, a Ground click changed one boundary and kept its type, and the
  local Assembly paint changed only `assembly_id`. Each has exact native Undo and Redo, and Surface and None have
  no paint icon. At 420 and 360 px the Type column is reachable only by scrolling the whole tab sideways, which
  takes the selection bar out of view. Narrow-menu painting starts, and Escape stops it. Rechecked
  [below](#179-recheck-a09-and-uxr-paint-on-the-fixed-build): the narrow clause now fails on
  [#188](https://github.com/bldgtyp/ph-composer/issues/188); after the #188 fix it passes
  ([below](#188-recheck-a09-uxr-solve-and-uxr-paint-on-the-fixed-build)).
- COLOUR: each paint choice selects its Colour-by mode. Escape keeps Boundary or Assembly, and a Face type
  override chosen during Assembly painting survives stopping, with no write.
- FILTER-OCC: a nested Group Face and two placements of one shared Component Face have three distinct paths.
  Masking colours exactly the chosen panels (4 triangles coloured and 26 washed, then 2 and 28), and clearing
  gives 30 and 0. The post-setup Model fingerprint is unchanged.

## UXK1, classified fills, selection edges and occlusion

A fresh copy of `ux-followups-integrated.skp`. With Boundary condition Colour-by, the left Zone's native blue
selection edges show over its Outdoors fill, and the two internal Surface Faces stay hidden behind the exterior
walls. A front Face record was removed by labelled development eval. That Face shows the neutral grey hatch and
outline, and its neighbours' fills stay legible. The HUD counts read Outdoors 10 and Surface 2 with 12 classified,
then Outdoors 9, Surface 2 and Unclassified 1, then Outdoors 10 and Surface 2 once the exact record was written
back. No PH-Composer material entered the Model.

## ZO-H1 to ZO-O7, managed Zone options: O7 fails on the component path

One process for H1 to H3 on a blank destination and a copy of `zone-field-options-20261005/legacy-baseline.skp`.
O7 then continued on the same two files. The 2026-10-05 destination had changed after its baseline, so H1 used a
fresh copy of the blank template.
- H1: Manage Building Segments opens on an empty Model, and Escape writes nothing. At full width, 420 px and the
  360 by 520 minimum, Save and Cancel stay visible and the row list scrolls. Add focuses the new row. The name is
  prefilled but not selected, so typing appends; recorded as a note. Escape discards the whole draft, and Enter
  saves one Segment. The dialog is modal and shows the saved default. A Model switch dismisses an unsaved draft.
  Native Make Zone on a fresh Model gives one Zone with one valid default Segment and no Level in one operation.
- H2: Legacy adoption, chip assignment, a Unicode rename and recolour batch, the used merge, the used removal and
  the default replacement each have exact native Undo and Redo. The merge dialog counts one live and one
  recoverable use and writes nothing as a draft. Save rewrites live and orphan stamps. This fixture has two
  Zones and three stamps, where the 2026-10-05 fixture had three and four. A fresh process reads the saved
  state exactly, with no write. The Segment merge note mentions a Level
  ([#180](https://github.com/bldgtyp/ph-composer/issues/180)).
- H3: A custom Level hue, native selection edges and the missing-Level hatch show together. The Level filter
  composes with Colour-by, and the held mask survives a Unicode rename. A new Model starts clear, and the
  normal panel shows no development styling.
- O7, **fail on the component path ([#181](https://github.com/bldgtyp/ph-composer/issues/181))**:
  - Same-Model copy: a native same-Model Copy and Paste makes the copy independent in the paste's own Undo
    step, keeping choice ids and user_data. One Undo Paste is exact.
  - Shared copies: copies SketchUp keeps shared (two component placements, a copied parent Group) read
    `shared_definition`, and Make Zone independent refuses them. After native Edit Group, the native Repair
    menu makes the Group copy independent with a new Zone id and unchanged choices. A unique component
    placement still refuses after native Make Unique, while the message says to make it unique. The Group
    refusal says to choose Make Unique, which the SketchUp 2026 Group menu does not offer. Explode does make a
    placement's Zone independent.
  - Explode, merge and Restore: Explode, a used Segment merge and Restore recover the survivor Segment, and
    Restore has exact native Undo and Redo.
  - Line split: a native Line split duplicates a Face id, keeping the Zone record and stamps on both pieces.
    Repair split Face identities keeps the selected piece's id and gives the other a new one without changing
    choices.
  - Cross-Model paste: the paste keeps the raw record and asks for adoption. Cancel writes nothing. Adopt keeps
    the Segment export id `bseg_6f72f96c5d046220`, the Unicode Level name and user_data, with exact native
    Undo and Redo.
  - Reopen: both Models reopen in fresh processes with new sessions and no helper. They read exactly as saved,
    with no write, and the reopened normal panel renders.
  - Separately: native Make Component on a Zone Group empties the Zones tab and makes `zones.all` refuse
    ([#182](https://github.com/bldgtyp/ph-composer/issues/182)). One native Undo restores it.

## S01 to S11, Spaces

S01 and S02 each ran on a fresh copy of `envelope/reference-assigned.skp` (`147a5638`). S03, S04 and S07 to S11
ran as one chain on that fixture, rebuilt with the P3a-12 scripts (`build2.rb`; `build3.rb` adapted to the fresh
ids). The chain fixture `built.skp` is `84b50512`. S05 and S06 ran in a separate synthetic launch (development
scripts loaded), closed by the normal restoration below. Raw files are in `_private/host/acceptance-3a/S01` to
`S12`, `B8b` and `RESTORE`.

- S01: a Zone-stamped Group inside west is absent from the Face list, Suggest, Solve and the export preflight; the
  reads equal the baseline in every field but the revision. A native Classify click on its Face refuses, and so
  does a native Shift-click (offline last time). Removing the stamp returns the Face.
- S02: `SpacesWalkthrough.run` passes with the panel never opened. A native Undo walk of all 19 steps shows each
  of the nine product writes as one step, and 19 Redos restore the final state exactly. A native copy is now made
  independent in its Paste step (D3a-14); the earlier run read two ambiguous occurrences. Edit Group keeps every
  id. Cut and paste keeps ids. Airflow states and Volume `user_data` survive a fresh reopen, and two Models stay
  isolated.
- S03, post-D3a-19:
  - Leaving a Volume by a click commits outside it, then changes the path, then protects it in one pass. Escape
    gives Undo Close, whose Undo reopens the Volume unprotected and whose Redo protects it.
  - A direct switch between Volumes protects the first. A Rectangle at the Space root is one Undo step. A Move
    of an unprotected Volume raises both findings, and Restore position clears them.
  - Native Cmd+S inside a Volume leaves the user there, unlocked and modified, with nothing written by the
    extension. A 1-minute autosave behaves the same and writes to `working/`. A fresh open protects the Volume
    that was saved open.
  - Two Models stay isolated. The autosave interval is back at 5.
- S04: the copy, `5x` array, cut and paste, Volume and Floor Segment copies, the nested paste, Move Space to Zone
  with its refusal, and the D3a-13 Zone copy with a Window Unit all ran natively. Undo and Redo are exact and a
  reopen and export reload match. On a scratch copy: the rotated wrapper, a Space inside a component placed twice
  (draw-directly finding, `target.shared_definition`), `user_data` through Make independent, and Restore Zone
  around the moved Space, then two save and reopen cycles.
- S07: rows, in-place edits with refusals and the stale draft, a range paste as one Undo Edit Spaces, airflow
  states through reopen, Zone sums with the imbalance marker and the inheriting dash, the selection bar, Select by
  (D3a-18), Locate, Colour by weighting factor from its header, IP and back. Cmd+Z in the panel does nothing
  (#168). The 300-Space timing is still #154.
- S08: Mark floor from the column menu, with a click and a held drag (native mouse down and up; probe 258 held,
  256 on release), each one Undo step. The Create Space offer, refusals, Escape mid-drag, the glyph stop and one
  tool at a time all hold. Create Space from the context menu makes 104 Spare in one step, with exact Undo and
  Redo. The review of a three-Face selection leaves out the classified wall. Mark floor was painted at 0 and 1 only;
  a typed 0.6 was entered in S07 and joined the paint choices, but not painted with the tool. A Model switch keeps the tool per
  Model.
- S09: the four modes and legends; prisms (103's 5 m Volume, 201's projected base); labels, toggles and selection
  totals in SI and IP with no mode active; a hidden tag. Digests are unchanged through the modes and a save, and
  By Space colours are stable across a reopen. Three of four Spaces share one By Space colour
  ([#183](https://github.com/bldgtyp/ph-composer/issues/183)).
- S11: the native Height from solid confirmation, Set height to 3.0 m, and the owed native Undo and Redo (one
  step). Refusals through the public preview and the panel's selection query. The native Extensions entry does
  nothing, silently, with a wrong selection ([#184](https://github.com/bldgtyp/ph-composer/issues/184)), so that
  clause holds on the preview route only. The two-solid Group was accepted without its summed volume being read.
- S10: a fresh normal process exports natively and through an approved location with the same ids. The reload
  gives iCFA 32.0 m2 and net volume 95.6 m3, airflows in m3/s, 201 with none, and `user_data` on the three
  objects. The preflight and report carry the expected lines. Both blocking rows block with no pair written. An
  export from inside an open Volume leaves it as it was, and the reopen export has identical ids.
- S05, synthetic composition: By height and Footprints through the public contract, with a hidden ancestor still
  counted. D3a-5: slice B (`74365c7`) changes only `features/windows/colour_modes.rb` and its test in code. Draw cost on the 1,012-triangle scene: fill p95 adds 12.87 ms, inside 16 ms. Operation marks read as
  the exterior elevation. Digests are unchanged.
- S06, synthetic composition: the Areas view; switching keeps the filter, expanded and checked Zones and the
  Locate outline, and sends nothing. The Faces-alone view row (hidden with one view) stays offline. Classify stops on a switch. The view returns after reopening the panel and in
  a fresh process. A focused filter field blocks a view switch
  ([#185](https://github.com/bldgtyp/ph-composer/issues/185)).

## Normal restoration

Fresh process (pid 72234) on a clean copy of `built.skp`, with no development constant, script or extra feature
loaded:
- The installed package matches `dist/ph_composer.rbz` (`28bac2c8`, 454 entries).
- The library setup equals the pre-run setup.
- The 15 bridge-approved locations added during the run are revoked, leaving the two from 2026-10-13.
- Units are SI, the autosave interval is 5 and the Zones view preference is Faces.
- The Model opens unmodified at revision 1. Reads complete, and a stale edit refuses `target.changed` with
  nothing written.

## #179 recheck: A09 and UXR-PAINT on the fixed build

Build: `main` at `9781190f`, which merges the #179 fix (PR [#187](https://github.com/bldgtyp/ph-composer/pull/187)).
Normal RBZ SHA-256 `89afe2ef173edebe56221dd70edefee4cf625469fdfc6724c396bb83f7b3f9f8`, 454 files, installed package
matching. Same host versions. Raw files are in `_private/host/acceptance-3a/A09/` and `UXR-PAINT/` (run 1 kept as
`A09-run1/` and `UXR-PAINT-run1/`), with UXR captures in `UXR2/`.

**Scope.** The ledger screens 15 current cases on #187's two shipped paths: `zones.css` (21 cases through
`src/ph_composer/html/*`) and the vendor manifest (10). A09 and UXR-PAINT, the two cases that failed on #179, were
rerun in full. The other 13 (A04, A11, E14, E17, ZO-H1, ZO-H2, ZO-H3, ZO-O7, UXR-SOLVE, UXR-FILTER, UXR-HATCH,
UXR-COLOUR, UXR-FILTER-OCC) are unaffected by construction and keep their run 1 results. The fix changes one
declaration: `.phc-overview` gets `grid-template-columns: minmax(0, 1fr)`, so its single column track no longer
grows to the table's min-content width. Where the pane is wider than that width, the computed layout is
unchanged. Where it is narrower, the horizontal overflow moves from the tab into the table mount. None of the 13
makes a claim about the Zones tab at a narrow panel. ZO-H1's narrow dialog sizes belong to the Zone options
dialog, which opens in the top layer through `showModal` and is sized by the viewport, not by the overview
grid. The manifest change records the new stylesheet hashes and nothing else.
[P3a-01's recheck](../../features/phase-03a-spaces/evidence/p3a-01-groundwork.md) is the precedent. No new ledger
rows are written for the 13, so the ledger keeps screening them stale; this section is their disposition.

**A09: pass.** Fresh copies of `envelope/reference-assigned.skp`, with the panel clauses in one process and the
held gestures in their own fresh processes (pids 96543 and 96669) under the tools-only tracer.
- Narrow layout, the #179 clause: at 365 px the tab does not scroll sideways (pane 365 of 365). The table
  scrolls in its own 349 px mount (1,207 px of content), the control row wraps with Expand all, the Zone count, more and help in view, and
  after a 400 px table scroll the Actions column stays sticky at its left edge. A native horizontal scroll
  over the table moved the mount 320 px and the tab 0 px.
- Cell drafts, Classify and the edit path, filter and tree keys, and Cmd-N from the panel repeat run 1's
  results. The empty-filter step typed into the existing text (the field read "eastzzz", because the
  background select-all was ignored), which still exercises the empty case.
- Held, Model switch: down collected one Face; Cmd-N while held; the release arrived in the new Model with the
  revision and full fingerprint unchanged and the collection cleared.
- Held, edit context: the timer entered the west Zone while the button was down (revision 5 to 7 on
  navigation). The release cleared the collection, wrote nothing and showed "The Classify gesture was
  cancelled. Nothing was written." Close Group/Component and native Save left the root, unmodified, with the
  exact fingerprint.

**UXR-PAINT: fails on a new issue, [#188](https://github.com/bldgtyp/ph-composer/issues/188).** One fresh
process on a fresh copy of `run-baseline.skp`. Before the baseline, a labelled setup through public actions
solved the two Zones and created the empty local Assembly (revision 3); run 1 did these in UXR-SOLVE and
during the case.
- Paint, Undo and the icons repeat run 1's results exactly. One native drag of the Roof or ceiling icon changed
  exactly the two front walls, and boundaries were kept. A Ground click changed one boundary and kept its type.
  The Assembly icon changed only `assembly_id`. Native Undo and Redo are exact for each. Ground, Outdoors and To
  neighbour carry paint icons; Attached zone, Surface and Assembly None do not.
- The #179 part of the narrow clause passes. At 420 px and at the 360 x 520 minimum, the tab does not scroll
  sideways (pane 420 of 420 and 360 of 360). The table scrolls natively in its mount under the sticky identity
  columns. The open Type menu stays inside the window: at 420 px it draws over the selection bar, and at 360 px it
  flips above its trigger. Narrow-menu Wall paint
  starts, and a panel Escape stops it with nothing written.
- The selection bar fails. At 420 px, the wrapped control row adds 40 px to the tab's vertical overflow (80 px,
  against 40 before the fix), so "Solve adjacencies for checked Zones" sits under the footer until the tab is
  scrolled. Run 1's 420 px capture (`UXR/out/narrow-420-bar.jpg`), taken before the tab was scrolled
  sideways, shows it in view. At the 360 x 520 minimum, the 229 px bar covers
  the 270 px table mount, including the header, so no column menu can be opened while Faces are checked. With
  the pre-fix rule injected into the live panel, the bar measures the same, so this part predates the fix. A
  native vertical scroll of the tab reveals Solve at both widths.
- Rechecked after the #188 fix [below](#188-recheck-a09-uxr-solve-and-uxr-paint-on-the-fixed-build): passes.

Restoration (receipt in `RESTORE-179/state.json`): a fresh process (pid 98325) on a clean synthetic Model, with no development constant, script or
probe loaded. The library setup equals the pre-run setup, and the two approved locations from 2026-10-13
remain. Units are SI, the autosave interval is 5 and the Zones view preference is Faces. The Model opens
unmodified at revision 1. A read completes, and a stale edit refuses `target.changed` with nothing written.

## #188 recheck: A09, UXR-SOLVE and UXR-PAINT on the fixed build

Build: PR [#190](https://github.com/bldgtyp/ph-composer/pull/190), merged as `3db8f281`. The ledger rows record the
PR head `a9140cca`, whose tree is identical to the merge (`git diff a9140cca 3db8f281` is empty). Normal RBZ
SHA-256 `11b5f00f73c110e708597633f66a3e676a1c37de0e9bd49a854355fe152e9e18`, 454 files, installed package matching.
Same host versions. Raw files are in `_private/host/acceptance-3a/A09/`, `UXR-SOLVE/`, `UXR-PAINT/` and `UXR3/`;
the previous runs are kept as `A09-run2/`, `UXR-PAINT-run2/` and `UXR-SOLVE-run1/`.

**What changed.** The overview fits the shown view's table to the height its pane leaves, on render and on
resize, with a 240 px floor; before, a fixed `100vh - 250px` budget left the tab overflowing whenever the tabs or
the control row wrapped. The shared selection bar docks in flow beneath the table where floating would cover the
table's header, which happens at the 360 x 520 minimum; taller panels keep the floating bar. Ed chose docking.

**Scope.** The ledger screens 18 current cases on #190's paths (`selection_bar.js`, `overlay.css`, `overview.js`,
`zones.css` and the vendor manifest). A09, UXR-SOLVE and UXR-PAINT were rerun in full: the two cases that
failed on #179 (UXR-PAINT again on #188), and the case whose Solve control lives in the bar. R05 is superseded. The other 14
(A04, A11, E14, E17, HGUI, ZO-H1, ZO-H2, ZO-H3, ZO-O7, UXR-FILTER, UXR-HATCH, UXR-COLOUR, UXR-FILTER-OCC, S06)
keep their results by construction: 13 passes, and ZO-O7's fail on #181. The fit only sets the table's maximum height, which at the sizes those
cases ran changes where the table ends and nothing they assert. The dock applies only where a floating bar
would reach the table's header. `overlay.css` gains only the `.is-docked` rule, which no other surface uses, so
HGUI's library and export forms are untouched. S06's view switching re-runs the fit and asserts nothing about
heights. The manifest records new hashes only. No ledger rows are written for the 14, so the ledger keeps
screening them stale; this section is their disposition. S07 asserts the Spaces view's selection bar, but its
dependency paths do not name `selection_bar.js`, so the ledger does not screen it
([#191](https://github.com/bldgtyp/ph-composer/issues/191)); the shared bar ran natively here and the Spaces
browser check asserts its dock at 360 x 520.

**UXR-SOLVE: pass.** One fresh process (pid 10954) on a fresh copy of `run-baseline.skp`. Native check-all gave
12 Faces and 2 Zones checked with Solve enabled, the bar floating at the pane's visible bottom and the pane not
scrolling; unchecking one Floor gave 11 Faces, 1 Zone and Solve disabled; re-checking enabled it again. Solve
wrote the reciprocal Surface pair `adj_6c7596c0fa84` (9.0 m2 each), and native Undo and Redo ("Solve Zone
Adjacency") are exact.

**UXR-PAINT: pass.** Same process, after UXR-SOLVE, with an empty local Assembly created by a labelled public
setup.
- Paint, Undo and the icons match the earlier outcomes (new revisions and Assembly id).
- 420 x 732 with all 12 Faces checked: the tab scrolls neither way, the bar floats at the pane's visible bottom
  (469 to 660) with Solve in view (621 to 651, pane bottom 696), and the open Type menu draws over the bar inside
  the window. Narrow-menu Wall paint starts, and a panel Escape stops it.
- 360 x 520 with all 12 Faces still checked: the bar docks beneath the table and the header stays clear, so the
  Type menu opens (above its trigger, inside the window). Wall paint starts and Escape stops it. A native
  vertical scroll of the tab brings the whole bar into view, Solve included.
- Growing the panel back to 420 x 732 floats the bar again with identical geometry. Nothing was written in the
  narrow steps.

**A09: pass.** Fresh copies of `envelope/reference-assigned.skp`; the panel clauses in one fresh process, the held
gestures each in their own (pids 12472 and 12636) under the tools-only tracer. At 365 px the tab scrolls neither
sideways nor down, the table fills the pane and scrolls in its own mount, Actions stays sticky, and a native
horizontal scroll moved the mount 200 px and the tab 0 px. Cell drafts, Classify and the edit path, filter and
tree keys, Cmd-N, and both held gestures repeat the earlier results.

Restoration (receipt in `RESTORE-188/state.json`): a fresh process (pid 12853) on a clean synthetic Model, with no
development constant, script or probe loaded. The library setup equals the pre-run setup, and the two approved
locations from 2026-10-13 remain. Units are SI, the autosave interval is 5 and the Zones view preference is
Faces. The Model opens unmodified at revision 1. A read completes, and a stale edit refuses `target.changed` with
nothing written.
