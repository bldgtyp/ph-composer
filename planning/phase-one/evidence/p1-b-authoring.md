# P1-B Zone and face authoring evidence

DATE: 2026-09-20
STATUS: Pass on the current proving host. SketchUp 2023 and Windows remain support gates.

## Scope

This record closes P1-B only. It covers compound record/geometry proposals, entity-owned Zone and
Face records, explicit occurrence references, Make Zone, Zone details, single-Face classification,
the minimal Overview UI and panel-closed public-operation parity. Adjacency, bounded Classify
gestures, Auto-classify, Reverse face, Colour-by and HBJSON remain P1-C/P1-D work.

The synthetic fixture contains no project or licensed data. The reproducible public-operation
driver is [`tools/examples/authoring/walkthrough.rb`](../../../tools/examples/authoring/walkthrough.rb).

## Deterministic checks

- `make ci` passed under Ruby 3.2.2 and the Ruby 2.7.2 compatibility floor.
- Ruby: 248 runs, 1,123 assertions. JavaScript: 116 tests. Python: 77 tests. Hostkit: 9 runs,
  30 assertions. All had zero failures.
- Coverage passed at 95.4 percent Ruby, 97.7 percent JavaScript and 100 percent Python.
- Panel and runtime manifests, runtime pins, fixtures, type checks and RBZ inventory passed. The
  RBZ contains 107 files and excludes development examples.
- The Chromium 88 runtime browser check passed, including isolation, single-flight boot and both
  translation replies. The Playwright UI-preview check reported its documented skip because the
  external scratch Playwright installation was absent; focused panel tests and the live-host visual
  check covered the P1-B surface.

The offline suite verifies stale/wrong-target refusals, preview digest comparison, retry behavior,
record deletion and projected reference checks, metadata preservation, duplicate Zone identity,
nested hierarchy refusal, explicit keep/set/clear intent, SI world geometry and truthful rollback
results when a record write fails after geometry has changed.

## Fresh-process host acceptance

Host: SketchUp 26.1.188 on macOS, embedded Ruby 3.2.2. Installed from the verified RBZ and launched
with the development bridge into a fresh synthetic Model.

1. `AuthoringWalkthrough.setup` created two adjacent box Groups.
2. `AuthoringWalkthrough.run` previewed and invoked Make Zone twice with the panel closed, updated
   one Zone to `West Zone`, `Walkthrough`, `L1`, 150 mm, and classified one Face in each Zone from
   the read-only geometric suggestions.
3. The public reads returned two Zone paths, 12 Face occurrences and two classified Faces. Both
   Face membership stamps agreed with their containing Zone records.
4. Native Undo removed exactly the last Face assignment. Native Redo restored it and its matching
   stamp.
5. After save, clean quit and fresh reopen, the public verification returned the same two Zones,
   12 Faces, two assignments, Zone values and stamp agreement.
6. The live HtmlDialog at a narrow width showed both Zone forms, IP display of canonical ground
   depth and the Face type/boundary controls. The selected classified Face displayed Floor/Ground;
   unclassified Faces displayed Keep controls. Make Zone was disabled with no eligible selection.

The proving-host result satisfies P1-B acceptance. It does not establish public support for
SketchUp 2023 or Windows and makes no construction, export or certification claim.
