# Library product tabs, host look, 2026-10-03

The host look owed by [library-product-tab-headers](../../features/unscheduled/library-product-tab-headers/PLAN.md),
issue #38, PR #46. Ledger case `PTAB`.

## Conditions

- SketchUp 26.1.188, Ruby 3.2.2, macOS. Development bridge for launch, panel sizing and readback
  through `PhComposer::API` queries; the panel and the Edit menu driven through the native window
  controller with SketchUp frontmost; one Escape keypress by Ed.
- Build A: `dist/ph_composer.rbz` from `feat/library-product-tab-headers` at `d3a30a2`, SHA256
  `77e5133d…49a4`. Build B: the same branch after the fix below (`fe80410`), SHA256 `a3d9f7be…aaeb`.
  For each build the package comparison against the installed Plugins folder matches with no extra
  files, and SketchUp was launched fresh.
- Fixture (gitignored `_private/host/ptab/ptab.skp`): a copy of `hgui.skp` (`166a5556…d225`), one
  Frame, one Glazing and one Psi-Install Type; Model defaults unset, install depth 0 m.
- Panel sized through `HtmlDialog#set_size` to 1280 by 900 and 420 by 900.

## Results

| # | Check | Build | Result | Observation |
| --- | --- | --- | --- | --- |
| 1 | Frames tab layout, 1280 px | A | pass | "+ New Frame" sits in the Library heading beside Export library; the tab body opens with the action bar; no second title. |
| 2 | Create a Frame from the heading button | A | pass | The Create Frame form opened; "Host frame" created; readback two Frames, revision 1 to 2. |
| 3 | Frame create is one Undo step | A | pass | Edit menu read "Undo Create Frame"; one Undo left only the fixture Frame and the Model unmodified; Redo restored the same id `frm_pYuemGhB8jwO`. |
| 4 | Install depth bubble | A | pass | Bubble headed "Default install depth" holding the unit field alone. "abc" with Enter kept it open with "Enter a length, for example 1200, 1' 6" or 1.2 m."; "120 mm" with Enter closed it, the trigger read "Install depth: 0.12 m" with focus on it; readback 0.12 m, one write. |
| 5 | Default Psi-Install choice | A | pass | Choosing "R11 install" closed the list and applied at once; readback `default_psi_install_id` set, depth unchanged, one write. |
| 6 | Each default change is one Undo step | A | pass | Edit menu read "Undo Change Window Defaults" twice: the first Undo cleared only the Psi-Install default, the second only the depth; the panel repainted to "None" and "0 m". |
| 7 | Current choice marked at rest | A | fail, fixed | The open list showed "None" unmarked until focused: the at-rest teal rule in `base.css` matched only dimension-format buttons. |
| 7 | Current choice marked at rest | B | pass | "None" shows teal tint, teal text and border at rest. |
| 8 | 420 px | A | pass | Heading on one line; both defaults on one row below the view controls; the depth bubble fits inside the panel. |
| 9 | Escape restores and closes | A | pass | Ed pressed Escape with an "abc" draft: the bubble closed, the trigger still read "0 m"; an injected keydown logger recorded `Escape` on the input; readback unchanged, revision unchanged. |

## Observations, not failures

- At 1280 px the defaults wrap as a group to a second, right-aligned line when the Psi-Install
  Library sidebar is expanded; with it collapsed the whole action bar fits one line. The decision
  recorded in the packet stands.
- Escape synthesized by the computer-use controller never reached the panel's web view, on the new
  bubble or on the existing record form; Backspace, Enter and letters did. A physical Escape did.
- Under background control, clicks stopped reaching the panel after a few interactions and Edit >
  Undo stayed disabled; both worked with SketchUp frontmost. The first SketchUp process exited
  during that stretch with no crash report; its scratch edits were lost and all results above come
  from the relaunch.

## Restoration

SketchUp quit cleanly through the bridge after build B's check. The fixture is a scratch copy;
nothing was saved over a source fixture. The keydown and focus loggers were development eval
injected into the panel page and ended with the process. Raw captures are in gitignored
`_private/host/ptab/`.
