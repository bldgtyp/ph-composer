# Ruby readability native batch, 2026-10-17

The native-acceptance batch of the Ruby contributor-readability program
([packet](../../archive/ruby-readability/STATUS.md), "Native-acceptance batches"). Every stage was a
behaviour-preserving refactor; this batch rechecks one case per affected boundary on the final shipping code.

Build: `main` at `64d4775e` (Wave D merged). Normal RBZ SHA-256
`3a41307aa29f58283c99cbc15ffed097d6930dcc1b0c1b4a623a8cf78079240a`, 456 files. SketchUp 2026.1 build
26.1.188, Ruby 3.2.2, macOS. Each case starts from a fresh copy of a base fixture whose SHA-256 is recorded in
its result. Raw baselines, receipts, scripts and captures are in gitignored `_private/host/readability-20261017/`.

## R06, panel-closed API client

Fresh copy of `blank-template.skp`; setup by bridge: Suggest-on-Make off, one 4 x 3 x 3 m box Group drawn and
selected, a save destination approved in an empty folder. The panel was never opened. Every quickstart step
matched the 2026-10-16 run: make, classify and edit committed and read back equal; the stale write refused
`revision.stale` with effect `none`, and resending its sequence returned the identical outcome, as did
`API.outcome`; the Material, Assembly, Layer-Segment Material and assignment committed; paging returned 4 then
2 rows and a cursor reused under another field list refused `params.invalid`; preflight listed 5 blocking
`face.unclassified` and 2 non-blocking `material.thermal_mass_defaulted`; the export finished failed
`face.unclassified`, effect `none`, with the destination empty, and `latest_export` named the task. The Edit
menu, opened natively, read "Undo Assign Assembly".

## A05, adjacency boundaries and reciprocal references

Fresh copy of `blank-template.skp`, Suggest-on-Make off, `AdjacencyWalkthrough`, each step in its own bridge
call. Make, classify by suggestion and Solve committed with both ends `current`, and a repeat Solve had effect
`none`. Moving the east Zone made both ends `stale`; Retire committed and removed the Surface; restoring the
position and solving again committed with both ends `current`. Plane offsets of 0.0254 mm and normals 0.1 degree
apart match; 0.0255 mm and 0.101 degree do not. Both Surface records share `pair_id` `adj_186812f7a3e2`, and each
one's `self` is the other's `counterpart`, with reciprocal 12 m2 geometry digests. Both Zones' sections extract 12
Faces with no findings.

## A04, native Classify from the Type column

Fresh copy of `blank-template.skp`, Suggest-on-Make off, `CorrectionsWalkthrough.handoff_setup`, `handoff_paste`
and `handoff_finish` (three Zones). The panel was opened from the Extensions menu. In the Faces view, the Type
column menu's Wall paint icon started Classify: the header showed the pressed glyph and the status bar "Classify:
face type Wall. Click or drag over Faces; Shift-click takes a whole plane." One native held drag from Zone 3's
west wall to its south wall reported "Classified 2 Faces."; the revision moved 35 to 36, with exactly two new Wall
records and the other four Faces unchanged. (A first press only raised the document window, which sat behind the
panel, and wrote nothing.) Native Escape returned Select, and the Classify tool read inactive.

## UXR-SOLVE, UXR-HATCH and UXR-FILTER-OCC, Faces view refinements

One fresh process on a copy of `ui-ux-acceptance-20261007/run-baseline.skp` (two six-Face Zones), cases in this
order, the file saved after SOLVE.
- SOLVE: the panel opened from the Extensions menu. A native header check-all gave 12 Faces, 2 Zones checked and
  Solve enabled; unchecking East Floor 1 gave 11 Faces, 1 Zone and Solve disabled; re-checking enabled it. A
  native click on Solve wrote one reciprocal Surface pair (`adj_6c7596c0fa84`, 9.0 m2 each, both `current`). The
  Edit menu read "Undo Solve Zone Adjacency"; native Undo restored the pre-solve digest of every Zone, Face
  reference, value, record and adjacency state exactly, and native Redo restored the solved digest.
- HATCH: a native click selected West, and Extensions > PH-Composer > Colour by > Assembly drew the hatch on all
  twelve Faces with West's blue selection edges visible. The service held 1,144 hatch entries, no fills, no
  outlines and no unclassified solid outline; the revision and modified flag were unchanged.
