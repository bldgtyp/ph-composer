# Plan: Ruby contributor readability

DATE: 2026-10-17
STATUS: Complete
AUTHOR: Ed May, BLDGTYP
ISSUE: [#198](https://github.com/bldgtyp/ph-composer/issues/198)
BASELINE: `2f8becb4`

## Authorization

Ed authorized the repository-wide refactor on 2026-10-17: review and refactor the repository's Ruby
for contributor readability, delivered sequentially as small coherent PRs through the PR loop, with a
Codex review per PR and merge delegated once review and CI pass. This supersedes the "no refactor
authorized" language in [review-2026-10-17.md](review-2026-10-17.md). Product behaviour changes are
not authorized; one found necessary becomes a separate proposal.

## Scope

Every file listed in [INVENTORY.md](INVENTORY.md): tracked Ruby under `src/`, `tests/` and `tools/`,
excluding `src/ph_composer/vendor/`, `vendor/`, `tests/fixtures/` and `_private/`. Retained evidence
probes under `planning/` are records, not code, and stay out, as `.rubocop.yml` already rules.
`features/windows/units/generated_geometry.rb` is authored source that builds geometry, not a
generated file, and is in scope.

## What every stage preserves

Public signatures and registered declarations; stored, returned and panel JSON shapes; record
identities, references and occurrence paths; SI units; metadata and unavailable-extension payloads;
refusal codes, messages and the `Nothing was written.` sentence; batch atomicity and transaction
ownership; observer, Undo/Redo, active-edit-path and drawing lifecycle. A golden diff, a changed
refusal or a test edited to follow new behaviour stops the stage. A test may change only where it
asserted an internal shape the stage replaces, and the PR names each such edit.

Ruby 2.7 stays the floor: `Struct.new(..., keyword_init: true)` is available; `Data`, pattern
matching, endless methods and `Hash#except` are not.

## Stage model

Each inventory group ends in exactly one of three outcomes, recorded in [STATUS.md](STATUS.md):

- **Refactored**: one branch `refactor/ruby-readability-rNN`, one PR, one Codex review, merged on
  green CI. A stage may cross groups where an internal contract needs producer and consumers changed
  together; the ledger records the crossing on both rows.
- **Reviewed, no change needed**: the group was traced and is already clear, or its remaining
  findings are optional polish below the bar. The row records what was read and why it stays. These
  rows ride in the next refactor PR; they get no PR of their own.
- **Host gate pending**: refactored and merged offline, with native acceptance owed because the
  boundary touches Undo/Redo, observers, edit paths, shared storage or drawing. Host checks are
  batched across stages, following `.agents/skills/ph-composer-native-acceptance/SKILL.md`, so Ed sees
  one approval per batch; the cases owed come from `tools/hostkit/acceptance_ledger.py status
  --changed <path>` for each changed file. Every owed batch runs before the program closes.

A group may also be split into two stages when its trace shows two independent responsibilities.

## Delivery order and reasons

Size and complexity rank inspection; the order weighs what a contributor must learn, how far a change
reaches, and the risk of the boundary.

**Wave A, evidenced and contained.** The investigation already traced these, so the loop is
calibrated on known findings before it meets unread code.

1. R01 Spaces authoring: positional edit plans cross one module boundary into HeightFromSolid; two
   files, feature-local, well tested.
2. R04 Windows export assessment: one mixed method; offline-verifiable through export outputs.
3. R02 Face classification, with the R10 retirement producer: the positional retirement value crosses
   Faces and Adjacency, so producer and consumers move together.
4. R05 Registration validation: contributor-facing contracts and goldens; stronger reviewer.
5. R03 Colour-by drawing: buffer ownership and failure cleanup; carries a drawing-lifecycle host gate.

**Wave B, features, leaf responsibilities first.** Features depend on core, never the reverse, so a
feature refactor cannot ripple into another feature. Within each feature the most-read and most
branched groups go first: Spaces R06, R07, R08; Zones R09, R10, R11, R12, R13, R14; Assemblies R15;
Windows R16, R17, R18, R19, R20. R18 (36 files, the most threshold reports) may split by step family.

**Wave C, foundations.** Everything depends on these, so they go after the features have shown which
shapes their consumers actually rely on: R29 export, R30 library, R28 approved locations, R27 panel,
R31 runtime and composition root, R23 values, R24 geometry, R22 operations, R21 records, R25 session,
R26 shell dispatch and API. R26 is last because Phase 3a1 (agent access) plans to reshape the API
transport; its stage rechecks that packet's state first and avoids churn the plan will replace.

**Wave D, harness and tools.** R32 test harness and SketchUp stub, R33 host bridge, R34 examples,
R35 development tools, R36 spikes. Spikes are retained evidence that may cite planning; the expected
outcome there is reviewed, retained, with only defects fixed.

## Per-stage loop

1. Switch to an up-to-date `main`, clean merged branches, branch `refactor/ruby-readability-rNN`.
2. Trace the group: entrypoints, callers, data shapes, one normal and one refusal path. List
   findings with source, contributor task obstructed, smallest adequate change and affected checks
   before editing. Record "no change needed" where the code is already clear.
3. Refactor that responsibility and its necessary consumers only. Focused tests while editing.
4. Ledger: the group's row in [STATUS.md](STATUS.md), plus any rows reviewed without change since the
   last PR.
5. Gate: `LANG=en_US.UTF-8 make ci && git commit -s ... && git push`. Check the branch and stage files
   by name immediately before committing; other sessions share the checkout.
6. PR `Part of #198`; the final stage says `Closes #198`. Codex review through
   `~/.claude/scripts/codex_pr_review.py --post` with a context file naming this plan's section for the
   stage, both review skills and the coding-standards section. Reviewer `gpt-6.1-sol`; `gpt-6-astra`
   for R05, R21, R25 and R26, which carry public contracts, references and session lifecycle.
7. Verify each finding against the code, fix the real ones, re-run the gate, answer every thread.
8. Enable auto-merge (`gh pr merge N --auto --squash`) once threads are answered and the reviewed head
   is pushed; main requires both CI jobs. The next stage starts after the merge.

`make coverage` runs for a stage that adds or removes tested branches; `make ci` does not include it.
