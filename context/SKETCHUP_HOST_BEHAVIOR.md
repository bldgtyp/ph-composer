# SketchUp host behavior: measured facts for agents

**DATE:** 2026-09-18

Unless a row says otherwise, every fact here was measured in the predecessor, PH-Navigator for
SketchUp, on SketchUp Pro 2026.1 build 26.1.188 (macOS, embedded Ruby 3.2.2) between 2026-09-06 and
2026-09-17, through its development host bridge. Rows marked "Measured in PH-Composer" come from this
repository's own bridge on the same host. designPH 2.2.29 was installed and loaded on that host throughout.
Re-measuring the observer-ordering facts on a host without designPH is a pending gate for this
project; until then treat them as likely and pin them in the stub as the predecessor did.

Each fact names the code that depended on it and the offline test or stub rule that pinned it in
the predecessor. Those tests move here with the tooling transplant. When a fact changes on a newer
host, update the stub and this file in the same change. The full record, including the designPH
and Dynamic Components facts this file drops, is
[`../../ph-navigator-sketchup/context/SKETCHUP_HOST_BEHAVIOR.md`](../../ph-navigator-sketchup/context/SKETCHUP_HOST_BEHAVIOR.md).

## Observers and edit contexts

| Fact | Consequence | Pinned by |
| --- | --- | --- |
| Observer callbacks for one user action arrive after the Ruby call that caused them returns, and in a fixed order: `onTransactionCommit`, then `onActivePathChanged`. On leaving a Volume with Escape (or `Model#close_active`), the commit callback arrives with `active_path` already outside the Volume. | A reconciler that rebaselines on commit loses the Volume it needs to protect. Either callback must queue the exit protection from the baseline. | `test_exit_protects_when_commit_arrives_before_path_change` |
| For an operation Ruby opens and commits itself, `Model#commit_operation` delivers `onTransactionCommit` synchronously, before the call returns. Measured in PH-Composer on 26.1.188, 2026-09-18. | The session recognizes its own commit inside the operation; it still handles a callback that arrives later. | Stub `Model#commit_operation`; `tests/sessions_test.rb` |
| `Model#abort_operation` fires `onTransactionUndo`, synchronously, and no `onTransactionAbort`. Measured in PH-Composer on 26.1.188, 2026-09-18. | An observer cannot tell an aborted operation from a user Undo by the callback alone. The session ignores the Undo callback inside its own operation, so a rolled-back change leaves the revision. | Stub `Model#abort_operation`; `test_abort_reports_an_undo_as_the_host_does` |
| Leaving or entering a group edit context is itself a transaction: `onTransactionCommit` fires on Escape, and a context change marks the Model modified. | Do not read a commit as "geometry changed"; a save followed by a context close leaves the title marked modified. | Recorded; no stub rule |
| Inside `onPreSaveModel`, `Model#active_path` is empty although the edit context is still open on screen. SketchUp restores the context after the save. | Pre-save work cannot read the Volume from the path; the reconciler uses its baseline Volume. | Stub `Model#save` (`fire_pre_save`) |
| Setting `Model#active_path` inside `onPreSaveModel` makes SketchUp serialize the reopened context in world coordinates: the reopened file has the Space transform baked into its Volumes. In memory nothing has moved. | Never change the path during pre-save. Protect in `onPreSaveModel`; close the boundary in `onSaveModel`. | Stub `Model#save` raises on a pre-save path change |
| `onSaveModel` fires after the file is written, on the restored path, with `modified?` false. | The right moment to close a boundary the save left open. | Stub `Model#save` fires it |
| While a context is open, the API reports `Group#transformation` of entities on the active path in world coordinates, not relative to their parent. Closing the context restores relative values. | Compare against stored home transforms only through a path-aware transform reader; a raw comparison reports `volume_moved` for every open Volume. | `GeometryReference` tests |
| Opening a repeated parent context rebases shared child transformations, and `Sketchup::InstancePath#transformation` can then return a wrong position for another occurrence of that parent. | Withhold world geometry for shared definitions while their edit context is open, or compensate with the current raw root-to-leaf transform. | Predecessor window reader phases 3a and 3b1 |
| After `Model#active_path=` opens a Volume inside a Space that sits in a rotated plain group, `View#zoom(face)` frames that face correctly. A screen box computed from `edit_transform` times the entity's reported bounds disagreed with the capture. | Zoom the target entity directly; judge framing from a capture, not from coordinates computed inside an open context. | Predecessor Spaces table controls, phase 4 |
| `Selection#add` of an entity outside `Model#active_entities` does nothing and raises nothing. | Selecting a sibling Volume from inside another Volume needs the context closed first. | Stub `Selection#add` ignores out-of-context entities |
| `Model#active_path=` from Ruby is honored outside save callbacks and fires `onActivePathChanged` later, not synchronously. | Read state in a later call; a `sleep` in the same call blocks the UI timers that deliver callbacks and run deferred work. | Bridge usage rule |
| `Model#close_active` delivers the same observer sequence as Escape. | The bridge can exit contexts without keystrokes. | Host gate 2026-09-06 |
| With `model.active_path` inside a group, face vertices transformed by `model.edit_transform` give world geometry, while `InputPoint#position` is in active-context coordinates. | Transform a picked point to world coordinates for preview and containment. | Predecessor phase 7b2 |
| A component placed in a parent mirrored on X and scaled 1.5 by 0.75 measured its intended size after Redo and reopen only when its world placement transform was converted through `model.edit_transform.inverse` before `active_entities.add_instance`. Without that conversion the parent scale applied twice. | Keep preview and containment in world coordinates and compensate exactly once at the `add_instance` boundary. | Predecessor phase 7b2 |
| SketchUp cut and paste can replace a `persistent_id`. | A durable UUID in PH-Composer's own dictionary survives the operation when the object is still logically the same; placement references stay path-qualified; session `entityID` is never durable identity. | Predecessor B2 evidence |
| `Sketchup::Model#delete_attribute` returned `nil` without removing the key. Deleting the key from `model.attribute_dictionary(namespace, false)` succeeded. | Remove Model-level keys through `AttributeDictionary#delete_key`, and model this in the stub. | Predecessor phase 6c2 |
| `Model#guid` changes across reopen. Persistent ids remain stable. Subnanometre floating-point differences also appear across reopen without a meaningful Model change. | A durable fingerprint uses persistent ids and normalized floats. Never use runtime Model or definition GUIDs as durable identity. | Predecessor phase 6c2 |
| Walking shared definition geometry once and hashing each occurrence path and transform separately reduced a 44-window Model fingerprint to 32,502 items in 103 slices; expanding definitions per occurrence was unacceptably large, and running the scan synchronously during Export blocked SketchUp before progress or cancellation. | Separate graph identity from occurrence placement in large Model walks, and run them under a bounded cancellable task. | Predecessor phases 6c2 and 6d |

