# P2-17 retained-observation and source-reuse matrix

DATE: 2026-10-01
STATUS: Draft for independent assertion and ledger consolidation; no case award
SOURCE REVIEW BASE: `95a0ad9`; current E03/E05/E17 documentation incorporated
DOCUMENT CHECKPOINT: Pending independent consolidation
LATEST SHIPPING CORRECTION: `8a43bec`
ISSUE: https://github.com/bldgtyp/ph-composer/issues/14

This matrix records retained observations, bounded source-reuse qualifications and unobserved
assertions. It does not change [ACCEPTANCE](../ACCEPTANCE.md), award a case, or turn offline proof
into native observation. The root integrator must validate consequential reuse decisions and append
final provenance to the native ledger. Historical evidence retains its original source and package.

All native observations below concern SketchUp 26.1.188 / Ruby 3.2.2 on macOS. Current normal
installed package `f85b789455882d4ba39fafc0edd7266c7cafc973975b3a14832677f8f71537fd`
contains signed shipping correction `8a43bec`. The preceding `e11a767` package was
`bcb9c024e20ce686b52e0b851e13fd2e762e97aa25d61551b838e6aaaf75c018`.
Exact current installation and native colour recheck are recorded in
[P2-17, Assembly colour redraw correction verified](p2-17-acceptance.md#assembly-colour-redraw-correction-verified).

## Reading the qualifications

**Observed** means a retained native journal or the owning historical observation explicitly
supports the assertion. **Offline** means the owning tests cover it without a native observation.
**Unobserved** means this bounded audit found no retained direct native proof; it does not assert
that the behavior fails. **Qualified reuse** preserves a historical observation for an unchanged
path or states the later change that needs separate coverage. These labels concern assertions,
not whole-case outcomes.

Source comparisons in the preceding bounded audit used `35704bd`, `43a1418`, `146076e` and
`74f7f05` against `e11a767`. The subsequent shipping delta `8a43bec` changes generic Dispatch
publication only: it retains the outcome within exclusivity and publishes a committed change after
releasing the mutation lock. It changes neither record values nor the native proposal steps. It
therefore does not erase historical authoring/Undo/reopen observations. It does affect subscriber
reads and redraw; the fresh native Assembly colour edit, exact active legend, visible overlay/HUD,
Undo and Redo are the direct current-source evidence for that correction. A prior successful record
write alone cannot stand in for this redraw proof.

## E01: groundwork and retained Phase 1 boundaries

Authority: [E01 evidence, Delivered / Offline / Native observations](p2-01-groundwork.md#native-observations).

| Assertion | Retained observation and original checkpoint | Source/reuse qualification | Current missing assertion or consolidation boundary |
| --- | --- | --- | --- |
| CONTRACTS answers, contributor architecture, Subtabs/RecordEdits/InventoryGrid | Recorded code answers, independent review and focused/offline/browser checks in E01. Initial installed package `554ef3d0…` predates final select and duplicate-hook changes; its source commit is not identified in that summary. | Later integrated dual-Ruby/browser gates cover the final source. Initial package cannot prove those later changes. | Reconcile the final code answers and review links with the current register; no new native assertion is supplied by this draft. |
| Real Zones/Faces panel and Export retain behavior | Initial normal Zones-only panel opened; empty Export refused. Later normal reference export and current panel routes are observed under E06/E14/E05. | Use each observation's original checkpoint. `8a43bec` publication/redraw has its own current proof. | Initial opening is a bounded observation, not the full Phase 1 regression screen or whole E01 gate. |
| Phase 1 occurrence/adjacency/API regression support | E01 records native R01–R04/R06 supporting observations: shared-storage refusals, nested ownership, orphan references, partial overlap, stale revision and retry. | Later E12 Slice B and E05 direct/nested/shared fixtures supply affected-path observations. They do not automatically close every screened Phase 1 assertion. | Retain the narrow R01/R05/A04 qualifications below; held-Classify remains a separate manual boundary. |

## E02: Material and Assembly records

Authority: [E02, Verified checkpoint and native record proof](p2-02-assembly-records.md#verified-checkpoint-and-native-record-proof);
[owning stage, Tests and Host gate](../phases/p2-02-material-and-assembly-records.md#host-gate).

| Assertion | Retained observation and original checkpoint | Source/reuse qualification | Current missing assertion or consolidation boundary |
| --- | --- | --- | --- |
| Schemas, membrane/steel/one-spacing rules, predecessor thermal fixtures | Offline reference/schema checks and closed thermal-path/name review findings. | Commands, thermal and record engine are unchanged from the earlier checkpoint. Shared AuthoringFields is an unchanged promotion; later Material source-category widening concerns attribution only. | Keep these as offline evidence, not native membrane/spacing authoring observations. |
| Panel-closed three-layer walkthrough, each Undo/Redo, save/fresh reopen | `35704bd`: fourteen commits; all fourteen Undo and fourteen Redo comparisons true in `e02-native-roundtrip.json`. Fresh reopen exactness is recorded historically with retained public comparison scripts. | Catalog path unchanged. Later Assembly delete retargeting does not change walkthrough edits. Reference-removal support is additive and unused by this path. | Supports host-gate consolidation with original provenance; the comparison scripts are not new current-host executions. |
| Metadata, Duplicate and references | `35704bd`: six commits with nested user_data; fresh nested ids, retained Material references and independent metadata copies. Six Undo/Redo comparisons all true; fresh reopen documented. | Record engine and Duplicate path unchanged. | Understood/unavailable extension handling is offline evidence; no separate native extension injection was retained. The owning stage places it in Tests. Resolve any stronger interpretation of the register explicitly. |
| Two Models with identical ids | `35704bd`: inactive first Model targeted, second unchanged, native Undo restores first. `e02-two-models.json` has distinct sessions and unchanged-second checks. | Session targeting is retained; current integrated two-Model evidence also belongs to E14/E17. | Do not relabel historical results as observations of the current RBZ. |

## E03: Materials and Assemblies inventories

Authority: [E03, Verified checkpoint and remaining native work](p2-03-inventories.md#verified-checkpoint-and-remaining-native-work),
[current inventory continuation](p2-03-inventories.md#current-inventory-continuation),
[P2-17 colour recheck](p2-17-acceptance.md#assembly-colour-redraw-correction-verified) and
[owning stage, Host gate](../phases/p2-03-inventories.md#host-gate).

| Assertion | Retained observation and original checkpoint | Source/reuse qualification | Current missing assertion or consolidation boundary |
| --- | --- | --- | --- |
| Material create/edit, in-use replacement, Undo | `35704bd`: explicit SI conductivity in IP, creation Undo/Redo, inline name edit; replacement rewrites both nested references and one Undo restores the complete catalog. | Material authoring path retained. Later provider/export additions do not change the recorded local edit. | Retain historical provenance; formal consolidation pending. |
| Material Duplicate through inventory | Normal `8a43bec`, PID 33871: exactly one fresh id with derived provenance; values/metadata identical except name/source; all six existing records unchanged. One native Undo restores the complete inventory, uses and categories. | Direct current-host observation in the inventory continuation; no unchanged-source inference is needed for Duplicate. | Formal assertion/ledger consolidation pending. |
| Assembly create/Duplicate/delete and in-place edit | `7932856`: native forms and fresh nested Duplicate ids. `43a1418`: corrected replacement caption and nonmutating Cancel. Normal `8a43bec`: in-place colour edit and exact Undo/Redo in P2-17's fresh colour recheck. | Historical Assembly inventory/form/grid and Builder path retained; changed Dispatch publication has separate direct current proof. | Formal consolidation pending; historical create/Duplicate/delete retain their original checkpoint. |
| Stale expected values on both inventories | Normal `8a43bec`, PID 33871: both public update actions refuse stale `expected_values.name` with `target.changed`, effect none; complete inventories and revisions unchanged. | Direct native-host API evidence at the current revision; distinct from E02's `revision.stale` probe. | This proves the action guard, not a simulated HtmlDialog response race. Formal consolidation pending. |
| Draft retention, navigation, units and narrow width | `35704bd`: dirty peer-navigation guard and retained draft through units. Normal `8a43bec`: 904-pixel capture (~452 CSS px), wrapped controls/working peer subtabs and internally scrolling New Material form with reachable Cancel/Create. First Escape dismisses Category selector only; second closes form/restores trigger focus. Reopen, Cancel, Attached zones and return preserve typed unsaved name without creating a Material. | Current inventory continuation supplies bounded native layout/Escape/subtab observations; historical unit-draft observation remains separately identified. | These observations do not constitute a whole-case award or universal width claim. Formal consolidation pending. |
| Filter/group/order/direction never mutate the Model | Normal `8a43bec`, PID 33871: Material filter/category group/conductivity order/descending and Assembly filter/Type group/thickness order/descending; complete public inventory outcomes and revisions identical. Clearing filters/changing tabs also unchanged. | Direct native nonmutation readback in current inventory continuation; inventory grid was unchanged in the compared range. | Formal assertion/ledger consolidation pending. |

## E04: Assembly Builder

Authority: [E04, Expanded native Builder journal](p2-04-assembly-builder.md#expanded-native-builder-journal);
[owning stage, Host gate](../phases/p2-04-assembly-builder.md#host-gate).

| Assertion | Retained observation and original checkpoint | Source/reuse qualification | Current missing assertion or consolidation boundary |
| --- | --- | --- | --- |
| Toolbar/drawing/material gestures are one Undo | `7932856`: drop, Add Segment, width, Add Layer, Mirror Segments, Flip Layers, Flip Orientation; seven exact Undo/Redo states. `43a1418`: Add outside, Move outward, thickness, continuous insulation, Clear Material, Delete Segment and Delete Layer; each exact Undo. | Editor, inspector, canvas, commands and thermal unchanged since `43a1418`. All twenty retained `assembly-native-*-verify.json` proofs are true. | Current `8a43bec` native Add inside and Move inward each have exact one-step Undo: see E04 complementary controls. The stage host gate requires a stud wall; steel-specific spacing remains in the schema/thermal tests. Formal consolidation remains pending. |
| Partial save, fresh reopen and continued editing | `43a1418`: saved incomplete Assembly equals prior full authored catalog, then continued tools and wall-building edits. | Unchanged authored Builder path. | Historical provenance supports this assertion; E03 prerequisite consolidation remains separate. |
| Complete three-layer stud wall, both thermal values, withholding | `43a1418`: board / mixed insulation and 0.13 W/(m K) wood framing / cladding; U with films 0.329263, construction U 0.348786. Independent scalar proof true. Incomplete values withheld with reasons. | Unchanged thermal projection. Wood framing supports the generic stud-wall workflow; it is not native steel-spacing authoring proof. | Native steel-spacing entry is not established by this wall. Membrane/steel mathematical rules remain covered under E02/E06 offline evidence. |
| Keyboard Use and ventilated film flag | `43a1418`: details do not write; Enter assigns selected framing and one Undo restores catalog. Film flag changes Rse 0.04→0.13, retains construction R/U and Rsi; one exact Undo. | Unchanged header/material gesture path. | Supports assertion consolidation; no whole-case award here. |

## E05: assign Assemblies to Faces

Authority: [E05, P2-17 current-host route verification](p2-05-assign-assemblies.md#p2-17-current-host-route-verification), including its subsequent guard/replacement/hint/performance batches;
[P2-17 colour correction](p2-17-acceptance.md#assembly-colour-redraw-correction-verified).

| Assertion | Retained observation and original checkpoint | Source/reuse qualification | Current missing assertion or consolidation boundary |
| --- | --- | --- | --- |
| Selection/right-click/table/Paint; one Undo; usage | Normal `e11a767` RBZ: four routes, exact public Face/Unit/area Undo; table Redo; correct 36/36/78/24 m2 reference usages. | Current-source observation before publication correction; `8a43bec` changes publication only. | Formal assertion/ledger consolidation pending, not another ordinary route gesture. |
| 250/251 and stale/unreachable atomic refusal | `e11a767`: two-target `target.changed`/`target.not_found`; 251 refuses, 250 commits, one native Undo exact; fixture cleaned exactly. | Same guarded proposal/native steps after `8a43bec`. | Formal consolidation pending. |
| Replacement across direct/nested occurrences and shared storage | `8a43bec`: direct plus two unique nested Groups retarget and one native Undo restores all values/catalogs. Real three-instance shared definition refuses atomically. Copied Face identity also refuses ambiguity until fixture explicitly reauthored. | Accepted mutable-occurrence contract governs. Unique-occurrence success cannot establish mutation of shared definitions or automatic copied-Face identity repair. | Reconcile literal repeated-definition success wording against the recorded shared-storage qualification. |
| Hint precedence, mismatch, Colour-by, Model/nested-path behavior | Current batches: absent fields fill; explicit Floor/boundary-clear win; blank hints fill nothing; reciprocal different-id pair warns. `8a43bec`: corrected colour overlay/HUD/legend with Undo/Redo; Model switch preserves state; two-level native path assignment and Undo exact. | Colour correction has direct fresh-process proof; prior failed redraw is retained as a failure. Usage aggregation measured ~3 ms within ~1.26 s full snapshot at 2,003 Faces. | Formal consolidation pending. Do not claim a whole-snapshot performance budget or held-Classify coverage. |

## E06: construction export

Authority: [E06, Integrated checkpoint and current-host proof](p2-06-construction-export.md#integrated-checkpoint-and-current-host-proof) and
[P2-17 dependency refusal consolidation](p2-06-construction-export.md#p2-17-dependency-refusal-consolidation).

| Assertion | Retained observation and original checkpoint | Source/reuse qualification | Current missing assertion or consolidation boundary |
| --- | --- | --- | --- |
| Normal RBZ, actual assigned reference export and fresh reopen | `6a7e08f`: normal runtime export, two Rooms/twelve Faces/Surface pair/four referenced constructions; fresh SKP reopen and authored energy/reference comparison exact. Current E14 reference export retains normal composition. | Reuse the explicit authored-reference/energy comparison. Honeybee-PH generated default metadata prevents whole-text equality. | Formal consolidation pending; do not substitute construction counts for actual resolved identities. |
| Single/mixed/steel/membrane grids, repeated thickness, metadata allowlist | Pinned-stack offline HBJSON reload tests read actual construction/material references, division fields and namespace; closed emissivity/default-disclosure review. Native reference carries relevant mixed/membrane constructions. | Construction conversion has later Window integration; current reference export supplies integration evidence, while detailed adversarial mappings remain offline proofs. | Label detailed grid/thickness assertions by their actual evidence type, not all as native readbacks. |
| Absent/incomplete assigned and unused incomplete outcomes | `e11a767`: exact Face-specific findings; normal canonical workflow refuses before destination dialog; aborted fixture restoration exact. Unused incomplete remains nonblocking and reference extracts normally. | `8a43bec` does not change canonical mapping or blocking policy. Extraction success is distinct from permission to write canonical artifacts. | These outcomes are observed; formal stage/prerequisite consolidation remains pending. |

## E07–E11: library and Window records/Builder

| Case / assertion | Retained observation and original checkpoint | Source/reuse qualification | Current missing assertion or consolidation boundary |
| --- | --- | --- | --- |
| E07 provider/refusal/resolver/limit contract | Offline envelope/row/folder/ambiguity/failure cases; `146076e` native 20,000 rows and exact 32/64 MiB load measurements. [E07 current-host proof](p2-07-library-seam.md#current-host-proof). | Provider/parser/catalog/admission/resolver/coordinator unchanged to `e11a767`; later registrations add independent commands/participant. | Distinct refusal and one-above limits remain offline. Do not turn load measurements into panel-rendering claims. |
| E07 panel-closed preview/apply/read/retry and atomic copy+assign | `146076e`: digest, duplicate retry, readback and exact native copy+assignment Undo/Redo; provider-free reopen/edit. `library-native-roundtrip.json` flags true. | Existing coordinator path unchanged; generic participant adds composability without changing that action. | Normal `8a43bec`, PID 33871: public preview, `revision.stale` and `session.unknown` refusals with exact unchanged two-Model catalogs/revisions; provider setup restored empty. Deliberately failed copy+assignment remains offline proof, as the stage Tests clause requires. |
| E08 Setup, two-provider state, three review answers, drag/Add-only | `146076e`: native pickers and Cancel, separate catalogs/local marks, Cancel/Keep/Use-library review, exact drag/Add-only Undo/Redo. [Native panel workflow](p2-08-library-sidebar.md#native-panel-workflow-on-146076e). | Shared sidebar delta adds optional localOnly handling; configured provider flow retained. | Separate-provider state is observed; explicit cross-source reuse is not established merely by showing two catalogs. Nonempty evidence/user_data/unavailable extensions through replacement are offline, not retained native injections. |
| E08 provider-free persistence/edit | `146076e`: zero providers, exact fresh reopen, native conductivity edit without source provider; retained proof true. | Same local Material authoring path. | Supports consolidation with original provenance. |
| E09 export/update/new/selected/reuse/failure | `7afe894`/`74f7f05`: real Save/review, FileProvider readback, local ids, retained/fresh UUIDs, selected hidden-row scope, reuse, Cancel, injected rename failure preserving bytes/Model. [Native export](p2-09-library-export.md#native-export-checkpoint-on-installed-7afe894), [remaining observations](p2-09-library-export.md#remaining-native-export-observations). | Projection/workflow/writer/export registration unchanged since `74f7f05`; `8a43bec` does not change FileExport. | Secret/address/path filtering and fresh-Model semantic round trip are offline boundary proof. Preserve that distinction during consolidation. |
| E09 outside provider / starter | Separate native extension lists/copies without core changes; public example approval and signed commit recorded. [Approved public example](p2-09-library-export.md#approved-public-example). | Keep separate-extension/native and published-example provenance distinct. | No outstanding publication authorization is implied; no broader case award follows from publication. |
| E10 schemas/grid/thermal/delete/settings and panel-closed walkthrough | Offline four-kind checks; `146076e` seven native commits/Undo/Redo, exact reopen; saved Phase 1 fixture returns settings defaults without authored storage/dirtying. [E10 current-host proof](p2-10-window-records.md#current-host-record-proof). | Product/Type schemas, thermal, grid calculations and ModelSettings unchanged. Handlers now prepare Unit repair; historical fixture has no Units, so qualify reuse as that catalog path. | Native proof does not cover every adversarial product-delete or non-default settings case; those are offline. Stage host-gate consolidation is available with this qualification. |
| E11 Builder/Installs/thermal gestures | `7afe894`: grid/product/operation/paste/flip/Duplicate/replacement; one staged Installs Save; 38 exact journal checks. `74f7f05`: corrected forms, incomplete null thermal values and exact Undo. [Native Builder](p2-11-window-type-builder.md#native-builder-workflow-on-installed-7afe894). | Editor/product selection and handlers later change for Units and provider imports; not a blanket unchanged-source claim. Link changed paths to E12/E15 evidence. | Root must validate that reconciliation; no newly observed E11 assertion is supplied here. |
| E11 fresh persistence | `74f7f05`: saved/reopened query values equal for all four inventories, including references, after excluding revision envelopes. [Corrected build and persistence](p2-11-window-type-builder.md#corrected-installed-build-and-fresh-persistence). | Retain original checkpoint; schemas/thermal unchanged, later native Unit changes have their own acceptance. | Historical persistence is reusable only with its stated scope. |

## Phase 1 narrow qualifications retained

Authority: [native acceptance index](../../../native-acceptance/README.md),
[PR #11 recheck, Notes](../../../native-acceptance/evidence/phase-1-recheck-pr11-2026-09-30.md#notes)
and the append-only [results](../../../native-acceptance/results.jsonl), latest relevant entries
at original checkpoint `595323f`.

| Assertion | Retained observation | Qualification retained |
| --- | --- | --- |
| R01 shared-Face native context-menu route | Native shared Copy/Paste, Classify/Reverse public refusals and unchanged records/revision are recorded. Opening a shared child Group natively gave it its own definition, so the ensuing context menu no longer targeted shared storage. | A native right-click on a still-shared Face was not recorded. Do not infer it from public API refusal or current unique nested-path assignment. |
| R05 Save/Cancel visibility while request pending | Draft/navigation/focus/Save/Cancel behavior observed; Save completed before pending capture. | Pending-state visibility remains unknown in the ledger. Ed's accepted offline coverage is recorded separately; do not turn it into native observation or a new manual requirement. |
| A04 Classify cursor | Native activation, two-Face drag/readback and Escape recorded; Ed confirmed cursor on 2026-09-30. | Controller did not capture the real pointer. Retain human-confirmation provenance rather than claiming controller observation. |

Held-Classify across Model/edit-path switching is a different assertion. Separate button-down/up
control remains unavailable; ordinary placement Model switching, E05 Paint/Escape and the three
qualifications above do not close it.

## Boundaries for final consolidation

E12–E15 already have their current-host case outcomes; this draft does not reopen or reaward them.
E16 is deferred to Phase 5. E17 integrated cross-feature Undo/Redo, nested paths and two Models retain their assertion/ledger reconciliation. The current normal runtime export, exact full public-value restart and staged-artifact restart recovery are observed in [P2-17](p2-17-acceptance.md#integrated-export-and-fresh-restart-continuation). SketchUp 2023, Windows,
public distribution, certification and METr consumer gates remain separate.

E03's current inventory continuation is incorporated above without a case award. Resolve the
E04 literal-menu interpretation and E05
repeated-definition wording against accepted contracts before final awards; do not invent native
success for shared storage or automatically repaired copied Face identities.
