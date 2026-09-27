# P1-D D7 host gate: the three runs that remain

DATE: 2026-09-26
STATUS: Executed 2026-09-26. Retained as the historical procedure. Results and fixes are in
[evidence/p1-d-overview.md](evidence/p1-d-overview.md); current remaining gates are in
[ACCEPTANCE.md](ACCEPTANCE.md).
ISSUE: none (local implementation packet)

The continuation completed the remaining questions and implemented the fixes under Ed's
2026-09-26 authorization. The instructions below describe the pre-fix state.
Q5's premise was wrong: the accepted contract is Off at rest, with the remembered mode used
when Classify starts. The broken preference did not prevent extension or panel startup.

## What you are driving

PH-Composer is a SketchUp extension. Its panel is an `HtmlDialog`, and **nothing in the Ruby API
can click one** — that is the whole reason this gate needs an operator. Ruby reads the Model back
and says what the panel's commands did to it; the clicking is yours.

Three windows matter: the SketchUp model window, the `PH-Composer` panel window, and your
terminal for the bridge.

## Setup

Run everything from the repo root,
`/Users/em/Dropbox/bldgtyp-00/00_PH_Tools/ph-composer`.

The bridge client is invoked as `uv run tools/hostkit/host_bridge.py <subcommand>`. If your shell
is zsh, do not hold that in a variable — zsh will not word-split it. Write a wrapper instead:

```sh
printf '#!/bin/sh\ncd /Users/em/Dropbox/bldgtyp-00/00_PH_Tools/ph-composer\nexec uv run tools/hostkit/host_bridge.py "$@"\n' > /tmp/b
chmod +x /tmp/b
```

Subcommands you will need: `state`, `eval '<ruby>'`, `save`, `console --tail 40`, `quit`,
`launch <model.skp> [--fresh-from <template.skp>]`. `eval` prints captured stdout then the
result as JSON, exits 1 on a Ruby error and 2 when the bridge is unreachable.

**If SketchUp is still running from the session that wrote this file**, the Q7 state below is
already set up and live — go straight to Q7 and do not save, relaunch or touch the panel first.
Check with `/tmp/b state`.

**If you are starting cold:**

```sh
make install
make bridge-install
/tmp/b launch _private/host/p1d-overview.skp --fresh-from _private/host/blank-template.skp
/tmp/b eval 'load "/Users/em/Dropbox/bldgtyp-00/00_PH_Tools/ph-composer/tools/examples/authoring/overview_walkthrough.rb"; OverviewWalkthrough.setup'
/tmp/b eval 'PhComposer::Panel.show'
```

`setup` builds two Zones, `Living` and `Attic`, six Faces each, the first four of each
classified. It returns a report; expect `"zones": ["Living","Attic"], "classified": 8,
"unclassified": 4`.

### The snapshot counter

Q8 was measured by counting snapshot publishes, because reading `refresh.pending?` is a race
against a coalesced timer. The counter is a session-only alias that dies with the process, so
**reinstall it after any relaunch**. It is deliberately not committed to the repo.

```sh
/tmp/b eval '
$phc_snap = 0
module PhComposer
  module Panel
    class << self
      unless method_defined?(:publish_snapshot_orig)
        alias_method :publish_snapshot_orig, :publish_snapshot
        def publish_snapshot(session); $phc_snap += 1; publish_snapshot_orig(session); end
      end
    end
  end
end
$phc_snap'
```

Read it with `/tmp/b eval '$phc_snap'`, reset with `/tmp/b eval '$phc_snap = 0'`.

### Reading state back

This one line answers most questions at once:

```sh
/tmp/b eval 's = PhComposer::Sessions.current; t = PhComposer::FaceAssignment.classify_tool(s); svc = PhComposer::ColourBy.for(s); {"snapshots" => $phc_snap, "revision" => s.revision, "selected" => Sketchup.active_model.selection.length, "depth" => (Sketchup.active_model.active_path || []).length, "tool_active" => t.active?, "active_tool" => Sketchup.active_model.tools.active_tool_name, "palette" => t.palette, "mode" => svc.mode_name, "isolated" => svc.isolated, "remembered" => PhComposer::Preferences.colour_by_mode}'
```

