# Bugs

DATE: 2026-10-02
STATUS: Active index.
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: none (local planning draft)

Reproduced defects whose evidence is too long for a status row. One file per bug.

| Bug | State |
| --- | --- |
| [runtime-probe-test-flake](runtime-probe-test-flake.md) | Requested; root-caused, a fixed 5 ms wait in `tests/runtime_page_test.js` |
| [ci-needs-utf8-locale](ci-needs-utf8-locale.md) | Requested; reproduced, five tests read source files with no encoding |
