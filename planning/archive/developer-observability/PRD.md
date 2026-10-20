# Developer observability: requirements

DATE: 2026-10-19
STATUS: Complete
AUTHOR: Ed May, BLDGTYP, with Codex
ISSUE: [#254](https://github.com/bldgtyp/ph-composer/issues/254)

## Purpose

A development agent should get useful failure evidence from one check or bounded wait. It should
not need to guess how long SketchUp needs, parse several unrelated log tails or rerun a failed
case just to discover its browser exception. Existing acceptance tools remain the authority for
source, installed-build and native-observation provenance.

## Browser evidence

Use one shared collector in the current Playwright library scripts. It records console errors,
uncaught page errors, failed requests and HTTP error responses with action/time context.
On failure, save a bounded JSON summary and readable account beside existing screenshots.
Diagnostic-write failures must preserve the original test failure.

Expected fault-injection errors are declared by the case and must actually occur. They are not
a blanket console-error exemption. Browser and context cleanup runs after assertions fail.
For difficult cases, retain a local trace containing the action history and browser evidence.
Keep the existing runner and dependencies; add no parallel browser-test framework.

The report identifies the fixture, browser, viewport and check. It does not claim that a preview
failure reproduces in HtmlDialog or that browser success establishes native behavior.

## Asynchronous waits

Provide a Python helper over existing bridge reads. A case chooses a named condition and explicit
session/task/revision when relevant. Each poll is a short separate host call, so UI timers and
observers can advance between calls. The overall deadline and each call's remaining timeout are
bounded by a monotonic clock.

Return a structured ending: condition met, timed out, cancelled by the developer, invalid
condition/session or bridge unavailable. Include elapsed time, poll count and last observed
projected state. After DV-03, include relevant recent diagnostic references when available.
Absence of DV-03 must not prevent basic waits from working.

A timeout describes observation, not the outcome of a mutation. Waiting cannot apply another
operation, relaunch SketchUp, switch documents or save/repair a Model. A stale or switched session
is explicit. Do not silently follow the new active Model.

## Diagnostic reads

After production PS-01, expose its bounded diagnostic projection to development probes through
the existing development bridge/helper path. Filter by incident/run/session, severity and cursor.
Include capture health, build references and explicit history gaps.

Return detached structured values, never arbitrary log-file bytes or hidden logger objects.
Process restart or ring eviction invalidates a cursor honestly. Reference the existing
acceptance/package receipt when exact installed-byte proof is needed.
No new permission or log-reading tool is added to the public product agent interface.

## Named fault cases

Provide small helpers for lost replies, silent runtimes and failed writes where the owning
production tests/native cases need them. Each helper has explicit arm, observe and restore
operations. Arming records an independently checked baseline and limits the fault to the named
synthetic target. Nothing arms on import or extension load.

The helper reports whether restoration was observed, including active fault state and residual
resources. A failed restore stops the case; it cannot produce a passing receipt.
Use a dedicated synthetic host/fixture, never the user's working Model. Existing normal-build
restoration and installed-byte checks remain required.

The production-support packet owns behavioral regression assertions. This packet tests the
fault controls and evidence mechanics, then references the production cases for product results.

## Developer experience

Document one command/example per workflow and print machine-readable output with evidence paths.
Bound the output and show truncation. Failures name the stage and expected versus observed state
where available. Reuse current tools and machine setup; no additional account or hosted service.
