# P3a-01 evidence: contracts and groundwork

DATE: 2026-10-15
STATUS: Host gate passed. Architecture review recorded below.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: [#133](https://github.com/bldgtyp/ph-composer/issues/133)

Branch `feature/spaces-p3a-01` from `main` at `1d9f593`. Register row S01.

## What changed

- **Nested-container rule (H1, D3a-1).** `Zones::Occurrences` treats a Group inside a Zone that
  carries a Zone stamp as a nested container: `walk_faces` skips it (so the Face list, Suggest,
  Solve and the Zone index skip it), `occurrence_for_path` answers nil for a pick through it (the
  Classify tool's click, drag and Shift-click), and `resolve_face_path` refuses a path through it as
  `target.wrong_hierarchy`. `Zones::ExportProjection.zone_faces` and `zone_owner` apply the same
  rule to the export snapshot, which still captures the Faces. Folded into `context/CONTRACTS.md`,
  "Zones geometry rules", and `context/TECH_STACK.md`, "Envelope".
- **Empty Room (H4, R05 item 1).** `ZoneSection.translate` refuses a Zone with no emitted Face as
  `object.unavailable`. `ZoneSection.attach` no longer asks a Face `translate` left out for its
  pair, which had refused the neighbouring Zone too. Recorded in validation-and-export's STATUS.
- **CONTRACTS section 8.** All nine questions answered, H1 and H4 rows corrected
  ([CONTRACTS](../CONTRACTS.md#8-p3a-01-contract-answers)).

## Offline

| Check | Result |
| --- | --- |
| `tests/zone_nested_container_test.rb` (five tests, written first; all five failed before the change) | Pass |
| `tests/python/test_model_sections.py::test_a_zone_whose_faces_are_all_omitted_is_refused_and_the_rest_reloads` (failed first: the Room could not be read back) | Pass |
| `tests/python/test_room_attachment.py` (contract answers 5, 6 and 8 on honeybee-ph 1.33.65) | Pass |
| Every existing Zones, Classify, Suggest, Solve, export, snapshot and Windows export suite, unchanged | Pass |
| `make ci` on Ruby 3.2.2, after `vendor.py --refresh-manifest` | Pass. Ruby 2.7.2 runs in GitHub CI |

## Host gate

SketchUp 26.1.188, Ruby 3.2.2, macOS. Installed RBZ built by `make ci` from this branch, SHA-256
`40b811e1fb21034a41cb7876eb7351780bc4ccef899266da3f2351defeb5a97c`. Fixture: a copy of the Phase 2
reference model (`_private/host/envelope/reference-assigned.skp`, two Zones, west and east, every
Face classified and assigned), SHA-256
`147a5638a3203381829bc35700530d5012b14fae3ad77ae330a5134ded7f7d9a`. Fresh process through the
bridge, session `d2a712f9-e5ef-4b4c-8f43-470c92cd1779`. Fixture arrangement by development eval,
labelled as such: one Group holding one 1 m square Face at z 0.5 m inside west, then a Zone stamp
for west written on the Group. Reads through the public API. Raw files in
`_private/host/spaces/p3a01/`.

| Step | Observation |
| --- | --- |
| Baseline, before the Group | west and east 6 Faces each, all classified; Suggest preview classifies 0; Solve preview `ok` with nothing affected; export preflight recorded |
| Group drawn, not stamped | west 7 Faces; Face `[49010, 49019]` unclassified; Suggest would classify 1; preflight adds `face.unclassified` |
| Group stamped | Face list, Zone Face counts, Suggest, Solve and export preflight equal to the baseline in every field but the session revision. The Zones / Faces table shows west with its six envelope Faces only |
| Native Classify click on the container Face (Classify tool, Floor, real click from a camera inside west) | Refused with "That Face is in no Zone. Make it a Zone first, then classify its Faces."; no Face record written, session revision unchanged |
| Stamp removed | The Face returns: "1 unclassified Face" under west in the table, Suggest would classify 1 |
| Restoration | SketchUp quit cleanly; the scratch copy was not saved over the fixture |

Not run natively: the Shift-click flood. It is the same refusal: the Classify tool asks
`occurrence_for_path` before it floods, and the offline test drives that path with the Shift
modifier. The click refusal reuses the generic "no Zone" sentence; Spaces' own tool (P3a-08) will
say what a Floor Segment is.

## Earlier cases the ledger screens

`acceptance_ledger.py status --changed` for the three changed source files lists 35 Phase 1,
Phase 2 and UI cases, because their dependency patterns cover all of `features/zones/`. None of
their fixtures holds a stamped Group, the only input the rule reads, so their behavior is unchanged
by construction, and every offline suite behind them passes unchanged. The host probe above is the
regression check on the reference model: with the container unstamped and stamped, the Face list,
Suggest, Solve and preflight read exactly as the rule predicts. They were not rerun one by one.

## Architecture review

Codex `gpt-6-astra` on PR #135, with the repository architecture rubric: one P1, two P2, all
accepted and fixed in the same pull request.

- P1: a classified Face inside a stamped container vanished from inventories but its record still
  reached the Face export, which then blocked as `face.wrong_zone`. The Face contributor now skips
  container Faces (`Zones::ExportProjection.contained?`); a test exports the two Zone Faces and not
  the container's.
- P2: the snapshot's container test read the stamp's truthiness while the live rule read its
  presence, so a stamp stored as `false` split them. Both now test presence; a parity test covers it.
- P2: contract answer 2 named `Zones::Occurrences.resolve_zone`, which is Zones-internal: the Zone
  target declares no public `locate:`. Corrected, and the public Zone locator is allocated to P3a-02
  as its step 0.

Second pass on the fix commit: two P2, both reproduced and fixed. A Surface Face whose counterpart
was already in a plain Group when solved, and then stamped, still read as a current pair and
exported against a Face no section exported; the counterpart check now applies the container rule
and the Face exports as `adjacency.unresolved`. And the Face export decoded a container Face's
record before skipping it, so an unreadable leftover record still blocked; the export and the
shared Face projection now leave container Faces out before reading anything stored on them. Two
review cycles is the loop's cap, so these fixes were not reviewed a third time. The review fixes
change only how export treats Faces inside a container, which the host run did not exercise; they
are covered offline.

The review also restated the two host limits already recorded above (Shift-click offline; the 35
screened cases judged unaffected). The S01 row now says "pass with two stated limits".
