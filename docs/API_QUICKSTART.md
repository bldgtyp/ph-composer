# API quickstart

DATE: 2026-09-30
STATUS: Implemented on the Phase 1 branch for in-process Ruby clients. No external connection is
supported yet; see [AGENT_ACCESS.md](AGENT_ACCESS.md).

This walks one session from discovery to a verified edit using only the public interface. Every
operation name, params schema and result schema it uses is in the generated
[API_REFERENCE.md](API_REFERENCE.md), and `PhComposer::API.describe(name:)` answers the same at
run time. A client needs nothing else: no feature module, store or dictionary name.

The offline suite runs these steps as written (`tests/api_client_test.rb`).

## 1. Find the Model and connect

```ruby
found = PhComposer::API.discover
session = found["sessions"].find { |row| row["active"] }
context = PhComposer::API.connect(session_id: session["id"], capabilities: %w[read view model_write export])
```

Ask only for the grants you need; `export` is required for step 7 alone.

`discover` lists the registered queries, actions, view commands and record kinds by name.
`describe` returns one of them in full:

```ruby
PhComposer::API.describe(name: "ph_composer.zones.make")        # params, result, an example
PhComposer::API.describe(name: "ph_composer.zones.faces.face")  # values, references, occurrence
```

## 2. Make a Zone from the selection

The Zones read offers the params Make Zone takes for whatever the user has selected, or null.
Preview first; the preview's digest makes the invoke refuse if the change would now differ.

```ruby
zones = PhComposer::API.query(context: context, name: "ph_composer.zones.list")
target = zones["value"]["make_zone"]
preview = PhComposer::API.preview(context: context, name: "ph_composer.zones.make", params: target)
made = PhComposer::API.invoke(context: context, name: "ph_composer.zones.make", params: target,
                              request: { "sequence" => 1, "expected_revision" => zones["revision"],
                                         "proposal_digest" => preview["proposal_digest"] })
made["affected"]  # the Zone written, with its kind, id and change
```

`sequence` counts this caller's writes from 1. `expected_revision` is the revision of the read the
write is based on; the result's `revision` is the one to use next.

## 3. Read the Zone's Faces and classify one

A Face is named by an occurrence reference, never by its SketchUp id alone. Send the values you read
as `expected_values`, so a Face that changed in the meantime refuses rather than being overwritten.

```ruby
faces = PhComposer::API.query(context: context, name: "ph_composer.zones.faces.list")
face = faces["value"]["faces"].first
classified = PhComposer::API.invoke(
  context: context, name: "ph_composer.zones.faces.classify",
  params: { "faces" => [face["reference"]], "expected_values" => face["values"],
            "intent" => { "face_type" => { "mode" => "set", "value" => "Wall" },
                          "boundary_condition" => { "mode" => "set", "value" => "Outdoors" } } },
  request: { "sequence" => 2, "expected_revision" => faces["revision"] }
)
classified["affected"].first["reference"]  # the Face occurrence, now with its record id
```

## 4. Preview and edit the Zone

```ruby
zone = PhComposer::API.query(context: context, name: "ph_composer.zones.list")["value"]["zones"].first
edit = { "reference" => zone["reference"], "expected_values" => zone["values"],
         "values" => zone["values"].merge("level" => "L1") }
preview = PhComposer::API.preview(context: context, name: "ph_composer.zones.update", params: edit)
updated = PhComposer::API.invoke(context: context, name: "ph_composer.zones.update", params: edit,
                                 request: { "sequence" => 3, "expected_revision" => classified["revision"],
                                            "proposal_digest" => preview["proposal_digest"] })
```

Read the Zone again and compare its `values` with what you sent; `updated["affected"]` names the
Zone.

## 5. Recover from a stale revision

A write based on an old read refuses with `revision.stale` and changes nothing. Read again, rebuild
the params from what you now see, and send them under the next sequence.

```ruby
stale = PhComposer::API.invoke(context: context, name: "ph_composer.zones.update", params: edit,
                               request: { "sequence" => 4, "expected_revision" => zones["revision"] })
stale["code"]    # "revision.stale"
stale["effect"]  # "none"
```

## 6. Retry after a lost response

If a response never arrives, send the same request again with the same sequence. The first outcome
comes back and nothing is written twice. `PhComposer::API.outcome(context:, request: { "sequence" => n })`
answers the same without resending. A request refused as `request.malformed` never took its
sequence, so the corrected request may reuse it.

## 7. Read in pages, and export

Every list read answers one page. Name the values you need and pass `next_cursor` back for the next
page; a cursor only answers the same query and filter at the same revision.

```ruby
page = PhComposer::API.query(context: context, name: "ph_composer.zones.faces.list",
                             params: { "fields" => ["face_type", "boundary_condition"], "limit" => 100 })
page["value"]["faces"]        # reference and the two values, nothing else
page["value"]["next_cursor"]  # nil on the last page
```

Export is a task, not a Model change. Preflight shows what blocks it; start writes to an explicit
destination and never replaces an existing pair unless you pass `replace: true`; poll until the
status carries an outcome.

```ruby
PhComposer::API.export_preflight(context: context)["value"]["findings"]
task = PhComposer::API.start_export(context: context, destination: "/path/to/model.hbjson")["value"]
status = PhComposer::API.export_status(context: context, task_id: task["task_id"])["value"]
status["outcome"]             # nil while running; then completed, refused, failed or cancelled
PhComposer::API.latest_export(context: context)
```

Until authored Assemblies arrive, the normal build refuses the export as `export.blocked`, naming
each Face without a construction in the preflight findings.
