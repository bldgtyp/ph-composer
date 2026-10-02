# P2-01: contracts and shared groundwork

DATE: 2026-09-30
STATUS: Implemented on branch; named acceptance passes, including affected held-Classify.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/14

## Entry and scope

Requires the entry gates in [STATUS](../STATUS.md). D2-1 is answered, as revised on 2026-10-01. Owns the confirmation of
[CONTRACTS](../CONTRACTS.md) against the merged code and the shared pieces two or more Phase 2
features need before either can start. No building record, no feature folder and no new tab.

Paths are relative to `src/ph_composer/`. Predecessor paths are relative to
`../ph-navigator-sketchup/src/ph_navigator_sketchup/` at `f358ebf`.

## Read first

`context/CONTRACTS.md`, `context/EXTENSIBILITY.md`, the architecture review skill, then
[DECISIONS](../DECISIONS.md) part 1 and CONTRACTS section 7.

## Steps

1. **Answer CONTRACTS section 7 from code.** For each of the six items, write a focused test
   against `tests/support/test_feature.rb` that demonstrates the answer:
   - a catalog kind with a reference nested in an array of objects, and whether the engine's
     incoming-reference scan refuses deleting the target;
   - a query handler in one feature reading a registered query of a feature it requires, in the
     same read phase, and the refusal when it does not require that feature;
   - an entity reference target in feature A naming a catalog kind in feature B, where A
     requires B, registering cleanly, and the reverse `requires` refusing as `registration.cycle`;
   - a reference retargeter (G10): feature A registers one for B's kind, B's delete handler
     calls `request.retarget_references`, the steps join B's proposal, the returned rows satisfy
     `propose_delete` as its `reference_plan`, a refusing retargeter refuses the whole proposal,
     and B's code names nothing of A;
   - a nested `layers` shaped field validating inside the registered JSON Schema subset.
2. **Close each gap with the smallest generic addition.** Where a test shows the foundation
   cannot do it, add the capability to `core/` or `shell/` so that it names no feature, with its
   own tests and a `registration.*` or foundation code if a new refusal exists. Record the rule
   in `context/CONTRACTS.md`. Do not work around a gap inside a feature folder.
3. **Correct CONTRACTS.** Edit the packet's CONTRACTS so every table matches what the tests
   proved. Remove the "confirm in P2-01" notes.
4. **Subtabs.** Add `html/subtabs.js`: one shared nav for peer subtabs with one work surface at a
   time, keyboard reachable, remembering the active subtab per session in page state. The
   predecessor builds the same nav twice, in `html/sections/library.js` and
   `html/window_editor.js`; extract the common behavior, do not copy either.
5. **Port `record_edits.js`** (`html/record_edits.js`, 270 lines) and its test
   (`tests/record_edits_units_test.js`). It is configured with an action name and a field list,
   sends through `request.js`, and carries `expected_values`. Adapt it to `action.invoke` and the
   outcome envelope. A refused edit keeps the draft and shows the refusal.
6. **Port `inventory_grid.js`** (`html/inventory_grid.js`, 202 lines) and its test
   (`tests/inventory_grid_test.js`): fill down, fill right, range selection, the keyboard hint.
7. **Regenerate.** `make panel-manifest`, then refresh the vendor manifest. Add preview fixtures
   to `tools/ui-preview/` for the two ports.
8. **Fold into context.** Correct `context/TECH_STACK.md`, "A definition record, end to end", so
   it describes `RecordKind`, `Field`, `Reference`, proposals and `expected_values` as they exist,
   and names the Attached zone kind as the worked example. State the cross-feature read rule and the
   retargeter contract in `context/EXTENSIBILITY.md` and `context/CONTRACTS.md` once step 1 has
   settled them.
9. **Review.** One stronger independent pass with the architecture rubric over the foundation
   additions. Record its outcome in the packet STATUS.

## Tests (write first)

1. The six CONTRACTS section 7 tests above, each asserting the behavior and its refusal code.
2. `record_edits`: a committed cell sends one action with `expected_values`; a stale refusal keeps
   the draft; a unit switch does not reinterpret typed text; a disposed field never commits.
3. `inventory_grid`: fill down and fill right over a range send one action per target or one
   batch, whichever the port keeps, and never write a read-only cell.
4. `subtabs`: switching shows one surface, hides the rest and moves no focused input.
5. `tests/panel_messages_test.rb` still passes: no new message type was added.

## Host gate

Install the build, reopen the panel in a fresh process, and confirm Zones / Faces and Export
behave as before. Run the ledger screen for the changed `html/`, `core/` and `shell/` paths and
repeat the Phase 1 cases it reports.

## Out of scope

Enabling the Assemblies, Window Types or Library tabs: each feature stage enables its own tab
when its first section lands. The settings primitive (P2-10), the library registrations (P2-07),
the pick point (P2-13) and the Zones cutting-instance rules (P2-12).

## Done when

- The six questions have a test and an answer, and CONTRACTS carries no open "confirm" note.
- `make ci` passes on both Rubies with the manifests fresh.
- E01 has evidence in `evidence/p2-01-groundwork.md` and the stage row reads
  `Implemented on branch`.

Current consolidation and provenance: [P2-17](../evidence/p2-17-acceptance.md#register-consolidation-at-f4f6576).
