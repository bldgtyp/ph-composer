# Panel domain ownership status

DATE: 2026-10-13
STATUS: Complete; merged to main 2026-10-13 in [PR #108](https://github.com/bldgtyp/ph-composer/pull/108) as `80b1d8f`, with the other delivery group 3 packet.
ISSUE: [#107](https://github.com/bldgtyp/ph-composer/issues/107)

The phased plan is the `## Stages` section of [PLAN.md](PLAN.md); there is no `phases/` folder.
Acceptance rows are in [ACCEPTANCE.md](ACCEPTANCE.md).

| Stage | Scope | State | Evidence |
| --- | --- | --- | --- |
| PD-01 | `Installs.topology_facts`; `display.install_topology` on Type rows; schema and fixture tests | Merged to main | `Installs.topology_facts`, `display.install_topology`, `INSTALL_TOPOLOGY` schema; `tests/window_install_topology_test.rb` (four cases: classification against `paint`, missing dimensions, copy key against `copy`, the panel-closed read); `docs/API_REFERENCE.md` regenerated |
| PD-02 | Installs editor consumes edges, `copy_key` and `copy_slots`; JS classifier and local topology deleted | Merged to main | Editor reads `edges`, `copy_key` and `copy_slots`; `editor_shared.classification` and the local `topology` deleted; fixtures carry the facts; two new cases (missing facts; only a matching key offered, facts kept through staging); 35 of 35 |
| PD-03 | Zone occurrence totals published and consumed; read cost measured | Merged to main | `face_area_m2` and `unclassified_face_area_m2` on Zone rows and in `units`; `tests/zone_area_totals_test.rb` (three cases); Overview and the preview host read them; measurement below |
| PD-04 | AGENT_INTERFACE and CONTRACTS wording; stronger review; dual-Ruby `make ci`; native observation | Merged to main | AGENT_INTERFACE "Focused reads" paragraph (CONTRACTS describes no Type or Zone row, so nothing to amend there); dual-Ruby `make ci`; native receipt below |

Reviewed against source on 2026-10-13. The slot key is the `[kind, row_span, column_span]` tuple
`Installs.copy` already joins on; the first draft's five stages collapsed to four.

One difference kept as it was: the editor offers glazed elements only, while `paintable` follows
`Installs.paint`, which accepts any non-empty element. The panel's existing glazed-only offer and
Save are unchanged; whether opaque elements should take installations is a product question for a
later packet.

Read cost (PD-03), measured on the host below, five runs each: with 412 Faces in three Zones,
`zones.all` 15.5 ms, `zones.faces.all` 53.4 ms, and the added totals alone 16.9 ms. The totals cost
is under the Faces read, the plan's working threshold, so no memo was added.

## Native receipt, 2026-10-13

SketchUp 26.1.188 (Ruby 3.2.2), current host, not the support floor; source `e89644d`, RBZ sha256 prefix `97b23da9c066f0bc`, same process as the Windows orchestration receipt. Panel gestures were real clicks in the
HtmlDialog through background computer use; the Psi-Install Type and the second Type's matching
columns were arranged through the API.

| Step | Observation |
| --- | --- |
| Overview, Zone and its x2-scaled copy | Area column 1162.5 ft² and 2066.67 ft² (108 and 192 m²); each equals the sum of its Face rows |
| Installs on Type Pair, click the left element's top edge | painted, value shown |
| Click the shared middle edge | nothing painted; the edge stays dotted with its derived zero |
| Copy to other Window Types | only "Pair copy" offered (equal published copy key) |
| Copy, Save Installs | "Installs saved."; both Types' left element top edge names the product |
| Save, quit, reopen | Zone totals 108, 192 and 100 m², each equal to its Face rows; both Types keep the install |


First review on PR 108 (gpt-6-astra): the copy key now digests dimensions as Floats, so `[1]` and
`[1.0]`, which `copy` accepts, share a key; the editor requires a complete one-to-one slot mapping
before staging a copy, and refuses a second copy to a Type changed in the Model, leaving the first
staged copy untouched. It also found that a change set's admitted write kept the caller's kind and
records by reference (from PR 105): `put` now stores frozen copies, and the two places that edited a
staged record afterwards (a Zone option create's `user_data`, an adopted option's remapped extension
data) now write it at creation or through `ChangeSet#restage`, which the write guard sees.

Second review on PR 108: the Zone reads now declare `geometry.invalid`, which the area totals can
raise, and validate each stored Face record as the Face read does, so an unreadable record refuses
with the Face read's code instead of being counted; the editor treats a topology without `edges`
or a well-formed edge as unread, and requires a copy key on both sides before offering a copy.

Final build: the bridge-driven scenario (placement, resize, locked-copy refusal and repair, Zone totals, an Installs save) passed again on the host at the merged head `58889ad` (RBZ sha256 prefix `73734abfe07c84ab`). Native Undo/Redo and the panel gestures ran at `e89644d` only.
