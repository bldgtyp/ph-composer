# Zone-copy participation by child owners

DATE: 2026-10-13
STATUS: ZC-01 implemented on branch: late binding confirmed on the host. ZC-02 to ZC-04 are implementation ready. Stage ledger in [STATUS.md](STATUS.md).
ISSUE: [#113](https://github.com/bldgtyp/ph-composer/issues/113)
BASELINE: `cfe01a6aad99a0e09d5ecf0de5659c606d7ba4f9`
PRODUCT REQUEST: [copied-Zone Windows](../../../features/unscheduled/copied-zone-windows/README.md)
DEPENDS ON: [Registration reliability](../../../archive/registration-reliability/PLAN.md) RR-02 for the new
declaration; [Windows orchestration](../../../archive/windows-orchestration/PLAN.md) for `units/identity_step.rb`
ownership; [Cross-feature composition](../../../archive/cross-feature-composition/PLAN.md) C-02 for the owner-derived
request pattern. [Entity customization](../entity-customization/PLAN.md) shares `Extension.copy_data`.

## Goal

When a Zone occurrence becomes independent, by the explicit action or by the copy watcher's
follow-up, every feature that owns records inside that occurrence contributes its own restorable
steps to the same proposal, under its own owner, without Zones naming any child. Windows is the
first adopter: copied Units get new ids in the same Undo step as the Zone. A synthetic second child
proves the seam. Spaces P3a-04 adopts it later under D3a-13.

## Verified at the baseline

| Where | What it does now | Consequence |
| --- | --- | --- |
| `features/zones/zone/copy_watch.rb` | Schedules a deferred pass after an added container commits; runs `HostFollowUp.run(session, "ph_composer.zones.make_independent", paths)`; announces; on a later Undo that took the repair back, notices and leaves the copy read-only | The gesture-join uncertainty is already accepted for Zones (D-1): a callback cannot tell the copy's trailing commit from an unrelated one; the Undo notice is the mitigation |
| `shell/host_follow_up.rb` | Runs the action handler per params into one proposal; refuses record changes; requires every step to answer `restore`; applies in one transparent operation; on failure restores applied steps in reverse and commits | A child step joins by being added to the same proposal with `restore` |
| `features/zones/zone/operations.rb`, `make_independent` | `Repair.identity_plan(... isolating: true)`, adds `MakeIndependentStep` | The one place the transition is emitted, for both routes |
| `features/zones/zone/steps.rb`, `MakeIndependentStep#apply` | `make_unique` on the Group and nested Groups, re-resolves the occurrence at the same path, rebuilds the plan with the preview's mapping, refuses `target.changed` on any drift, writes, captures pre-images; `restore` writes them back | Nested entity ids change at apply; Zones binds logically and re-resolves. Children must do the same |
| `features/windows/units/identity_step.rb`, `IdentityStep` | `apply` only; resolves by `reference.entity_path` | No `restore`; references captured before `make_unique` are stale after it |
| `features/windows/units/identity_plan.rb`, `IdentityPlan.build(occurrences, identity:, catalog:, engine:, only:)` | Allocates new `wun_` ids for every copy after the first by path; copies extension data under the declared rules; `only:` limits to named shared ids | The planner to reuse, scoped to the copied occurrence |
| `shell/registry.rb`, `reference_retargeter` and `HandlerRequest#retarget_references` | A definition owner calls a foundation route; every registered retargeter for the kind runs under its own owner and returns a typed plan | The declaration and invocation pattern to mirror |
| `planning/archive/copied-zone-edit-refusal/evidence/p5-host-acceptance.md`, S10 | Copied Units are new instances glued to the copy's own walls; they keep the original Unit ids | The product gap; also evidence that Units survive the native copy |
| `tools/spikes/copied-zone-independence/spike.rb` | The host spike behind the Zone transition | ZC-01 extends it |

## Target design

### Declaration, mirroring retargeters

```ruby
# A feature that owns records inside Zone occurrences:
feature.transition_contributor("ph_composer.windows.units.follow_zone_copy",
                               :transition => "ph_composer.zones.occurrence_independent") do |request, proposal, transition|
  Units::ZoneCopy.contribute(request, proposal, transition)
end
```

`Declarations::TransitionContributor(name:, owner:, transition:, handler:)`. Registration requires the
contributor's feature to require the transition's owner (the prefix before the last segment names the
feature, `ph_composer.zones`), a callable handler, and RR-02 owns the values. Zones declares nothing
extra: the transition name is a string Zones documents in CONTRACTS, as retargeters' `target_kind` is.

### Invocation

```ruby
# shell/handler_request.rb
# Runs every registered contributor for `transition` under its own owner, in name order, inside
# this request's proposal. Each returns detached affected references; its steps must answer
# `restore`. Any failure refuses the proposal. The caller owns the transition's own step.
def contribute_transition(transition, description)
```

`description` is detached JSON: `zone_path`, `old_zone_id`, `new_zone_id`, `mapping` (every old to
new id Zones allocated), `revision`, and `mode` (`"explicit"` or `"follow_up"`). The foundation
validates the result shape, checks every step the contributor added answers `restore`, and poisons
the proposal on error, as `retarget_references` does.

`make_independent` calls `request.contribute_transition("ph_composer.zones.occurrence_independent", description)`
after adding `MakeIndependentStep`, so child steps apply after the parent isolated storage.

### Late binding in the child step

A child plans at preview against entity references that `make_unique` replaces. The step therefore
binds logically: for each Unit inside `zone_path`, the pre-image record and its ordinal among Units
with the same record id in path order. At apply it enumerates Units inside the final occurrence,
groups by record id, orders by path, and requires the same count per id and equal pre-images;
otherwise `target.changed`. It writes new ids from the preview's allocation, captures what it wrote,
and `restore` writes the captured pre-images back, tolerating never-applied entries.

`IdentityPlan.build(..., only:)` already scopes the plan; the contributor passes the ids of Units
inside the copied occurrence. Units outside the occurrence are untouched: this route does not scan
the Model. The broad next-Windows-mutation repair stays as the fallback for every other copy route
(W1).

### Execution routes

| Route | Owner of the operation | Failure |
| --- | --- | --- |
| Explicit Make Zone independent | Ordinary action through `Dispatch` | Whole proposal refuses before apply, or the outer abort with verified rollback |
| Copy watcher follow-up | `HostFollowUp`, transparent | Never aborts; restores applied steps in reverse (parent and children), commits, notices |

Provenance: this plan adds no new join mechanism. The follow-up joins the same transaction the Zone
repair already joins, with the same accepted uncertainty and the same Undo notice. D-01 in
[DECISIONS](../DECISIONS.md) becomes relevant only if ZC-01 shows the Units are not reliably present
or re-resolvable after `make_unique` on the host.

## Stages

### ZC-01: host spike (document deliverable)

State: Implemented on branch. Decision: late binding as designed; D-01's decline path is not needed.
The note is [SKETCHUP_HOST_BEHAVIOR.md, "Window Units inside a copied Zone"](../../../../context/SKETCHUP_HOST_BEHAVIOR.md#window-units-inside-a-copied-zone).
Two refinements for ZC-02 and ZC-03, neither an escalation: the logical binding matches same-id
Units by equal pre-images, so path order is only a tiebreak; and a nested copy reaches the transition
only after the wrapper's Make Unique, because the parent refuses first. Native Undo of copy plus
repair is left to ZC-04.

Extend `tools/spikes/copied-zone-independence/spike.rb` or add a sibling. On the current host, with a
Zone holding two glued cutting Units of two Types:

1. Native copy the Zone; record Unit instance persistent ids and `glued_to` before and after
   `make_unique` on the copy's Group, and after `isolate_groups`.
2. Repeat with a `5x` array copy and with a copy nested one Group deeper.
3. Apply a trial `restore` that writes the old Unit records back inside the transparent operation
   and confirm one Undo removes copy and repair together.
4. Check whether `Occurrences.all(model)` enumerates the copied Units at their final paths after
   isolation within the same operation.

Deliverable: a note in `context/SKETCHUP_HOST_BEHAVIOR.md` with host version, the id behaviour and
the enumeration result, and a decision in this packet: late binding as designed, or D-01's decline
path. No shipping source changes.

Exit: the note exists and the ZC-02 design is confirmed or amended against it.

### ZC-02: declaration and invocation

State: Merged to main in PR 115. Review added: contributors run with the participant guards (owner-only
writes, add-only proposal, `{kind, id}` references of owned kinds); actions declare `transitions:` and
contributors `refuses:`, so discovery projects child codes onto the emitting action. Deviation: the description carries no `mode`; no contributor needs to
tell the routes apart, since both require restorable steps. Add it when a contributor does.

Files: `shell/declarations.rb`, `shell/registry.rb`, `shell/registry_validation.rb`,
`shell/handler_request.rb`, `features/zones/zone/operations.rb`; tests `tests/registry_test.rb`,
`tests/handler_request_test.rb`, `tests/zone_repair_test.rb`.

1. Add `TransitionContributor`, its scope method, validation and `contribute_transition`.
2. `make_independent` emits the transition after its own step.
3. Tests, one each: a contributor whose feature does not require Zones refuses registration; a
   contributor runs under its owner with a detached description; a contributor adding a step without
   `restore` refuses the proposal; a contributor that raises after another contributed poisons the
   whole proposal; no contributor registered leaves `make_independent` unchanged.

Exit: tests pass; Zones source contains no child feature name.

### ZC-03: Windows adopter and a synthetic child

State: Merged to main in PR 116. The step is `Units::ZoneCopyStep` beside `Units::ZoneCopy` rather than a
mode of `IdentityStep`, which keeps path binding for the broad repair; `IdentityStep` still gains
`restore`. `HostFollowUp` now asks every step to restore even after one fails. The test stub's Make
Unique now gives nested ComponentInstances new ids and glue, as ZC-01 measured. Review added: the
description carries the parent's typed reference entries so copied payloads remap to sibling Units and
the new Zone and Faces; Units with already-unique ids are remapped too; two copied Units sharing an id
each keep their own self-reference; enumeration is scoped to the occurrence; every captured Unit
restore is attempted. Open follow-up: a copied payload that names a sibling Unit is checked through
`Engine#resolve_reference`, which reads every Unit in the Model, so an unreadable Unit elsewhere still
refuses that case. Scoping the engine's check to the staged plan is an Engine change outside ZC-03.

Files: `features/windows/units/zone_copy.rb` (new), `units/identity_step.rb` (`restore`, late
binding), `windows/install.rb`; a synthetic child feature under `tests/support/` or
`tools/examples/`; tests `tests/window_unit_identity_step_test.rb`, `tests/zone_copy_watch_test.rb`,
`tests/zone_repair_test.rb`, `tests/windows_walkthrough_test.rb`.

1. `IdentityStep` gains `restore` and the logical binding; `Units::ZoneCopy.contribute` builds the
   scoped plan with `only:`.
2. The synthetic child owns one record kind stored on Groups inside Zones and contributes a
   restorable id rewrite.
3. Tests, one each: explicit Make independent with two Units gives new Unit ids, same Type ids and
   anchors, originals unchanged; the watcher route does the same in one `HostFollowUp` with both
   children; a child restore failure still attempts the other child's restore and reports
   `restored: false`; a fault after the parent write restores parent and children; an unsupported
   extension payload on a Unit refuses the whole transition; Undo and Redo through the stub.

Exit: `tests/zone_copy_watch_test.rb` proves both children in one gesture; the Zones feature source
still names no child.

### ZC-04: native proof, export read-back and canon

State: Implemented on branch; native Undo and Redo outstanding (receipt in STATUS).

1. Native, current host, fresh process: copy a Zone with two export-ready Types (frames, glazing and
   Psi-Install Types assigned); distinct Unit ids at once; originals unchanged; one Undo and Redo;
   `5x` array copy; save and reopen; HBJSON export with unique Aperture ids on the copied Faces.
2. `context/CONTRACTS.md` "Compound proposals": the transition contributor contract and the
   `occurrence_independent` transition. `context/EXTENSIBILITY.md`: the Zone-child pattern with
   Windows as the example and Spaces as the next adopter. Update the product request README and the
   Spaces packet's link.
3. One stronger independent review; dual-Ruby `make ci`; `make coverage`.

Exit: receipts filed; STATUS updated; the product request marked implemented on branch.

## Decisions and deviations

Accepted by Ed on 2026-10-13.

| Earlier default | Now | Reason |
| --- | --- | --- |
| A new gesture-provenance lifecycle with invalidation on intervening commits | None added; inherit the Zone repair's accepted join and Undo notice | The uncertainty is already accepted for Zones; a child joining the same follow-up adds no new risk |
| A declared transition registry with input and result schemas | A string transition name plus a contributor declaration, as retargeters use `target_kind` | One mechanism to learn; schemas can be added when a second transition exists |
| Two-phase bundle with "late target materialization" as a foundation protocol | Logical binding inside the child step, the way `MakeIndependentStep` already binds | The parent already solved this shape; the child copies it |

The coding agent decides module and test names.

Escalate to Ed: if ZC-01 shows Units cannot be re-resolved after isolation (D-01 decline path), or
if array copies behave differently from single copies.

## Verification profile

High assurance: the ZC-01 host note, deterministic fault tests in ZC-02 and ZC-03, dual-Ruby
`make ci`, one stronger review, the ZC-04 native receipt. See [ACCEPTANCE.md](ACCEPTANCE.md).
