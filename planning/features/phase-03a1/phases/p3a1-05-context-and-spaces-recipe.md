# P3a1-05: Context navigation and public-only Spaces authoring

DATE: 2026-10-17
STATUS: Implemented on branch `feat/phase-03a1-p3a1-05`; see [STATUS](../STATUS.md). Rewritten 2026-10-17 to accepted D3a1-04 (foundation-owned navigation) and D3a1-13 (navigation stays `view` and declares the lock it may trigger).
ISSUE: [#221](https://github.com/bldgtyp/ph-composer/issues/221)

## Entry and ownership

Workstream: W2. Order: V4. Depends on: P3a1-02 (`side_effects` on view commands, the `context` read) and P3a1-04.
Review findings: A08, A09 integration, Spaces portion of A13. Acceptance: C05 in [ACCEPTANCE](../ACCEPTANCE.md).
Behavior: [PRD](../PRD.md). Proposed boundaries: [CONTRACTS](../CONTRACTS.md) section 3.
Decisions: [DECISIONS](../DECISIONS.md) D3a1-04, 13. Delivery rules: [PLAN](../PLAN.md).

Navigation is a foundation capability: `ph_composer.context.open(path)` and `ph_composer.context.root`,
view commands registered beside `RecordQueries`, `ColourBy`, `Library` and `LocationCommands`.
Zones gains nothing; Spaces keeps `context.open` and `context.close` as reference-aware conveniences.
Where D3a1-13's row says "the new Zones navigation" declares the lock, it means these two foundation
commands, which the later D3a1-04 receipt relocated from Zones; nothing Zones-owned is added.
Under D3a1-13 a view command writes no authored data and creates no Undo entry of its own, and may
trigger the Model's own protection boundaries, which each command declares in `side_effects`.

## Source and intended change surface

Existing files changed:

- [session/edit_context.rb](../../../../src/ph_composer/session/edit_context.rb): unchanged in behavior; the one place the path is assigned, which the new commands call through `enter` and `enter_root`
- [extension.rb](../../../../src/ph_composer/extension.rb): the context capability joins `FOUNDATION_FEATURES`
- [features/spaces/declarations/context.rb](../../../../src/ph_composer/features/spaces/declarations/context.rb): `context.open`, `context.close` and `locate` declare the Volume lock in `side_effects`
- [features/spaces/context/navigation.rb](../../../../src/ph_composer/features/spaces/context/navigation.rb) and [context/protection.rb](../../../../src/ph_composer/features/spaces/context/protection.rb): unchanged; `Protection.leaving` is the boundary the foundation command triggers
- [features/zones/faces/locate.rb](../../../../src/ph_composer/features/zones/faces/locate.rb): `locate` declares its side effect too
- [features/spaces/authoring.rb](../../../../src/ph_composer/features/spaces/authoring.rb): unchanged; `create` keeps requiring the Zone's open context, which the foundation command now supplies
- [tools/examples/authoring/spaces_walkthrough.rb](../../../../tools/examples/authoring/spaces_walkthrough.rb): split into labelled native fixture setup and a public-only client segment
- [tools/hostkit/.index.md](../../../../tools/hostkit/.index.md): the stale Spaces routing sentence (CL04)

New file, named here and linked when the stage merges: `src/ph_composer/shell/context_commands.rb`
(the foundation feature `ph_composer.context` with the two view commands, beside `location_commands.rb`).

## The two commands

| Command | Params | Behavior | Declared side effect |
| --- | --- | --- | --- |
| `ph_composer.context.open` | `path`: root-to-occurrence persistent-id path of Groups and ComponentInstances, outermost first; optional `expected_path`, the current path the caller read | Resolves every step, refuses a locked entity on the path (`target.locked`), a step that does not resolve (`target.not_found`) or a changed current path (`target.edit_path_changed`, the code Make Zone and the Spaces steps already answer with "the active edit path changed"); then `EditContext.enter`, so every registered boundary runs | Leaving an unprotected Volume locks it (Spaces' `Protection.leaving`); the Model revision advances on the path change |
| `ph_composer.context.root` | optional `expected_path` | `EditContext.enter_root` after the same checks | The same |

Both refuse while the session is busy, as every view command does, and never close a user's tool
or draft to succeed. A path equal to the current one changes nothing and reports no change.

## Implementation steps

1. Register the foundation feature with the two commands, their schemas, examples and refusals;
   the handler resolves the path on the live Model and calls `EditContext`, nothing else.
2. Add `side_effects` to the Spaces context commands and `locate` with the lock wording the
   consent copy in 07 reuses; the generated reference shows it.
3. Measure the C05 matrix for a `view`-only caller: admission, lock, path, revision and Undo effects
   of `context.root` from inside an unprotected Volume, of `context.open` into a Zone, and of
   Spaces' `context.close`; record what the Undo menu shows.
4. Write the public-only client segment: `discover` and `context` read, `candidate_faces.list`,
   `ph_composer.context.open` on the Zone, `spaces.create`, `volumes.create` from a loose Face,
   `floors.mark`, height and airflow edits, `ph_composer.context.root`, `move_to_zone`, read-back of
   every affected reference; through the live V2 connection and the in-process API alike.
5. Add the refusal paths to that segment: wrong session, stale `expected_path`, locked step, busy
   reconciliation, a user tool active; each leaves path and Model unchanged. Step N's failure does
   not undo steps 1 to N minus 1.
6. Update the walkthrough comments, the hostkit routing sentence, [AGENT_INTERFACE](../../../../context/AGENT_INTERFACE.md)
   (the Spaces inventory section A13 asks for, and the view sentence D3a1-13 rewrites) and the
   quickstart at docs-pass.

## Acceptance checks

- The public segment assigns no path and traverses no geometry after fixture setup; open, root and
  move return correct references and metrics.
- Opening the current path reports no change; leaving a Volume protects it and the outcome's
  revision matches the host's; locked, stale and busy requests leave path and Model unchanged.
- The C05 matrix for the `view`-only caller is recorded with exact Undo menu labels; declared
  `side_effects` match the measured effect.
- Native Undo, Redo, save and reopen preserve data, protection, metadata and references; no
  selection or draft is stolen to force success.

## Native/client gate

Fresh process with FX1, panel closed, through both CLIs and the bridge for observation. Native
controls verify per-action Undo and Redo and a fresh reopen; cases registered in the acceptance
tooling; a user's modified Model is never discarded.

## Cleanup and documentation

CL03 and CL04: the strict recipe has no private navigation; the fixture helpers stay and say what
they are; the hostkit index routes to the present walkthrough. Context [CONTRACTS](../../../../context/CONTRACTS.md)
"Public interface" and the view sentence in [AGENT_INTERFACE](../../../../context/AGENT_INTERFACE.md)
take D3a1-13's wording at docs-pass; the packet's section 3 folds in.
Record affected context/docs, exact checks and evidence in [STATUS](../STATUS.md) through docs-pass.
Shipping source/tests cite durable context rather than this plan. Preserve unrelated dirty work.

## Done when

C05's public-only offline and native cases pass, the matrix is recorded, the generated reference
shows the declared side effects, and the high-assurance review passes.
Applicable full gates, review level, manifest handling and DCO/hook rules are in [PLAN](../PLAN.md).
A planning document or unexecuted check is not implementation evidence.

## Out of scope

Zones-owned navigation, generic Model lifecycle or Undo tools, CAD drawing automation, a new panel
layout, and any path assignment outside `EditContext`.
