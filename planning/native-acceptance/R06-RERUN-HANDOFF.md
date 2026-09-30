# Native acceptance handoff: R06 rerun on main

DATE: 2026-09-30
STATUS: Complete 2026-09-30; pass. Codex ran steps 0 to 2 and stopped at native check A (no
screenshot); the requesting session finished on the same process. [Evidence](evidence/r06-rerun-2026-09-30.md)
OWNER: [acceptance register, R06](../archive/phase-one/ACCEPTANCE.md#pr-3-foundation-correction-cases);
ledger case `R06` in [cases.json](cases.json)
ISSUE: none (local tooling work)

You are rerunning one SketchUp acceptance case, R06: a client that knows only the public interface
drives a Model with the PH-Composer panel never opened. It last passed on 2026-09-30 at `0f77fff`.
PR #7 (`281ee8e`) changed only a status line in `docs/API_QUICKSTART.md` and comment paths under
`src/ph_composer/features/zones/`, which moved the ledger's source fingerprint, so the ledger reads
`needs_recheck`. No behavior changed; this run confirms that on the installed build. Report what you
observe, including anything that differs from the expectations below.

## Rules

- Touch only SketchUp 2026 and a terminal at the repository root,
  `/Users/em/Dropbox/bldgtyp-00/00_PH_Tools/ph-composer`. Never capture the full screen: bound every
  screenshot to the SketchUp document window.
- **Never open the PH-Composer panel.** Do not use Extensions > PH-Composer > Open PH-Composer, the
  toolbar, or any panel route. The whole case depends on it staying closed.
- Product writes go through `PhComposer::API` only, as below. `eval` is used for the walkthrough's
  geometry setup, the API calls themselves and readback.
- Run each numbered step as its own bridge call and read its output before the next. Deferred work
  runs on UI timers that cannot fire while an `eval` blocks.
- Do not edit tracked repository files, commit, push, or record ledger results. Write only under
  `_private/host/r06/` (gitignored).
- If a step does not behave as described, stop, record `fail` or `unknown` with the verbatim output,
  and report. Do not retry into a pass.

## 0. Preconditions

1. On `main`, `git status --short` shows at most this handoff file, and
   `git diff --stat 281ee8e HEAD -- src docs tools tests` is empty (the build under test is
   `281ee8e`'s code). If not, stop and report.
2. SketchUp 2026 may already be running. `launch` below quits it, and unsaved work in an open
   document is lost. Look at SketchUp's open windows (Window menu). If any document is open that is
   not under `_private/host/`, or any title shows unsaved changes, stop and ask Ed. Do not quit it.
3. Create the bridge wrapper (zsh does not word-split a variable holding a command):

   ```sh
   mkdir -p _private/host/r06
   printf '#!/bin/sh\ncd /Users/em/Dropbox/bldgtyp-00/00_PH_Tools/ph-composer\nexec uv run tools/hostkit/host_bridge.py "$@"\n' > _private/host/r06/b
   chmod +x _private/host/r06/b
   B=_private/host/r06/b
   ```

## 1. Build, install and baseline

```sh
make ci                      # must pass; stop if not
make rbz && make rbz-check
make bridge-install
make install
shasum -a 256 dist/ph_composer.rbz | tee _private/host/r06/rbz.sha256
uv run tools/hostkit/acceptance_ledger.py snapshot R06 --output _private/host/r06/R06-baseline.json
```

## 2. Fresh process and fixture

```sh
$B launch _private/host/r06/r06-rerun.skp --fresh-from _private/host/blank-template.skp
$B state
shasum -a 256 _private/host/blank-template.skp
```

Expect `state` to show SketchUp 26.1.188, Ruby 3.2.2, the extension loaded with one feature
(`PhComposer::Zones`), and the Model `r06-rerun.skp`. Save the `state` output verbatim.

**Native check A (computer use).** Take one screenshot bounded to the SketchUp window, saved to
`_private/host/r06/A-panel-closed.png`. Expected: no PH-Composer dialog anywhere on screen. Also
open the Window menu and confirm no PH-Composer window is listed, then press Escape.

## 3. Load the walkthrough and read the session

```sh
$B eval 'load "/Users/em/Dropbox/bldgtyp-00/00_PH_Tools/ph-composer/tools/examples/authoring/corrections_walkthrough.rb"; true'
$B eval 'PhComposer::API.discover["sessions"].map { |s| s.slice("id", "active") }'
```

Record the active session id.

## 4. Quickstart steps 1 to 6

`CorrectionsWalkthrough.r06_run` draws one 4 m box Group (development setup), selects it, and then
runs `docs/API_QUICKSTART.md` steps 1 to 6 through `PhComposer::API` as written.

```sh
$B eval 'CorrectionsWalkthrough.r06_run'
```

Expected, verbatim in the returned hash:

- `made`, `classified`, `updated`: each `["completed", "committed"]`
- `classified_reference`: present, naming the classified Face
- `read_back_matches`: `true` (the Zone read back carries Level `L1`)
- `stale`: `["refused", "revision.stale", "none"]`
- `retry_same_outcome`: `true` (same sequence returned the identical first outcome)

**Native check B (computer use).** With SketchUp frontmost, open the Edit menu and read the Undo
item's label without choosing it; expected "Undo Edit Zone", the last committed write. Press Escape to close the menu. Record the exact label. Do not undo.

## 5. Quickstart step 7: paged read

```sh
$B eval '$r06 = PhComposer::API.connect(session_id: PhComposer::API.discover["sessions"].find { |s| s["active"] }["id"], capabilities: %w[read export]); p1 = PhComposer::API.query(context: $r06, name: "ph_composer.zones.faces.list", params: { "fields" => ["face_type", "boundary_condition"], "limit" => 4 }); $r06_cursor = p1["value"]["next_cursor"]; { "rows" => p1["value"]["faces"].length, "keys" => p1["value"]["faces"].map(&:keys).uniq, "total" => p1["value"]["total"], "next" => !$r06_cursor.nil? }'
$B eval 'p2 = PhComposer::API.query(context: $r06, name: "ph_composer.zones.faces.list", params: { "fields" => ["face_type", "boundary_condition"], "limit" => 4, "cursor" => $r06_cursor }); { "rows" => p2["value"]["faces"].length, "total" => p2["value"]["total"], "next_cursor" => p2["value"]["next_cursor"] }'
$B eval 'bad = PhComposer::API.query(context: $r06, name: "ph_composer.zones.faces.list", params: { "fields" => ["face_type"], "limit" => 4, "cursor" => $r06_cursor, "ids" => ["fac_none"] }); bad.slice("status", "code", "effect")'
```

Expected: page one 4 rows, each with only `reference` and `values` keys, `total` 6, a next cursor;
page two 2 rows, `total` 6, `next_cursor` null; the same cursor under another filter refused
`params.invalid` with effect `none`.

## 6. Quickstart step 7: export task

The normal build has no authored Assemblies and five Faces are unclassified, so the export must end
refused or failed without writing anything.

```sh
mkdir -p _private/host/r06/export
$B eval 'PhComposer::API.export_preflight(context: $r06)["value"]["findings"].map { |f| f.slice("code", "blocks_export") }.uniq'
$B eval 'r = PhComposer::API.start_export(context: $r06, destination: "/Users/em/Dropbox/bldgtyp-00/00_PH_Tools/ph-composer/_private/host/r06/export/r06.hbjson"); $r06_task = r.dig("value", "task_id"); r.slice("status", "code")'
$B eval 's = PhComposer::API.export_status(context: $r06, task_id: $r06_task)["value"]; { "stage" => s["stage"], "outcome" => s["outcome"] && s["outcome"].slice("status", "code"), "keys" => s.keys }'
```

Repeat the status call, one call at a time, until `stage` is `finished`. Then:

```sh
$B eval 'l = PhComposer::API.latest_export(context: $r06)["value"]; l && l["task_id"] == $r06_task'
ls -la _private/host/r06/export
```

Expected: preflight lists blocking findings; `start_export` queued a task; polling reaches
`finished` with an outcome whose status is `failed` or `refused` and whose code names the blocker
(last run: `failed`, `face.unclassified`); no status carries canonical HBJSON bytes (`keys` has no
`hbjson` or `canonical_model`); `latest_export` names the task; the export folder is empty.

**Native check C (computer use).** One SketchUp-window-bounded screenshot,
`_private/host/r06/C-after.png`: the Model shows the one box Zone, still no PH-Composer dialog.

## 7. Leave the host

```sh
$B state
```

Leave SketchUp running on `r06-rerun.skp`; do not save or quit.

## Report

Write `_private/host/r06/R06-codex.json`:

```json
{"case": "R06", "outcome": "pass|fail|unknown",
 "host": {"sketchup": "", "ruby": "", "session_id": "", "fixture_id": "_private/host/r06/r06-rerun.skp fresh from blank-template.skp",
          "fixture_sha256": "", "rbz_sha256": "", "composition": "normal", "commit": "<git rev-parse HEAD>"},
 "assertions": [{"observation": "one sentence of what you saw", "status": "pass|fail|unknown"}],
 "native": {"panel_never_opened": true, "undo_label": "", "screenshots": ["paths"]},
 "readbacks": ["every bridge output you relied on, verbatim, in order"]}
```

Use one assertion per expectation block: steps 1 to 6; paged read; cursor refusal; export
lifecycle; nothing written; panel closed throughout. Your final message: only a compact JSON
object `{case, outcome, one_line}`. The requesting session checks the readbacks, writes the
synthetic evidence summary and records the ledger result.
