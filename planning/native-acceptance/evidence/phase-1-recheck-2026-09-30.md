# Phase 1 recheck after PR #10

Observed 2026-09-30 local time (2026-10-01 UTC) by Codex from
[PHASE-1-RECHECK-HANDOFF.md](../PHASE-1-RECHECK-HANDOFF.md), on SketchUp 26.1.188, Ruby 3.2.2,
macOS, normal installed composition from `main` at `badb481` (RBZ `5d7d9a43…c948b`; the installed
files matched the built RBZ). Every fixture was a fresh copy of `blank-template.skp`
(`2ae1418d…21063`) with Suggest on Make switched off through the public settings action, because
the walkthroughs predate it. Raw readbacks and captures remain in `_private/host/p1r/`.

| Case | Outcome | Observed |
| --- | --- | --- |
| A02 | pass | Two Zones made, one edited, one Face classified in each; identical after save and a fresh reopen; a direct read of every Zone, Face record and stamp agreed |
| A04 | pass | The panel palette's Wall started the Classify tool; one native drag across two walls classified 2 Faces in one step; Escape stopped the tool (`active?` false) |
| A05 | pass | Shared wall paired `current`, read `stale` after a move, retired and re-solved `current`; 0.0254 mm and 0.1° matched, 0.0255 mm and 0.101° did not; reciprocal references exact |
| A11 | pass | Normal-build preflight blocked on `construction.missing`; the export finished refused `export.blocked`; nothing written |
| R01 | pass | Both placements of the shared child listed with one Face id (48922); Classify and Reverse preview and invoke refused `target.shared_definition`, effect `none`, Make Unique named, records and revision unchanged |
| R02 | pass | Nested Zone read `wrong_hierarchy`; crossing Classify and Reverse refused `target.wrong_hierarchy`; the ordinary nested Group classified |
| R03 | pass | Native Undo and Redo of the Attached zone delete; a Face cut to the root made both delete modes refuse `reference.in_use`, naming it; three native Undos restored it |
| R04 | pass | Partial AttachedZone cut: two `current` Surface pieces without the reference, 6 m² remainders kept; native Undo and Redo exact; both-wall variant identical after reopen |
| R05 | unknown | Draft refusals, focus on Save, Cancel and Save all observed natively; Save finished before the pending state could be captured |
| R06 | pass | Panel-closed quickstart, paged read, cursor refusal and the export task ending `failed` `face.unclassified` with nothing written; the panel never opened |

## Corrections made while recording

- **R01.** Codex recorded `fail` because the walkthrough's `shared_storage` probe returned false.
  The probe compared the Ruby `object_id` of each Group's `entities`, and SketchUp returns a fresh
  wrapper on every call: on the same host, two placements of one definition (2 instances, the same
  Face id) compare unequal that way. The Face id evidence and the product's own refusals both show
  shared storage. `corrections_walkthrough.rb` now compares definitions; re-run on a shared fixture
  it reports true. The assertion is recorded from the Face id readback.
- **A02.** The walkthrough's `stamps_agree?` found Zones by a name prefix that Make Zone replaces,
  so it checked nothing and returned true. Codex replaced it with a direct dictionary read, which is
  the recorded evidence. `walkthrough.rb` now finds Zones by record; it returns false for a
  deliberately wrong stamp and true once restored.
- **Assertions outside the register.** The handoff added two checks no case requires: the Classify
  cursor under A04 (Codex's controller could not show the real pointer; C1 owns it, confirmed by Ed
  on 2026-09-30) and a right-click on a shared Face under R01 (not attempted). Neither is recorded
  as a case assertion.

## Observations for follow-up

- With a Zone details draft open, the tab's settings gear opens its bubble rather than refusing.
  The draft survived and no setting was changed. Whether a settings change during a draft should be
  refused, as Solve adjacencies is, is undecided.
- R05's pending-state visibility stays `unknown`, as in the previous run, where Ed accepted the
  offline coverage for that one assertion.
