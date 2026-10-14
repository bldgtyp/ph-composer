# Phase 3a, Spaces: what the merged foundation changed, and the decisions that follow

DATE: 2026-10-12
STATUS: Scoped. Part 1 is findings read from source on `main` at `70c340f` and from the predecessor at `f358ebf`. Part 2's twelve decisions remain unanswered. D3a-13 is confirmed; mechanism and acceptance pending.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

The [Spaces PRD](PRD.md) was interviewed on 2026-09-18, before the foundation existed and
before Phases 1 and 2 were built. It says its PLAN "follows the overlay spike and the foundation
transplant". This file is the review of that PRD against what is now on `main`. Part 1 lists what
differs. Part 2 lists the choices the differences force. The bindings are in
[CONTRACTS.md](CONTRACTS.md).

Paths are relative to `src/ph_composer/` unless stated. Predecessor paths are relative to
`../ph-navigator-sketchup/src/ph_navigator_sketchup/`. "Read from source" means the file was read,
not that the consequence was reproduced in a test or on a host. Nothing in Part 1 was reproduced.
P3a-01 reproduces each finding it depends on before acting on it.

Thermal bridges has no rows here; it is [Phase 3b](../phase-03b-thermal-bridges/DECISIONS.md). The
ids here were renumbered on 2026-10-03 when Phase 3 split: D3-1 to D3-12 became D3a-1 to D3a-12
and stages P3-01 to P3-12 became P3a-01 to P3a-12. F ids are unchanged.

## Part 1: findings

### Foundation the PRD assumed and that did not land

| # | Finding | Consequence for Spaces |
| --- | --- | --- |
| F1 | No deferred-reconciliation primitive exists. The PRD's disposition says the generic `PendingWork` and `UndoLedger` "land with the foundation transplant". They did not: `context/TECH_STACK.md`, "Observers report; deferred work mutates", describes them as the predecessor's, and a search of `core/` and `session/` finds only `session/timer.rb` (`CoalescedTimer`). The one worked example of deferred work is `Zones::Names::State` (`features/zones/zone/names.rb`) | The plan owns them. P3a-03 ports `reconciler/pending_work.rb` (64 lines) and `undo_ledger.rb` (81) as shared primitives that name no feature, with Spaces as the first user. Where they live is D3a-4 |
| F2 | Nothing assigns `model.active_path`. `context/TECH_STACK.md`, "Treat the active editing path as data", requires exactly one module to do so and a test that refuses any other. In the predecessor that module was `Spaces::ActivePath`, and Assemblies and Windows called into it | Under the layering (D2-1) Spaces is layer 3 and nothing below it may name it. The single writer is a foundation module, Spaces is its first caller, and the refusing test lands with it in P3a-03 |
| F3 | Nothing writes lock state, and no feature subscribes to `:pre_save` or `:post_save`. The host events exist (`session/host_observers.rb`, `Sessions::HOST_EVENTS`) | Volume protection, exit protection and the pre-save rule are first of their kind here. P3a-03 owns them and gets the stronger review |
| F4 | Identity is `Records::Identity`: a prefix and twelve characters, stored through `Records::EntityStore` and described with a `Records::ReferenceTarget`. The PRD says "a UUID ... as the predecessor's `identifiers.rb` issues it" | Bind to the foundation: `spc_`, `vol_` and `fsg_` ids. `identifiers.rb` (18 lines) is dropped, not ported. The PRD's Records section and disposition row are corrected when Ed confirms D3a-2 |
| F5 | There is no generic `duplicate_identity` finding and no Make independent. Three feature-local repairs exist: `zones.repair_identity`, `SplitIdentityRepair`, and Windows' `IdentityPlan` with `IdentityStep` | Spaces needs a fourth. Local or promoted is D3a-3 |
| F6 | Ruby `core/units.rb` has no `volume` and no `airflow` quantity. The panel's `html/unit_tables.js` has both (m3 and ft3; m3/h and cfm) | The Ruby rows are added in P3a-01. Ruby still formats no unit-bearing text; the rows exist for the Ruby length and number readers and for the report |
| F7 | The record engine has no migrations and treats an unknown key as unreadable (Phase 2 F6) | All three Spaces records ship version 1 with their final field set in P3a-02, the airflow fields included, although the airflow screens arrive in P3a-08 |

