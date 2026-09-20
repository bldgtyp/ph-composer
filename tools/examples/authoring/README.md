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
