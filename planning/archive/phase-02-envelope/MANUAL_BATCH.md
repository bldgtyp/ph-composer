# Phase 2: remaining human batch

DATE: 2026-10-01
STATUS: Complete. All required human gestures observed; preparation instructions below are historical.

All in-scope implementation is delivered on `codex/phase-02-envelope`. Named cases are
consolidated in [ACCEPTANCE](ACCEPTANCE.md). Only the held-Classify action requires human
controls. The subsequent handoff records findings; it does not substitute for the gesture.

## Held Classify across Model and edit-path change

Codex prepares `_private/host/envelope/held-classify-ready.skp`, a separate synthetic model,
at its root edit path with Classify set to Floor. The target is an existing classified Wall,
so an erroneous write is observable. Do not operate the integration/reference model.

1. Hold the left mouse button on the prepared Wall. While holding, press Cmd-N. Release only
   after the new Model opens. Stop there; Codex reads both sessions and the callback trace.
2. Codex restores the prepared fixture and arms a two-second development-only timer. Hold the
   left button on the same Wall. The timer enters the owning Zone; release after that change.
   Stop there. Codex checks cancelled status, cleared collection, unchanged revision and full
   authoring fingerprint. Entering edit context alone may set SketchUp's modified flag.

The tools-only wrapper traces genuine native callbacks; it does not replace shipping tool logic.
The timer changes native edit context only. Both are removed by process restart after readback.
Current CUA combines button-down/up in one drag and cannot interleave the required transition;
this is a control limitation, not another approval requirement. Codex collects results directly.
Original authority: [Phase 1 held-button cases](../phase-01-faces-and-zones/evidence/p1-d-keyboard-context.md#held-button-model-switch-reproduced-defect-and-correction).

## Completed human items

Ed's actual Move then Option-copy has exact separate Copy Undo/Redo proof; E12 passes.
The approved example is published at
[bldgtyp/ph-composer-library-provider-example](https://github.com/bldgtyp/ph-composer-library-provider-example),
signed commit `d54a2ca`, with provider checks and remote byte comparison complete.
Ed's placement/measurement/refusal/colour walkthrough supplies E13 evidence. No repetition of
these completed gestures is required without a relevant source/evidence change.

## After the gesture

Codex completes readback, removes instrumentation through a fresh normal host, updates the
register/context/packets and records the hands-on findings before any archive. E16 stays deferred
to Phase 5. Main-repository push, PR and merge have not occurred. SketchUp 2023, Windows,
public release, certification and METr consumer acceptance remain separate.


## Prepared remaining gesture

Normal shipping checkpoint `f4f6576`, signed consolidation `80815f0`; PID 45208 has the restored,
saved integration Model and active isolated `held-classify-ready.skp`. Prepared session
`49781f8a-a2ae-478b-a4f9-f0de2a00e55e`, root edit path, unmodified; Classify Floor is active.
Fixture SHA-256: `147a5638a3203381829bc35700530d5012b14fae3ad77ae330a5134ded7f7d9a`.
The native view shows a large tan classified Wall on the right. Model-switch tracing is armed;
no edit-path timer is armed yet. Before-action ledger snapshot is `p217-held-a09-baseline.json`,
authored fingerprint is `p217-held-authoring-before.json`, preparation is `p217-held-prepared.json`
in the private corpus. Preserve this state until Ed's held Cmd-N/release gesture is read back.
Existing historical trace/results were copied with the `pre-p217-` prefix before instrumentation.


## Model-switch attempt and prepared repeat

Ed reported the held Cmd-N sequence done. New empty session
`2c8f0bfa-fbcb-45f3-abc5-8ec847f8129d` opened; original session revision remained 1,
full authoring fingerprint was unchanged and modified was false. The callback trace contained
no events and remained armed. The attempt is unknown for held-button cancellation, not a pass.
The empty test Model was closed through native controls. An unarmed ordinary native click then
recorded down/up, classified one Face and advanced revision. One native Undo restored the exact
original fingerprint. This validates tracing, not the held-switch assertion. Its private journal
is `p217-held-diagnostic-click.json`; any `held-classify-model-result.json` produced by that click
must not be counted as the human acceptance result.

Model mode is rearmed in the same isolated fixture/session at root, Classify Floor active.
New before-action snapshot: `p217-held-repeat-a09-baseline.json`; full authoring fingerprint:
`p217-held-repeat-authoring-before.json`. Ask Ed to activate SketchUp by clicking its title bar
first, then hold on the tan Wall, Cmd-N and release after the new Model opens. The trace must
observe down on the original Model and up after the switch before this assertion can pass.


## Held Model switch verified; edit-path half armed

The repeat passes on PID 45208, normal installed shipping `f4f6576` with tools-only callback
tracing. Original session `49781f8a-a2ae-478b-a4f9-f0de2a00e55e`: genuine mouse-down collected
one Face at root with revision 3; mouse-up ran after new session
`389d3286-0224-44ec-962f-4c8ac860dd7e` became active. Revision stayed 3, collecting false,
collected zero; full authoring fingerprint equals `p217-held-repeat-authoring-before.json` and
modified is false. Native AX shows Select in the new Model. Private direct readback:
`p217-held-model-observed.json`; genuine events are retained separately from the first unobserved
attempt and ordinary diagnostic click.

The private summary writer used an unavailable `Sketchup.status_text` getter, after writing the
genuine event trace. Direct bridge readback supplies the result without invoking any synthetic
callback. That getter is removed from the tools-only helper; native UI supplies status evidence.
No shipping code changed. The empty test Model is closed. Original fixture is active at root,
Classify Floor enabled and `edit_path` mode armed. The timer starts only on genuine mouse-down,
then enters the west Zone after two seconds. Snapshot `p217-held-edit-a09-baseline.json` and
fingerprint `p217-held-edit-authoring-before.json` precede this next gesture. Ask Ed to activate
via title bar, hold on the tan Wall until the edit context changes, release, then stop. No Cmd-N
for this half. Afterwards collect readback and restore a fresh normal host without tracing.


## Final held-Classify result and normal-host restoration

Both required physical gestures pass on shipping `f4f6576`. For the edit-path half, genuine
mouse-down at root collected one Face at revision 3. The timer entered west Zone 48880 and
native navigation advanced revision to 5 before mouse-up. Release stayed at revision 5,
cleared collection and left the complete authored fingerprint unchanged. The helper's whole-
gesture `revision_unchanged=false` reflects navigation; the relevant release boundary is
`release_revision_unchanged=true`. Native AX/pixels report “The Classify gesture was cancelled.
Nothing was written.” Closing the context and native Save return root/unmodified with exact
fingerprint. Private evidence: `p217-held-edit-observed.json`, the genuine callback trace and
`p217-held-edit-authoring-before.json`. The append-only ledger retains earlier unknown attempts.

Native Quit removes tracing and the timer. Fresh normal SketchUp PID 47711, session
`d26e1cae-e952-4c6f-8642-c92608a1ff9d`, opens only the saved integrated Model at root,
unmodified, with no tracing constant and zero configured providers. Full public catalogs,
Faces, Units, glazed areas and settings equal the pre-test baseline. Normal public export
preflight succeeds with its expected nonblocking disclosures and no blockers. Journal:
`p214-p217-final-normal-restoration.json`. No shipping hotloads, synthetic construction provider,
fault override or private runtime remains active. Installed package identity is unchanged.

E01 and E05 now pass their remaining affected A09 assertion. E17's required checks pass with
explicit current/retained provenance. Ed's hands-on continuation covered placement, sill/offset,
roof, refusal, session change, Colour-by, outline bounds, Move-copy and held-Classify. The only
findings during consolidation were the corrected Assembly redraw and draft-focus defects,
and the tools-only summary getter correction; no shipping finding remains open. This is the
hands-on record, not a claim that every future workflow has been evaluated.

Phase 2 is accepted on the feature branch for the current macOS/SketchUp 2026 host. E16,
METr/PHX, Spaces/thermal bridges, SketchUp 2023, Windows, public distribution and certification
remain explicitly outside this closure. Final docs reconcile delivered capabilities, and archive
packets retain their original evidence identities. No main-repository push, PR or merge occurs.
