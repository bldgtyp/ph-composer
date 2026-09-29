# P1-D keyboard and edit-context continuation

DATE: 2026-09-29
STATUS: Named cancellation and quantity-save cases verified on the current host; A09 remains open.
ISSUE: none (local implementation packet)

## Scope and host

SketchUp 26.1.188, Ruby 3.2.2, macOS. Synthetic fixture
`_private/host/p1d-keyboard-context.skp` contains 86 Zones and 516 classified Faces.
Native computer control operated panel inputs, menus and keyboard commands. The established
host bridge prepared edit context and read exact records, transforms, loops, stamps, entity
attributes and materials. These local fixtures and helpers remain gitignored.

## Defects and corrections

Escape with panel focus did not end the active Classify tool. The feature now relays unconsumed
Escape through its public stop view command. Editors retain their first cancellation press;
an open dialog retains its native cancel press. Pending commands prevent duplicate stops.

Native menu activation also left the panel's tool state stale. Classify now requests a coalesced
session refresh after palette choice, activation and deactivation. This publishes view state
without opening a Model operation. The final installed code was tested in fresh process 85406;
no manually requested refresh was used for its native-menu checks.

## Native results

| Case | Result |
| --- | --- |
| Ground-depth input, invalid draft then Escape | Restored the stored zero value without changing Model data. |
| Ground-depth input, 12.5 in then Enter | Committed the input draft without writing the Model. Tab then Enter on Save stored 317.5 mm, changing only that Zone record. Native Model Undo restored exact prior data; Redo restored exact saved data. Final Undo restored the baseline. |
| Active Classify, quantity draft then Escape | First Escape restored zero and retained Classify; second Escape ended Classify. Full Model fingerprint stayed unchanged. |
| Active Classify, New Attached zone dialog then Escape | First Escape discarded the named dialog draft and retained Classify; second Escape ended Classify. No record was created, no Model data changed, and discovery reported no operation held during the draft. |
| Native menu starts Classify, panel Filter focused then Escape | Panel reflected the active mode; Escape stopped the tool and released forced Colour-by. Exact full Model fingerprint stayed unchanged. |
| Same menu/Filter sequence inside scale_0 edit context | Escape stopped Classify and retained active path `[48881]`. Exact Model data stayed unchanged; entering the native context itself marked the Model modified. |
| Subsequent Escape with viewport focused | Exited the Zone edit context without changing Model data. |

Quantity-save Undo/Redo was measured before the Escape correction. Modal and quantity cancellation
priority passed in fresh installed process 83646; native-menu and edit-context cancellation passed
again with the final lifecycle correction in fresh installed process 85406. The synthetic file
was saved with baseline data restored and edit context closed.

## Verification and boundary

`make ci` passes: 488 Ruby tests / 2,099 assertions, 174 JavaScript tests, 84 Python tests and
9 hostkit tests, with lint, fixtures, manifest and RBZ checks. `make coverage` passes: Ruby 96.6%,
JavaScript 98.2%, Python 97.46%. The Ruby 2.7.2 full suite also passes. The shipped asset manifest
was refreshed, and `make install` installed the final RBZ before the last fresh-host checks.
One independent review of the coherent keyboard/lifecycle diff found no actionable defects.

These checks add A09 evidence; they do not close all keyboard/focus cases, atomic Attached-zone
create-and-assign, split identity/reference recovery, remaining Colour-by visual/timing cases,
P1-E or compatibility-floor host acceptance.
