# P3a-07 evidence: the Spaces view

DATE: 2026-10-16
STATUS: Slices A to C2 merged through #150 (`7619964`), #151 (`a9d2f72`), #152 (`34db51a`) and #153 (`803e95b`); slice D in review; host gate pending
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: [#133](https://github.com/bldgtyp/ph-composer/issues/133)

Register row S07. Delivered in four slices, one pull request each: A rows and read-only columns; B editing
and airflow entry (steps 4 to 6); C the selection bar, row actions, findings, Colour by weighting factor and
the shared checked Zones carried from P3a-06 (steps 8 to 11 and 17); D preview fixtures, the unit-switch
measurement and docs (steps 14 to 16). Slice C went out in two parts: C1 (steps 7's finding, 9, 10 and
11) and C2 (step 8 and 17).

## Slice A: rows, columns and Zone sums

`html/features/spaces/view.js` registers the Spaces view under the Zones tab's host (step 1), with no file
under `html/features/zones/` naming it. Beneath each Zone, its Spaces, each Space's Volumes and each
Volume's Floor Segments ("Segment" in the hierarchy column), with no Space Floor row; a Space no Zone holds
sits under one "Outside every Zone" group row after the Zones (step 2). Columns follow step 3: No. before
Name, then Floor area, Weighting factor, Weighted area, Height, Net volume, Supply, Extract and Transfer;
Building-Segment, Level and Net area factor are hidden at first and offered in Table options. Every figure
is the snapshot's: Space rows show the area-weighted average height muted, with the rule in its tooltip.
Airflow cells follow step 6's three states (a set rate, a muted 0, a muted "Zone"); Zone rows carry the
snapshot's sums, a muted dash naming the inheriting count while any Space inherits, and the amber marker
with supply, extract and the difference when the host flags the imbalance (step 7's display; the finding
lands with slice C). The kit formatter drops trailing zeros, so "22" reads where the mockup shows "22.00".

Kit and host changes the view needed, each documented in `context/EXTENSIBILITY.md`, "Zone views": the
shared table's `tiers` option and fourth-tier indent (H19), a muted cell style, and the host hooks
`extraRows`, `leadingColumns`, `tiers`, `hiddenColumns`, `optionalColumns`, `count` and `placeholder`;
Expand all and Collapse all reach every row with rows beneath it.

Tests: `tests/spaces_view_panel_test.js` (phase doc tests 1, 6 and 10 for slice A: the projection with a
multi-Volume Space and a Space outside every Zone, the airflow states, the marker and the inheriting dash,
sorting, the hidden columns, and no action sent by filtering, sorting or expansion) on a synthetic snapshot
of the reference model (`tests/support/spaces_fixture.js`), and `tests/table_test.js` for the fourth tier.
The threshold's boundaries are tested on the host side (`spaces_records_test.rb`).

Review: Codex `gpt-6.1-sol` on #150. The first pass found four P2 (the group row counted and sorted as a Zone;
Expand all disabled while nested rows started shut; a hidden column kept its filter; the Expand defaults),
the second three P2 (Table options could hide a held Zone edit; a view's older copy of a Zone filter could
replace the one set since; a leading column missed the view's header and menu hooks). Each was reproduced by
a test and fixed; the second pass's three were gated by `make ci` only, at the review cap.

## Slice B: editing and airflow entry

`html/features/spaces/cells.js` makes the view's editable cells through the shared record drafts and the
range-edit grid: a Space's number, name and three airflows, a Volume's name and height, a Floor Segment's
name, weighting factor and net area factor (steps 4 to 6). A cell commit is one `ph_composer.spaces.update`
with `expected_values` as read (a key absent where the value was unset); a refusal keeps the draft with the
host's reason. A range fill or a paste is one `batch_update`, every change to one record merged into one
edit; a pasted blank over a rate that was never set is left out. Factors outside 0 to 1 refuse at the cell.
An airflow cell keeps unset distinct from zero: a blank commit sends `null`, a typed 0 is a value, and an
unset rate shows its muted placeholder ("0" beside a set rate, "Zone" on an inheriting Space). Display
follows the unit preference; a draft keeps its typed text through a switch. The phase doc names
`volumes.update` and `floors.update`; the host has one `update` for all three kinds, which this uses.

The host gained `attach`, `prepare` and `painted` for it (`context/EXTENSIBILITY.md`, "Zone views").

Tests: `tests/spaces_cells_panel_test.js` (phase doc tests 2 to 5 and 9: one update per commit, a refusal
keeping the draft, the factor range, the zero and clear cases, the three airflow states, a range fill and a
paste each as one `batch_update`, a unit switch). Clearing the last set rate returning a Space to inheriting
is the host's any-set rule (`spaces_reads_test.rb`); the panel sends the clear.

Seen in the panel (the preview page fed the reference model's snapshot): an editable height read "2500"
under "Height m" (its field carried a dimension scope, whose default is mm), numbers edited in place sat
left of the read-only numbers, and the range-edit tools stood in a row of their own. Heights now edit in
metres, a numeric cell input right-aligns (kit class `is-numeric`), and each view has a tools slot in the
shared controls row holding its help and what it binds there.

Slice B review: Codex `gpt-6.1-sol` on #151. The first pass found four P2 (cells a row chevron revealed
missed the range grid; Volume and Floor Segment names could not be cleared; a refused draft had no visible
Cancel; shutting a row could hide a held draft), the second three P2 (a Space removed under a draft
re-entered the drafts' refresh through the notice and overflowed the stack; the guard offered Cancel for an
edit already sent; the paste test never cleared a set rate). Each was reproduced by a test and fixed (the
kit table now calls `options.painted` after every paint and asks `options.mayToggle` before a row opens or
shuts); the second pass's three were gated by `make ci` only, at the review cap.

## Slice C1: row actions, findings and Colour by weighting factor

Host: the Zone rows of the `spaces` read carry `space.airflow_imbalance` (non-blocking) when the host flags
the imbalance (step 7's finding; P3a-10's preflight lists it), and every finding may name its `repair`
(`make_independent` for a copy that can be made independent, `restore_position` for a moved Volume), so a
reader offers the repair without reading words. `features/spaces/colour_modes.rb` registers
`ph_composer.spaces.by_weighting_factor` over every Floor Segment face, one band per factor in use, keyed by
its shortest exact text, which the read publishes on each Floor Segment row (`weighting_band`) so the
legend and the panel's filter use one string (step 11; nothing under `colour_by/` names it).

Panel: `html/features/spaces/actions.js` gives each row its actions (step 9): Locate every row (the
`locate` view command); Open or Close a Space and Enter a Volume (unprotect, then `context.open` once that
completes); Delete a Space and Remove a Volume after a confirmation in the shared dialog naming what goes;
Move a Space to another Zone, chosen in the shared dialog; and the repair a finding names. Every Model change
carries `expected_revision`, so a row from a stale snapshot refuses, and a refusal shows the host's reason.
The open row is the one on the snapshot's edit path (the host's new `selected` hook). Each Space, Volume and
Floor Segment row shows its findings as its marker, those blocking export first (step 10). The Weighting
factor column filters by band, reaches the viewport as the matching Floor Segment faces, and carries the
mode's Colour-by toggle. The Spaces view widens the Hierarchy column for four indented levels with markers.

