# frozen_string_literal: true

# Synthetic host geometry and public clients shared by the assignment checks and walkthrough test.
module AssemblyAssignmentFixtures
  API = PhComposer::API
  FACE_PREFIX = "ph_composer.zones.faces"
  ASSEMBLY_PREFIX = "ph_composer.assemblies.assemblies"
  STORE = PhComposer::Zones::Faces::FACE_STORE

  def assignment_setup
    @model = Sketchup.active_model
    settings = PhComposer::Zones::Faces::Settings
    settings::STORE.write(@model, settings::DEFAULTS.merge("suggest_on_make" => false))
    @session = PhComposer::Sessions.for(@model)
    @context = API.connect(:session_id => @session.id)
    @sequence = 0
  end

  def assignment_invoke(name, params, digest = nil)
    @sequence += 1
    request = { "sequence" => @sequence, "expected_revision" => @session.revision }
    request["proposal_digest"] = digest if digest
    API.invoke(:context => @context, :name => name, :params => params, :request => request)
  end

  def assignment_query(name, params = {})
    result = API.query(:context => @context, :name => name, :params => params)
    assert_equal "completed", result.fetch("status"), result.inspect
    result.fetch("value")
  end

  def assignment_faces
    assignment_query("#{FACE_PREFIX}.all").fetch("faces")
  end

  def assignment_assembly(name, values = {})
    result = assignment_invoke("#{ASSEMBLY_PREFIX}.create", "values" => { "name" => name }.merge(values))
    assert_equal "completed", result.fetch("status"), result.inspect
    result.fetch("value").fetch("id")
  end

  def assignment_zone(base, count = 1, nested: false)
    faces = count.times.map do |offset|
      z = offset * 10
      Sketchup::Face.new(base + offset + 1, {}, :points => [Geom::Point3d.new(0, 0, z),
                                                            Geom::Point3d.new(100, 0, z),
                                                            Geom::Point3d.new(100, 100, z)])
    end
    entities = nested ? [Sketchup::Group.new(base + count + 1, Sketchup::Entities.new(faces))] : faces
    group = Sketchup::Group.new(base, Sketchup::Entities.new(entities))
    @model.entities << group
    result = assignment_invoke("ph_composer.zones.make", "parent_path" => [], "entity_ids" => [base])
    assert_equal "completed", result.fetch("status"), result.inspect
    [group, faces]
  end

  def assignment_params(rows, id)
    { "targets" => rows.map { |row|
                     { "reference" => row.fetch("reference"),
                       "expected_values" => row.fetch("values") }
                   }, "assembly_id" => id }
  end

  def assignment_classify(rows, intent)
    assignment_invoke("#{FACE_PREFIX}.classify", "faces" => rows.map { |row| row.fetch("reference") },
                                                 "intent" => intent)
  end

  def assembly_intent(id, mode = "set")
    { "assembly_id" => { "mode" => mode, "value" => id } }
  end

  def assignment_pair(base)
    metres = 1.0 / 0.0254
    points = [[0, 0, 0], [0, 4 * metres, 0], [0, 4 * metres, 3 * metres], [0, 0, 3 * metres]]
             .map { |xyz| Geom::Point3d.new(*xyz) }
    [[base, points, 1], [base + 10, points.reverse, -1]].each do |id, outline, normal|
      face = Sketchup::Face.new(id + 1, {}, :points => outline, :normal => Geom::Vector3d.new(normal, 0, 0))
      @model.entities << Sketchup::Group.new(id, Sketchup::Entities.new([face]))
      assignment_invoke("ph_composer.zones.make", "parent_path" => [], "entity_ids" => [id])
    end
    assignment_classify(assignment_faces, "face_type" => { "mode" => "set", "value" => "Wall" },
                                          "boundary_condition" => { "mode" => "set", "value" => "Outdoors" })
    zones = assignment_query("ph_composer.zones.list").fetch("zones")
    result = assignment_invoke("ph_composer.zones.solve_adjacency",
                               "zones" => zones.map { |zone| zone.fetch("reference") })
    assert_equal "completed", result.fetch("status"), result.inspect
    assignment_faces
  end
end