### Zones and the Face walk

| # | Finding | Consequence for Spaces |
| --- | --- | --- |
| F8 | `Zones::Occurrences.walk_faces` descends into every Group inside a Zone, skipping only a Group that carries a Zone record and a cutting component (`features/zones/zone/occurrences.rb:325-336`). `export/geometry_snapshot.rb` walks the same way. D2-5 covered cutting components only | A Space group sits inside its Zone group, so every Floor Segment face would be reported as an unclassified Zone Face: offered to Suggest classification, reachable by the Shift-click flood, seen by Solve and captured for export. Zones needs a host-level rule that names no feature before the first Space is created, exactly as D2-5 preceded the first window unit. See D3a-1 |
| F9 | The Zone stamp store (`ph_composer.zone_stamp`) exists, and `context/CONTRACTS.md` already lists "Space Groups when they exist" as a stamped entity. Restore Zone reads Face stamps only | The stamp on a Space group is the natural marker for D3a-1's rule. P3a-04 extends Restore Zone and orphaned-contents detection to Space stamps (zones Q14) |

### Colour-by and the viewport

| # | Finding | Consequence for Spaces |
| --- | --- | --- |
| F10 | A Colour-by entry needs a live entity; `colour_by/tessellation.rb` draws Faces and recurses into Groups and Components. Derived geometry is unsupported (Phase 2 F20). There is no readout registration: the HUD is drawn by `colour_by/overlay.rb` from the legend alone | The volume preview prism, Space labels and selection totals all need the extension D2-6 deferred to this phase. P3a-05 builds it as a foundation stage before any Spaces mode needs it. Its shape is D3a-5 |
| F11 | `entity_kind` is already open prose in `colour_mode` | Spaces Q22's "open entity kind" needs no change. Only derived geometry and readouts are new |
| F12 | There is no toolbar; nothing uses `UI::Toolbar`. There is no shared drawing-tool state: Classify and Place each call `model.select_tool`, and the panel's pressed state is per feature | The PRD's "beside the Classify tool on the toolbar" and "one of the two is pressed at a time" describe things that do not exist. See D3a-7 |
| F13 | `core/pick.rb` and `core/drag_set.rb` already carry comments naming Mark floor as a later user | Mark floor reuses both unchanged. P3a-06 confirms it adds nothing to either |

### Panel

| # | Finding | Consequence for Spaces |
| --- | --- | --- |
| F14 | `html/index.html` has a disabled "Spaces · Planned" tab and no Spaces pane. The Zones / Faces tree (`html/features/zones/overview.js`) is a fixed two-level Zone to Face projection that does not call `composeTable`, so another feature cannot contribute child rows to it | Spaces Q11 and face-assignment Q11 said "one tree" with the faces table as a sibling under each Zone. As built, that tree would have to be rewritten or the Spaces feature would have to edit Zones' panel module. See D3a-6 |
| F15 | `html/inventory_grid.js` has range selection, TSV paste and fill; `html/record_edits.js` has inline drafts. No right-click cell menu exists anywhere in `html/` | Range edit and paste are reuse. Select by (Q12) is a UI kit addition in P3a-07 |
| F16 | Units follow-up U1-F1: a unit switch on a 300-Space table repainted every cell at a median 513 ms in the predecessor, and the units packet leaves the optimization with Spaces "if measurements justify it" | P3a-07 measures it on the new table and records the number before deciding |

### Metrics and export

