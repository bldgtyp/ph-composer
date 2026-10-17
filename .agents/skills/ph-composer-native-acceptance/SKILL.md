---
name: ph-composer-native-acceptance
description: Run or resume PH-Composer acceptance in real SketchUp, preserving fixture and installed-build identity, native evidence, and check reuse. Use for host gates and lifecycle validation, not ordinary offline tests.
---

# PH-Composer native acceptance

Resolve the repository from the task or this skill's real path. Use the owning acceptance packet;
this skill does not authorize a feature, release, restart of unrelated documents or publication.
Read the active agent's machine-level host-automation guidance before controlling SketchUp. Reuse orientation,
accepted decisions, the existing independent reviewer and unchanged evidence within a coherent task.

1. Select a bounded batch of named cases from the owning packet and
   [case ledger](../../../planning/native-acceptance/README.md). Its dependency paths screen which
   checks a change affects; they do not replace the packet or required final gates.
2. Follow [native-control capabilities](../../../context/NATIVE_CONTROL_CAPABILITIES.md) to choose
   bridge, native controls or one precise human action. Use public operations for product writes.
   Development eval can arrange synthetic fixtures and faults; label it separately.
3. Establish the case preconditions: synthetic fixture identity/hash, active Model session and edit
   path, host/Ruby version, installed RBZ hash and source fingerprint. Confirm the installed build
   matches the reviewed source. A bridge connection or installation alone is not a passing case.
   Apply the [run preflight and receipt procedure](../../../tools/hostkit/ACCEPTANCE_RUN.md):
   verify window activation, tool/edit path, target, actual probe callbacks and evidence writer before
   a human handoff. Capture an immutable run baseline; loading a helper must not overwrite it.
   `uv run tools/hostkit/acceptance_case.py begin <case> --run-dir _private/host/<run>` does this in
   one step: it reads the session, tool, edit path and versions from the bridge, checks the installed
   extension against `dist/ph_composer.rbz`, hashes the fixture, proves the folder writable, captures
   the baseline, snapshots the ledger and starts the case's `steps.md`.
4. Execute action and readback in separate calls so UI timers run. Capture native window pixels for
   drawing/UI claims and actual references/records for persistence claims. Use the case's required
   refusal, rollback, Undo/Redo and reopen checks; do not infer them from aggregate object counts.
   Distinguish queued, translating and completed states before a lifecycle action. An explicit
   tools-only delay can make a pending state reachable but must not become shipping behavior.
5. Record assertion-level observations, outcome and evidence in a ledger result
   (`acceptance_case.py finish <case>` reads `<case>/observations.json`). Keep raw Models,
   screenshots, full traces and real data in gitignored `_private/`; commit synthetic summary
   evidence only. Never retrofit missing provenance into a historical run or mark a scripted
   callback simulation as a native gesture. Unknown/interrupted outcomes stay unknown.
6. Continue the authorized batch after checkpoints or human replies. Stop for a consequential
   decision, inaccessible native action or real scope frontier. Use focused checks during fixes;
   recheck affected cases against the new build and preserve required final suite/review gates.

Restore normal composition after private fault/provider overrides: fresh process with the normal
installed RBZ, no development monkeypatches or live runtimes, clean saved synthetic Model and
expected normal refusal/success. Check open documents before `launch`, which can quit/kill the host.
Never discard other work. Restoration is a separate observed result, not an assumed teardown.

Use the [current execution receipt](../../../tools/hostkit/ACCEPTANCE_RUN.md#current-execution-receipt)
in the owning packet, replacing current state while preserving linked historical evidence.
Human instructions include the expected visual cue as well as action and release condition.

Keep a compact resume note: batch/case, fixture/session/build, accepted decisions, last verified
checks and their invalidation, reviewer, remaining action and normal-build restoration state.
Do not reload all closed phases or rerun passing checks merely because the chat compacted.

Write how each case is driven into its `steps.md` while you run it: the fixture and where it was copied
from, labelled bridge setup, panel size and position, camera, native steps with screen-frame
coordinates and the window they belong to, probe arming and the readback for each assertion. A rerun
starts from the earlier run's `steps.md` instead of rediscovering them. Session scratch space does not
survive; keep run helpers in the repository (`tools/hostkit/`) or the run folder, never only in scratch.
