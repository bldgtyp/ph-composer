# Zone and face authoring walkthrough

This development-only walkthrough exercises the first Phase 1 building features through
`PhComposer::API` while the panel is closed. It creates two synthetic box Groups, makes each a
Zone, edits Zone details, classifies one Face in each Zone, and reads the persisted values back.
It uses only public discovery, query, preview and invoke contracts after creating the geometry.

Run it in a fresh scratch Model through the development bridge:

```sh
uv run tools/hostkit/host_bridge.py eval \
  'load "/absolute/path/to/ph-composer/tools/examples/authoring/walkthrough.rb"; AuthoringWalkthrough.setup'
uv run tools/hostkit/host_bridge.py eval 'AuthoringWalkthrough.run'
uv run tools/hostkit/host_bridge.py eval 'AuthoringWalkthrough.undo'
uv run tools/hostkit/host_bridge.py eval 'AuthoringWalkthrough.verify'
uv run tools/hostkit/host_bridge.py eval 'AuthoringWalkthrough.redo'
uv run tools/hostkit/host_bridge.py eval 'AuthoringWalkthrough.verify'
uv run tools/hostkit/host_bridge.py save
```

After reopening the saved Model, load the script and run `AuthoringWalkthrough.verify`. The result
reports the Zone and classified-Face counts, the canonical Zone values, occurrence paths and the
agreement between each Face record and its Zone membership stamp. The fixture contains no
licensed or project data and is never included in the RBZ.

## P1-D repairs: identity repair and limited Restore Zone

`repair_walkthrough.rb` covers the two explicit Zone repairs. Run it in a fresh scratch Model:

```sh
uv run tools/hostkit/host_bridge.py eval \
  'load "/absolute/path/to/ph-composer/tools/examples/authoring/repair_walkthrough.rb"; RepairWalkthrough.setup'
uv run tools/hostkit/host_bridge.py eval 'RepairWalkthrough.copy_shared'
uv run tools/hostkit/host_bridge.py eval 'RepairWalkthrough.repair_copy'
```

`copy_shared` adds a component instance over the source Zone's definition. Repair must refuse it
with `target.shared_definition`, because shared storage cannot be given an identity of its own.

The independent copy is the case repair exists for, and how SketchUp makes one is what this
walkthrough is measuring rather than assuming. Select the source Zone in the viewport, Ctrl-drag a
copy clear of the original, then:

```sh
uv run tools/hostkit/host_bridge.py eval 'RepairWalkthrough.adopt_copy'
uv run tools/hostkit/host_bridge.py eval 'RepairWalkthrough.repair_copy'
```

`adopt_copy` reports `copy_has_own_zone_record` and `copy_shares_definition`. Record both: they are
the host evidence A06 wants for copy references, and they decide which branch repair takes.
After repair, `duplicate_zone_ids` is empty, both `zone_states` read `found`, and no Face id appears
twice.

Then explode and restore:

```sh
uv run tools/hostkit/host_bridge.py eval 'RepairWalkthrough.explode_source'
uv run tools/hostkit/host_bridge.py eval 'RepairWalkthrough.restore_source'
uv run tools/hostkit/host_bridge.py eval 'RepairWalkthrough.undo'
uv run tools/hostkit/host_bridge.py eval 'RepairWalkthrough.redo_last'
uv run tools/hostkit/host_bridge.py save
```

`explode_source` should leave the stamped Faces in the parent context with their payloads, which is
what makes a limited Restore possible; `restorable` then names the exploded Zone id and its member
count. `restore_source` reports `unrecoverable`: the Zone name, ground depth and Group metadata are
not recovered, and the restored Zone takes a fresh default name. Reopen the saved Model and run
`RepairWalkthrough.verify` to confirm nothing became current across save and reopen.

## P1-D Colour-by: the overlay, its cache and the HUD

`colour_by_walkthrough.rb` is the host gate for A08. B2 measured that a filled overlay is
affordable and correct; this measures the feature built on it, which B2 did not have. Run it in a
fresh scratch Model:

```sh
uv run tools/hostkit/host_bridge.py eval \
  'load "/absolute/path/to/ph-composer/tools/examples/authoring/colour_by_walkthrough.rb"; ColourByWalkthrough.setup'
uv run tools/hostkit/host_bridge.py eval 'ColourByWalkthrough.meshes'
uv run tools/hostkit/host_bridge.py eval 'ColourByWalkthrough.on'
```

`meshes` answers the first question, which the offline suite cannot: the stub fans a Face's outer
loop, so what SketchUp does with the holed wall and with a concave Face is unmeasured. A hole that
survives as a second loop, and a triangle count above the fan's, is the answer the fill needs.

With a mode on, look at the viewport: the HUD legend in the upper left, the fill hidden behind
geometry in front of it, edges showing through, and clicking a filled Face still selecting it.
`fingerprint_before` and `fingerprint_now` must be equal in every field, and the Undo menu must
name no Colour-by entry.

Then the invalidation questions:

```sh
uv run tools/hostkit/host_bridge.py eval 'ColourByWalkthrough.hide_tag'
uv run tools/hostkit/host_bridge.py eval 'ColourByWalkthrough.undo'
uv run tools/hostkit/host_bridge.py eval 'ColourByWalkthrough.redo_last'
uv run tools/hostkit/host_bridge.py eval 'ColourByWalkthrough.cost'
uv run tools/hostkit/host_bridge.py eval 'ColourByWalkthrough.off'
```

`hide_tag` is the one to watch: the tag path assumes `Sketchup::LayersObserver#onLayerChanged`
fires when a tag's visibility is toggled, and nothing has measured that. If `rebuilds` does not
advance, the assumption is wrong and the tag rule needs another route. Toggle a tag by hand in the
Tags panel as well, since a scripted `layer.visible =` and a user's click need not behave alike.
It also reports the revision either side of the toggle: if hiding a tag turns out to be undoable,
the host commits a transaction for it and the revision advances too, which costs a second rebuild
and is worth knowing rather than assuming.

`meshes` reports `triangles_only` alongside the triangle count. The fill flattens every polygon
into one `GL_TRIANGLES` stream, so a polygon of any other arity would draw the wrong shape.

SketchUp's own Overlays panel is a second on/off switch, kept per overlay id. Untick
"PH-Composer Colour by" there while a mode is on and record what happens: the drawing should stop
while the Colour by menu still shows the mode checked, and whether the menu ought to follow that
switch is a question for this gate.

Scene activation is expected to leave the drawing stale, because this session subscribes to no
observer that reports it. Make two scenes with different tag visibility, run `activate_scene` for
each, and record what actually happens; that answer decides whether the scene rule needs a frame
change observer or belongs in a later slice.

Finally switch to another open Model and back, and close the walkthrough Model, confirming the
overlay leaves with it and comes back with it.