- FILTER-OCC: `UxFilterOccurrences.setup` added a nested Group Face in West and two placements of one shared
  Component Face, three distinct paths. By Zone colours 30 triangles; masking the nested and West-shared paths
  colours 4 and washes 26; masking the East-shared path colours 2 and washes 28; clearing restores 30 and 0. The
  post-setup Model fingerprint never changed.

## UXK1, classified fills, selection edges and occlusion

A fresh copy of `ux-followups-integrated.skp`. A native click selected the left Zone, and Colour by Boundary
condition was chosen from the Extensions menu. The Zone's native blue selection edges show over its Outdoors fill,
and the two internal Surface Faces stay hidden behind the exterior walls. A front Face record was removed by
labelled development eval: that Face shows the neutral grey hatch and outline, and its neighbour's fill stays
legible. The legend read Outdoors 10 and Surface 2, then Outdoors 9, Surface 2 and Unclassified 1, then Outdoors 10
and Surface 2 once the exact record was written back. No PH-Composer material entered the Model.

## GH47, the shared value bubble

A fresh copy of `r11/r11.skp` (standing in for the issue fixture, as on 2026-10-16), IP units. The Column width
bubble kept "abc" with the length hint, accepted 4 ft as 1.2192 m on Enter, and cancelled 5 ft on Escape. The
default install depth bubble kept "xyz" with the same hint, accepted 0.5 ft as 0.1524 m on an outside click, and
cancelled 0.8 ft on Escape. The depth bubble opens with its value unselected, so text typed straight in appends:
"0xyz" gave the unit hint, also with nothing written. Native "Undo Change Window Defaults" and "Undo Resize Window
Band" restored 0 m and 1 m, with the Model unmodified.

## S02, Spaces records and operations

A fresh copy of `envelope/reference-assigned.skp`.
- With the panel never opened, `SpacesWalkthrough.run` passed all 15 steps through registered operations.
- Native Edit > Undo walked the whole stack, 19 labelled steps: each product write (Move Space to Zone, Make
  Space Independent, Edit Space four times, Mark Floor, Add Volume, Create Space) was exactly one step, between
  the script's own SDK steps. The bottom equals the pre-walkthrough read, and 19 native Redos restore the final read
  exactly.
- Native Cmd+C and Paste In Place of the Kitchen inside east made the paste independent in its own "Undo Paste"
  step: a new Space id, number 2, new Volume and Floor Segment ids, both Spaces found, still 12 Zone Faces. Edit
  Group then Close Group on the copy changed no record (SketchUp 2026 offers no Make Unique for a Group). Native
  Cut and Paste In Place kept the same ids and values under a new persistent id.
- Transfer set to an explicit 0 and a Volume's user_data (with a Unicode note) through public actions, then native
  Cmd+S and a fresh process: the whole Spaces read equals the saved read, extract absent, transfer 0, user_data
  kept, unmodified at revision 1.
- A second document with the same ids opened beside it: renaming its Space moved only its own revision; the first
  stayed at revision 1, unmodified. Native File > Close with Don't Save left one session.

## S09 and S08, Spaces Colour-by and Mark floor

Each on a fresh copy of `acceptance-3a/S12/after-s07.skp`. The display unit preference was IP, so figures read in
IP; each equals the 2026-10-16 SI figure.
- S09: Extensions > PH-Composer > Colour by Space, Ventilation, Weighting factor and Height each colour the Floor
  Segment Faces and the Volume prisms alike, with the same legend rows and counts as before. Prisms draw
  translucent, 103's 5.0 m Volume above the roof and 201's from the projected base of its sloped Face. With no mode
  active, Space labels and their three lines read 101 Living 129.17 ft2, 1059.44 ft3, 35.3 / 0 cfm; selecting 101
  and 102 inside west gave totals of 172.22 ft2, 1398.46 ft3, supply 35.3 and extract 23.5 cfm. Model digests were
  identical before any mode, after cycling them, and after a native Cmd+S. With 201 on a hidden tag, By Space drew
  nothing for it while the legend still counted it. A fresh reopen gave every Space the same colour.
