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