| # | Finding | Consequence for Spaces |
| --- | --- | --- |
| F17 | The predecessor's flatten rule lives only in Python (`spaces/geometry.py`, `authored.py:64-77`). It flattens a face whose z-spread is under 1 mm and omits one whose spread is larger. Ruby `metrics.rb` uses true `face.area` | Spaces Q14 and Q23 allow any non-horizontal face and use its projected horizontal area in metrics, preview and export alike. That is a replacement in both languages, not a port. The PRD's disposition says "Adapt ... adds the floor projection"; the omit branch is removed |
| F18 | The Python `Attachment` already names `ROOM` as a host, and `ApertureSection` is the working example of a section that attaches to an object another section built (`python/ph_composer_translation/sections.py`, `window_sections.py`) | The Spaces section attaches each `Space` to its Zone's Room with `Attachment(ROOM, key=zone id)`. The PRD's "open foundation question" about a section dependency is closed, as assemblies' was by Phase 2 F9 |
| F19 | PHX is not vendored (eight wheels, none PHX) and METr is deferred by D12 | Every "through PHX" and "PHX writes the METr rooms" step in the PRD's acceptance moves to [metr-export](../unscheduled/metr-export/README.md), as Phase 2 F13 did. Spaces closes on HBJSON reloaded in the pinned honeybee stack |
| F20 | honeybee-ph's `SpaceProperties.has_ventilation_flow_rates` is `any([_v_sup, _v_eta, _v_tran])`, which is false when all three are 0. PHX tests each rate with `is not None` (`PHX/from_HBJSON/create_rooms.py:133`). Read from source in the sibling checkouts; not run, and the pinned honeybee-ph 1.33.65 was not checked against it | A user-specified Space with three explicit zeros stores three zeros and reads back as three zeros, but that honeybee-ph property reports false. P3a-10 asserts on the stored `_v_*` values, not on the property. Nothing here is called a defect; the consumer consequence belongs to metr-export when it resumes |
| F21 | Ruby registration checks that a contributor's section reads are declared and owned by a required feature, and has no cycle check among section reads (R05 item 2). `ZoneSection` builds `Room(id, [])` when every Face is omitted (R05 item 1) | Both are settled in P3a-01, before the Spaces contributor exists |
| F22 | The export report has a per-contributor hook: `report: ->(ResultView, display_units) { [html_section] }` | The Spaces schedule per Zone is one contributor's report section. No report seam is added |

## Part 2: decisions for Ed

Each row says whether it is a UI choice or a code-structure choice, gives a recommendation and
names the stage it blocks. None is answered.