`OverviewWalkthrough.report` gives a fuller picture including per-state Face counts. After
anything unexpected, `/tmp/b console --tail 40` shows what the Ruby Console saw.

---

## Q7. Does a chip edit refuse cleanly when the Model changed underneath?

**What it is really asking.** The panel holds a revision and the values it last saw. An edit
sends those as its expectation. If the Model moved on, the edit must refuse — and the row must
then settle on **what the Model holds**, not on what the user picked. The failure modes worth
catching are a silent refusal, and a row that keeps showing the rejected value.

**The setup is already live** if SketchUp has not been restarted: `Living → Wall 1` is `Ground`
in the Model while the panel still shows `Outdoors`, and the refresh was cancelled so nothing
healed it.

To recreate it from scratch, in one `eval` — the `refresh.cancel` at the end is the point, since
without it the change publishes a fresh snapshot and the row heals before you can click:

```sh
/tmp/b eval '
s = PhComposer::Sessions.current
c = OverviewWalkthrough::Client.new
f = c.query("ph_composer.face_assignment.list").fetch("value").fetch("faces").find { |x| x["state"] == "classified" }
c.invoke("ph_composer.face_assignment.classify",
         {"faces" => [f.fetch("reference")],
          "intent" => {"boundary_condition" => {"mode" => "set", "value" => "Ground"}},
          "expected_values" => f.fetch("values")})
s.refresh.cancel
{"stale_row" => f["reference"], "was" => f["values"], "now" => "Ground", "pending" => s.refresh.pending?}'
```

**Do:** on the `Living → Wall 1` row, open the **Boundary** dropdown and choose **To neighbour**.

**Record:** whether a refusal message appeared and what it said; what the row's Boundary cell
shows once things settle; and the state read-back. Then republish and confirm the row shows
`Ground`:

```sh
/tmp/b eval 'PhComposer::Panel.send(:publish_snapshot, PhComposer::Sessions.current); "published"'
```

`CoalescedTimer` has only `schedule`, `cancel` and `pending?` — there is no `run` to call.

**Pass:** a visible refusal, and the row ends on `Ground`.

---

## Q1. What does the screen cost to paint?

**Read the brief's version critically.** As written it measures the wrong thing. `crowd(500)`
leaves every Face unclassified, and `overview.js` only emits Face rows for Faces whose state is
not `unclassified` — so after `crowd` the table shows **one Zone row and a "500 unclassified"
marker, and no child rows at all**. The Ruby snapshot cost would rise and the row painting, which
is the thing nothing has measured, would stay unmeasured. Classify the crowd first.

```sh
/tmp/b eval 'OverviewWalkthrough.read_cost'          # baseline, expect ~3-8 ms at 12 Faces
/tmp/b eval 'OverviewWalkthrough.crowd(500)'         # one Zone, 500 unclassified Faces
```

Then classify them. **One call will not do it:** `check_limit!` refuses a gesture over
`GESTURE_FACE_LIMIT`, which is **250**, with `gesture.too_large`. Chunk it:

```sh
/tmp/b eval '
c = OverviewWalkthrough::Client.new
refs = c.query("ph_composer.face_assignment.list").fetch("value").fetch("faces")
        .select { |f| f["values"].empty? }.map { |f| f.fetch("reference") }
refs.each_slice(200) do |slice|
  c.invoke("ph_composer.face_assignment.classify",
           {"faces" => slice,
            "intent" => {"face_type" => {"mode" => "set", "value" => "Wall"},
                         "boundary_condition" => {"mode" => "set", "value" => "Outdoors"}},
            "expected_values" => {}})
end
OverviewWalkthrough.report'
```

```sh
/tmp/b eval 'OverviewWalkthrough.read_cost'          # after, expect ~512 Faces
```

**Record two numbers, separately, and do not conflate them:**

1. **The Ruby snapshot cost**, from `read_cost`. That is the host side.
2. **The panel paint**, which is the JavaScript side and the part at issue. There is no
   instrumentation for it and **none should be added to the repo for this gate**. Observe it: how
   long between the table going stale and the rows appearing, whether scrolling is smooth,
   whether the Colour by dropdown and the chips still respond while the table is large. If the
   panel's own devtools are reachable, a timing there is better than a stopwatch — say which you
   used.

**Also do,** with the large Model loaded, because these are the interactions that get slow first:

