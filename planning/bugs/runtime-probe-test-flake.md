# Runtime page test fails under CPU load

DATE: 2026-10-02
STATUS: Requested. Reproduced and root-caused 2026-10-02; not fixed.
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
