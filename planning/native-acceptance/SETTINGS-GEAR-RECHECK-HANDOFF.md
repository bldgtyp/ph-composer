# Native acceptance handoff: settings gear guard (R05, A04, A11)

DATE: 2026-09-30
STATUS: Ready for Codex. Not yet run.
OWNER: [acceptance register](../archive/phase-01-faces-and-zones/ACCEPTANCE.md); ledger cases in
[cases.json](cases.json); procedure base [PHASE-1-RECHECK-HANDOFF.md](PHASE-1-RECHECK-HANDOFF.md)
ISSUE: none (local tooling work)

The Zones / Faces tab's settings gear now refuses to open while a Zone details draft is open, with
the same "Save or cancel the Zone details first." notice as Solve adjacencies, and focus returns to
Save. The change touched `html/sections/zone_settings.js`, `html/sections/overview.js` and the
runtime manifest, so the ledger marks R05, A04 and A11 `needs_recheck`. Rerun those three on the
branch head. Everything else from the Phase 1 recheck stands.

## Rules and preconditions

Follow [PHASE-1-RECHECK-HANDOFF.md](PHASE-1-RECHECK-HANDOFF.md), "Rules" and section 0, with these
changes:

- The build under test is the head of branch `fix/settings-gear-draft-guard` (or `main` once that PR
  merges). Record `git rev-parse HEAD`; `git status --short` shows at most this handoff file.
- Write under `_private/host/gear/` instead of `p1r/`, including the bridge wrapper `B`.
- Take baselines for `A04 A11 R05` only.
- Run `$B eval "$OFF"` after every `launch`, as before.

## A11 (`a11.skp`)

Exactly as the Phase 1 handoff's A11 block, with paths under `_private/host/gear/`.

## R05 and A04 (`r-native.skp`)

Build the native fixture as the Phase 1 handoff's section 3 does (`handoff_setup`, `handoff_paste`,
`handoff_finish`; `handoff_paste` needs SketchUp frontmost to deliver the paste).

**R05.** Follow NATIVE-HANDOFF.md's R05 section, as the Phase 1 handoff directs, on the
**Zones / Faces** tab, plus:

1. With the Zone 1 name draft open, click the settings gear. Expected: the settings bubble does not
   open; the yellow notice "Save or cancel the Zone details first." shows; the draft and its Save
   and Cancel stay; focus lands on Save.
2. After Cancel, click the gear again. Expected: the settings bubble opens. Close it with Escape
   without changing anything.
3. The "Solve adjacencies" button during a draft: refused with the same notice, as before.
4. The pending-request visibility assertion may again finish too fast to capture; record `unknown`
   if so. Ed has accepted the offline coverage for that one assertion.

**A04.** The Phase 1 handoff's A04 block, steps 1 to 3 (panel palette Wall, one native drag across
two walls of Zone 3, Escape, `active?` false). The cursor is not part of A04; skip it.

## Report

Same format as the Phase 1 handoff, one file per case at `_private/host/gear/<CASE>-codex.json`.
Final message: a compact JSON array of `{case, outcome, one_line}`. The requesting session checks
the readbacks, writes the evidence summary and records the ledger results.
