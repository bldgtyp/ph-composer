# Phase 2: status

DATE: 2026-10-01
STATUS: In progress
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/14

## State

The packet was drafted on 2026-09-30 against `main` at `052a7a1`, after Phase 1
merged and was archived. Ed authorized the full implementation run on 2026-10-01, on a new feature branch.
Active branch: `codex/phase-02-envelope`. P2-01 to P2-06 have an integrated checkpoint; complete native attestations remain open.

The three feature PRDs were interviewed on 2026-09-18, before any PH-Composer code existed.
Phase 1 then built the foundation they assumed, and built parts of it differently. The
differences are listed in [DECISIONS.md](DECISIONS.md) and recorded as an amendments section at
the top of each PRD.

## Entry gates

1. Met: Ed answered D2-1 to D2-10 in [DECISIONS.md](DECISIONS.md) on 2026-09-30 and revised D2-1 on
   2026-10-01.
2. The explicit 2026-10-01 instruction to implement this packet is the authority to proceed
   with its accepted PRDs and decisions. Historical interview confirmation labels are retained
   as provenance, not a second implementation approval request.
3. Met: Ed authorized the full packet with `implement-loop` on 2026-10-01.
4. Met: [implementation issue #14](https://github.com/bldgtyp/ph-composer/issues/14) created;
   the coordinating and feature packet issue headers are linked.

## Current resume checkpoint

Branch `codex/phase-02-envelope`, installed checkpoint `43a1418`. Both Ruby full CI gates
pass: 995 tests / 6725 assertions, 346 JS and 135 Python tests. Coverage is
96.6% / 94.9% / 94.98%. Chromium 88 and all eight browser scripts pass after the caption correction. Exact installed 296-file RBZ is
`checkpoint-43a1418.rbz`, SHA-256
`af377ff41e6dcf6a3b906acbc1a87ce7733ffec18b2a87981d65da1bb1cb22d3`,
22,624,674 installed bytes. Independent geometry review is clear.

P2-12 Slice B fresh normal SketchUp 26.1.188 / Ruby 3.2.2 replay passes cutting-descendant
exclusion, both partial-glue refusals, full pairing, covered-side preservation and unchanged-
geometry glue preview refusal. Native Undo/Redo restores both pairing and counterpart splits
exactly. The replay found and corrected SDK cutter-adjusted area leaking into gross Face area;
public glued hosts now report 12.0 m². Private evidence and safety checks are retained.
Slice B observed model: `_private/host/envelope/p212b-native.skp`, PID 21117 / bridge 61720;
its probe changes are saved separately in `p212b-7932856-observed.skp`. No outside provider
or fault override is installed. See [Slice B evidence](evidence/p2-12-zone-cutting-rules.md).

E15 has a passing structured result; D2-8 defers P2-16 to Phase 5. P2-09/P2-11 native
workflows are observed. Complete E12 and consolidated E01 to E14 / E17 remain open.
Native Assembly batch follows: seven Builder gestures pass one-step Undo and final Redo
exact catalog comparison; observed model saved privately. Caption-only correction `43a1418`
passes both full CI gates, Chromium 88 and eight browser scripts; fresh native caption
readback and partial-Assembly reopen pass. Film toggle changes only the authored flag
and exterior-film result; one Undo restores full catalog and unmodified state.
Seven further native Layer/Segment commits and their individual Undo comparisons pass:
Add outside, Move outward, 75 mm thickness, continuous insulation, Clear Material,
Delete segment and Delete Layer. Details opening is read-only, and native keyboard Material
Use plus one exact Undo also pass. The complete three-Layer mixed framing construction
matches an independent thermal calculation; all five construction commits pass individual
Undo comparisons. E04's native workflow is observed across the recorded batches, but
consolidated attestation and the preceding E03 gate remain open.
The Assembly batch ends in its saved, unmodified state with the panel closed. Private
journals, `assemblies-native-builder-observed.skp` and `assemblies-native-three-layer.skp`
preserve the observed states. The quit helper timed out and terminated that owned process;
no work was lost, and no clean-shutdown acceptance is claimed for that transition.
Native human Option Move-copy now passes separate Copy Undo/Redo verification. The preceding
native Move is retained by Undo Copy, and exact Units/Faces/definitions return on Redo.
Slice A is current-host observed; Slice C and P2-13/P2-14 are no longer held by this gate.
Ed confirmed the held-Classify check and approved the separate public example repository,
which is published at [bldgtyp/ph-composer-library-provider-example](https://github.com/bldgtyp/ph-composer-library-provider-example),
signed-off commit `d54a2ca`. Both Ruby provider checks pass (four tests / 36 assertions each),
and all six remote files match the verified local checkout.
Remaining work: held-Classify replay, Slice C and downstream implementation, Assembly /
assignment / export attestation, affected Phase 1 checks and integrated final acceptance.
Public placement is implemented in source; native placement acceptance and Aperture implementation remain open.

Slice C source is committed, independently reviewed and installed at signed checkpoint
`d376684`. Records, occurrence reads, generated definitions, public placement, used-Type
propagation, copy identity repair, Remove, Re-host, Swap, Reset, New flipped Type, Restore
and used-Type deletion retargeting are registered. All reproduced review findings are closed.
Full CI passes on both Rubies: 1261 tests / 9082 assertions, 346 JavaScript tests and 135
Python tests. Final Ruby coverage is 96.9% of 12,966 lines across 209 files.

Fresh-process wall/roof placement, three-anchor Type resize, Swap, scaled/detached Reset,
New flipped Type, Restore, Remove, Re-host and used-Type replacement deletion pass native
Undo/Redo. Scale has no grips. Overhang, overlap, missing Zone, oversized Type edit, Surface
host and merged-pane Restore refuse without writes. Solve reports the glued-unit partial
match rather than cutting it. The panel-closed copy/resize/swap walkthrough and actual native
Cut/Paste In Place across Zones pass. The pasted Unit retains its record, loses glue, and
re-hosts after fixture positioning.

Fresh-process readback preserves every public authoring row. A bounded second roundtrip
also preserves every captured native definition, material, matrix, record and glue field.
Inside-definition Reset, actual foreign-Model paste with unknown-Type Swap recovery, and
used-Type deletion with explicit Unit removal all pass native Undo/Redo. Five Units are saved
without findings. Native canvas clicks currently fail in the
controller with `noWindowsAvailable`; screenshots, keys, menu commands and bridge actions
work. The actual Line-tool split remains a batched manual item. The actual Line split/Re-host is now the remaining native-edit matrix item. The controller
still fails after restart and reset, so this is the current real blocker. E12 and downstream
P2-13/P2-14 entry gates remain open. See
[Unit source evidence](evidence/p2-12-unit-geometry.md) and
[native Unit evidence](evidence/p2-12-window-unit.md).

## Earlier implementation checkpoints

Checkpoint `6a7e08f` contains P2-01 to P2-06. An immutable source archive passes full
`make ci` on Ruby 2.7.2 and 3.2.2: 818 Ruby tests, 4667 assertions, 281 JavaScript tests and
127 Python tests. Chromium 88 runtime export passes. Independent construction review findings
are closed. All five integrated browser scripts pass.

The immutable package is installed in fresh SketchUp 26.1.188. Actual reference SKP export
produces two Rooms, twelve Faces, four authored constructions and one reciprocal Surface pair,
with exact expected usage areas. Four native Undo and four Redo states match the Face journal.
The native Builder retains an explicit-unit dimension draft through a unit switch, commits the
canonical value, and one native Model Undo restores the complete catalog. Fresh reopen preserves the complete Face list and Assembly catalog; a second runtime export
preserves Rooms and energy constructions/materials exactly. Generated Honeybee-PH default UUIDs
change between exports. Remaining UI gestures still precede full E03 to E05 attestation.

Package: `_private/host/envelope/checkpoint-6a7e08f.rbz`, SHA-256
`35a7c2a90f87acb58b54c2ca4721cfce59b7ecf61ab85c0f8951172cece3b245`.
It contains 235 files and 22,242,825 installed bytes, below the 24 MB ceiling but above the 22 MB
size target. The actual native fixture is saved as `reference-assigned.skp` in that private folder.

P2-07, P2-08 and P2-10 are integrated in installed checkpoint `146076e`; every full-gate
target passes on both Rubies, all six browser scripts pass, and Chromium 88 runtime export
passes. Native library proof covers 20,000 rows at the 32 MiB per-file / 64 MiB aggregate limits,
copy/reuse, review choices, atomic drag assignment, native Undo/Redo, removal and fresh persistence.
Window record proof covers seven public commits, seven exact native Undo/Redo states and fresh
reopen. See the owning evidence for limits and provenance; complete case attestations remain open.

P2-09 export backend, explicit panel form and local outside-provider example are implemented and
independently reviewed, with native export acceptance still open. Twelve starter public-source records pass reader and packaging checks.
The example passes its shared provider contract and public copy/read-back on both Rubies.
P2-11 Window editors are independently reviewed and pass focused checks and four browser widths.
Checkpoint `7afe894` is installed byte-for-byte in a fresh SketchUp 26.1.188 process; native
Builder acceptance is in progress. P2-12 Slice B is implemented and independently reviewed;
its affected native Zone replay remains open.
At this earlier checkpoint Slice A lacked native Move-copy; the current continuation above
closes that observation without substituting API or clipboard copies.

## Earlier installed verification checkpoint

`make ci` passes on Ruby 2.7.2 and 3.2.2 for shipping source `d812540`: 972 Ruby tests /
6373 assertions, 329 JavaScript tests and 135 Python tests, plus hostkit checks. Subsequent
example-provider wire corrections pass four tests / 36 assertions on both Rubies. The tests-only
`7afe894` checkpoint adds eight meaningful Window behavior cases; focused Window checks and lint
pass. Coverage is Ruby 96.5%, JavaScript 94.8% and Python 94.98%. All seven browser scripts and
Chromium 88 runtime checks pass. This is not a new full-suite invocation on `7afe894`.

Installed package `_private/host/envelope/checkpoint-7afe894.rbz` contains 290 files and
22,602,164 installed bytes, above the 22 MB target and below the 24 MB ceiling. Its SHA-256 is
`04a51985ebc0ff4068572289a5b7f05daa288ae3d50992ffc10b23fefd83c9d4`.
The install proof verifies every archive entry and absence of extras. Fresh native E09/E11
baselines precede actions in `p209-p211-native.skp`. Window Type creation and rename each have
one exact native Undo/Redo inventory restoration. The rest of E11 and E09 remain in progress.

## Blockers

- The held-Classify fixture is armed for the requested human press/hold gesture. No gesture result
  is recorded yet; preserve its host state while source work continues.
- No repository decision remains: Ed approved the exact outside example, and it is published.

## Stage ledger

| Stage | Roadmap | State | Evidence |
| --- | --- | --- | --- |
| [P2-01 Contracts and groundwork](phases/p2-01-contracts-and-groundwork.md) | 2.1 entry | In progress; implementation and review checked, native gate open | [Groundwork evidence](evidence/p2-01-groundwork.md) |
| [P2-02 Material and Assembly records](phases/p2-02-material-and-assembly-records.md) | 2.1 | Implemented and reviewed; dual-Ruby CI and native records proof pass; complete attestation open | [Record evidence](evidence/p2-02-assembly-records.md) |
| [P2-03 Materials and Assemblies inventories](phases/p2-03-inventories.md) | 2.1 | Implemented and reviewed; dual-Ruby CI/coverage/browser pass; native inventory gate open | [Inventory evidence](evidence/p2-03-inventories.md) |
| [P2-04 Assembly Builder](phases/p2-04-assembly-builder.md) | 2.1 | Implemented and reviewed; dual-Ruby CI/runtime/browser and initial native Builder proof pass; full native gate open | [Builder evidence](evidence/p2-04-assembly-builder.md) |
| [P2-05 Assigning Assemblies to Faces](phases/p2-05-assign-assemblies-to-faces.md) | 2.1, 1.2 | Implemented and reviewed; dual-Ruby CI/browser and exact native Undo/Redo pass; UI attestation open | [Assignment evidence](evidence/p2-05-assign-assemblies.md) |
| [P2-06 Construction export](phases/p2-06-construction-export.md) | 2.1, 1.3 | Implemented and reviewed; dual-Ruby CI/runtime and real-SKP export pass; final native gate open | [Construction evidence](evidence/p2-06-construction-export.md) |
| [P2-07 Library seam and file provider](phases/p2-07-library-seam-and-file-provider.md) | 2.2 | Implemented and reviewed; integrated gates and native library proof pass; final attestation open | [Library evidence](evidence/p2-07-library-seam.md) |
| [P2-08 Library sidebar and setup](phases/p2-08-library-sidebar-and-setup.md) | 2.2 | Implemented and reviewed; integrated gates and native UI workflows pass; final attestation open | [Sidebar evidence](evidence/p2-08-library-sidebar.md) |
| [P2-09 Library file export, starter library, example provider](phases/p2-09-library-export-starter-example.md) | 2.2 | Implemented and reviewed; full shipping gates pass; native export checks observed; approved outside repository published; final attestation open | [Export evidence](evidence/p2-09-library-export.md) |
| [P2-10 Window product and Window Type records](phases/p2-10-window-records.md) | 2.3 | Implemented and reviewed; integrated gates and native records Undo/Redo/reopen pass; final attestation open | [Window records evidence](evidence/p2-10-window-records.md) |
| [P2-11 Window Type Builder](phases/p2-11-window-type-builder.md) | 2.3 | Implemented and reviewed; full shipping/browser/coverage gates pass; native workflow observed; final attestation open | [Builder evidence](evidence/p2-11-window-type-builder.md) |
| [P2-12 Window unit and placement operations](phases/p2-12-window-unit-and-placement.md) | 2.3 | Slice A/B verified; Slice C implemented/reviewed/installed; native actions and roundtrips pass; Line split control blocker, E12 open | [Host observations](evidence/p2-12-window-host.md), [cutting rules](evidence/p2-12-zone-cutting-rules.md) |
| [P2-13 Place tool, Schedule and Colour-by](phases/p2-13-place-tool-schedule-colour-by.md) | 2.3 | Scoped | |
| [P2-14 Aperture export](phases/p2-14-aperture-export.md) | 2.3, 1.3 | Scoped | |
| [P2-15 Frame, Glazing and Psi-Install library kinds](phases/p2-15-window-library-kinds.md) | 2.4 | Implemented, native E15 passes | 2026-10-01 |
| [P2-16 Connection provider and sign-in](../phase-05-post-mvp/phases/p2-16-connection-provider.md) | 2.5 | Deferred to Phase 5 by D2-8 | 2026-10-01 |
| [P2-17 Acceptance and handoff](phases/p2-17-acceptance-and-handoff.md) | all | Scoped | |

## Verification

Groundwork has dual-Ruby full-gate and coverage results for the initial coherent build, followed
by focused checks and independent review of final select corrections. Supporting native observations
include reciprocal adjacency, native Undo/Redo, exact references after fresh reopen, and shared
Group refusal. Complete native case attestations and final integrated gates remain open. See
[groundwork evidence](evidence/p2-01-groundwork.md) for build provenance and resume instructions.

## Ledger

| Date | Event |
| --- | --- |
| 2026-10-01 | Implementation authorized. Clean `main` checkout; created `codex/phase-02-envelope` and issue #14. High-assurance profile. P2-01 Ruby groundwork and bounded UI ports underway; required gates remain open. |
| 2026-10-01 | Ed revised D2-1: definitions at the bottom. Assemblies requires nothing, Zones requires assemblies, window placement requires Zones. Delete with replacement moves onto a foundation retarget contract (G10) and inventory usage onto table contributions (G11). CONTRACTS, PLAN, the PRD amendments, stages P2-01, P2-02, P2-05, P2-06 and P2-10, and `context/EXTENSIBILITY.md` updated. D2-10 reaffirmed. |
| 2026-09-30 | Ed answered D2-1 to D2-10, each as recommended. Answers recorded in DECISIONS and folded into the PRDs, CONTRACTS, stage documents, the UI baseline and `context/EXTENSIBILITY.md` (D2-1). The pane-as-Zone-Face finding behind D2-5 was reproduced offline. |
| 2026-09-30 | Packet drafted: plan, contracts, decisions, acceptance register and seventeen stage documents. Feature packets moved into phased directories. PRD amendments recorded for the Phase 1 consequences. |


## Native resume checkpoint

The installed `7afe894` Builder completes the three-element native workflow, including
Empty, merge/split, eyedropper, flip, Installs staging/Save, audit and atomic Frame
replacement. Eighteen native Undo and Redo steps produce 38 exact inventory/reference
comparisons; creation and rename add four exact comparisons. The saved private fixture is
`p209-p211-native.skp`. Fresh reopen remains pending. Native export writes and warning-free
readback succeed for four Materials; explicit Update preserves the library UUID.

Two bounded corrections found in the host now pass focused tests: whole-field visibility
in Duplicate/Delete and readable omission kinds in the final file-export review. The next
step is to install these corrections, recheck those screens and reopen persistence, then
finish E09/E11 and continue P2-15. Full case awards remain open. See P2-09/P2-11 evidence.


## P2-15 integration checkpoint

P2-11's required native Builder workflow, exact journals and fresh persistence are observed;
targeted form/incomplete-state checks pass on installed `74f7f05`. Its full offline gates pass
on both Rubies (973 / 6383, 338 JS, 135 Python); all seven browser scripts pass. E09's remaining
native selected-scope, fresh identity, reuse, failure preservation and outside-provider checks
are recorded. Structured case consolidation remains separate from these retained observations.

Generic copy composition is corrected in `04c4ff9` and independently reviewed. P2-15 source is
implemented and independently reviewed, with focused dual-Ruby tests and four-width browser
checks passing. It adds no library-core or shared-sidebar source changes against that correction.
Integrated dual-Ruby, coverage, runtime and all eight browser gates pass. Exact package
is installed in fresh SketchUp PID 15247; native Frame copy/assignment and single Undo
restore are observed. Glazing, staged Psi and four-kind export/readback are next. Slice B's affected native replay is still open;
Slice C and subsequent placement/export stages still wait for the native Move-copy observation.

## P2-15 closure and D2-8

E15 passes from the recorded fresh native baseline, including both library drags, staged Psi
Save, single native Undo for each and warning-free four-kind semantic export/readback.
P2-16 and roadmap 2.5 move to Phase 5 under the previously accepted D2-8 rule. Endpoint
evidence is [connection decision](evidence/p2-16-deferral.md). Phase 2 remains in progress:
Slice B affected native replay, Move-copy, placement, Unit aggregates, Aperture translation
and consolidated E01 to E14 / E17 acceptance remain. Next autonomous work: remaining Assembly, assignment, export and affected Phase 1 checks.

## Native human continuation

Actual Option Move-copy, exact Copy Undo/Redo and example repository publication are complete.
The retained historical checkpoints above describe their original frontier; current work is
Slice C and the held-Classify replay. Full E12 and Phase 2 remain open.
