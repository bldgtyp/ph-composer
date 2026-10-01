# Native acceptance handoff: Phase 1 recheck for PR #11

DATE: 2026-09-30
STATUS: Ready for Codex. Not yet run.
OWNER: [acceptance register](../archive/phase-01-faces-and-zones/ACCEPTANCE.md); ledger cases in
[cases.json](cases.json); procedure base [PHASE-1-RECHECK-HANDOFF.md](PHASE-1-RECHECK-HANDOFF.md)
ISSUE: none (local tooling work)

PR #11 changes two things. The Zones / Faces settings gear now refuses to open while a Zone
details draft is open, with the same "Save or cancel the Zone details first." notice as Solve
adjacencies, and focus returns to Save. And comments across the source and tests no longer cite
planning identifiers; that is comment-only, but it changes shipped files, so the ledger again marks
all ten Phase 1 cases `needs_recheck`: A02, A04, A05, A11 and R01 to R06.

Run [PHASE-1-RECHECK-HANDOFF.md](PHASE-1-RECHECK-HANDOFF.md) in full, with the changes below.
Its last run passed on 2026-09-30; expect the same results.

## Changes to the base procedure

- The build under test is the head of branch `fix/settings-gear-draft-guard`. Record
  `git rev-parse HEAD`; `git status --short` is clean.
- Write under `_private/host/pr11/` instead of `p1r/`, including the bridge wrapper `B`.
- Take baselines for all ten cases, as in the base section 0.
- The walkthrough probes fixed after the last run now report correctly: `r01_check` reports
  `shared_storage: true` for the shared child, and `AuthoringWalkthrough.verify`'s `stamps_agree`
  checks every Zone. Record them as observed.
- `handoff_paste` delivers a native Paste In Place, which needs SketchUp frontmost.

## R05 additions

With the Zone 1 name draft open, on the **Zones / Faces** tab:

1. Click the settings gear. Expected: the settings bubble does not open; the yellow notice "Save or
   cancel the Zone details first." shows; the draft and its Save and Cancel stay; focus lands on
   Save.
2. Click "Solve adjacencies". Expected: refused with the same notice, as before.
3. After Cancel, click the gear again. Expected: the bubble opens. Close it with Escape without
   changing anything.
4. The pending-request visibility assertion may again finish too fast to capture; record `unknown`
   if so. Ed has accepted the offline coverage for that one assertion.

## Report

Same format as the base handoff, one file per case at `_private/host/pr11/<CASE>-codex.json`.
Final message: a compact JSON array of `{case, outcome, one_line}`. The requesting session checks
the readbacks, writes the evidence summary and records the ledger results.