| ID | Kind | Question | Recommendation | Blocks | Ed's answer |
| --- | --- | --- | --- | --- | --- |
| D3a-1 | Code | What does Zones do with a Space group inside a Zone? (F8) | One host-level rule in Zones that names no feature: a Group inside a Zone that carries a Zone stamp is a nested authoring container, and its Faces are not Zone Faces. The walk, the export snapshot, Suggest, the Shift-click flood and Solve skip it. Spaces writes the stamp at creation, which `context/CONTRACTS.md` already expects. Zones still never names Spaces. The alternative, Zones asking "is this a Space?", would make layer 2 depend on layer 3 | P3a-01 | |
| D3a-2 | Code | Which identity do Space, Volume and Floor Segment carry? (F4) | The foundation's: `spc_`, `vol_`, `fsg_` ids through `EntityStore`, with a `ReferenceTarget` each. No UUID. This amends the PRD's Records section; the honeybee-ph identifiers still derive from the id | P3a-02 | |
| D3a-3 | Code | Is `duplicate_identity` with Make independent Spaces-local or a shared contract? (F5) | Spaces-local, shaped like Windows' `IdentityPlan` and `IdentityStep`: a pure plan and a step added to the caller's proposal. Three existing repairs differ in their keeper rule, so a shared contract would be designed against four users at once inside a feature stage. Record the consolidation as a refactor candidate when P3a-04 closes, with four real shapes to compare. The reason is design evidence, not protecting existing code: nothing here needs a migration path | P3a-04 | |
| D3a-4 | Code | Where do the edit-context writer and the deferred-work primitives live? (F1, F2) | In `session/`, naming no feature: one edit-context module that is the only `active_path=` writer, and one deferred-work primitive (the coalesced queue plus the Undo ledger). Spaces composes them in its own reconciler, which stays in `features/spaces/`. `Zones::Names::State` is not migrated onto the primitive in this phase; record it as a follow-up once the primitive has a second shape to fit. Again the reason is design evidence, not staging: moving it now would shape the primitive around one caller's guess at another | P3a-03 | |
| D3a-5 | Code | What is the Colour-by extension, and are the Window Type operation marks built with it? (F10) | Two additions to the existing contract and no new framework. One: an `Entry` may carry `derived`, a list of world-space polygons and segments the service fills and outlines in the entry's colour, with or without a backing entity. Two: `FeatureScope#colour_readout`, a separately registered pure projection that returns viewport text anchors or HUD lines, shown with any mode and with none. Build the operation marks in the same stage as the second real user: a contract proven only by a synthetic mode and one feature is not proven, and D2-6 asked for one design against both | P3a-05 | |
| D3a-6 | UI | Where does the Space tree live? (F14) | On its own Spaces tab, enabling the pane that is already reserved: a Zone, Space, Volume, Floor Segment tree with the airflow balance view as its second subtab. The Zones / Faces tab keeps its Zone to Face tree unchanged. This amends spaces Q11 and face-assignment Q11 ("one tree") and settles zones Q13's "re-rule against the tab as built". The reason is that the two trees answer different questions, envelope faces versus rooms, and a single tree would need the Spaces feature to edit Zones' panel module or a new child-row contribution point with one user | P3a-07 | |
| D3a-7 | UI | How do Mark floor and Create Space start, with no toolbar? (F12) | From the Spaces tab, the Extensions menu and the right-click menu, as Classify and Place start. A toolbar button waits with [zones-entry-points](../unscheduled/zones-entry-points/README.md) E1 and covers all three tools together. "One pressed at a time" is met by SketchUp's single active tool: each panel palette already derives its pressed state from its own tool's `active?`, so no shared tool-state rule is added | P3a-06 | |
| D3a-8 | Code | How does the equipment packet regroup the airflow balance view later? | Build the grouping as a pure function the balance read takes as an argument, with Zone grouping as the only caller. Do not add a registration point now. The PRD's promise that equipment "edits nothing in this feature's folder" is kept by adding the registration when the equipment packet is planned, against its real shape | P3a-08 | |
| D3a-9 | Code | Is the Spaces export section required for export? (R05 item 4) | Yes. A Space that fails to translate blocks the canonical pair, consistent with the PRD's blocking findings. So Spaces is not the first optional attaching section, and R05 item 4 stays owed with validation-and-export until an optional one exists | P3a-10 | |
| D3a-10 | Code | Does a blocked run report `construction_usage`, `window_face_areas` and the Spaces schedule? (R05 item 3) | A blocked run reports them, and the report says in one line that the figures come from a run that published nothing. Hiding them removes the numbers a user needs to fix the block | P3a-10 | |
| D3a-11 | UI | Does the Spaces tab keep the predecessor's Level rail and saved column layout? | Keep the saved column layout. Drop the Level rail: Level moved to the Zone (zones Q6), and the Zone level of the tree does the same job. `docs/PRODUCT.md` still describes the rail and is corrected when P3a-07 lands | P3a-07 | |
| D3a-12 | UI | The PRD warns where supply and extract "differ by more than 10 percent" and does not say of what | Of the larger of the two sums: warn when the absolute difference exceeds 0.10 times the larger. A Zone with one sum at zero and the other not is always warned | P3a-08 | |

