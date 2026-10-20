# Production support: acceptance

DATE: 2026-10-19
STATUS: Complete 2026-10-20, archived
AUTHOR: Ed May, BLDGTYP, with Codex and Claude
ISSUE: https://github.com/bldgtyp/ph-composer/issues/245

All rows are requirements, not passes. Record actual results only in STATUS and linked receipts.
Use synthetic data and development-only fault injection. Never package fault switches.

## Acceptance matrix

| ID | Case and required observation | Evidence | Stage |
| --- | --- | --- | --- |
| A01 | Two distinct Ruby failures produce distinct log records: exception class, extension-relative frames, stage and code; no message text, absolute path, token or payload appears. The incident reference in the outcome's detail matches the log record | Offline schema/privacy/fault tests; integrated native incident | PS-01 |
| A02 | A caught rendering error, an uncaught panel error and a rejected promise each reach the Ruby log as bounded records; one broken pane does not suppress another pane's failure notice or support access | JS tests plus native panel fault | PS-01 |
| A03 | Asset refusal, startup timeout, translation failure and conformance failure retain their original stage and code in the log with fixed user-facing messages; two different packages produce different build identities | Runtime/Python tests, package test, real shipped-runtime fault | PS-01 |
| A04 | Drop a request before execution and drop a reply after a successful commit. Neither is blindly resent; Check status identifies the retained outcome or preserves uncertainty, with one mutation at most | Offline boundary tests and native committed/lost-reply case | PS-02 |
| A05 | A runtime that never sends ready and one that never replies after ready both reach a bounded, explained state within the deadline; Cancel stays usable and releases supported resources; late completion after Model close or switch applies nothing | Fake-clock tests and native asynchronous faults | PS-02 |
| A06 | A failed preference write produces a failure, not saved-success copy. Unreadable or future stored configuration is not overwritten. Reset display preferences preserves other stores and the SKP | Store tests and native persistence/restart read-back | PS-02 |
| A07 | With the main panel broken or closed, the native menu opens support without booting Python or requiring a Model. Support HTML failure falls back to a message box with version, build and log folder. Missing or unwritable log storage shows as degraded, keeps the in-memory tail and locks nothing | Native menu/control evidence and unwritable-location fault | PS-03 |
| A08 | Every failure view says what changed, what remains unknown and the safe next step; technical detail is disclosed on request. Narrow windows, keyboard-only use and focus return work. Reopen panel with an active draft explains loss or preserves it | Content/state tests, JS/browser checks, native walkthrough | PS-03 |
| A09 | Preview, copied text and saved file are byte-equal for the same capture. Cancel writes nothing; clipboard and destination failure keep a usable preview and an alternative route. Seeded paths, project names, tokens, payloads and licensed-like text at each boundary are absent from the report; truncation and missing evidence are explicit. Clear history confirms loss, leaves Model, configuration and saved reports intact | Exact byte comparisons, negative privacy tests, native clipboard/Save sheet, fake-clock retention | PS-03 |
| A10 | A user finds offline help, sees the installed and current release, and prepares a public issue without terminal commands or an automatic upload. A maintainer traces a report to its package and a synthetic reproduction | Packaged help/link checks and walkthrough | PS-04 |

PS-05 runs A01 to A10 as applicable on a fresh installed RBZ, with the release receipt below.
Logging, support reads and report actions create no SKP writes, revision advance, Undo entry or
implicit save; all development helpers are absent afterward.

## Accepted host deviation

A07's "without requiring a Model" holds for the window, not for the native menu: SketchUp for
macOS disables every extension menu item while no document is open (measured 2026-10-19, PS-05
run). Ed accepted this on 2026-10-20 (DECISIONS, PS-D11): the native Help and Diagnostics menu
needs a document open, and the panel footer link covers the rest. A07's menu route is satisfied
with a document open and the panel closed; the no-document route is not required.

## Explicit unsuccessful endings

Exercise no recent events, unreadable history, logging unavailable, unsupported host, unavailable
Python, support window disposal, closing the native Save sheet, unwritable destination,
clipboard failure, request outcome expiry and a rollback that cannot be verified.
Each ending must leave a truthful state and a reachable next action. An unavailable read does
not become passed. A support report must not assert that an empty log proves no failure.

Native crash reporting is a documented manual route. A previous process ending without a clean
marker may justify an interrupted-session message, but cannot establish that PH-Composer caused
a native crash. Never promise that a Ruby handler can intercept every SketchUp crash.

## Release receipt

Record source commit, immutable build/RBZ hash, vendor manifest identity, installed comparison,
host/OS/Ruby/CEF, synthetic fixture identity and session. Include the actual saved/copied report
comparison, observed Model/Undo state, fault setup/removal and resource teardown.

One native case can satisfy several rows if its receipt explicitly records each observation.
Restore the normal installed build and clean host state before closure. Keep synthetic public
fixtures separate from private native evidence. This feature's receipt does not award another
platform's acceptance or certification approval.
