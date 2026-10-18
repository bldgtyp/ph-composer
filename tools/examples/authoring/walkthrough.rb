# frozen_string_literal: true

require_relative "client"

# Zone and Face authoring through the public operations. Run only in a fresh synthetic Model; setup replaces earlier
# `p1b_walkthrough_*` fixtures. Geometry construction is deliberately outside the product API. All
# authoring after that point uses the same PhComposer::API contracts available with the panel closed.
module AuthoringWalkthrough
  PREFIX = "p1b_walkthrough_"

  module_function

  def setup
    model = Sketchup.active_model
    model.start_operation("Authoring walkthrough geometry", true)
    old = model.entities.grep(Sketchup::Group).select { |group| group.name.start_with?(PREFIX) }
    model.entities.erase_entities(old) unless old.empty?
    first = AuthoringExample.box(model.entities, "#{PREFIX}west", [0, 0, 0])
    second = AuthoringExample.box(model.entities, "#{PREFIX}east", [4000.mm, 0, 0])
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
    zones = client.query("ph_composer.zones.all").dig("value", "zones")
    west = zones.find { |zone| zone.dig("values", "name") == "west" }
    values = west.fetch("values").merge("name" => "West Zone", "building_segment" => "Walkthrough",
                                        "level" => "L1", "ground_depth_mm" => 150.0)
    edited = client.invoke("ph_composer.zones.update", {
      "reference" => west.fetch("reference"), "values" => values, "expected_values" => west.fetch("values")
    })

    faces = client.query("ph_composer.zones.faces.all").dig("value", "faces")
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
    AuthoringExample.undo
    :undo_requested
  end

  def redo
    AuthoringExample.redo
    :redo_requested
  end

  def verify
    client = Client.new
    zones = client.query("ph_composer.zones.all").dig("value", "zones")
    faces = client.query("ph_composer.zones.faces.all").dig("value", "faces")
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

  # Make Zone renames each Group to its Zone name, so the Zones are found by record, not by PREFIX.
  # No Zone at all is not agreement.
  def stamps_agree?
    zones = Sketchup.active_model.entities.grep(Sketchup::Group)
                    .select { |group| PhComposer::Zones::ZONE_STORE.read(group) }
    !zones.empty? && zones.all? do |group|
      zone = PhComposer::Zones::ZONE_STORE.read(group)
      group.entities.grep(Sketchup::Face).all? do |face|
        assignment = PhComposer::Zones::Faces::FACE_STORE.read(face)
        next true unless assignment

        PhComposer::Zones::STAMP_STORE.read(face)&.fetch("zone_id", nil) == zone&.fetch("id", nil)
      end
    end
  end

  class Client < AuthoringExample::Client; end
end