## Saving, dialogs and the panel

| Fact | Consequence |
| --- | --- |
| `Model#save` fires `onPreSaveModel`, writes, then `onSaveModel`. On SketchUp 2026 it shows the Purge Unused prompt when the Model has unused assets; the prompt blocks the main thread until dismissed. Escape keeps the save without purging. | Scripted saves need a dialog guard (the bridge sends Escape after three seconds). |
| `Sketchup.send_action("saveDocument:")` from Ruby was ignored when SketchUp was not the frontmost application. | Use `Model#save` for scripted saves. |
| Cmd-S while the HtmlDialog panel has focus does not save the Model. | A user save must come from the Model window or the File menu. Worth a line in user-facing docs. |
| `UI::HtmlDialog#close` returns immediately; `set_on_closed` runs a moment later. | Poll the panel state after closing. A `show` in the same eval as `close` reaches the closing dialog, and the close then clears it (PH-Composer, 26.1.188, 2026-09-18). |
| A callback added with `add_action_callback` after the page had loaded was not reachable from that page's `sketchup` object; the same callback added before `show` was. Observed once in PH-Composer on 26.1.188, 2026-09-18. | Register every callback while building the dialog. A development probe that reports from the page adds its callback there too. |
| Choosing SI or IP in the PH-Composer panel wrote `Sketchup.write_default` and left the Model unmodified, its session revision unchanged and `UnitsOptions` untouched; the choice read back after a fresh-process restart (26.1.188, 2026-09-18). | Display preferences never go through a Model operation. |
| The Pyodide runtime boots on first use (Export, probe), not when the panel opens; the panel reports `idle` until then. | `idle` after `Panel.show` is normal, not a failure. In PH-Composer the runtime has its own page and window and the panel never loads it. |
| An `HtmlDialog` page loaded with `set_url` from a loopback server requested `/favicon.ico` at the server root on each load. PH-Composer, 26.1.188, 2026-09-18. | A token-path server logs it as a refused request. The runtime page declares an inline empty icon. |
| Pyodide 0.24.1 booted in a PH-Composer `HtmlDialog` on the token origin in 1,275 to 1,300 ms cold, round trips of 0.3 to 0.5 ms, with the asset server's UI-timer pump never over 7.4 ms. 26.1.188, 2026-09-18. | The manifest's 6,000 ms cold and 50 ms pump ceilings hold on the proving host with no wheels installed. |
| After `Model#close(true)` on the only open Model, `Sketchup.open_file` of the same path in the same process loaded it again with a new session; no `ModelSession` for the old id survived `GC.start`. 26.1.188, 2026-09-18. | A same-process close and reopen is reachable from the bridge; the earlier note about reopening an open path applies only while it is still open. |
| `Sketchup.open_file` on an already open path in the same process activates the existing document rather than reloading the file. | A real reopen needs a fresh SketchUp process. |
| That activation fires no `onActivateModel`, not even to a fresh `AppObserver`; `Sketchup.active_model` changes and every session observer stays silent. A native click in another document's window fires it each time. Measured in PH-Composer on 26.1.188, 2026-09-18. | A Model switch driven by `open_file` leaves the panel on the previous Model; a same-process switch check needs native window clicks. |
| `UI.savepanel(title, directory, filename)` opened in `~/Documents` on this host, with `directory` naming the Model's folder, both under `/private/tmp` and under a normal user folder. The proposed file name was kept. Observed in PH-Composer on 26.1.188, macOS 26, 2026-09-18. | Phase 1 Export cannot rely on the `directory` argument to start in the Model's folder; the cause and a working form are unverified. |
| `Sketchup.write_default` accepts a string containing a double quote and returns true, but `read_default` returns nil for it. Plain strings, base64 text, arrays and hashes read back intact. | Store structured preferences as base64 JSON. The Ruby stub's `read_default` returns nil for such strings so the offline tests catch a regression. |
| A panel that is hidden or behind other windows throttles its timers. | Bring the dialog to the front before a scripted run. |
| `Sketchup.redo` replays a panel edit from the bridge; `Sketchup.send_action("editRedo:")` does not redo. | Use `Sketchup.redo`, or raise the document window by title and send the keystroke. |