- S08: Classify from the Faces Type menu stopped when the view switched to Spaces, leaving one tool. The Weighting
  factor column menu's paint icon for 0 started Mark floor, turned on By weighting factor and pressed the glyph. A
  native click marked 101's Segment in one "Undo Mark Floor" step; a held drag from 102 across 101 wrote once at
  release, every held move carrying the button flag. Mark floor on the loose spare Face offered Create Space, and
  Create Space with the Zone closed refused with nothing written; with west open it created 104 Spare in one "Undo
  Create Space" step, with exact native Undo and Redo. Mark floor on a classified wall and on a root Face refused
  with nothing written. Escape while held cancelled with nothing written; Escape at rest and the pressed glyph each
  stopped the tool, and the mode stayed on. A mixed three-Face selection reviewed 2 Faces in and 1 left out, and
  Cancel wrote nothing. File > New with Mark floor running opened the new Model with no tool; closing it left one
  session.

## S03, Spaces edit contexts and the session lifecycle

A fresh copy of `acceptance-3a/S12/built.skp`, with a read-only recorder of commits, Undo, Redo, path changes and
saves. Volume 1 of 101 entered from its Spaces row; a native click on empty space left it, and the recorder showed
the commit, the path change and then one commit locking it. Native Escape left it again with "Undo Close" on the
Edit menu; Undo reopened it unprotected and Redo protected it. With Volume 1 of 103 open, its sibling's row opened
Volume 2 directly and locked Volume 1 in the same pass. A native Rectangle at Space 103's root made a loose Face
with no finding, removed by one Undo. A Volume unprotected through the public action and moved 0.1 m natively
raised both findings; the row's restore put it back and locked it. A native Cmd+S and an autosave (interval set to
1 minute natively, then restored) each left the user inside the open, unlocked Volume, with no extension commit
between the save callbacks; the autosave copy went to SketchUp's working folder. A fresh process opening the file
saved with the Volume open found it locked, protected and unmoved, with every Space's metrics equal to the
fixture's. A second document's in-cell rename moved only its own revision ("Undo Edit Space"); closing it with
Don't Save left one session.

## S04, Spaces copies and moves

A fresh copy of `acceptance-3a/S12/after-s03.skp`, one process until the two reopens.
- Native Copy and Paste In Place of 102 inside west made the copy independent in its own "Undo Paste" step, and one
  Undo removed it. A Move-tool copy then 5x made 104 to 108 with 29 unique ids in one "Undo Array" step, removed
  by one Undo. Native Cut and Paste In Place kept 102's ids and values under a new entity.
- With 103's locked Volume selected, Cut and Copy are greyed. Unprotected, its native copy raised the duplicate
  finding on both occurrences; the row's "Make independent" gave the copy new ids in one step, with exact Undo and
  Redo. A Move-tool copy of a Floor Segment Face split the overlap into three Faces sharing the duplicate id,
  removed by one Undo; a Paste In Place onto itself merged back to one Face. 102 pasted inside Space 101 was made
  independent and flagged nested.
- Move Space to Zone refused with a Volume open; closed, it moved 102 into east with every vertex unchanged in world
  space, the same ids, the stamp rewritten and the Volume locked, and native Undo returned it exactly. The same move
  into east wrapped in a Group rotated 30 degrees also left every vertex unchanged.
- A native Move-tool copy of west with a Window Unit on its wall made a new Zone whose Spaces keep their numbers,
  airflows and metrics under new ids, with the Unit copied on the same Type and the originals unchanged; exact
  native Undo and Redo; a save and a fresh process read it identically, and the export reloads in honeybee-ph with
  three Rooms (iCFA 52.0 m2, net volume 149.2 m3).
- 201 wrapped in a copied component placement reads the "draw the Space directly" finding on both occurrences, and
  Make independent refuses `target.shared_definition`. A Volume with user_data made independent keeps it.
- A native Explode of east left its Spaces outside any Zone; the public Restore, with the parent context open,
  regrouped its six Faces and both Spaces. With the context closed it refused `target.edit_path_changed`, and its
  message says "before Make Zone" although the operation is Restore; noted as a wording follow-up. Two fresh
  reopens read the same ids, numbers, airflows and findings, unmodified.

## S05, Colour-by derived geometry and readouts

A fresh copy of `acceptance-3a/S12/pre-s10.skp`, synthetic composition: the example Colour-by feature in
`tools/examples/colour_by/` installed through `Registry.install`. Its By height mode draws a translucent prism per
root Group (legend High 8). Hiding east removed its prism while the legend still counted it, and one native Undo
restored it. The Footprints readout labels each Group with its footprint area (west 20 m2, east 16 m2) and shows
its HUD line, with the mode on and with no mode. Model digests are unchanged by all of it. With the Walkthrough
Type's elements set to swing left and slide right, Colour by Window Type draws each element's operation marks
toward its opening side. In a scratch Model the overlay spike's fill adds a median 0.54 ms and p95 10.03 ms per
frame on the 1,000-triangle scene, within the 16 ms criterion.

