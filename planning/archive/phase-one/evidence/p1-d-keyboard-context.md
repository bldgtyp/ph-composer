# P1-D keyboard and edit-context continuation

DATE: 2026-09-29
STATUS: A09 named cases verified on the current host; Phase 1 and P1-D remain open.
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

At this earlier checkpoint, these checks added A09 evidence without closing all keyboard/focus
cases. The continuation below completes the named current-host A09 cases. It does not close
atomic Attached-zone create-and-assign, split identity/reference recovery, the remaining
Colour-by timing gate, P1-E or compatibility-floor host acceptance.

## 2026-09-29 table and Model-switch continuation

On installed `c584f4f`, process 85406, native Left/Right collapsed and expanded the Zone tree;
Down moved through its Face rows. A host snapshot refresh retained focus on the Floor row,
so the next Down reached Roof or ceiling. Left returned focus to the parent, then collapsed it.
Filtering to `scale_85` retained that Zone's six Face rows and reported `1 of 86`. Clearing the
filter and reversing Name order preserved the selected Zone's unsaved Name draft. An unmatched
filter showed `0 of 86` and the explicit empty result. The draft was restored to its stored value
without Save. The exact full Model fingerprint remained unchanged throughout.

Native Cmd-N from the focused panel opened a new Model. The panel showed zero Zones, removed
the previous Zone details, and read Classify inactive and Colour-by Off. The prior selected Zone
and its draft did not appear in the new Model. Display ordering remained a panel preference.

In the subsequent synthetic three-Zone visual fixture, opening a classified Floor's native type
select, highlighting another option and pressing Escape retained Floor with exact unchanged Model
data. Repeating with Classify active retained the tool after the first Escape; the second Escape
ended it. The first attempted palette activation used coordinates from the older two-Zone layout
and did not activate the tool; that attempt is excluded. The accepted repeat verified activation
by host readback before opening the select.

These checks verify tree navigation, stable refresh focus, filtering/order/draft retention and
select-menu cancellation. The computer-control API completes a drag as one call and cannot interleave a Model/context
change while the mouse button is held. Ed operated the held-button Model-switch check below.
The held edit-path repeat is recorded below.

## Held-button Model switch: reproduced defect and correction

Ed held the mouse button on a classified Wall, pressed Cmd-N and released after the new Model
opened. The original Wall changed to Floor. The first attempt was therefore excluded as a pass.
A repeat with development-only callback tracing established the order: onLButtonDown ran with
the original Model active; onLButtonUp ran on the original tool with the new Model already active.
No suspend/deactivate callback intervened. The old session revision advanced from 13 to 14 and
the Face record changed. Native Undo restored exact baseline data after each reproduction.

Classify now captures the persistent-id edit path at button-down and checks both active Model
identity and that path before completing. A mismatch cancels the gesture and invalidates the
preview rather than invoking the write operation. Regression tests cover both late mouse-up
cases without a suspend callback. Independent review caught the initially missing invalidation;
it was corrected and covered by the edit-path test.

In fresh installed process 91497, Ed repeated the physical held-button Cmd-N sequence. The trace
again delivered mouse-up with another Model active, but the old revision stayed 5, collecting
cleared, and the full original Model fingerprint, including modified state, matched the baseline.
The new Model had no active Classify tool. A normal native viewport click still classified one
Wall as Floor; its live legend updated immediately and native Undo restored exact prior data.
The development-only tracing disappears on process restart.

## Held-button edit-context change and A09 boundary

In installed process 93100, Ed held the button on a classified Wall while a development-only
UI timer entered the owning Zone's native edit context. Mouse-up cancelled the gesture: collecting
cleared, session revision remained 5, and records, Model dictionaries, entity attributes and
materials matched the exact baseline. Entering the edit context alone set SketchUp's modified
flag. Closing the context and saving restored the full fingerprint, including that flag. The
viewport status read “The Classify gesture was cancelled. Nothing was written.”

An initial computer-controlled drag completed before the timer could run and classified one
Face; it is excluded from this cancellation proof. Native Undo restored exact data before Ed's
accepted held-button repeat. The final Classify guard was unchanged between the fresh Model-switch
proof in process 91497 and this edit-context proof; subsequent code changes affected only hatch
density. The timer and callback instrumentation disappear on process restart.

Together with the linked Overview and broader acceptance records, the continuation completes
A09's named current-host UI cases: Overview/tree/table and classification review, narrow sizing,
unit-switch drafts, focus/Escape/Enter, stable rows, and active-edit-path/Model-switch behavior.
It does not close P1-D's split identity/reference, native adjacency boundaries, atomic Attached-zone
create-and-assign or isolated GPU timing work, nor SketchUp 2023 or Windows host acceptance.
Final offline verification and installed hatch evidence are recorded in
[p1-d-hatch-and-invalidation.md](p1-d-hatch-and-invalidation.md).
