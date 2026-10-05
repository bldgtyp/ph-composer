# Native-control capabilities

DATE: 2026-10-01
STATUS: Development guidance grounded in SketchUp 26.1.188 on the current macOS system.

Choose the control by the claim being tested. Recheck current tool capabilities when they change;
these are observed limitations of this run, not permanent limits of SketchUp or every controller.
[Host behavior](SKETCHUP_HOST_BEHAVIOR.md) owns measured API facts. The
[native acceptance skill](../.agents/skills/ph-composer-native-acceptance/SKILL.md) owns execution.

| Claim/action | Preferred control and evidence | Limit or fallback |
| --- | --- | --- |
| Model/session, edit path, records and actual references | Development bridge readback; product mutations through public operations | Read after action in a separate call. An eval sleep prevents host timers from running. |
| Native Undo/Redo, menus, keyboard and dialog behavior | Available native controller; compare records before/after through bridge | Bridge-triggered menu actions are asynchronous; callbacks called directly are offline simulation. |
| Overlay/HUD, occlusion, hatch, hover and visual layout | Real window capture and native interaction | Bridge `shot` uses `View#write_image`, which omits overlay/tool/HUD drawing. |
| Floating Overlays inspector | Fresh native snapshot, target the actual inspector and verify overlay enabled state | This inspector was inconsistently exposed/clickable. After one refreshed targeting attempt still fails, ask for one checkbox action, then machine readback. No repeated coordinate guessing. |
| Hold mouse while switching Model or edit context | Separate button-down/up controls if supported by the current controller | The run's drag API completed in one call. Human holds/releases while the bridge traces the transition. Do not replace the gesture with manually invoked callbacks and call it native proof. |
| Pending export plus Model/panel/runtime loss | Read task stage before triggering loss; later session/file readback | Use an explicit tools-only runtime delay when ordinary completion is too fast. Remove it in a fresh normal process afterward. |
| Destination selection | Native Save dialog navigation followed by actual path readback | An entered full path became a colon filename in Documents in this run. Use the dialog's folder navigation; do not assume the requested directory was selected. |
| Missing/blank window | Refresh current surface and check active Space/document | A missing capture is not proof of a failed panel. Bridge state may remain available. |
| Window-bounded capture and menu labels | Current native computer-use controller: bind SketchUp, capture its window, read fresh accessibility state and invoke the observed menu item | Window screenshots and native menu targeting worked on 2026-10-01 for SketchUp and PH-Composer. The 2026-09-30 capture limitation is historical. `getScreenshot` returned pixels; an AX-plus-screenshot call did not consistently include pixels. Use the explicit screenshot call when needed. Never capture the full screen. |
| Escape inside the panel | The background controller's `app_key escape` on the panel window, with the bridge reading the Model before and after | On 2026-10-04 (ZT-07) background Escape reached the web view and drove its Escape layers. On 2026-10-03 a synthesized Escape did not, while Backspace, Enter and letters did; if it fails again, ask for one physical keypress. |
| Panel clicks and Edit > Undo | SketchUp frontmost under full-screen control, with the model window clicked before the Edit menu | Under background control, clicks stopped reaching the panel after a few interactions and Undo stayed disabled (2026-10-03). Undo reads "Undo <operation>" only while the model window is key. `Sketchup.send_action("editUndo:")` did nothing while SketchUp was in the background. |
| Fresh process / install | Existing hostkit launch and build/install workflow | Inspect all open documents first. `launch` quits the host and may kill it after timeout; a scratch save does not authorize discarding unrelated work. |

A human handoff names one action, its starting state, when to release/stop, the expected visible cue,
and the observation needed. Activate the document before a held gesture; verify tool/edit path and
target through current native state plus bridge readback. In the Phase 2 run, coordinate targeting
failed while accessibility window activation worked. A dotted Group boundary indicated entry into
an edit context; no confirmation dialog was expected. Test actual probe callbacks and evidence
writing before asking for a hold/release. See the [run procedure](../tools/hostkit/ACCEPTANCE_RUN.md).
Tools should collect console/state/results themselves. Human confirmation establishes only the
reported observation; bridge readback supplies the corresponding Model/task assertion.

## Capability changes and restoration

If a new controller can hold a button across calls or reliably address floating windows, verify it
with a harmless synthetic case and update this reference. Do not require human help by habit.
After development provider/fault overrides, restart the normal installed extension, verify no
helper override/live runtime remains, and record the normal build's expected behavior.

Sources: [Phase 2 groundwork observations](../planning/archive/phase-02-envelope/evidence/p2-01-groundwork.md),
[Colour-by toggle continuation](../planning/archive/phase-01-faces-and-zones/evidence/p1-d-colour-by-continuation.md),
[held gesture/context continuation](../planning/archive/phase-01-faces-and-zones/evidence/p1-d-keyboard-context.md),
[export lifecycle and restoration](../planning/archive/phase-01-faces-and-zones/evidence/p1-e-export-workflow.md),
[R06 rerun](../planning/native-acceptance/evidence/r06-rerun-2026-09-30.md),
[Library product tabs](../planning/native-acceptance/evidence/library-product-tab-headers-2026-10-03.md).
