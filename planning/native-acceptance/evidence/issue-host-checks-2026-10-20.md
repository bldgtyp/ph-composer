# Issue host checks, 2026-10-20

Host measurements Ed asked for on 2026-10-20 for open and recently merged issues. They are investigations and
rechecks, not ledgered acceptance cases: no `acceptance_case.py begin` baseline was taken, so nothing here is a
ledger Pass.

- **Host:** SketchUp 26.1.188, macOS, Ruby 3.2.2.
- **Build:** installed RBZ from `origin/main` 72251bd1, built in a detached worktree; SHA-256 prefix 06ce79efc38168f1.
- **Bridge:** installed from the same worktree.
- **Fixture:** `_private/host/hostchecks-2026-10-21/a.skp`, a fresh copy of `_private/host/blank-template.skp`.
- **Bridge setup:** the authoring walkthrough built two Zones and `SpacesWalkthrough.run` built a Space with
  Volumes. Groups, components and explodes for the checks below were made through the bridge and are labelled as
  setup.
- **Native steps:** System Events (menus, window raise, keystrokes) and background computer use.

## #233: `active_path=` into a hidden Group

| Path set | Starting from | Result |
| --- | --- | --- |
| `[hidden]` | root | accepted, path `[hidden]` |
| `[hidden at root]` | inside `outer > inner` | accepted |
| `[outer, hidden child]` | inside `outer > inner` | accepted |
| `[hidden ancestor, visible child]` | root | accepted |

SketchUp does not refuse a hidden step, so no `hidden?` refusal is needed in `ContextCommands.resolve`. The fact
is recorded in `context/SKETCHUP_HOST_BEHAVIOR.md`.

## #239: capture window states

Not re-measured. Stage 16 (`planning/archive/phase-03a1/evidence/p3a1-16-integrated-acceptance.md`, "Capture
window states") already captured the current view correctly in four states: behind another app, hidden,
minimized, and minimized with the camera moved. By the issue's own plan, that means dropping `window_state`. The
receipt left the change for Ed's call.

## #174: the active Model closes

Setup: two documents, `a.skp` and Untitled, with the panel open. Probes logged every AppObserver callback, a
ModelObserver on each Model, and each `panel.snapshot` the panel published.

1. Raising Untitled fired `onActivateModel`, and the panel published Untitled's snapshot.
2. Closing Untitled through its window's close button:
   - fired no callback at all: no `onActivateModel`, and no `onDeleteModel` on the probed Model;
   - left `Sketchup.active_model` reading `nil` and `Sessions.current` empty;
   - published no new snapshot, so the panel still shows the closed session.
3. A panel `action.invoke` and a `view.invoke` for the closed session were refused `session.inactive`, and
   nothing was written. Both messages say "The panel now shows a different Model", which is untrue: the panel
   still shows the closed one.

The issue reproduces. A fix cannot wait for a close callback, because none exists. It has to act on the next
thing the panel hears, such as a request or a window focus, when no current session remains.

## #231: Undo after leaving an unprotected Volume

1. `spaces.volumes.unprotect`, then `ph_composer.context.open` to the Volume: the path ends at the Volume, which
   is unlocked.
2. `ph_composer.context.root`: the path is root and the Volume is locked again.
3. Native Undo (`Sketchup.undo`, SketchUp frontmost): the path is back in the Volume, which is **still locked**.
   The Edit menu then offers "Undo Open".
4. A second Undo: the path is root and the Volume is still locked. The Edit menu then offers "Undo Unprotect
   Volume".

Cause: `Protection.protect` locks in a transparent operation. That joins the previous **Ruby** operation, not
SketchUp's own "Close" entry, so undoing the navigation never reverses the lock. Ed still has to decide whether
an Undo into the Volume should restore the unprotected state or close the context again.

## #168: Cmd+Z in the panel (merged in #268)

Setup: one public `spaces.update` set `v_tran_m3h` to 33. A development probe recorded `PanelHistory.step`
calls.

| Input | Handler | Result | Exactly one step |
| --- | --- | --- | --- |
| Background raw-input Cmd+Z to the panel | `panel.undo` | 33 to unset | yes: one Redo restored 33 |
| Background raw-input Cmd+Shift+Z | `panel.redo` | unset to 33 | yes |
| Foreground keystroke Cmd+Z, panel key window | `panel.undo` | 33 to unset | yes: one Redo restored 33 |

macOS delivers the shortcut to the page, and SketchUp's menu key-equivalent does not also fire.

## ZO-O7: a Zone made into a component (#182, merged in #267)

1. Native Edit > Make Component… on the Zone Group "east", then Create:
   - the Group became ComponentInstance 49072;
   - `zones.all` completed, listing "West Zone";
   - `zone.component` was reported on `[49072]` with the new message;
   - export preflight blocked on `zone.component`;
   - the panel showed "1 Zone" with the amber finding line under the table (screenshot
     `_private/host/hostchecks-2026-10-21/zo-o7-component-finding.jpg`).
2. Exploding it (bridge setup): Restore was offered for the Zone with 7 members and no refusal, and its
   unrecoverable fields were the ones the message names.

## ZO-O7: remedies named by Make Zone independent (#181, merged in #275)

1. A Zone inside a component placed twice (bridge setup) was refused with "Explode that component first".
2. After exploding the second placement, Make Zone independent answered `zone.identity_unique`. Exploding was
   enough, as the issue observed.
3. A Zone inside a copied parent Group (bridge setup) was refused with "Open that Group with Edit Group, or
   double-click it, then close it, then try again".
4. Native Edit > Group > Edit Group on the copy gave it its own definition, and Close Group/Component returned to
   the root. Make Zone independent then completed and committed.

## Findings outside the issues

- The authoring walkthrough's `verify` requires exactly 2 classified Faces. On the host, Make Zone's
  suggest-on-make classifies all 12 box Faces, so it reports `passed: false` even though the Zone edit applied.
  This predates #176.
- Mid-run, the bridge's state file `ph_composer_host_bridge.json` disappeared while the bridge kept listening
  inside SketchUp. Another session was running the gate in the shared checkout at the time; the cause is
  unconfirmed. Recovered by having the running bridge rewrite the file from SketchUp's Ruby Console.
- The panel HtmlDialog captured blank while SketchUp was in the background, though its page had reported ready
  and kept receiving snapshots. A foreground capture showed it correctly.

## Teardown

`host_bridge.py quit` closed the one document and SketchUp quit cleanly. No tokens, approved locations or
preferences were written. No stray saves were left in `~/Documents`.