Tests: `tests/spaces_actions_panel_test.js` (phase doc test 8 and the filter), `tests/spaces_colour_modes_test.rb`
(test 11), and the finding and repair assertions in `spaces_reads_test.rb`, `spaces_identity_test.rb` and
`spaces_context_test.rb`.

Slice C1 review: Codex `gpt-6.1-sol` on #152. The first pass found one P1 (a confirmation sent the revision
current at its commit, not at its opening) and five P2 (row changes ignored a held cell draft; rounded band
keys merged nearby factors; outside-Zone rows missed the viewport mask; descendants of a copied Space offered
a repair that refuses; Close on a Space left it open under an open Volume); the second three P2 (a copied
Volume's Floor Segments pointed to the Space rather than the Volume; six-decimal keys still merged factors and
rounded differently in Ruby and JavaScript, so the host now publishes the band; confirmations for unnamed
records named nothing). Each was reproduced by a test and fixed; the second pass's three were gated by
`make ci` only, at the review cap.

## Slice C2: the selection bar and shared checked Zones

`html/features/spaces/selection.js` holds the view's checked rows and its selection bar (step 8). A row's box
checks it and everything beneath it, so a Zone's box checks every Space, Volume and Floor Segment in the Zone
and reads mixed while only some are; the header box checks every row the filters show; Escape clears. The
bar shows one group of controls for each kind it holds: the weighting and net area factors for Floor Segments,
the height for Volumes, the three airflows for Spaces. A value the checked rows of that kind share shows in
its field, one they do not share reads "Mixed", and each choice applies to every checked row of that kind as
one `batch_update`; a blank airflow clears the rate on the rows that have one, and a factor outside 0 to 1
refuses at the bar. The plan's "a mixed set shows the controls its rows share" is read as one group per kind
present, since a Zone's box always checks several kinds.

