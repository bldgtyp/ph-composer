# frozen_string_literal: true

# P1-C's fresh-host walkthrough. Geometry setup is development-only; every Zone, classification,
# adjacency and retirement change after setup goes through the public operation contracts.
module AdjacencyWalkthrough
  API = PhComposer::API
  PREFIX = "p1c_walkthrough_"

  module_function

  def setup
    model = Sketchup.active_model
    model.start_operation("P1-C walkthrough geometry", true)
    old = model.entities.grep(Sketchup::Group).select { |group| group.name.start_with?(PREFIX) }
    model.entities.erase_entities(old) unless old.empty?
    west = box(model.entities, "#{PREFIX}west", [0, 0, 0], 5000.mm)
    east = box(model.entities, "#{PREFIX}east", [5000.mm, 0, 0], 4000.mm)
    tolerance_fixtures(model.entities)
    raise "SketchUp refused the walkthrough geometry." unless model.commit_operation

    { "groups" => [west.persistent_id, east.persistent_id], "tolerances" => tolerance_report }
  rescue StandardError
    model.abort_operation
    raise
  end

  def author_and_solve
    client = Client.new
    groups = zone_groups
    raise "Run setup in a fresh Model first." unless groups.length == 2

    groups.each do |group|
      target = { "parent_path" => [], "entity_ids" => [group.persistent_id], "name" => group.name.sub(PREFIX, "") }
      preview = client.preview("ph_composer.zones.make", target)
      client.invoke("ph_composer.zones.make", target, preview.fetch("proposal_digest"))
    end
    zones = client.query("ph_composer.zones.all").dig("value", "zones")
    client.query("ph_composer.zones.faces.all").dig("value", "faces").each do |face|
      client.invoke("ph_composer.zones.faces.classify", {
        "faces" => [face.fetch("reference")],
        "intent" => {
          "face_type" => { "mode" => "set", "value" => face.dig("suggested", "face_type") },
          "boundary_condition" => { "mode" => "set", "value" => face.dig("suggested", "boundary_condition") }
        },
        "expected_values" => face.fetch("values")
      })
    end
    params = { "zones" => zones.map { |zone| zone.fetch("reference") } }
    preview = client.preview("ph_composer.zones.solve_adjacency", params)
    solved = client.invoke("ph_composer.zones.solve_adjacency", params, preview.fetch("proposal_digest"))
    second = client.invoke("ph_composer.zones.solve_adjacency", params)
    verify.merge("solve" => solved.values_at("status", "effect"),
                 "unchanged_solve" => second.values_at("status", "effect"),
                 "pair_ids" => solved.dig("value", "pair_ids"))
  end

  def stale_and_retire
    east = zone_groups.find { |group| group.name == "east" || group.name.end_with?("east") }
    east.transformation = Geom::Transformation.new([5001.mm, 0, 0])
    client = Client.new
    faces = client.query("ph_composer.zones.faces.all").dig("value", "faces")
    surface = faces.find { |face| face["adjacency_state"] == "stale" }
    raise "Moving the east Zone did not expose a stale pair." unless surface

    stale_states = faces.map { |face| face["adjacency_state"] }.compact

    result = client.invoke("ph_composer.zones.retire_adjacency", "face" => surface.fetch("reference"))
    verify.merge("stale_before_retire" => stale_states, "retire" => result.values_at("status", "effect"))
  end

  def restore_and_resolve
    east = zone_groups.find { |group| group.name == "east" || group.name.end_with?("east") }
    east.transformation = Geom::Transformation.new([5000.mm, 0, 0])
    client = Client.new
    zones = client.query("ph_composer.zones.all").dig("value", "zones")
    result = client.invoke("ph_composer.zones.solve_adjacency", "zones" => zones.map { |zone| zone.fetch("reference") })
    verify.merge("resolve" => result.values_at("status", "effect"))
  end

  def verify
    client = Client.new
    zones = client.query("ph_composer.zones.all").dig("value", "zones")
    faces = client.query("ph_composer.zones.faces.all").dig("value", "faces")
    states = faces.map { |face| face["adjacency_state"] }.compact
    names = [PhComposer::Zones::Faces::ExportProjection::SECTION, PhComposer::Zones::ExportProjection::SECTION]
    extraction = PhComposer::Export::Collection.build(Sketchup.active_model, :run_id => "host-p1c",
                                                                             :contributors => names)
    {
      "zones" => zones.length, "faces" => faces.length,
      "classified" => faces.count { |face| face.dig("reference", "entity_id") },
      "adjacency_states" => states,
      "surface_faces" => faces.count { |face| face.dig("values", "boundary_condition") == "Surface" },
      "extracted_faces" => extraction.document.dig("sections", names.first, "records").length,
      "findings" => extraction.findings, "tolerances" => tolerance_report
    }
  rescue PhComposer::Export::Blocked => error
    { "export_blocked" => error.code, "adjacency_states" => states }
  end

  def tolerance_report
    {
      "plane_0.0254_mm" => tolerance_match?("#{PREFIX}plane_base", "#{PREFIX}plane_0.0254"),
      "plane_0.0255_mm" => tolerance_match?("#{PREFIX}plane_base", "#{PREFIX}plane_0.0255"),
      "normal_0.1_deg" => tolerance_match?("#{PREFIX}angle_base", "#{PREFIX}angle_0.1"),
      "normal_0.101_deg" => tolerance_match?("#{PREFIX}angle_base", "#{PREFIX}angle_0.101")
    }
  end

  def tolerance_match?(left_name, right_name)
    left = named_group(left_name)
    right = named_group(right_name)
    left_face = left.entities.grep(Sketchup::Face).first
    right_face = right.entities.grep(Sketchup::Face).first
    a = PhComposer::FaceCapture.call(left_face, left.transformation)
    b = PhComposer::FaceCapture.call(right_face, right.transformation)
    PhComposer::FaceGeometry.equivalent_full_face?(
      a, b, :plane_tolerance_m => PhComposer::Zones::Adjacency::PLANE_TOLERANCE_M,
            :angle_tolerance_degrees => PhComposer::Zones::Adjacency::NORMAL_ANGLE_TOLERANCE_DEGREES,
            :point_tolerance_m => PhComposer::Zones::Adjacency::POINT_TOLERANCE_M
    )
  end

  def tolerance_fixtures(entities)
    rectangle_group(entities, "#{PREFIX}plane_base", Geom::Transformation.new, 4000.mm)
    rectangle_group(entities, "#{PREFIX}plane_0.0254", Geom::Transformation.new([0.0254.mm, 0, 0]), 4000.mm, true)
    rectangle_group(entities, "#{PREFIX}plane_0.0255", Geom::Transformation.new([0.0255.mm, 0, 0]), 4000.mm, true)
    rectangle_group(entities, "#{PREFIX}angle_base", Geom::Transformation.new, 11.mm)
    angle_01 = Geom::Transformation.rotation(ORIGIN, Z_AXIS, 0.1.degrees)
    angle_0101 = Geom::Transformation.rotation(ORIGIN, Z_AXIS, 0.101.degrees)
    rectangle_group(entities, "#{PREFIX}angle_0.1", angle_01, 11.mm, true)
    rectangle_group(entities, "#{PREFIX}angle_0.101", angle_0101, 11.mm, true)
  end

  def rectangle_group(entities, name, transform, width, reverse = false)
    group = entities.add_group
    group.name = name
    group.transformation = transform
    points = [[0, 0, 0], [0, width, 0], [0, width, 3000.mm], [0, 0, 3000.mm]]
    points.reverse! if reverse
    group.entities.add_face(points)
    group
  end

  def box(entities, name, origin, width)
    group = entities.add_group
    group.name = name
    group.transformation = Geom::Transformation.new(origin)
    floor = group.entities.add_face([0, 0, 0], [0, 4000.mm, 0], [width, 4000.mm, 0], [width, 0, 0])
    floor.reverse! if floor.normal.z.positive?
    floor.pushpull(-3000.mm)
    group
  end

  def zone_groups
    Sketchup.active_model.entities.grep(Sketchup::Group).select do |group|
      ["#{PREFIX}west", "#{PREFIX}east", "west", "east"].include?(group.name)
    end
  end

  def named_group(name)
    Sketchup.active_model.entities.grep(Sketchup::Group).find { |group| group.name == name }
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
      revision = query("ph_composer.zones.all").fetch("revision")
      request = { "sequence" => @sequence, "expected_revision" => revision }
      request["proposal_digest"] = proposal_digest if proposal_digest
      API.invoke(:context => @context, :name => name, :params => params, :request => request)
    end
  end
end