## Process lifecycle on macOS

| Fact | Consequence |
| --- | --- |
| `open -a "SketchUp 2026"` fails; the bundle path works: `open -a "/Applications/SketchUp 2026/SketchUp.app" <model>`. | The bridge launcher uses the bundle path. |
| `Model#close` raises "Only the active model can be closed" for any other open Model. `Sketchup.file_new` fires `onNewModel` for the new document but leaves `Sketchup.active_model` on the previous one until the new window activates, which did not happen while SketchUp was in the background. Measured in PH-Composer on 26.1.188, 2026-09-18. | Drive a multi-document check by closing the active Model; never assume `file_new` switched the active Model. |
| Launched with no document, SketchUp waited at its Welcome screen and no bridge or extension code ran within two minutes. Observed once in PH-Composer on 26.1.188, 2026-09-18. | `host_bridge.py launch` always opens a Model. |
| A killed SketchUp restores its previous documents on the next launch, so the requested file may not be the active Model. | Quit cleanly: discard-save a modified Model to a scratch path, then `Sketchup.send_action("terminate:")`. Verify the active Model's file name. |
| AppleScript `tell application "SketchUp 2026" to quit` did not complete from a terminal; `terminate:` through the bridge does. | Do not use AppleScript to quit. |
| `osascript` System Events keystrokes to `process "SketchUp"` work once Accessibility is granted. `screencapture -x` captures the whole screen. | Send keys only to SketchUp. For evidence, prefer `View#write_image` for the viewport and a window-by-title capture for one SketchUp window. |
| A SketchUp window on an inactive macOS Space is absent from the on-screen window list, and a capture taken while it is being switched away comes back blank with the title bar intact; the bridge and the panel DOM keep working. | Treat a blank or missing capture as a Space or lock-screen condition, not a panel failure. Do not `activate` SketchUp to force it. |
| The first bridge launch after a clean quit sometimes brought SketchUp up without the bridge; the next launch found the process, could not quit it within 30 s, killed it, and the relaunch loaded normally. | Treat a launch that ends with "SketchUp not running" and no bridge as retryable. |
| `open` immediately after a kill can fail with `LSOpenURLs ... error -600` while the process is still exiting. | Wait for the process to disappear, then retry. |
| SketchUp has one Plugins folder per major version; a `.rb` file placed there loads at startup. | The bridge is installed there and never in the RBZ. |
| A launch fails while the Mac screen is locked. | A gate needs an unlocked screen. |
| A host check can fail because SketchUp is running with no Model open, which looks the same from outside as a running idle process. | Verify an active Model, not just a live process, before reading a gate result. |

