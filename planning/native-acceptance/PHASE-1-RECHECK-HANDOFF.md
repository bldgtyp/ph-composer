# Native acceptance handoff: Phase 1 recheck after PR #10

DATE: 2026-09-30
STATUS: Complete 2026-09-30. Codex ran all ten; nine pass, R05 `unknown` (pending state). [Evidence](evidence/phase-1-recheck-2026-09-30.md)
OWNER: [acceptance register](../archive/phase-01-faces-and-zones/ACCEPTANCE.md) (A02, A04, A05, A11,
R01 to R06); ledger cases in [cases.json](cases.json); prior results in
[pr3-corrections-native.md](../archive/phase-01-faces-and-zones/evidence/pr3-corrections-native.md)
ISSUE: none (local tooling work)

You are rerunning ten SketchUp acceptance cases that the ledger marks `needs_recheck`. They last
passed on 2026-09-30 (R05 with one `unknown` assertion), before PR #10 (`badb481`) changed the
code they depend on: Zone reads now take the native Group name, Make Zone runs Suggest
classification by default, right-click selection actions replaced the Classify menu's palette items,
the Overview tab became **Zones / Faces**, and Colour-by draws fills without coloured outlines.
This run establishes whether each case still passes on `main`. Report what you observe, including
anything that differs from the expectations below. You do not record ledger results.

`uv run tools/hostkit/acceptance_ledger.py status` lists the ten as `needs_recheck`. Each case's
full requirement is its row in the acceptance register; this page gives the procedure.

## Rules

- Touch only SketchUp 2026 and a terminal at the repository root,
  `/Users/em/Dropbox/bldgtyp-00/00_PH_Tools/ph-composer`. Never capture the full screen. Capture the
  SketchUp window by its window id (`screencapture -x -o -l <id>`; find the id with
  `CGWindowListCopyWindowInfo`, owner `SketchUp`, the large document window), which works while other
  windows overlap it. The PH-Composer panel is a separate window of the same app.
- `launch` brings SketchUp to the front. Tell Ed before each launch so he is not typing: a keystroke
  meant for another app can edit the Model under test. On 2026-09-30 one erased a selected Zone.
- Native Undo and Redo only run with SketchUp frontmost and the viewport focused. Click empty sky
  before a shortcut; focus in the Outliner swallows Cmd+Z. Undo sent through the bridge or System
  Events while SketchUp is in the background is delivered late; never use it.
- Product writes go through `PhComposer::API` or the native UI. `eval` is for readback and the
  walkthroughs' named setup methods only.
- Run each command as its own bridge call and read its output before the next: deferred work runs
  on UI timers that cannot fire while an `eval` blocks.
- Do not edit tracked files, commit, push or record ledger results. Write only under
  `_private/host/p1r/` (gitignored).
- If a step does not behave as described, record `fail` or `unknown` with the verbatim output, and
  move to the next case. Do not retry into a pass. If a walkthrough method itself errors because the
  code changed under it, record `blocked` with the error and continue.

## 0. Preconditions and build

1. On `main` at `badb481` or later, `git status --short` shows at most this handoff file. Record
   `git rev-parse HEAD`.
2. Look at SketchUp's open windows. If a document not under `_private/host/` is open, or a title
   shows unsaved changes, stop and ask Ed. `launch` quits SketchUp.
3. Bridge wrapper (zsh does not word-split a variable holding a command):

   ```sh
   mkdir -p _private/host/p1r
   printf '#!/bin/sh\ncd /Users/em/Dropbox/bldgtyp-00/00_PH_Tools/ph-composer\nexec uv run tools/hostkit/host_bridge.py "$@"\n' > _private/host/p1r/b
   chmod +x _private/host/p1r/b
   B=_private/host/p1r/b
   ```

4. Build and install, then take one baseline per case:

   ```sh
   make ci                      # must pass; stop if not
   make bridge-install && make install
   shasum -a 256 dist/ph_composer.rbz | tee _private/host/p1r/rbz.sha256
   shasum -a 256 _private/host/blank-template.skp | tee _private/host/p1r/fixture.sha256
   for c in A02 A04 A05 A11 R01 R02 R03 R04 R05 R06; do
     uv run tools/hostkit/acceptance_ledger.py snapshot $c --output _private/host/p1r/$c-baseline.json
   done
   ```

5. **Suggest on Make off.** Every walkthrough below was written before Make Zone auto-classified
   its Faces, and several cases depend on unclassified Faces. After each `launch`, before any setup
   method, run this public settings action, and record its output:

   ```sh
   OFF='s = PhComposer::API.discover["sessions"].find { |x| x["active"] }; c = PhComposer::API.connect(session_id: s["id"]); cur = PhComposer::API.query(context: c, name: "ph_composer.zones.settings.get")["value"]; r = PhComposer::API.invoke(context: c, name: "ph_composer.zones.settings.update", params: { "values" => cur.merge("suggest_on_make" => false), "expected_values" => cur }, request: { "sequence" => 1, "expected_revision" => s["revision"] }); [r["status"], r["effect"]]'
   $B eval "$OFF"
   ```

   Expected `["completed", "committed"]`. The default-on path was accepted natively in PR #10.

