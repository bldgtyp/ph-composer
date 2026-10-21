# frozen_string_literal: true

require_relative "client"

# Native checks of Zone and Face corrections: shared child Groups (R01), a nested Zone path (R02), an
# orphaned Attached zone (R03), a partial Attached zone cut (R04) and a panel-closed API client (R06).
# Each case's methods carry its label. Development only; never shipped.
#
# Geometry setup is development-only. Every product write goes through the public operations with
# the panel closed. The steps a person performs are named in the method that follows them; each
# method returns what it observed, and nothing here asserts on the person's behalf.
module CorrectionsWalkthrough
  API = PhComposer::API
  PREFIX = "pr3_"
  GARAGE = { "name" => "Garage", "kind" => "garage", "temperature_reduction_factor" => 0.95 }.freeze
  ATTIC = { "name" => "Attic", "kind" => "attic", "temperature_reduction_factor" => 0.95 }.freeze

  module_function

  # ---------------------------------------------------------------- R01 shared child Groups

  # One Zone holding a small child Group with one Face. Ed then copies the child natively.
  def r01_setup(fresh: true)
    clear if fresh
    zone = box(Sketchup.active_model.entities, "#{PREFIX}r01", [0, 0, 0], 4000.mm)
    child = zone.entities.add_group
    child.name = "#{PREFIX}r01_child"
    child.entities.add_face([500.mm, 500.mm, 1000.mm], [1500.mm, 500.mm, 1000.mm], [1500.mm, 500.mm, 2000.mm],
                            [500.mm, 500.mm, 2000.mm])
    make_zone(zone)
    { "zone" => zone.persistent_id, "child" => child.persistent_id,
      "next" => "Ed: double-click the Zone, select the small Group inside it, Edit > Copy, " \
                "Edit > Paste In Place, then close the Group." }
  end

  # `placements` is how many child Groups the setup and the native copies left, when the caller knows it.
  def r01_check(placements: nil)
    client = Client.new
    zone = zone_group("#{PREFIX}r01")
    children = zone.entities.grep(Sketchup::Group)
    # Every placement shares one definition, however many copies were pasted. Each `Group#entities` call
    # returns a fresh wrapper, so compare definitions, never wrapper object ids.
    shared = children.length > 1 && children.map(&:definition).uniq.length == 1 &&
             (placements.nil? || children.length == placements)
    rows = client.faces.select { |row|
      row.dig("reference", "zone_path") == [zone.persistent_id] &&
        row.dig("reference", "entity_path").length == 2
    }
    before = [client.revision, children.map { |group| face_record(group.entities.grep(Sketchup::Face).first) }]
    target = rows.first.fetch("reference")
    classify = { "faces" => [target], "expected_values" => {},
                 "intent" => { "face_type" => { "mode" => "set", "value" => "Wall" } } }
    results = [client.preview("ph_composer.zones.faces.classify", classify),
               client.invoke("ph_composer.zones.faces.classify", classify),
               client.preview("ph_composer.zones.faces.reverse", "face" => target),
               client.invoke("ph_composer.zones.faces.reverse", "face" => target)]
    after = [client.revision, children.map { |group| face_record(group.entities.grep(Sketchup::Face).first) }]
    { "child_groups" => children.length, "shared_storage" => shared,
      "occurrences_listed" => rows.map { |row| row.dig("reference", "entity_path") },
      "refusals" => results.map { |result| result.values_at("status", "code", "effect") },
      "message" => results.last["message"], "unchanged" => before == after }
  end

  # ---------------------------------------------------------------- R02 nested Zone path

  # An outer Zone with an ordinary nested Group, and a second Zone at the root that the next two
  # steps move inside it through native Cut and Paste In Place.
  def r02_setup
    clear
    model = Sketchup.active_model
    outer = box(model.entities, "#{PREFIX}r02_outer", [0, 0, 0], 6000.mm)
    plain = outer.entities.add_group
    plain.name = "#{PREFIX}r02_plain"
    plain.entities.add_face([500.mm, 500.mm, 1000.mm], [1500.mm, 500.mm, 1000.mm], [1500.mm, 500.mm, 2000.mm],
                            [500.mm, 500.mm, 2000.mm])
    make_zone(outer)
    inner = box(model.entities, "#{PREFIX}r02_inner", [1000.mm, 1000.mm, 0], 1000.mm)
    make_zone(inner)
    model.selection.clear
    model.selection.add(inner)
    Sketchup.send_action("cut:")
    { "outer" => outer.persistent_id, "next" => "r02_paste" }
  end

  def r02_paste
    model = Sketchup.active_model
    model.active_path = [zone_group("#{PREFIX}r02_outer")]
    Sketchup.send_action("pasteInPlace:")
    { "next" => "r02_check" }
  end

  def r02_check
    model = Sketchup.active_model
    model.active_path = nil
    client = Client.new
    outer = zone_group("#{PREFIX}r02_outer")
    inner = outer.entities.grep(Sketchup::Group).find { |group| PhComposer::Zones::ZONE_STORE.read(group) }
    raise "The pasted Zone is not inside the outer Zone." unless inner

    outer_zone = client.zones.find { |row| row.dig("reference", "zone_path") == [outer.persistent_id] }
    face = inner.entities.grep(Sketchup::Face).first
    crossing = outer_zone.fetch("reference").merge("entity_path" => [inner.persistent_id, face.persistent_id],
                                                   "entity_id" => nil)
    revision = client.revision
    intent = { "face_type" => { "mode" => "set", "value" => "Wall" } }
    classify = client.invoke("ph_composer.zones.faces.classify", "faces" => [crossing], "intent" => intent)
    reverse = client.invoke("ph_composer.zones.faces.reverse", "face" => crossing)
    stamp_after = PhComposer::Zones::STAMP_STORE.read(face)
    plain_row = client.faces.find { |row|
      row.dig("reference", "entity_path").length == 2 &&
        row.dig("reference", "zone_path") == [outer.persistent_id]
    }
    plain = client.invoke("ph_composer.zones.faces.classify",
                          "faces" => [plain_row.fetch("reference")], "expected_values" => plain_row.fetch("values"),
                          "intent" => { "face_type" => { "mode" => "set", "value" => "Wall" },
                                        "boundary_condition" => { "mode" => "set", "value" => "Outdoors" } })
    { "inner_state" => client.zones.map { |row| row["state"] },
      "crossing" => [classify, reverse].map { |result| result.values_at("status", "code", "effect") },
      "inner_face_stamp_zone" => stamp_after && stamp_after["zone_id"],
      "revision_unchanged_by_refusals" => revision == plain.fetch("revision") -
                                                      (plain["effect"] == "committed" ? 1 : 0),
      "ordinary_nested_group" => plain.values_at("status", "effect") }
  end

  # ---------------------------------------------------------------- R03 orphaned Attached zone

  # One Zone whose first two Faces use the Garage, and an Attic to move them to. Ed then explodes
  # the Zone (right-click, Explode) and runs r03_delete.
  def r03_setup(fresh: true)
    clear if fresh
    client = Client.new
    zone = box(Sketchup.active_model.entities, "#{PREFIX}r03", [8000.mm, 0, 0], 4000.mm)
    @r03_zone_id = make_zone(zone).dig("value", "zone_id")
    client.invoke("ph_composer.zones.faces.auto_classify", "zone" => r03_zone(client).fetch("reference"))
    garage = client.invoke("ph_composer.zones.faces.attached_zone.save", "values" => GARAGE).dig("value", "id")
    attic = client.invoke("ph_composer.zones.faces.attached_zone.save", "values" => ATTIC).dig("value", "id")
    r03_faces(client).first(2).each do |row|
      client.invoke("ph_composer.zones.faces.classify",
                    "faces" => [row.fetch("reference")], "expected_values" => row.fetch("values"),
                    "intent" => { "boundary_condition" => { "mode" => "set", "value" => "AttachedZone" },
                                  "attached_zone_id" => { "mode" => "set", "value" => garage } })
    end
    { "garage" => garage, "attic" => attic, "assigned" => assigned(garage).length,
      "next" => "Ed: right-click the Zone and choose Explode, then run r03_delete." }
  end

  # Both replacement modes refuse while any Face outside every Zone still uses the Garage.
  def r03_delete
    client = Client.new
    garage, attic = attached_ids
    revision = client.revision
    results = [{ "mode" => "boundary_condition", "boundary_condition" => "Outdoors" },
               { "mode" => "attached_zone", "attached_zone_id" => attic }].map do |replacement|
      client.invoke("ph_composer.zones.faces.attached_zone.delete", "id" => garage, "replacement" => replacement)
    end
    { "refusals" => results.map { |result| result.values_at("status", "code", "effect") },
      "named_faces" => results.first.dig("detail", "faces")&.length, "message" => results.first["message"],
      "definition_kept" => client.attached_ids.include?(garage), "assignments_kept" => assigned(garage).length,
      "revision_unchanged" => client.revision == revision }
  end

  # After Ed's native Undo and Redo of the explode, Restore Zone brings the Faces back, and the same
  # delete then moves every one.
  def r03_restore_and_delete
    client = Client.new
    garage, = attached_ids
    offer = client.zones_value.fetch("restorable").first
    restored = client.invoke("ph_composer.zones.restore",
                             "parent_path" => offer.fetch("parent_path"), "zone_id" => offer.fetch("zone_id"))
    deleted = client.invoke("ph_composer.zones.faces.attached_zone.delete",
                            "id" => garage,
                            "replacement" => { "mode" => "boundary_condition", "boundary_condition" => "Outdoors" })
    { "restore" => restored.values_at("status", "effect"), "delete" => deleted.values_at("status", "effect"),
      "reassigned" => deleted.dig("value", "reassigned_faces"), "garage_left" => client.attached_ids.include?(garage),
      "next" => "Ed: open the Zone, select one Outdoors wall Face, Edit > Cut, close the Zone, Edit > Paste, " \
                "then run r03_moved after r03_assign_again." }
  end

  # The moved-Face variant: give the Garage back to two Faces before Ed cuts one out of the Zone.
  def r03_assign_again
    client = Client.new
    garage = client.invoke("ph_composer.zones.faces.attached_zone.save", "values" => GARAGE).dig("value", "id")
    r03_faces(client).first(2).each do |row|
      client.invoke("ph_composer.zones.faces.classify",
                    "faces" => [row.fetch("reference")], "expected_values" => row.fetch("values"),
                    "intent" => { "boundary_condition" => { "mode" => "set", "value" => "AttachedZone" },
                                  "attached_zone_id" => { "mode" => "set", "value" => garage } })
    end
    { "garage" => garage, "assigned" => assigned(garage).length,
      "next" => "Ed: open the Zone, select a Garage Face (the first floor or wall), Edit > Cut, close the " \
                "Zone, Edit > Paste at the root, then run r03_delete." }
  end

  # By record id: Restore regroups the Faces under a new Group, so the persistent id does not last.
  def r03_zone(client)
    client.zones.find { |row| row["id"] == @r03_zone_id }
  end

  def r03_faces(client)
    zone = r03_zone(client)
    client.faces.select { |row| zone && row.dig("reference", "zone_path") == zone.dig("reference", "zone_path") }
  end

  # ---------------------------------------------------------------- R04 partial AttachedZone cut

  # Two Zones whose facing walls overlap for half their length. `both` makes both walls AttachedZone.
  def r04_setup(both = false)
    clear
    client = Client.new
    west = box(Sketchup.active_model.entities, "#{PREFIX}r04_west", [0, 0, 0], 4000.mm)
    east = box(Sketchup.active_model.entities, "#{PREFIX}r04_east", [4000.mm, 2000.mm, 0], 4000.mm)
    [west, east].each { |group| make_zone(group) }
    client.zones.each { |zone|
      client.invoke("ph_composer.zones.faces.auto_classify", "zone" => zone.fetch("reference"))
    }
    garage = client.invoke("ph_composer.zones.faces.attached_zone.save", "values" => GARAGE).dig("value", "id")
    walls = facing_walls(client)
    (both ? walls : walls.first(1)).each do |row|
      client.invoke("ph_composer.zones.faces.classify",
                    "faces" => [row.fetch("reference")], "expected_values" => row.fetch("values"),
                    "intent" => { "boundary_condition" => { "mode" => "set", "value" => "AttachedZone" },
                                  "attached_zone_id" => { "mode" => "set", "value" => garage } })
    end
    { "garage" => garage, "attached_walls" => both ? 2 : 1, "next" => "r04_solve" }
  end

  def r04_solve
    client = Client.new
    params = { "zones" => client.zones.map { |zone| zone.fetch("reference") } }
    preview = client.preview("ph_composer.zones.solve_adjacency", params)
    solved = client.invoke("ph_composer.zones.solve_adjacency", params, preview.fetch("proposal_digest"))
    again = client.invoke("ph_composer.zones.solve_adjacency", params)
    r04_verify.merge("solve" => solved.values_at("status", "effect"), "repeat" => again.values_at("status", "effect"))
  end

  def r04_verify
    faces = Client.new.faces
    surface = faces.select { |row| row.dig("values", "boundary_condition") == "Surface" }
    attached = faces.select { |row| row.dig("values", "boundary_condition") == "AttachedZone" }
    { "faces" => faces.length, "surface" => surface.map { |row| row["adjacency_state"] },
      "surface_carry_attached_zone_id" => surface.any? { |row| row.fetch("values").key?("attached_zone_id") },
      "attached_remainders" => attached.map { |row|
                                 [row.dig("values", "attached_zone_id").nil?, row["area_m2"].round(3)]
                               } }
  end

  # ---------------------------------------------------------------- R06 panel-closed API client

  # docs/API_QUICKSTART.md, steps 1 to 6, against one selected box.
  def r06_run
    clear
    model = Sketchup.active_model
    group = box(model.entities, "#{PREFIX}r06", [0, 0, 0], 4000.mm)
    model.selection.clear
    model.selection.add(group)
    found = API.discover
    session = found["sessions"].find { |row| row["active"] }
    context = API.connect(:session_id => session["id"])
    zones = API.query(:context => context, :name => "ph_composer.zones.list")
    target = zones["value"]["make_zone"]
    preview = API.preview(:context => context, :name => "ph_composer.zones.make", :params => target)
    made = API.invoke(:context => context, :name => "ph_composer.zones.make", :params => target,
                      :request => { "sequence" => 1, "expected_revision" => zones["revision"],
                                    "proposal_digest" => preview["proposal_digest"] })
    faces = API.query(:context => context, :name => "ph_composer.zones.faces.list")
    face = faces["value"]["faces"].first
    classified = API.invoke(
      :context => context, :name => "ph_composer.zones.faces.classify",
      :params => { "faces" => [face["reference"]], "expected_values" => face["values"],
                   "intent" => { "face_type" => { "mode" => "set", "value" => "Wall" },
                                 "boundary_condition" => { "mode" => "set", "value" => "Outdoors" } } },
      :request => { "sequence" => 2, "expected_revision" => faces["revision"] }
    )
    zone = API.query(:context => context, :name => "ph_composer.zones.list")["value"]["zones"].first
    edit = { "reference" => zone["reference"], "expected_values" => zone["values"],
             "values" => zone["values"].merge("level" => "L1") }
    preview = API.preview(:context => context, :name => "ph_composer.zones.update", :params => edit)
    request = { "sequence" => 3, "expected_revision" => classified["revision"],
                "proposal_digest" => preview["proposal_digest"] }
    updated = API.invoke(:context => context, :name => "ph_composer.zones.update", :params => edit, :request => request)
    read_back = API.query(:context => context, :name => "ph_composer.zones.list")["value"]["zones"].first
    stale = API.invoke(:context => context, :name => "ph_composer.zones.update", :params => edit,
                       :request => { "sequence" => 4, "expected_revision" => zones["revision"] })
    retried = API.invoke(:context => context, :name => "ph_composer.zones.update", :params => edit, :request => request)
    { "made" => made.values_at("status", "effect"), "classified" => classified.values_at("status", "effect"),
      "classified_reference" => classified["affected"].first["reference"],
      "updated" => updated.values_at("status", "effect"), "read_back_matches" => read_back["values"] == edit["values"],
      "stale" => stale.values_at("status", "code", "effect"), "retry_same_outcome" => retried == updated }
  end

  # ---------------------------------------------------------------- native handoff fixture

  # The state NATIVE-HANDOFF.md starts from, in three calls so the native Copy and Paste In Place
  # (menu actions through the bridge) run on the UI queue between them.
  def handoff_setup
    r01_setup
    zone = zone_group("#{PREFIX}r01")
    model = Sketchup.active_model
    model.active_path = [zone]
    model.selection.clear
    model.selection.add(zone.entities.grep(Sketchup::Group).first)
    Sketchup.send_action("copy:")
    { "next" => "handoff_paste" }
  end

  def handoff_paste
    Sketchup.send_action("pasteInPlace:")
    { "next" => "handoff_finish" }
  end

  # R03's Zone with the Garage on two Faces, a third Zone for R05, then the Garage delete committed
  # through the public action, so the next native Undo step is "Delete Attached Zone".
  def handoff_finish
    model = Sketchup.active_model
    model.active_path = nil
    shared = zone_group("#{PREFIX}r01").entities.grep(Sketchup::Group)
    r03_setup(:fresh => false)
    make_zone(box(model.entities, "#{PREFIX}r05", [0, 8000.mm, 0], 4000.mm))
    garage, = attached_ids
    deleted = Client.new.invoke("ph_composer.zones.faces.attached_zone.delete",
                                "id" => garage,
                                "replacement" => { "mode" => "boundary_condition", "boundary_condition" => "Outdoors" })
    watch
    { "shared_children" => shared.length,
      "shared_face_ids" => shared.map { |group| group.entities.grep(Sketchup::Face).first.persistent_id }.uniq,
      "garage_delete" => deleted.values_at("status", "effect"), "zones" => Client.new.zones.length }
  end

  # ---------------------------------------------------------------- shared

  # A native Undo or Redo only runs with SketchUp frontmost, so a person does them. This observer
  # records what each one left, a moment after it settles, so several can be done in a row.
  class Watcher < Sketchup::ModelObserver
    def onTransactionUndo(_model)
      settle("undo")
    end

    def onTransactionRedo(_model)
      settle("redo")
    end

    def settle(event)
      UI.start_timer(0.3, false) { CorrectionsWalkthrough.log << [event, CorrectionsWalkthrough.state] }
    end
  end

  def watch
    @watcher ||= Watcher.new.tap { |watcher| Sketchup.active_model.add_observer(watcher) }
    log.clear
    { "watching" => true }
  end

  def log
    @log ||= []
  end

  def undo
    AuthoringExample.undo
    { "next" => "read back in a later call" }
  end

  def redo_last
    AuthoringExample.redo
    { "next" => "read back in a later call" }
  end

  def state
    client = Client.new
    { "revision" => client.revision, "zones" => client.zones.map { |row|
                                                  [row.dig("reference", "zone_path"), row["state"]]
                                                },
      "faces" => client.faces.map { |row|
                   [row.dig("reference", "entity_id"), row.dig("values", "boundary_condition")]
                 },
      "restorable" => client.zones_value.fetch("restorable").map { |row| row.values_at("zone_id", "refusal") },
      "attached_zones" => client.attached_ids,
      "loose_faces" => Sketchup.active_model.entities.grep(Sketchup::Face).length }
  end

  def clear
    model = Sketchup.active_model
    model.active_path = nil if model.active_path
    model.start_operation("Corrections walkthrough reset", true)
    model.entities.erase_entities(model.entities.to_a) unless model.entities.to_a.empty?
    PhComposer::Zones::Faces::AttachedZone::RECORD_KIND.store.ids(model).each do |id|
      PhComposer::Zones::Faces::AttachedZone::RECORD_KIND.store.delete(model, id)
    end
    raise "SketchUp refused the reset." unless model.commit_operation
  end

  def box(entities, name, origin, width)
    group = AuthoringExample.box(entities, name, origin, width)
    groups[name] = group.persistent_id
    group
  end

  def make_zone(group)
    client = Client.new
    target = { "parent_path" => [], "entity_ids" => [group.persistent_id] }
    result = client.invoke("ph_composer.zones.make", target)
    raise "Make Zone did not commit: #{result['message']}" unless result["effect"] == "committed"

    result
  end

  # Make Zone renames a Group to its Zone name, so setup remembers each Group by persistent id.
  def zone_group(name)
    id = groups.fetch(name)
    Sketchup.active_model.entities.grep(Sketchup::Group).find { |group| group.persistent_id == id }
  end

  def groups
    @groups ||= {}
  end

  # The two walls in the plane x = 4 m: the west Zone's east wall and the east Zone's west wall.
  def facing_walls(client)
    zones = PhComposer::Zones::Occurrences.zones(Sketchup.active_model)
    client.faces.select do |row|
      zone = zones.find { |candidate| candidate.path == row.dig("reference", "zone_path") }
      occurrence = PhComposer::Zones::Occurrences.face_at(zone, row.dig("reference", "entity_path"))
      loops = PhComposer::FaceCapture.call(occurrence.entity, occurrence.transform).loops_m
      loops.flatten(1).all? { |point| (point[0] - 4.0).abs < 1.0e-6 }
    end
  end

  def assigned(garage)
    Client.new.faces.select { |row| row.dig("values", "attached_zone_id") == garage } +
      orphan_records.select { |record| record["attached_zone_id"] == garage }
  end

  def orphan_records
    Sketchup.active_model.entities.grep(Sketchup::Face).filter_map { |face| face_record(face) }
  end

  def attached_ids
    ids = Client.new.attached_ids
    garage = ids.find do |id|
      PhComposer::Zones::Faces::AttachedZone::RECORD_KIND.store.read(Sketchup.active_model, id)["name"] == "Garage"
    end
    [garage, (ids - [garage]).first]
  end

  def face_record(face)
    face && PhComposer::Zones::Faces::FACE_STORE.read(face)
  end

  class Client < AuthoringExample::Client
    def zones_value
      query("ph_composer.zones.all").fetch("value")
    end

    def zones
      zones_value.fetch("zones")
    end

    def faces
      query("ph_composer.zones.faces.all").dig("value", "faces")
    end

    def attached_ids
      query("ph_composer.records.list", "kind" => "ph_composer.zones.faces.attached_zone")
        .dig("value", "records").map { |record| record.fetch("id") }
    end
  end
end
