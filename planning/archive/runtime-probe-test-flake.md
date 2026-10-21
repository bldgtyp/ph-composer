# Runtime page test fails under CPU load

DATE: 2026-10-02
STATUS: Complete. Fixed on main through PR #127 (`87bdc62`); confirmed and archived 2026-10-21.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

## Defect

`tests/runtime_page_test.js`, "two probes share one boot, which installs the translation package
from the manifest's list", sometimes fails. The two `runtime.result` messages it expects have not
arrived yet: the assertion sees `[]` instead of `["one", "two"]`. It failed once in a full `make ci`
during R11 (PR #30) and passed on the rerun. No code it tests changed.

## Evidence

- On its own: 5 of 5 runs pass.
- 24 copies run in parallel to load the CPU: 3 failed.
- The same 24-way run with the test's `settle()` raised from 5 ms to 200 ms: 0 failed.

## Root cause

`settle()` (`tests/runtime_page_test.js`) waits a fixed 5 ms of wall-clock time and then asserts.
The boot it waits for includes a real `setTimeout(..., 0)` (the stand-in script's `onload`), then a
chain of promise steps (manifest fetch, asset fetches, Pyodide load, probe). Under load the 5 ms
timer can fire before that chain has finished, so the test asserts on a boot still in progress.

Ruled out: a defect in the runtime loader. Waiting longer always produced both results with one boot.

## Proposed correction

Wait for the condition, not a duration. Either poll until the expected `runtime.result` messages
arrive, with a generous upper bound that fails the test with a clear message, or have the stand-in
expose the boot promise so the test awaits it. Apply the same helper to every test in the file that
uses `settle()`, since they share the pattern.

## Verification

The 24-way parallel run passes repeatedly, and the file's tests still fail when the loader is broken,
for example with a refused asset.

## Resolution

PR #127 (`87bdc62`, 2026-10-15) fixed the race by another route than the one proposed above. The
stand-in script now fires `onload` or `onerror` as a microtask instead of on a `setTimeout(..., 0)`,
so the whole stand-in boot drains before `settle()`'s 5 ms timer can fire, however late the event
loop runs. `settle()` itself still waits a fixed 5 ms; it no longer races anything the stand-in
schedules.

Confirmed 2026-10-21 on `main@02fde97`: the 24-way parallel run of `tests/runtime_page_test.js`
under `tools/js_test_guard.js`, three rounds, 72 of 72 passed. The bug doc's reproduction failed 3
of 24 before the fix.
