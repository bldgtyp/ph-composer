# P3a-12 evidence: Spaces acceptance and handoff

DATE: 2026-10-16
STATUS: Integrated host run done; superseded for the ledger by the 2026-10-16 acceptance rerun ([rerun evidence](../../../native-acceptance/evidence/phase-3a-rerun-2026-10-16.md)), which records S01 to S11 and the 31 screened earlier cases. D3a-19 merged (#173) and the footprint change merged (#172)
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: [#133](https://github.com/bldgtyp/ph-composer/issues/133)

Register row S12, and the host rows S03 to S11 and the D3a-13 addition, all run in one integrated pass
on 2026-10-16. Every "pass" below is a host observation; none has a ledger result (decision 1). Branch `feature/spaces-p3a-12` from `main` at `f9104523` (P3a-01 to P3a-11 merged).

## Decisions for Ed

Answered by Ed on 2026-10-16: 1, rerun under the procedure; 2, rerun all 31 cases in the same
session; 3, raise the limits to a 24 MB target and 26 MB ceiling with a 1.5 MB growth budget per phase
(D3a-20); 4, restore the user after a save, proved by a host spike first (D3a-19). The questions as
raised:

1. **Recording the host rows.** The run did not follow the native-acceptance procedure's recording
   steps: no `acceptance_run.py capture` baseline, no `observe` receipts, no ledger result. So
   `acceptance_ledger.py status` still reads S03 as blocked and S04 as not run, and the rows below are
   host observations, not accepted results. A result cannot honestly be recorded after the fact without
   the baseline. Choose: rerun the rows under the procedure in a short host session (the scripts in
   `_private/host/spaces/p3a12/` rebuild the model), or accept this file as their evidence and record
   that decision in the register.
2. **Reuse matrix.** `acceptance_ledger.py status`, screened against the 96 source files Phase 3a
   changed (`1d9f593..f9104523`), marks 31 earlier native cases `needs_recheck` (A02, A04, A05, A09,
   A11, R01 to R06, UXK1, E14, E15, E17, R11H, HGUI, PTAB, ZO-H1 to ZO-H3, ZO-O7, six UXR cases, GH41,
   GH43, GH47) and ten `historical_affected`. Their path patterns cover all of `features/zones/` and the
   shared panel files, so every Spaces change trips them. They were not rerun one by one. The
   integrated run exercised the Faces view, Classify paint, Colour by face type, Solve in the export
   preflight and the Surface pair, all unchanged. Choose: a separate host session that reruns the 31,
   or accept them by construction as P3a-01 did for 35 of them. S01, S05 and S06 each require "the
   cases the ledger screens are repeated", so they stay open until this is settled.
3. **Footprint.** The host-tested RBZ installs 23,994,063 bytes, and the branch head 23,994,083 after the
   comment edits: above the 22 MB target and under 6 KB short of the 24 MB ceiling (Phase 2 closed at 22,900,236). Phase 3b will cross the ceiling unless the
   budget is raised or the payload shrinks.
4. **D3a-19, still open.** Observed again: a native Cmd+S from inside an open Volume protects it and
   leaves the path at the Model root, not at the Space. The predecessor's native save restored the
   context. Both the Ruby save and the native save behave the same way here.

## Build and host

- Commit `f9104523`. Normal RBZ `dist/ph_composer.rbz`: SHA-256
  `045bc83eb86b60c606fb1585d627d27d09b35e5e7f2429e8e5a879cfc9430599`, 454 files, 7,766,082 bytes
  packed, 23,994,063 bytes installed. Eight wheels, the same set as Phase 2; the vendor manifest changed
  only by hashes. No new wheel.
- Installed with `make install` and `make bridge-install`; `acceptance_run.py package` reported
  `matches: true`.
- SketchUp 2026.1 build 26.1.188, macOS 26.6.2, embedded Ruby 3.2.2, fresh process
  (`host_bridge.py launch`).
- Fixture: a new copy of the Phase 2 reference model `_private/host/envelope/reference-assigned.skp`
  (SHA-256 `147a5638…f7d9a`), Zone A ("west") 5 x 4 x 3 m and Zone B ("east") 4 x 4 x 3 m. Raw evidence,
  scripts, captures and SKP states are in `_private/host/spaces/p3a12/`.
- The final commit differs from the host-tested build by comments only: the host-fact citations in
  `features/spaces/height_from_solid.rb` and two test files now point at the measured "Solid volume"
  section.
- Input: native rows used full-screen control (real keystrokes, clicks and drags posted by a
  screen-control client), and panel rows used background clicks into the dialog. Setup and readback went
  through the development bridge. `acceptance_run.py capture` and `observe` were not used. The
  provenance is this file plus `_private/host/spaces/p3a12/`.

## Reference model

The four Spaces of [ACCEPTANCE](../ACCEPTANCE.md), "Synthetic reference model". The outlines are drawn as a
user's script would (`Entities#add_face` inside each Zone's edit context), 5 cm below the envelope Floor.
Spaces 101 to 103 and 201 come from `ph_composer.spaces.create`; a fifth Space was made through the native
context menu (S08 below). Space 201's outline is the sloped face, off to the side of Zone B. The wedge is a
closed Group inside Space 201.

An outline flush with the walls just above the Floor splits the wall Faces, and Create Space refuses it
with `shares_edge`. The first attempt did exactly that and was discarded. Filed as
[#169](https://github.com/bldgtyp/ph-composer/issues/169).

| | Weighted area, m² | Floor area, m² | Net volume, m³ | Expected |
| --- | --- | --- | --- | --- |
| 101 | 12.0 | 12.0 | 30.0 | as expected |
| 102 | 4.0 | 4.0 | 9.6 | as expected |
| 103 | 4.0 | 6.0 | 20.0 | as expected |
| Zone A | 20.0 | 22.0 | 59.6 | as expected |
| 201 | 12.0 (projected) | 12.0 | 36.0 at 3.0 m | as expected |
| Model | 32.0 | 34.0 | 95.6 | as expected |

## Rows

**S03, contexts and reconciliation (native rows owed by P3a-03).**
- Escape from an open Volume leaves to the Space with the Volume locked again. The Undo menu reads
  "Close" only, so the protection joined it transparently. Undo reopens the Volume unprotected with
  "Redo Close" still offered, so nothing wrote after the Undo. Redo leaves it protected again.
- Native Rectangle at a Space root: a loose Face, no finding, both Volumes still protected. One Undo
  removes it.
- Native Move of an unprotected Volume raises `space.volume_unprotected` and `space.volume_moved`.
  Restore position, with the Space open, puts it back and locks it.
- Native Cmd+S with a Volume open saves it protected and leaves the path at the root (D3a-19 above). The
  earlier bridge save from inside an open Volume reopened in a fresh process with that Volume protected and
  not moved, no transform baked in; the file of the native save reopened with every Spaces record intact
  (D3a-13 below).
- Two Models: a second SKP opened beside the first had its own session. A write in it moved only its own
  revision (1 to 2, the first stayed at 1); closing it left one session.
- Undo counts, read from the Edit menu after every gesture below: each product gesture is one entry
  (the labels read were "Create Space", "Edit Space", "Edit Spaces", "Paste", "Copy" and "Make Space Independent"; the Mark floor gestures were counted by state).
  A "Close" entry appeared once between a native paste and Make independent and did not recur on a
  rerun. The likeliest cause is a stray Select-tool click outside the open Zone during setup. A Ruby
  `active_path=` change records an "Open" entry of its own (host fact below).

**S04, copies and Move.**
- Native Copy then Paste in Place of Space 102: the copy is made independent in the gesture's own Undo
  step with number 104 and new Space, Volume and Floor Segment ids, with no finding. One Undo removes
  copy and repair together.
- Move tool copy then `5x`: copies 104 to 108, every id unique, no finding. One Undo removes the whole
  array.
- Cut and Paste in Place of 102: left alone (same ids and values, new entity).
- A protected Volume cannot be copied natively: Cmd+C on a locked Group copies nothing. After
  unprotecting, Copy then Paste in Place of 103's Volume 2 raises `space.duplicate_identity` on both.
  Make independent clears it with new Volume and Segment ids, as one Undo step.
- A Move-tool copy of a Floor Segment Face raises `space.duplicate_identity` on both Faces. A Paste in
  Place of a Face onto itself merges with the original instead (host fact below).
- A Space pasted inside another Space (a stale clipboard after the locked copy) was made independent
  and flagged `space.nested`.
- Move Space to Zone from the panel row action: 102 moved to Zone B with its world points, ids, number
  and airflows unchanged and its Zone stamp rewritten; one Undo returned it. That Undo was SketchUp's
  own command run through the bridge (`Sketchup.undo`), because the menu item is disabled with
  SketchUp in the background.
- Not repeated here: the rotated-wrapper case, the repeated-component Space, Restore Zone, and Make
  independent keeping `user_data`. Their evidence stays with P3a-04.

**D3a-13, copied Zone.** Zone A holds 101 to 103 and one glued Window Unit (a synthetic Type). A native
Move copy 8 m along green gave:
- a new Zone `zon_239da4934524` whose Spaces keep numbers 101 to 103, airflows and metrics, with new
  Space, Volume and Floor Segment ids (7 Spaces, 9 Volumes, 9 Segments, all unique) stamped to the new
  Zone;
- the Unit copied with a new id on the same Type, and the originals unchanged;
- matching Zone totals (20.0 m², 59.6 m³, 60 / 40 / 20 m³/h);
- one Undo restoring the before state exactly, and Redo restoring the after state exactly;
- a native save and fresh-process reopen with every id, reference and value identical.

The panel export reloads with three Rooms. The copied Room carries its own three Spaces, with distinct ids
and the same weighted area, net volume and airflows (iCFA 52.0 m², net volume 155.2 m³ for the Model).

**S06, Zone views.** The Spaces view returned after reopening the panel and after a fresh-process reopen
of the Model. A text filter and the expanded Zones survived a switch to Faces and back. A switch of view
stopped a running Classify paint and a running Mark floor cleanly. The synthetic Zone-only view and the
Locate-across-switch check were not rerun. Filter behavior noted in [#170](https://github.com/bldgtyp/ph-composer/issues/170).

**S07, Spaces view.**
- In-place edits commit on Return, and the any-set rule shows the other rates as 0 once one is set.
- Zone A sums 60 / 40 / 20 with the imbalance marker. Zone B shows the dash while 201 inherits, and so
  did Zone A while a fifth inheriting Space sat in it.
- A typed weighting factor of 0.6 on a Segment row changed the Zone's weighted area to 20.6 and added
  0.6 to the column menu's paint choices (D3a-17).
- A 3 x 2 range paste set 101's supply to 65 and 102's extract to 45, left the blank cells' rates
  unset, and was one Undo step ("Edit Spaces").
- Cmd+Z with the panel focused does nothing: [#168](https://github.com/bldgtyp/ph-composer/issues/168).
- The 300-Space unit switch timing stays with [#154](https://github.com/bldgtyp/ph-composer/issues/154).

**S08, Mark floor and Create Space.**
- Create Space from SketchUp's context menu (PH-Composer, Create Space…) on a loose Face in an open Zone
  showed the review with number and name. It made 104 "Spare" as one Undo step, Undo returned the loose
  Face with its persistent id, and Redo brought back the same Space id.
- Mark floor started from the Weighting factor column menu at 0, 1 and 0.6. It turned Colour by
  weighting factor on and showed the pressed glyph and the status bar prompt.
- A click marked one Segment; a held drag across 101 and 102 marked both; each gesture was one Undo
  step.
- A loose Zone Face offered Create Space (tooltip and status bar), writing nothing.
- A classified wall refused with its reason on the status bar.
- Escape, the pressed glyph and switching to Select each stopped the tool.
- Classify then Mark floor, each started from its own column menu, left one active tool.
- When either tool stops, its Colour-by mode stays on (#170, item 6).

**S09, Spaces modes.**
- Space, Ventilation, Weighting factor and Height each coloured the prisms, and Floor Segment faces
  alike. 201's prism is based on the projected face.
- The legends read correctly: Height 2.5 m (2) 40 m³, Weighting factor 1 (4) 32 m² and 0 (1) 2 m².
- Space labels and selection totals both showed with no mode active. Two Spaces read 16 m², 39.6 m³,
  supply 60 and extract 40; in IP, 172.22 ft², 1398.46 ft³, 35.3 and 23.5 cfm.
- By Space colours were identical after a fresh-process reopen.
- Cycling the modes left the Model's entity, dictionary, material and definition digests unchanged.

**S10, export.** The normal packaged RBZ exported through the export task and through the panel's
native destination dialog. The first destination was approved through the development bridge
(`ApprovedLocations.approve`), standing in for the native dialog, and revoked afterwards. The panel
export used the real dialog. With honeybee-ph 1.33.65 in the repository venv, the reload showed:
- each Space on its Zone's Room with name, number, quantity 1, volumes, heights, weighting factors and
  geometry;
- iCFA 32.0 m² and net volume 95.6 m³, equal to the panel;
- 101 `_v_sup` 0.016667 m³/s with explicit zeros, 102 `_v_eta` 0.011111, 103 `_v_tran` 0.005556, and
  201 with none of the three;
- `user_data` set on 102's Space, Volume and Floor Segment arriving on `Space`, `SpaceVolume` and
  `SpaceFloorSegment`.

The preflight listed the non-horizontal Segment, the Zone imbalance and the off-to-the-side Space. The
report carried the per-Zone schedule with Zone totals and the off-to-the-side line for 201. The blocking
rows and the metadata guard are covered offline in P3a-10 and were not forced on the host.

**S11, Height from solid.**
- The Volume row action read the wedge and asked "The solid encloses 36 m³ over a net floor area of
  12 m², so the average clear ceiling height becomes 3 m". Set height wrote 3.0 m.
- The wedge carries no dictionary and still measures 36.0 m³.
- Refusals: an open box and a Group holding only a Group both refuse as "not a closed solid"; a Volume
  or Space chosen as the solid refuses `target.wrong_kind`.
- A Group holding two separate solids is accepted with their summed volume.
- The zero-area refusal is offline only. The native Undo of the height was not observed, so S11 is partly
  observed; that Undo is owed.

**S12, integration.** The PRD's host gate ran in order, with the exceptions stated above, from fresh
processes on the reference model. The offline gates and the package are below.

## Host measurements

Recorded in [`context/SKETCHUP_HOST_BEHAVIOR.md`](../../../../context/SKETCHUP_HOST_BEHAVIOR.md): the
"Solid volume" section, the held-drag `MK_LBUTTON` row, and the row on context changes as Undo entries.
- `volume` applies the instance's own transform and no parent's. An open ancestor's scale is already
  in the child's reading. A Group of Groups reports -1; two disjoint solids sum.
- A held drag on macOS carries `MK_LBUTTON` (2) on every move: 258 throughout and 256 on release. The
  probe log is in `_private/host/spaces/p3a12/flags.json`.
- A Paste in Place of a Face onto itself merges into one Face.

## Reuse matrix

| Row | Stage evidence | At `f9104523` |
| --- | --- | --- |
| S01 | P3a-01 | Open. Rule re-observed: floor outlines in Space Groups are absent from the Faces view and the export snapshot. Its 35 screened earlier cases are in decision 1 |
| S02 | P3a-02 | Retained offline; on the host, airflows absent, zero and set, `user_data` on all three records, edit, Undo and reopen all re-observed |
| S03 | P3a-03 bridge rows | Native rows run here; bridge rows retained |
| S04 | P3a-04 bridge rows | Native rows run here; rotated wrapper, repeated component and Restore Zone retained from P3a-04 |
| S05 | P3a-05 offline | Draw cost at the overlay spike's size not re-measured; its screened Colour-by cases are in decision 1 |
| S06 | P3a-06 offline | Partly run here (above); the synthetic Zone-only view and the screened Zones / Faces cases are in decision 1 |
| S07 | P3a-07 offline | Run here, except the 300-Space timing (#154) |
| S08 | P3a-08 offline | Run here |
| S09 | P3a-09 offline | Run here |
| S10 | P3a-10 offline | Run here |
| S11 | P3a-11 offline | Run here except the native Undo, which is owed |

## Offline gates

Run on the branch head; `make ci` runs again before each commit.
- `make ci` on Ruby 3.2.2 passes: 1,871 Ruby runs, 21,816 assertions, 0 failures; 657 panel tests; 240
  Python tests; the RBZ verified.
- `make ci` on Ruby 2.7.2 passes with the same counts.
- `make coverage`: Ruby 97.0 percent of 19,451 lines (floor 93), JavaScript 96.8 percent of 13,082 lines
  (floor 94), Python 95.33 percent (floor 92).
- `make ui-checks` passes, with Playwright resolved from a scratch `node_modules` as
  `tools/ui-preview/.index.md` describes. It includes the 300-Space unit switch in the preview, every
  row open, at a median of 815 ms; that is a browser figure, not the host measurement #154 asks for.
- `make runtime-check` and `make runtime-browser-check` pass, the latter with `chromium_88: true`.

## Follow-ups filed

[#168](https://github.com/bldgtyp/ph-composer/issues/168) panel Undo shortcuts,
[#169](https://github.com/bldgtyp/ph-composer/issues/169) flush outlines split walls,
[#170](https://github.com/bldgtyp/ph-composer/issues/170) wording and display points. The doubled
"Nothing was written." on a Create Space refusal is [#157](https://github.com/bldgtyp/ph-composer/issues/157).
