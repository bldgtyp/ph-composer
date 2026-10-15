# P3a-02 evidence: Space records and operations

DATE: 2026-10-15
STATUS: Host gate passed. Offline gates and reviews recorded per slice.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: [#133](https://github.com/bldgtyp/ph-composer/issues/133)

Two pull requests: slice A (records, scan, metrics, findings, reads, settings and the Zones seams,
[#136](https://github.com/bldgtyp/ph-composer/pull/136)) and slice B (the operations and the
walkthrough). Register row S02.

## Host gate

SketchUp 26.1.188, Ruby 3.2.2, macOS. Installed RBZ built from slice B at `d11cb21` (slice A at
`1d07b82` beneath it), SHA-256 `1c570942d9c97295ba4f22b354bf8dfccf67c097dab0c8fd9a17d8adf50c1736`.
Fixture: a copy of the Phase 2 reference model (`_private/host/envelope/reference-assigned.skp`,
Zones west and east), SHA-256 `147a5638a3203381829bc35700530d5012b14fae3ad77ae330a5134ded7f7d9a`.
Fresh process through the bridge, panel closed. Raw files in `_private/host/spaces/p3a02/`.

| Step | Control | Observation |
| --- | --- | --- |
| `SpacesWalkthrough.run` | bridge, public API only after drawing | Every step passed: Create Space from three 1 m outlines in west, a second Volume, one Floor Segment at weighting factor 0, height 2.7 m, supply 60 and extract 40, extract cleared, a stale edit refused with nothing written and retried. Read back 4.0 m² floor, 3.0 m² weighted, 10.6 m³ (3 × 2.7 + 1 × 2.5) |
| Native hierarchy | development eval, read only | west holds one Space Group named `1 Kitchen` carrying the Zone stamp, with two Volume Groups; the Zone Face list still holds only the twelve envelope Faces |
| Native Undo and Redo | computer use, Cmd+Z and Cmd+Shift+Z with SketchUp in front; a development observer recorded the Spaces state on each callback | Each of the seven writes undid as exactly one step, in reverse order (rename, extract cleared, airflows, height, factor, second Volume, Create Space), then the script's drawing steps. Fourteen Redos restored the final state equal to the pre-Undo read in every field |
| Native Copy and Paste In Place of the Space Group | computer use (Cmd+C, Edit > Paste In Place) | The copy carries the Space, Volume and Floor Segment records and the Zone stamp: two occurrences of one `spc_` id, both read `ambiguous`; the Zone Face list stays at twelve |
| Make Unique on the copy | development eval (`Group#make_unique` in an operation) | The copy's definition becomes its own; every Space, Volume and Floor Segment id is kept |
| Native Cut and Paste In Place | computer use (Cmd+X, Edit > Paste In Place) | One Space again, `found`; every record id and the Zone stamp kept; the Space Group's persistent id changed (49040 to 49157) |
| Save and fresh-process reopen | bridge | Supply 60 (set), extract absent, transfer 0 (explicit) and a Volume's `user_data` read back exactly as before the save |
| Two Models | bridge, two sessions | A second document with the same synthetic ids: an edit through its session renamed only its Space; the first Model read unchanged and unmodified |

What this feeds P3a-04: a native copy duplicates every Spaces record, so the D3a-14 copy watcher
sees a Space added with an id another live Space holds; a cut and paste leaves one occurrence with
its ids and a new persistent id, as the Zones copy watcher assumes; Make Unique keeps the records.

Reviews: slice A, Codex `gpt-6.1-sol` two passes on #136, 3 P1 and 4 P2, all fixed (orphan-Volume
Floor Segments in the inventory, locks and shared storage on the stamped container's path,
floor-area-weighted height, local-origin plan area, a forwarded refusal declared, a container inside
a container refused, Building-Segment and Model totals). Slice B, two passes on #137, 6 P1 and 3 P2,
all fixed (incoming-reference checks before every identity removal, including every record a deleted
Space erases; edge closure of the grouped set; strict resolution of a marked Face and its Volume,
orphan copies included; writes recheck locks, shared storage and copies at apply; kind-specific
reference schemas; repeated targets; two test preconditions). Two cycles is the loop's cap, so the
last fixes were not reviewed a third time. Fixes after the host run change refusals and checks, not
the behavior the run observed; they are covered offline.

Limits: SketchUp was killed at the end of the run because the second document's save prompt held
the quit; nothing was saved over a fixture. The panel table was not opened; the Zone Face list was
read through `ph_composer.zones.faces.list`.
