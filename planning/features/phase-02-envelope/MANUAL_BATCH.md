# Phase 2: remaining human batch

DATE: 2026-10-01
STATUS: Move-copy and outside example complete. Held-Classify remains.

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
Original authority: [Phase 1 held-button cases](../../archive/phase-01-faces-and-zones/evidence/p1-d-keyboard-context.md#held-button-model-switch-reproduced-defect-and-correction).

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