## The panel's embedded browser

| Fact | Consequence |
| --- | --- |
| SketchUp's public `UI` API exposes no colour chooser, and an `<input type="color">` in an HtmlDialog opened no native chooser on this host. | A colour control has to be drawn in the panel. The predecessor's swatch plus in-panel palette, saturation and brightness field, hue slider and hex entry transplants. |
| A native `confirm()` dialog, and a native Escape to cancel one, cannot be driven by the development bridge or by System Events. | Any destructive action gated by a native confirm goes unexercised in an automated host gate. Give such an action a second route the bridge can reach, and say in the evidence which route was exercised. |
| `HtmlDialog` measurement callbacks are asynchronous: an immediate nil is a pending measurement, not a failure. | Wait for the callback. |
| Revealing table rows costs style and layout for each row, about 0.1 to 0.3 ms in Chrome. | Render filter input once per animation frame. A 100 ms budget for large reveals needs row virtualization; the predecessor accepted a raised budget for its MVP. |
| `document.hidden` is the page visibility flag and is true while the host window is occluded. | A grid's visibility walk stops at the scroll container rather than trusting `document.hidden`. |
| Retained DOM nodes with transient Saving/Queued text still increased row height from 38.5 to 50 pixels. | Keep routine pending feedback out of row flow, preserve control focus, and measure geometry in the host. |
| An 8-percent background tint fading in 200 ms was effectively invisible as a context-change cue; a 200 ms list fade with 4 px movement plus a separate 650 ms primary-blue outline fade was visible. | Use the measured cue for context swaps only; honor reduced-motion preferences. |

## Overlays

| Fact | Consequence |
| --- | --- |
| A `Sketchup::Overlay` drawing through the accumulated world transform lands on the right geometry under rotated parents; 44 items drew in 0.17 ms median with a one-off 1.4 s walk. `View#write_image` does not render overlays; `view.invalidate` inside an eval does not repaint before the eval returns. | Cache per instance and invalidate from the observers; capture overlay evidence with a window capture. |
| SketchUp 2023 to 2025 require a child drawing element appended to a component or group leaf path for `Model#drawing_element_visible?`; SketchUp 2026 accepts the occurrence path directly. | Branch on the host version in the visibility reader. |
| `Sketchup::Overlay` is a 2023.0 API. | It is why SketchUp 2023 is the compatibility floor. |
