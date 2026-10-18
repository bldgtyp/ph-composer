# frozen_string_literal: true

require_relative "client"

# A fresh-host walkthrough of what SketchUp actually does when the solver cuts a Face.
#
# The offline suite models a split so the record consequences can be tested. This measures the
# thing that model stands in for. Four questions it has to answer, because the implementation
# depends on all four:
#
#   1. Which resulting Face keeps the original native persistent id?
#   2. Does every resulting Face keep the dictionaries the original carried?
#   3. Does a shared region wholly inside a Face come back as one Face with a hole?
#   4. Is the whole cut, on both sides, one Undo step?
module CutWalkthrough
  PREFIX = "p1d_cut_"
  FACE_STORE = PhComposer::Zones::Faces::FACE_STORE

  module_function

  # Two boxes meeting on the x = 5 m plane, offset in y so their shared wall is a partial overlap:
  # A spans y 0..4, B spans y 2..6, so they share y 2..4 over the full 3 m height.
  def setup
    model = Sketchup.active_model
    model.start_operation("Cut walkthrough geometry", true)
    model.entities.erase_entities(zone_groups) unless zone_groups.empty?
    AuthoringExample.box(model.entities, "#{PREFIX}west", [0, 0, 0], 5000.mm, 4000.mm)
    AuthoringExample.box(model.entities, "#{PREFIX}east", [5000.mm, 2000.mm, 0], 4000.mm, 4000.mm)
    raise "SketchUp refused the walkthrough geometry." unless model.commit_operation

    author
  end

  # A box whose shared wall sits wholly inside the other's: C spans y 1..3 and z 0.5..2.5 against
  # the same plane, so the region it shares is an island in the larger wall.
  def setup_contained
    model = Sketchup.active_model
    model.start_operation("Contained cut walkthrough geometry", true)
    model.entities.erase_entities(zone_groups) unless zone_groups.empty?
    AuthoringExample.box(model.entities, "#{PREFIX}west", [0, 0, 0], 5000.mm, 4000.mm)
    inner = AuthoringExample.box(model.entities, "#{PREFIX}east", [5000.mm, 1000.mm, 500.mm], 4000.mm, 2000.mm, 2000.mm)
    inner.name = "#{PREFIX}east"
    raise "SketchUp refused the walkthrough geometry." unless model.commit_operation

    author
  end

  def author
    client = Client.new
    zone_groups.each do |group|
      target = { "parent_path" => [], "entity_ids" => [group.persistent_id],
                 "name" => group.name.sub(PREFIX, "") }
      preview = client.preview("ph_composer.zones.make", target)
      client.invoke("ph_composer.zones.make", target, preview.fetch("proposal_digest"))
    end
    client.query("ph_composer.zones.all").dig("value", "zones").each do |zone|
      client.invoke("ph_composer.zones.faces.auto_classify", { "zone" => zone.fetch("reference") })
    end
    before
  end

  # Everything about the two walls that the cut might change, recorded before it runs.
  def before
    @before = shared_plane_faces.map { |face| snapshot(face) }
    { "walls" => @before }
  end

  def solve
    client = Client.new
    references = client.query("ph_composer.zones.all").dig("value", "zones").map { |zone| zone.fetch("reference") }
    params = { "zones" => references }
    preview = client.preview("ph_composer.zones.solve_adjacency", params)
    result = client.invoke("ph_composer.zones.solve_adjacency", params, preview.fetch("proposal_digest"))
    report.merge(
      "solve" => result.values_at("status", "code", "effect"),
      "pair_ids" => result.dig("value", "pair_ids"),
      "findings" => result.fetch("findings").map { |finding| finding.fetch("code") }
    )
  end

  # The four questions, answered from the Model as it now stands.
  def report
    after = shared_plane_faces.map { |face| snapshot(face) }
    kept = after.select { |row| @before.any? { |old| old.fetch("persistent_id") == row.fetch("persistent_id") } }
    {
      "wall_faces_before" => @before.length,
      "wall_faces_after" => after.length,
      "original_persistent_ids_surviving" => kept.map { |row| row.fetch("persistent_id") },
      "face_ids_reused" => kept.map { |row| row.fetch("face_id") } &
        @before.map { |row| row.fetch("face_id") },
      "every_piece_has_a_record" => after.all? { |row| row.fetch("face_id") },
      "every_piece_has_a_stamp" => after.all? { |row| row.fetch("stamped") },
      "payloads_kept" => after.map { |row| row.fetch("user_data") },
      "loop_counts" => after.map { |row| row.fetch("loops") },
      "areas_m2" => after.map { |row| row.fetch("area_m2") },
      "boundary_conditions" => after.map { |row| row.fetch("boundary_condition") }
    }
  end

  # Native Undo goes through the menu action, not through the Model: SketchUp has no Model#undo.
  # It runs on the UI queue, so read the result in a later call, never in this one.
  def undo
    AuthoringExample.undo
    report
  end

  def redo_last
    AuthoringExample.redo
    report
  end

  # Marks every wall Face on the shared plane, so the payload rule can be checked on the pieces.
  def mark_payloads
    shared_plane_faces.each_with_index do |face, index|
      record = FACE_STORE.read(face)
      next unless record

      FACE_STORE.write(face, record.merge("user_data" => { "firm.mark" => "wall-#{index}" }))
    end
    before
  end

  def snapshot(face)
    record = FACE_STORE.read(face)
    {
      "persistent_id" => face.persistent_id,
      "face_id" => record&.fetch("id", nil),
      "boundary_condition" => record && record["boundary_condition"],
      "stamped" => !PhComposer::Zones::STAMP_STORE.read(face).nil?,
      "user_data" => record ? record.fetch("user_data", {}) : nil,
      "loops" => face.loops.length,
      "area_m2" => (face.area * 0.0254 * 0.0254).round(4)
    }
  end

  # Faces on the x = 5 m plane, in either Zone: the wall the solver cuts and whatever it becomes.
  def shared_plane_faces
    zone_groups.flat_map do |group|
      offset = group.transformation.origin.x
      group.entities.grep(Sketchup::Face).select do |face|
        face.vertices.all? { |vertex| ((vertex.position.x + offset) - 5000.mm).abs < 0.001 }
      end
    end
  end

  def zone_groups
    Sketchup.active_model.entities.grep(Sketchup::Group)
            .select { |group| group.name.start_with?(PREFIX) || %w[west east].include?(group.name) }
  end

  class Client < AuthoringExample::Client; end
end