Also needed, and not new: Ed's confirmation of the interview record in the Spaces PRD, which its
STATUS has carried as pending since 2026-09-18.

## PRD amendments that follow

Applied to [PRD.md](PRD.md) only after Ed answers, one change per decision:

| From | Amendment |
| --- | --- |
| F1, D3a-4 | Disposition row for `reconciler`, `undo_ledger`, `pending_work`, `session_state`: the generic primitives land in P3a-03, not with the foundation transplant |
| F4, D3a-2 | Records, Identity: foundation ids, not UUIDs. Disposition row for `identifiers`: Drop |
| F12, D3a-7 | Mark floor: no toolbar wording; the pressed-state sentence restated |
| F14, D3a-6 | "The model tree and the table": a Spaces tab with its own tree |
| F17 | Disposition row for Python `geometry.py`: Replace the flatten rule |
| F19 | Acceptance shape: PHX and METr steps point at metr-export |
| D3a-8 | Airflows: the grouping provider's registration is deferred to the equipment packet |

## Confirmed copy decision D3a-13

**D3a-13, confirmed by Ed 2026-10-12:** when a Zone is copied and made independent, every Space
included in that copy becomes an independent authored instance. This includes independent
storage and identities for its Volumes, Floor Segments and logical Space Floors, correct copied
Zone membership stamps, preserved ordinary values/metadata under their copy rules, and typed
references remapped within the copied collection. The original Zone and its Spaces stay unchanged.

Window Units in that same Zone follow Windows' protocol: new instances reference their existing
Window Type. Copying the Zone does not create new Window Type definitions in the same Model.
See [copied-Zone D-2 to D-6](../../archive/copied-zone-edit-refusal/DECISIONS.md).

This qualifies PRD Q20's "no silent reissue" rule: the standalone Spaces reconciler still cannot
guess which occurrence to rewrite, and standalone Space/Volume/Floor Segment copies retain their
explicit repair workflow. A proven Zone-copy gesture supplies the parent-copy scope; Spaces must
participate through its own declared copy planning/application, in that gesture's one atomic
proposal and Undo step. Zones must not learn Space schemas or rewrite their dictionaries. A
refusal/failure cannot leave a reported-independent Zone holding shared or duplicated Spaces.

Allocated to P3a-04, with S04/S12 host acceptance and S10 HBJSON read-back. Before implementation,
resolve the participation binding, child-storage isolation, typed collection mapping and failure
recovery against the copied-Zone mechanism then present. D3a-3's architecture choice remains open;
this decision specifies the result, not a new shared identity framework.

D3a-1 to D3a-12 remain open. No Spaces stage is authorized or implemented by this decision.

On 2026-10-13 Ed accepted the shared [Zone-child ownership pattern](../../archive/code-review-refactoring/ZONE_CHILD_PATTERN.md).
The [child lifecycle plan](../../archive/zone-child-lifecycle/PLAN.md) now specifies the
proposed parent transition and Windows/synthetic adopter proof. P3a-04 must reuse that accepted public
contract once implemented, rather than designing another copy framework. Spaces still owns its
collection mapping/storage and S04/S12/S10 evidence; its earlier decisions remain open. The contract is
implemented (zone-child lifecycle ZC-02 and ZC-03): a `transition_contributor` for
`ph_composer.zones.occurrence_independent`, described in [CONTRACTS.md](../../../context/CONTRACTS.md),
"Compound proposals", with Windows as the first adopter.

## Ledger

| Date | Event |
| --- | --- |
| 2026-10-03 | Drafted from a source review at `70c340f`, the predecessor at `f358ebf` and the Spaces PRD. Twenty-two findings, twelve decisions, none answered. |
| 2026-10-12 | Ed confirmed D3a-13 through the copied-Zone review: Spaces copied with a Zone become independent authored instances; Window Units remain instances of their existing Type. Q20 and P3a-04 qualified; the twelve earlier decisions and implementation gates remain open. |
