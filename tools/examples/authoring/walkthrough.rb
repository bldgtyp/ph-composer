# frozen_string_literal: true

# P1-B's public-operation walkthrough. Run only in a fresh synthetic Model; setup replaces earlier
# `p1b_walkthrough_*` fixtures. Geometry construction is deliberately outside the product API. All
# authoring after that point uses the same PhComposer::API contracts available with the panel closed.
module AuthoringWalkthrough
  API = PhComposer::API
  PREFIX = "p1b_walkthrough_"

  module_function

  def setup
    model = Sketchup.active_model
    model.start_operation("P1-B walkthrough geometry", true)
    old = model.entities.grep(Sketchup::Group).select { |group| group.name.start_with?(PREFIX) }
    model.entities.erase_entities(old) unless old.empty?
    first = box(model.entities, "#{PREFIX}west", [0, 0, 0])
    second = box(model.entities, "#{PREFIX}east", [4000.mm, 0, 0])
    raise "SketchUp refused the walkthrough geometry." unless model.commit_operation

    { "groups" => [first.persistent_id, second.persistent_id] }
  rescue StandardError
    model.abort_operation
    raise
  end

  def run
    client = Client.new
    groups = walkthrough_groups
    raise "Run setup in a fresh Model first." unless groups.length == 2

    made = groups.map do |group|
      target = { "parent_path" => [], "entity_ids" => [group.persistent_id], "name" => group.name.sub(PREFIX, "") }
      preview = client.preview("ph_composer.zones.make", target)
      client.invoke("ph_composer.zones.make", target, preview.fetch("proposal_digest"))
    end
    zones = client.query("ph_composer.zones.list").dig("value", "zones")
    west = zones.find { |zone| zone.dig("values", "name") == "west" }
    values = west.fetch("values").merge("name" => "West Zone", "building_segment" => "Walkthrough",
                                         "level" => "L1", "ground_depth_mm" => 150.0)
    edited = client.invoke("ph_composer.zones.update", {
      "reference" => west.fetch("reference"), "values" => values, "expected_values" => west.fetch("values")
    })

    faces = client.query("ph_composer.zones.faces.list").dig("value", "faces")
    classified = zones.map do |zone|
      face = faces.find { |row| row.dig("reference", "zone_id") == zone.fetch("id") }
      client.invoke("ph_composer.zones.faces.classify", {
        "faces" => [face.fetch("reference")],
        "intent" => {
          "face_type" => { "mode" => "set", "value" => face.dig("suggested", "face_type") },
          "boundary_condition" => { "mode" => "set", "value" => face.dig("suggested", "boundary_condition") }
        },
        "expected_values" => face.fetch("values")
      })
    end

    result = verify
    result.merge("previewed" => made.all? { |row| row["effect"] == "committed" },
                 "zone_edit" => edited.values_at("status", "effect"),
                 "classification" => classified.map { |row| row.values_at("status", "effect") })
  end

  def undo
    Sketchup.send_action("editUndo:")
    :undo_requested
  end

  def redo
    Sketchup.send_action("editRedo:")
    :redo_requested
  end

  def verify
    client = Client.new
    zones = client.query("ph_composer.zones.list").dig("value", "zones")
    faces = client.query("ph_composer.zones.faces.list").dig("value", "faces")
    classified = faces.select { |face| face.dig("reference", "entity_id") }
    {
      "zones" => zones.length,
      "zone_values" => zones.map { |zone| zone.fetch("values") },
      "zone_paths" => zones.map { |zone| zone.dig("reference", "zone_path") },
      "faces" => faces.length,
      "classified_faces" => classified.length,
      "stamps_agree" => stamps_agree?,
      "passed" => zones.length == 2 && classified.length == 2 && stamps_agree?
    }
  end

  def walkthrough_groups
    Sketchup.active_model.entities.grep(Sketchup::Group).select { |group| group.name.start_with?(PREFIX) }
  end

  def stamps_agree?
    walkthrough_groups.all? do |group|
      zone = PhComposer::Zones::ZONE_STORE.read(group)
      group.entities.grep(Sketchup::Face).all? do |face|
        assignment = PhComposer::Zones::Faces::FACE_STORE.read(face)
        next true unless assignment

        PhComposer::Zones::STAMP_STORE.read(face)&.fetch("zone_id", nil) == zone&.fetch("id", nil)
      end
    end
  end

  def box(entities, name, origin)
    group = entities.add_group
    group.name = name
    group.transformation = Geom::Transformation.new(origin)
    floor = group.entities.add_face([0, 0, 0], [0, 4000.mm, 0], [4000.mm, 4000.mm, 0], [4000.mm, 0, 0])
    floor.reverse! if floor.normal.z.positive?
    floor.pushpull(-3000.mm)
    group
  end

  class Client
    def initialize
      session = API.discover.fetch("sessions").find { |row| row.fetch("active") }.fetch("id")
      @context = API.connect(:session_id => session)
      @sequence = 0
    end

    def query(name)
      API.query(:context => @context, :name => name)
    end

    def preview(name, params)
      API.preview(:context => @context, :name => name, :params => params)
    end

    def invoke(name, params, proposal_digest = nil)
      @sequence += 1
      revision = query("ph_composer.zones.list").fetch("revision")
      request = { "sequence" => @sequence, "expected_revision" => revision }
      request["proposal_digest"] = proposal_digest if proposal_digest
      API.invoke(:context => @context, :name => name, :params => params, :request => request)
    end
  end
end