Each block below starts with its own fresh process:

```sh
$B launch _private/host/p1r/<case>.skp --fresh-from _private/host/blank-template.skp
$B state          # record: SketchUp 26.1.188, Ruby 3.2.2, one feature PhComposer::Zones
$B eval "$OFF"
```

## 1. Bridge cases

### A02: Make Zone and occurrence identity (`a02.skp`)

```sh
$B eval 'load "/Users/em/Dropbox/bldgtyp-00/00_PH_Tools/ph-composer/tools/examples/authoring/walkthrough.rb"; AuthoringWalkthrough.setup'
$B eval 'AuthoringWalkthrough.run'
$B eval 'AuthoringWalkthrough.verify'
$B save
```

Then a fresh process on the saved file (no `--fresh-from`): `$B launch _private/host/p1r/a02.skp`,
load the script again, `AuthoringWalkthrough.verify`. Expected: two Zones, edited values and one
classified Face each, identical after reopen, with every Face record agreeing with its Zone stamp.
The walkthrough's `undo`/`redo` go through the bridge, which is not native Undo; skip them.

### A05: adjacency boundaries and reciprocal references (`a05.skp`)

```sh
$B eval 'load "/Users/em/Dropbox/bldgtyp-00/00_PH_Tools/ph-composer/tools/examples/authoring/adjacency_walkthrough.rb"; AdjacencyWalkthrough.setup'
$B eval 'AdjacencyWalkthrough.author_and_solve'
$B eval 'AdjacencyWalkthrough.stale_and_retire'
$B eval 'AdjacencyWalkthrough.restore_and_resolve'
$B eval 'AdjacencyWalkthrough.verify'
$B eval 'AdjacencyWalkthrough.tolerance_report'
```

Expected: the shared wall pairs `current`, reads `stale` after the move, retires, and re-solves
`current`; the tolerance report holds the 0.0254 mm and 0.1 degree boundaries.

### A11: normal construction refusal (`a11.skp`)

Do not reuse the A05 Model: launch `a11.skp` fresh, run `$B eval "$OFF"`, then
`AdjacencyWalkthrough.setup` and `author_and_solve` as above so two Zones are fully classified.

```sh
$B eval 's = PhComposer::API.discover["sessions"].find { |x| x["active"] }; $p1r = PhComposer::API.connect(session_id: s["id"], capabilities: %w[read export]); PhComposer::API.export_preflight(context: $p1r)["value"]["findings"].map { |f| f.slice("code", "blocks_export") }.uniq'
mkdir -p _private/host/p1r/a11-export
$B eval 'r = PhComposer::API.start_export(context: $p1r, destination: "/Users/em/Dropbox/bldgtyp-00/00_PH_Tools/ph-composer/_private/host/p1r/a11-export/a11.hbjson"); $p1r_task = r.dig("value", "task_id"); r.slice("status", "code")'
$B eval 's = PhComposer::API.export_status(context: $p1r, task_id: $p1r_task)["value"]; { "stage" => s["stage"], "outcome" => s["outcome"] && s["outcome"].slice("status", "code") }'
ls -la _private/host/p1r/a11-export
```

Repeat the status call until `stage` is `finished`. Expected: preflight blocks on
`construction.missing` for every Face; the task ends refused `export.blocked`; the folder is empty.

### R02: explicit Face path through a nested Zone (`r02.skp`)

```sh
$B eval 'load "/Users/em/Dropbox/bldgtyp-00/00_PH_Tools/ph-composer/tools/examples/authoring/corrections_walkthrough.rb"; CorrectionsWalkthrough.r02_setup'
$B eval 'CorrectionsWalkthrough.r02_paste'
$B eval 'CorrectionsWalkthrough.r02_check'
```

Expected: Zone reads `found` and `wrong_hierarchy`; Classify and Reverse on the outer-Zone path
through the inner Zone refuse `target.wrong_hierarchy`, effect `none`, revision unchanged; Classify
on the ordinary nested Group completes and commits.

### R06: panel-closed API client (`r06.skp`)

Follow [R06-RERUN-HANDOFF.md](R06-RERUN-HANDOFF.md) steps 2 to 7 with these changes: use
`_private/host/p1r/` paths and `$B`, run `$B eval "$OFF"` right after `launch`, skip its step 0 and
step 1 (done above), and never open the panel. Its expectations stand, including the export ending
`failed` `face.unclassified` with nothing written.

## 2. R04: partial AttachedZone cut, with native Undo and Redo (`r04.skp`)

