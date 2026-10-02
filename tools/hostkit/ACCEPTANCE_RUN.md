# Acceptance run receipts

Development-only tooling. The bridge and native controls obtain observations; this harness freezes
and checks them. It neither controls SketchUp nor awards acceptance. Keep recipes, baselines,
observations, gate logs and raw evidence in gitignored `_private/host/<run>/`.

## Preflight and immutable baseline

Before asking for a human gesture, activate the actual document window, verify the active tool,
edit path and unobstructed target, and test the probe with a harmless synthetic action. Read back
its actual callback trace, undo the action through native Undo, and confirm baseline restoration.
Write and read a small evidence file before arming the probe. Do not use guessed API getters in
writers. Loading a helper must not automatically capture or replace a baseline.

Create a recipe from those observations. `ready` must be a JSON boolean, not a string. For cases
without callback instrumentation, record why `probe_callbacks_verified` is ready without a probe.
Unmatched source patterns are refused at capture. Every assertion declares conservative source patterns and relevant environment keys. Start with
its catalog case dependencies; narrow them only with a reviewed dependency rationale. Include
recipe/helper files among source dependencies when tracked; fingerprint private helper bytes in
an observation and reconsider reuse whenever they change.

```json
{
  "host": {
    "sketchup": "26.1.188", "ruby": "3.2.2", "os": "macOS",
    "controller": "observed controller/version", "session_id": "actual session",
    "fixture_sha256": "actual 64-character lowercase SHA256",
    "rbz_sha256": "actual 64-character lowercase SHA256", "composition": "normal"
  },
  "active_tool": "Classify", "edit_path": [],
  "preflight": {
    "window_active": {"ready": true, "observation": "Actual document activated and captured"},
    "tool_ready": {"ready": true, "observation": "Tool state read back through bridge"},
    "target_ready": {"ready": true, "observation": "Target Face visible and unobstructed"},
    "probe_callbacks_verified": {"ready": true, "observation": "Native down/up traced, native Undo restored records"},
    "writer_verified": {"ready": true, "observation": "Evidence file written and read back"}
  },
  "assertions": [{
    "id": "A09/release-after-context-change",
    "paths": ["src/ph_composer/session/*", "src/ph_composer/features/zones/*"],
    "environment_keys": ["sketchup", "ruby", "os", "controller", "fixture_sha256", "rbz_sha256", "composition"]
  }]
}
```

The displayed hashes are placeholders, deliberately rejected by the tool. Obtain real hashes from
the fixture and installed-package comparison; never substitute a source commit for build identity.

```sh
uv run tools/hostkit/acceptance_run.py capture --recipe _private/host/run/recipe.json --output _private/host/run/baseline.json
uv run tools/hostkit/acceptance_run.py screen --baseline _private/host/run/baseline.json --host _private/host/run/current-host.json
```

Capture creates a UUID and refuses to overwrite an existing file. `current-host.json` contains the
host object itself. Missing or changed environment fields invalidate dependent assertions. A new
session invalidates only assertions explicitly dependent on session identity. Unchanged dependencies
still require evidence review, preconditions and the owning packet's final gates.

## Observation and closeout receipts

After action and readback in separate calls, create an input with `assertions`, each containing
`id`, `status` (`pass`, `fail`, `unknown`, `blocked`), concrete `observation`, and an existing
`evidence` file path. Include every baseline assertion, retaining unobserved assertions as unknown.
`observe` hashes evidence and writes a separate immutable, timestamped receipt. It does not append
to the public ledger or validate a native claim. Review synthetic publication-safe summaries and
record them through `acceptance_ledger.py` as before; historical JSONL stays unchanged.

```sh
uv run tools/hostkit/acceptance_run.py observe --baseline _private/host/run/baseline.json --input _private/host/run/observations.json --output _private/host/run/observed.json
uv run tools/hostkit/acceptance_run.py package --rbz dist/ph_composer.rbz --plugins '/actual/SketchUp/Plugins'
uv run tools/hostkit/acceptance_run.py links planning/native-acceptance/README.md tools/hostkit/ACCEPTANCE_RUN.md
uv run tools/hostkit/acceptance_ledger.py validate
```

Use the actual RBZ path from `make rbz`. Package comparison reads every archived file and checks
for extra extension files; it does not install, launch, or prove which bytes a live process loaded.
The links command checks explicit local Markdown targets, including archive symlinks. It does not
validate anchors or reference-style links. Supply affected Markdown files, including routers.

## Current execution receipt

Keep one short current-state section in the owning packet's STATUS or handoff. Replace that section
at each material checkpoint; retain history in linked evidence and Git. This is not a new gate or
an obligation to stop or create a chat.

- Scope and next action: completed slice, exact next command/case, remaining decisions.
- Source/build: relevant source fingerprint, installed RBZ hash, package receipt.
- Verification: command, time, exit status, source/dependency scope and log/evidence link for each
  gate; covered review scope and unresolved findings. Explain invalidation before repeating a gate.
- Native state: case/assertion IDs, session, fixture/hash, tool/edit path, preflight and observation
  receipts, unresolved human actions, and normal-build restoration status.
- Handoff: for each human action, starting state, exact action, release/stop condition, expected
  visual cue and tool-collected readback. A dotted Group boundary is an edit-context cue, not a dialog.

Required native and final gates remain mandatory. Private fault probes require independently
observed normal-build restoration. Missing or invalid preconditions yield unknown, never an inferred pass.