- Turn Colour by to **Face type** and time the first paint.
- Click **Show only this** on a row and watch for lag.
- Type into the table's **Filter** box and see whether it keeps up with typing.
- Expand and collapse the 512-row Zone.

**What the answer decides.** Hover-to-highlight, the fourth legend affordance in PRD Q18, was
deliberately not built: it would send one view command per pointer move and rebuild the drawing
each time. Ed chose on 2026-09-20 to measure before shipping it. These numbers are what that
decision waits on, so say plainly whether one command-and-repaint per pointer move looks
affordable at this size.

---

## Q5 (restart half). Does the remembered mode survive, and does it come back safely?

The panel half passed: switching mode from the panel leaves the same state as the native
`Extensions → PH-Composer → Colour by` menu, and the menu's checkmark tracks the active mode.

What is left is the restart, and **F5 makes it pointed**. `ColourBy#activate` writes the
remembered preference *before* it rebuilds, so a mode that crashes — and per F4 all three
Zone-kind modes crash on any real Group — can be written to the preference and then reloaded on
the next launch. Two runs:

**Run A, the safe mode.**

1. Set Colour by to **Face type** from the panel.
2. `/tmp/b save`
3. `/tmp/b quit`, then `launch` the same model again and reinstall the counter.
4. Open the panel. Record: is Face type active, is the legend populated, does the model paint,
   and what does `remembered` read?

**Run B, the poisoned mode.** Do this one second, and expect it to be ugly.

1. `/tmp/b eval 'PhComposer::Preferences.set("colour_by_mode", "ph_composer.zones.by_building_segment")'`
   — or reach the same place through the UI by choosing **Building-Segment**, which is how a user
   would. There is no `colour_by_mode=` writer; `set` is the only route, and it refuses `nil`.
2. `quit`, `launch`, open the panel.
3. Record: does the extension load, does the panel open, does anything say the remembered mode
   failed, and can the user get back to a working mode without editing preferences by hand.

**Pass for B** is not "it works" — F4 guarantees it will not paint. Pass is that the failure is
survivable and legible: the panel opens, the user is told, and Off or another mode is reachable.
Note exactly where it falls short, because that shapes the F5 fix.

Afterwards, clear the preference. It is user-wide, so a stuck one follows Ed into his other
SketchUp work, and `Preferences.set` will not take `nil` — write the default directly:

```sh
/tmp/b eval 'Sketchup.write_default("ph_composer", "colour_by_mode", nil); PhComposer::Preferences.colour_by_mode'
```

**If the extension will not load at all** and the bridge cannot reach `PhComposer`, the same
write still works, because `Sketchup.write_default` is the host's own:
`/tmp/b eval 'Sketchup.write_default("ph_composer", "colour_by_mode", nil)'`.

---

## One reproduction attempt: F7

F7 is a single unreproduced instance in which clicking a face-type chip recorded the palette but
left SketchUp's Select tool active, so the next viewport click classified nothing. It did not
reproduce in two later attempts.

Try the sequence five or six times, varying the timing, and watch for one that fails:

1. `/tmp/b eval 't = PhComposer::FaceAssignment.classify_tool(PhComposer::Sessions.current); t.stop; t.choose("face_type", nil); t.stop; $phc_snap = 0'`
2. Click a legend row's **Show only this** or **Show all**.
3. **Immediately** click a face-type chip, with no pause.
4. Read back `tool_active` and `active_tool`.

`tool_active: false` with `active_tool: "SelectionTool"` is the failure. If it reproduces, say
what preceded it and how fast the two clicks were; that is the whole value of the attempt. If six
tries stay clean, say so and leave F7 as recorded.

---

## How to report

Append to [evidence/p1-d-overview.md](evidence/p1-d-overview.md), keeping its register: what was
observed, on which host, with the numbers. For each new finding give the symptom, the smallest
reproduction, and the file and line if you traced it — but **trace only as far as the evidence
carries**. F7 in that file is the model for something that happened once and has no confirmed
cause: record it as that, rather than supplying a plausible one.

Update the result table at the top for Q1, Q5 and Q7, and change the file's `STATUS:` line once
all three are answered.

Historical instruction superseded by Ed's 2026-09-26 request to patch and verify the findings.