Shared checked Zones (step 17, carried from P3a-06): on a switch the host asks the old view which Zone rows
are fully checked and hands them to the new view, which checks everything beneath them; the Faces view and
the Spaces view both supply `checkedZones` and `checkZones`. `context/EXTENSIBILITY.md`, "Zone views", says so.

Tests: `tests/spaces_selection_panel_test.js` (phase doc test 7 and step 17's test).

Seen in the panel with Hall checked: Supply and Extract read "Mixed" for one Space with neither rate set,
because "the rows differ" and "unset" shared one marker; a value the rows share, unset included, now reads as
itself.

Slice C2 review, first pass: Codex `gpt-6.1-sol` on #153 found two P1 (a bar draft read in the unit current at
Enter rather than the one typed in; a bar draft guarded by the values at Enter rather than at its start) and
four P2 (Enter on an unedited field wrote the rounded display back; a bar draft did not hold a view switch; a
refused bar entry lost its text; an automatic switch skipped the checked-Zone hand-over). Each was reproduced
by a test and fixed: a bar field fixes its unit and its target rows with their values at the first keystroke,
sends nothing for unchanged text, keeps refused text until it is corrected or Escape restores the Model's
value, and holds a switch meanwhile; the host's automatic switch hands checked Zones over as an explicit one.

Second pass: three P1 (the checked set could change under an open bar draft, so the draft wrote rows the bar
no longer showed; correcting a refused entry re-read it in the current unit; rows whose value already
matched were left out of the batch, so the host could not refuse a stale selection whole) and three P2 (Enter
on an untouched Mixed airflow did nothing; an automatic switch handed Zones to a view before it had read the
snapshot; a held bar entry had no visible Cancel). Each was reproduced by a test and fixed: the checked set
holds while a bar draft is open; a corrected entry keeps its first unit; every checked row goes in the batch
(the host checks each and skips the writes that change nothing); Enter on an empty Mixed optional field
clears it; the hand-over waits for the destination to consume; the bar shows Cancel beside a held entry. These
were gated by `make ci` only, at the review cap.

## Slice D: preview fixtures, the unit-switch measurement and docs

The preview host now publishes the fixture's `spaces` section (step 15): `?fixture=spaces` is the reference
model on the authoring Zones, `spacesempty` an empty Model, `spaceslarge` 300 Spaces.
`tools/ui-preview/spaces_checks.cjs` checks the reference model's rows, Zone marker, inheriting airflow, layout
at 1280, 900 and 420 px and the selection bar; the empty Model's Zones alone; and measures the unit switch on
300 Spaces (step 14): median 408 ms with the Zones open and 786 ms with every row open, each to the first
painted frame, desktop Chrome on an Apple M1 Max. The units STATUS records the measurement and the decision not to optimize in this stage, with
issue [#154](https://github.com/bldgtyp/ph-composer/issues/154) carrying the investigation. The browser checks
run in current Chrome, not Chromium 88; the host gate covers that.

Docs (step 16): `docs/PRODUCT.md`'s Spaces section describes the Spaces view as built (no Level rail, no
separate balance view, column widths for the session), and `context/UBIQUITOUS_LANGUAGE.md` replaces the
Airflow balance view with the Zone rows' airflow balance and the iCFA factor with the weighting factor
(D3a-17).

## Host

Not run. The S07 gate is batched with the S03 to S06 native rows.

