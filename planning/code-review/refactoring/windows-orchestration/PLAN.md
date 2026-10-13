# Windows definition and placement coordination plan

DATE: 2026-10-13
STATUS: Scoped; implementation ready, not authorized. Stage ledger in [STATUS.md](STATUS.md).
ISSUE: [#106](https://github.com/bldgtyp/ph-composer/issues/106)
BASELINE: `cfe01a6aad99a0e09d5ecf0de5659c606d7ba4f9`
FINDING: [RF-02](../../sections/04-ruby-features.md#rf-02-windows-definition-operations-know-placement-internals)
DEPENDS ON: nothing for the extraction itself. Coordinate file ownership with
[panel domain ownership](../panel-domain-ownership/PLAN.md), which edits `types/installs.rb` and
`snapshot.rb`, and with [zone-child lifecycle](../zone-child-lifecycle/PLAN.md), which edits
`units/identity_step.rb`.

## Goal

Product and Type operations propose record changes and nothing else. One feature-local coordinator
owns the order every public Windows command follows: the accepted copied-identity repair first, the
definition proposal, then whatever placed Units must do to follow the definition. Policy held fixed:
one generated primary component per Type; every Unit follows its Type; atomic used-Type propagation
with anchors preserved; and the next-Windows-mutation copied-id repair on every Windows action,
unrelated catalog actions included (Ed, 2026-10-13, W1).

## Verified at the baseline

The complete inventory of `Units::Mutation.prepare` and related calls outside `units/`:

| Caller | Call | Layer | Disposition |
| --- | --- | --- | --- |
| `products/operations.rb`: `create`, `update`, `duplicate`, `delete` | `Units::Mutation.prepare` first line each | Definition | Remove; the coordinator prepares |
| `types/operations.rb`: `create`, `update`, `duplicate`, `delete`, `grid` | `Units::Mutation.prepare` first line each | Definition | Remove; the coordinator prepares |
| `types/operations.rb`: `update`, `grid` | `moved(request, proposal, before)`, which calls `Units::Changes.type` and `Units::Changes.count` | Definition calling placement | Move `moved` to the coordinator |
| `types/operations.rb`: `delete` | `Units::TypeRetargeter.cleanup(request, proposal, current) unless retarget` | Definition calling placement | Move to the coordinator |
| `types/operations.rb`: `delete`; `products/operations.rb`: `delete` | `request.retarget_references(...)` | Foundation contract | Keep; this is the sanctioned downward-blind route |
| `install_save.rb`, `InstallSave.call` | `Units::Mutation.prepare` once, then product and Type operations | Feature-local compound command | Keep the single prepare; it is already a coordinator for one command |
| `settings.rb`, `Settings.propose` | `Units::Mutation.prepare` | Definition-adjacent | Move the prepare to the coordinator's settings wrapper; `Settings.retarget` runs inside an already prepared delete |
| `units/repairs.rb` (six sites), `units/actions.rb` `place` | `Mutation.prepare` | Placement | Keep; same layer |
| `declarations/records.rb` (eight actions), `declarations/grid.rb` (grid gestures) | Call `Products::Operations.*` and `Types::Operations.*` directly | Public actions | Route through the coordinator |
| `library_kinds.rb`, product `create` and `replace` callbacks | Call `Products::Operations.create` and `.update` | Library callbacks | Route through the coordinator |
| `library_assignment.rb`, `assign_grid` and `assign_psi` | `Types::Operations.grid`, `Settings.propose` | Library callback | Route through the coordinator |
| `units/identity_step.rb`, `Mutation.prepare` | Finds an existing `IdentityStep` on the proposal and returns it | Idempotent per proposal | The "once per root proposal" guarantee already holds |
| `declarations/shapes.rb`, `Shapes.side_effects` | Appends the copied-identity sentence to every Windows action's side effects | Discovery | Unchanged |

`DefinitionPlan.build`, `Types::Grid`, `Thermal` and `Installs` read explicit records and are already
pure. The repair policy is advertised and tested (`tests/window_unit_actions_test.rb` exercises a Type
rename repairing a copied Unit).

## Target design

One new module, `features/windows/authoring.rb`, required from `install.rb` after the operations
modules:

```ruby
module PhComposer
  module Windows
    # Every Windows command that changes a definition runs through here, in one order: the
    # copied-identity repair the feature advertises on every action, the definition's own record
    # proposal, then the placed Units' follow-up. Product and Type operations below it know only
    # records; Units know only Units; this module knows both and nothing else does.
    module Authoring
      module_function

      def create_product(request, proposal, collection, values:, user_data: nil)
        Units::Mutation.prepare(request, proposal)
        Products::Operations.create(request, proposal, collection, :values => values, :user_data => user_data)
      end

      def update_product(request, proposal, collection, id:, values:, expected_values:, user_data: nil)
        Units::Mutation.prepare(request, proposal)
        Products::Operations.update(request, proposal, collection, :id => id, :values => values,
                                                                   :expected_values => expected_values,
                                                                   :user_data => user_data)
      end

      # duplicate_product and delete_product follow the same shape.

      def update_type(request, proposal, id:, values:, expected_values:, user_data: nil)
        Units::Mutation.prepare(request, proposal)
        before = request.engine.find(TYPE_KIND, id)
        Types::Operations.update(request, proposal, :id => id, :values => values,
                                                    :expected_values => expected_values, :user_data => user_data)
        follow_type(request, proposal, before)
      end

      def grid(request, proposal, gesture:, id:, values:, expected_values:, &change)
        Units::Mutation.prepare(request, proposal)
        before = request.engine.find(TYPE_KIND, id)
        Types::Operations.grid(request, proposal, :gesture => gesture, :id => id, :values => values,
                                                  :expected_values => expected_values, &change)
        follow_type(request, proposal, before)
      end

      def delete_type(request, proposal, id:, expected_values: {}, retarget: false, replacement_id: nil)
        Units::Mutation.prepare(request, proposal)
        current = request.engine.find(TYPE_KIND, id)
        Types::Operations.delete(request, proposal, :id => id, :expected_values => expected_values,
                                                    :retarget => retarget, :replacement_id => replacement_id)
        Units::TypeRetargeter.cleanup(request, proposal, current) unless retarget
        { "id" => id }
      end

      def update_settings(request, proposal, values:, expected_values:)
        Units::Mutation.prepare(request, proposal)
        Settings.propose(request, proposal, :values => values, :expected_values => expected_values)
      end

      # The placed Windows follow the Type as the proposal leaves it.
      def follow_type(request, proposal, before)
        id = before.fetch("id")
        after = proposal.find(TYPE_KIND, id)&.after || before
        Units::Changes.type(request, proposal, :before => before, :after => after)
        { "id" => id, "unit_count" => Units::Changes.count(request.model, id) }
      end
    end
  end
end
```

`Products::Operations` and `Types::Operations` lose every `Units::` reference: the `prepare` lines,
`Types::Operations.moved`, and the `TypeRetargeter.cleanup` line. `Types::Operations.update` and
`grid` return `{ "id" => id }`; the coordinator supplies `unit_count`. `Settings.propose` loses its
`prepare` line. `InstallSave.call` keeps its one `prepare` and calls the operations directly, because
it is itself the coordinator for that command and must not prepare twice (it would not: `prepare`
finds the existing step, but the intent is clearer with one call).

A test for `Products::Operations` or `Types::Operations` then needs a Model with record dictionaries
and nothing else: no placed Unit, no host Face, no primary definition. That is the W-02 exit.

Not done here: no change to repair timing or trigger, no participant registration for internal
collaborators, no new Zone dependency, no per-Unit overrides, no move of `DefinitionPlan` (it is
already pure; moving it is churn).

## Stages

### W-01: introduce the coordinator and route every caller

State: Scoped.

Files: `features/windows/authoring.rb` (new), `install.rb`, `declarations/records.rb`,
`declarations/grid.rb`, `library_kinds.rb`, `library_assignment.rb`, the settings action in
`settings.rb` or its declaration; tests `tests/window_records_operations_test.rb`,
`tests/window_library_kinds_test.rb`, `tests/windows_walkthrough_test.rb`.

1. Add `Authoring` with wrappers for every product and Type command, `grid`, `update_settings` and
   `follow_type`. In this stage the wrappers call `prepare` and the operations still do too; `prepare`
   is idempotent, so behaviour is unchanged.
2. Route the eight record actions, the grid gestures, the two library callbacks, `assign_grid`,
   `assign_psi` and the settings action through `Authoring`.
3. Tests: one test per routed caller asserting the proposal holds exactly one `IdentityStep` after a
   compound command (a library copy that creates and assigns; an Installs save with an import) and
   that discovery output is unchanged (`make fixtures-check`).
4. `"$RUBY" -Itests -rwindow_records_operations_test -rwindow_library_kinds_test -rwindows_walkthrough_test -rwindow_unit_actions_test -e ''`.

Exit: all Windows suites pass unchanged; `make fixtures-check` passes.

### W-02: strip placement knowledge from the operations

State: Scoped.

Files: `products/operations.rb`, `types/operations.rb`, `settings.rb`; tests
`tests/window_records_operations_test.rb` (split into record-only cases) and a new
`tests/window_authoring_test.rb` for the coordinator.

1. Remove the `prepare` lines, `moved`, and the `cleanup` line from the operations; move
   `unit_count` to `follow_type`.
2. Record-only tests for each operation using a Model with record dictionaries only: create,
   update, duplicate, delete with and without retarget, `replace_in_types`, grid gestures, unique
   names, `source` handling. Assert no step is added to the proposal.
3. Coordinator tests: Frame create with a locked copied Unit refuses `target.locked` with
   `effect: none` (the advertised policy); unlocking and repeating creates the Frame and reports
   `identity_repaired`; Type resize with two anchored Units adds one `TypeChangeStep` with both
   hosts; a name-only Type edit adds no `TypeChangeStep`; Type delete without retarget adds the
   cleanup step; a compound Installs save prepares once.
4. Add a dependency check to `tests/load_order_test.rb` or a small new test: the source of
   `products/operations.rb` and `types/operations.rb` contains no `Units::`.
5. Run the W-01 command plus `-rwindow_authoring_test -rload_order_test`, `make lint-ruby`,
   `make coverage`.

Exit: operations tests run without any Unit fixture; the source check passes; coverage holds.

### W-03: canon, review and native proof

State: Scoped.

Files: `context/EXTENSIBILITY.md` "Organization and dependencies" (the layer rule paragraph and the
definition-feature paragraph), `context/CONTRACTS.md` where copied-identity repair is described.

1. EXTENSIBILITY: state that a definition feature with placed users keeps one authoring coordinator
   above its operations, name `Windows::Authoring` as the example, and say why the coordinator and
   not the operation owns host-dependent order. Keep the sentence that a lower layer never names a
   higher one; the coordinator sits at the feature's top, not in the definition layer.
2. CONTRACTS: the repair sentence names the coordinator as where the policy runs.
3. One stronger independent review with the architecture rubric; dual-Ruby `make ci`.
4. Native, current host: resize a used Type with two anchored Units on two Faces, Undo, Redo; create a
   Frame while a copied Unit is locked, observe the refusal, unlock, repeat, observe repair; save and
   reopen. Record host, head and RBZ hash.

Exit: both `make ci` runs pass; review has no open blocker; native receipt filed.

## Decisions and deviations

The coding agent decides the module name (`Authoring` is the default), whether `InstallSave` moves
under it or stays beside it, and test names.

Escalate to Ed only for a change to repair timing or trigger (D-02 in [DECISIONS](../DECISIONS.md)),
which this packet does not make.

No deviation from the accepted direction. The first draft's W-01 (an inventory stage) is done in this
document; the stages start with code.

## Verification profile

High assurance: record-only operation tests, coordinator tests, the source dependency check,
`make coverage`, dual-Ruby `make ci`, one stronger review, the W-03 native receipt. See
[ACCEPTANCE.md](ACCEPTANCE.md).