## ZO-O7, managed Zone native copy and recovery: fails on the component path, as before

Fresh copies of `zone-field-options-20261005/legacy-baseline.skp` and the blank template, options adopted first
through the public action. This case drives the two repair menus whose guards Wave D reshaped.
- A native same-Model copy of Zone 2 became independent in the paste's own step, keeping its choice ids and
  user_data; one Undo Paste was exact.
- **Fail, unchanged ([#181](https://github.com/bldgtyp/ph-composer/issues/181)).** A copied Group and copied
  component placements read `shared_definition`, and Make Zone independent refuses them. After native Edit Group,
  the native Repair > Make Zone independent menu asked once and gave the Group copy a new Zone id with its choices
  unchanged. After native Make Unique, the component placement still refuses while its message asks for Make
  Unique; the Group refusal names a Make Unique the SketchUp 2026 Group menu does not offer. Explode did make the
  placement's Zone independent.
- Explode of a Zone on a new Segment left a recoverable row; Manage Building Segments showed 0 live and 1
  recoverable, the merge draft wrote nothing, and Save merged it into the survivor and rewrote the orphan stamp.
  The public Restore regrouped the Face on the survivor, with exact native Undo and Redo.
- A native Line across a classified Floor split it into two pieces sharing one Face id; the native Repair > Repair
  split Face identities menu asked once, kept the id on the selected piece and gave the other a new one, with the
  classification and choices unchanged.
- Zone 1 pasted into the blank destination kept its raw record and Face ids and showed hatched chips; the Adopt
  dialog's Cancel wrote nothing; Adopt created local options keeping the export id, names, colours and user_data,
  with exact native Undo and Redo. Both Models, saved and reopened in fresh processes, read identically.

## E17, integrated authoring, lifecycle and export

A copy of the E14 integrated model in a fresh process. A public export through the shipped Pyodide runtime
reloads in the pinned wheels equal to the native translation (2 Rooms, 12 Faces, 6 Apertures, 3 constructions,
4.22 m2, net areas 14.01, 9.76 and 19.01 m2). With west opened by a native double-click, one public assignment on a
Face in each Zone kept the path; native Undo restored all ten public projections exactly and Redo the assigned
rows. A second Model from native File > New took a write in its own session only. Native Save, native Quit and a
fresh process read all ten projections equal, unmodified, at the root. The export fault hook stopped a commit
after the HBJSON step; after a native Quit, the next public start to that destination restored both prior files
byte for byte and cleared the journal before refusing `export.replace_required`, the old handle refused
`task.expired`, and a consented start cancelled while queued wrote nothing.

## E14, Window Aperture export and net opaque area

The box probe built in a native File > New Model and the integrated Model from a fresh copy of
`envelope/reference-assigned.skp`, both through public actions. The probe export reloads in the shipped wheels
equal to the native translation (1 Room, 6 Faces, 6 Apertures, 3 constructions); a repeat export keeps the same
Aperture and construction ids; g = 0 and g = 1 each export with the constructions named as schema exceptions. The
15 aborted adversarial edits raise exactly the blocking and refusal codes of the 2026-10-16 matrix, and the Frame
operation mismatch stays informational. The integrated export through the panel's native Save panel reloads with
2 Rooms, 12 gross Faces, 6 Apertures, the Surface pair intact and gross parents equal to the no-Window export; net
opaque areas 14.01, 9.76 and 19.01 m2 agree in the export, the public read, the report and the native Schedule. A
Unit moved onto the paired Surface gives exactly `window.surface_host`. Native Close and Open Recent read every
value identically in a new session.

## E15, Window product library copy and export

A copy of `envelope/p209-p211-native.skp`, with the user's library setup backed up and restored byte for byte
afterwards. The synthetic provider `tools/examples/library/materials.json` was added through the native picker.
Native drags of its Frame and Glazing onto the selected element card each copied and assigned in one operation,
and one native "Undo Copy Library Record" each restored every inventory and Window Type reference exactly. A
provider Psi-Install Type staged and painted in the Installs editor left the Model untouched; Save wrote one
library-attributed product with one perimeter reference, and native Undo restored the baseline. The Export library
review listed 4 Materials, 1 Frame, 1 Glazing and 1 Psi-Install Type, and the written file reads back as 7 rows that
map to the local records with no warnings.
