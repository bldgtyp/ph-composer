# D3a-19 evidence: a save leaves the user in the open Volume

DATE: 2026-10-16
STATUS: Implemented on branch `feature/spaces-save-keeps-volume-d3a-19`; host-checked through the bridge
AUTHOR: Ed May, BLDGTYP, with Claude
ISSUE: [#133](https://github.com/bldgtyp/ph-composer/issues/133)

Ed's answer to [D3a-19](../DECISIONS.md), B3 after a host spike. Raw notes and probe scripts are in
`_private/host/spaces/d3a19/`.

## Spike

SketchUp 26.1.188, macOS 26.6.2, the build from `main` at `f9104523` with a development probe; Volume 1 of
Space 101 opened; native Cmd+S unless stated.

| Variant | After the save | Undo after the save | File holds the Volume |
| --- | --- | --- | --- |
| The rule then: lock in `onPreSaveModel`, close in `onSaveModel` | At the Model root; not modified | SketchUp's "Close" | Locked |
| B: also unlock and re-enter in `onSaveModel` | In the Volume, unlocked; modified | SketchUp's "Close", then an "Open" the next Cmd+Z spends leaving the Volume; the re-lock that follows clears Redo | Locked |
| B3: no lock at save | In the Volume, unlocked; modified; nothing written by the extension | SketchUp's "Close" only, and undoing it changes nothing visible | Unlocked |

- The lock in `onPreSaveModel` was what stranded the user: SketchUp does not restore a context with a
  locked Group on its path.
- A save inside any edit context leaves the Model modified and a "Close" on the Undo stack. That is the
  host's behavior, so neither B nor B3 adds it.
- An autosave (interval set to 1 minute for the measurement, restored to 5) fired both callbacks, with
  `Model#path` still the Model's own file, and wrote its copy to SketchUp's `working` folder. Under B3 it
  left the user in the Volume.

Recorded in `context/SKETCHUP_HOST_BEHAVIOR.md`, "Observers and edit contexts".

## Change

- `features/spaces/context/reconciler.rb`: `pre_save` settles pending protection only, so Volumes
  already left are saved protected and the open one is left unlocked; `post_save` is gone; `opened`
  queues protection for every unlocked Volume off the path.
- `features/spaces/declarations/context.rb`: `opened` runs on `session_created` and on the new
  `model_opened`.
- `session/`: `onOpenModel` reports `model_opened` even to a session created before the file loaded.
  `Sessions.open_active` creates the active Model's session after the composition root composes the
  features, so their `session_created` subscribers hear it. Before this, every such subscriber missed
  the first session.
- The stub: a save does not restore a path holding a locked Group, and a save inside a context leaves
  the Model modified.
- `context/TECH_STACK.md` states the save rule; the PRD's line on it is amended.

Tests: `tests/spaces_context_test.rb` (a save leaves the open Volume unlocked and writes nothing; a
pending Volume is still saved protected; `session_created` and `model_opened` protect unlocked Volumes),
`tests/sessions_test.rb` (`model_opened` reaches an existing session; `open_active` creates the session),
`tests/loader_test.rb` (the composition root opens the active session after composing),
`tests/support/sketchup_stub_test.rb` (the two stub rules).

## Host check

The branch RBZ installed with `make install`, through the bridge:
- A save from inside Volume 1 of Space 101 left the path on the Volume, the Volume unlocked and the Model
  modified.
- A fresh-process open of that file left the Volume protected, with no finding and not moved, and the Model
  modified by that write.

The native Cmd+S and autosave rows join the acceptance rerun (P3a-12, decision 1).