```sh
$B eval 'load "/Users/em/Dropbox/bldgtyp-00/00_PH_Tools/ph-composer/tools/examples/authoring/corrections_walkthrough.rb"; CorrectionsWalkthrough.r04_setup'
$B eval 'CorrectionsWalkthrough.r04_solve'
```

Expected: solve completed/committed; 14 Faces; two Surface pieces `current` without
`attached_zone_id`; one remainder of 6 m² keeping AttachedZone; repeat solve completed with effect
`none`.

Native: with SketchUp frontmost, read the Edit menu's Undo label (expected "Undo Solve Zone
Adjacency"), choose it, then `$B eval 'CorrectionsWalkthrough.r04_verify'` (12 Faces, no Surface,
the 12 m² AttachedZone wall). Edit > Redo, then `r04_verify` again (back to the solved state).

Then the both-walls variant: `$B eval 'CorrectionsWalkthrough.r04_setup(true)'`,
`r04_solve` (two `current` Surface pieces without the reference, both 6 m² remainders AttachedZone),
`$B save`, and a fresh `launch` of `r04.skp` with the script reloaded: `r04_verify` identical.

## 3. Native UI cases on one handoff fixture (`r-native.skp`)

```sh
$B eval 'load "/Users/em/Dropbox/bldgtyp-00/00_PH_Tools/ph-composer/tools/examples/authoring/corrections_walkthrough.rb"; CorrectionsWalkthrough.handoff_setup'
$B eval 'CorrectionsWalkthrough.handoff_paste'
$B eval 'CorrectionsWalkthrough.handoff_finish'
$B eval 'CorrectionsWalkthrough.state'
```

Expected: three Zones, all `found`; `shared_children` 2; the Garage delete committed, so the next
native Undo is "Undo Delete Attached Zone". Do not `load` the script again in this process; R03's
helpers remember its Zone. `$B eval 'CorrectionsWalkthrough.log.map(&:first)'` shows what each native
Undo or Redo left.

**R01: shared child Group refusal.** `handoff_setup`/`handoff_paste` made the shared copy through
native menu actions. Run `$B eval 'CorrectionsWalkthrough.r01_check'`. Expected: two child Groups
sharing storage, both placements listed, Classify and Reverse preview and invoke all refused
`target.shared_definition`, effect `none`, message naming Make Unique, `unchanged` true. Then, in
the viewport, open the R01 Zone and then one child Group, select its square Face and right-click.
Expected: no "Classify faces" submenu, because a Face in shared storage is not a writable selection;
readback `CorrectionsWalkthrough.state` shows no record written. Record the control route honestly.

**R03: Attached-zone delete with orphaned Faces.** Follow
[NATIVE-HANDOFF.md](../archive/phase-01-faces-and-zones-refactor/NATIVE-HANDOFF.md), section R03,
steps 1 to 3, with one correction: the cleanup at the end of step 3 needs three Undos (Paste, the
Zone close, Cut), not two.

**R05: Zone details draft with the native keyboard.** Follow NATIVE-HANDOFF.md, section R05, with
the tab now named **Zones / Faces**. Additionally, while the draft is open, click the tab's gear
(settings) and the "Solve adjacencies" button, and record exactly what each does: whether it is
refused with the "Save or cancel the Zone details first." notice, and whether the draft survives.
These two controls are new since the case was written; there is no settled expectation. Try to observe Save and Cancel staying visible while
a Save request is pending; if it completes too fast to see, record that assertion `unknown`.

**A04: Classify tool drag.** Follow NATIVE-HANDOFF.md, section A04, steps 1 to 3, with these
changes: start the tool from the panel's Classify palette (Wall); the native menu no longer has
palette items. After Escape, confirm the tool stopped with
`$B eval 'PhComposer::Zones::Faces.classify_tool(PhComposer::Sessions.for(Sketchup.active_model)).active?'`
(expected `false`). Also confirm the pointer shows the Classify cursor while the tool is active. Skip
its step 4; R01 above covers the shared-child refusal.

## Report

One JSON file per case at `_private/host/p1r/<CASE>-codex.json`:

```json
{"case": "A02", "outcome": "pass|fail|unknown|blocked",
 "control": "bridge|native|human|combined",
 "host": {"sketchup": "", "ruby": "", "session_id": "", "fixture_id": "_private/host/p1r/<file> fresh from blank-template.skp",
          "fixture_sha256": "", "rbz_sha256": "", "composition": "normal", "commit": ""},
 "settings": "the $OFF output",
 "assertions": [{"observation": "one sentence of what you saw", "status": "pass|fail|unknown|blocked"}],
 "readbacks": ["every bridge output you relied on, verbatim, in order"],
 "screenshots": ["paths"]}
```

Leave SketchUp running on the last fixture; do not save or quit it. Your final message: only a
compact JSON array of `{case, outcome, one_line}`. The requesting session checks the readbacks,
writes the synthetic evidence summary under `evidence/` and records each ledger result.
