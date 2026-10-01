# frozen_string_literal: true

require_relative "test_helper"

# The Zone and Face reads are bounded, filtered and projected. Rows come in occurrence-path order a
# page at a time; a cursor answers only its own query, filter, session and revision; a projection
# returns the named values and nothing else. The panel reads the complete projections.
class EntityReadsTest < PhComposerTestCase
  API = PhComposer::API
  ZONES = "ph_composer.zones.list"
  FACES = "ph_composer.zones.faces.list"

  def setup
    super
    @model = Sketchup.active_model
    @session = PhComposer::Sessions.for(@model)
    @context = API.connect(:session_id => @session.id)
    @sequence = 0
  end

  def test_a_projected_one_row_page_returns_only_the_named_value
    make_zone(box(100, 2))
    make_zone(box(200, 2))

    page = read(ZONES, "limit" => 1, "fields" => ["name"])

    assert_equal "completed", page.fetch("status")
    rows = page.dig("value", "zones")
    assert_equal 1, rows.length
    assert_equal %w[id reference state values], rows.first.keys.sort
    assert_equal ["name"], rows.first.fetch("values").keys
    assert_equal 2, page.dig("value", "total")
    refute_nil page.dig("value", "next_cursor")
  end

  def test_zones_page_in_path_order_and_the_cursor_is_bound
    [300, 100, 200].each { |pid| make_zone(box(pid, 1)) }
    first = read(ZONES, "limit" => 2).fetch("value")
    second = read(ZONES, "limit" => 2, "cursor" => first.fetch("next_cursor")).fetch("value")

    assert_equal [[100], [200], [300]], (first.fetch("zones") + second.fetch("zones"))
      .map { |row| row.dig("reference", "zone_path") }
    assert_nil second.fetch("next_cursor")
    assert_equal "params.invalid", read(ZONES, "limit" => 2, "fields" => ["name"],
                                              "cursor" => first.fetch("next_cursor")).fetch("code")
    make_zone(box(400, 1))
    assert_equal "query.cursor_expired", read(ZONES, "limit" => 2, "cursor" => first.fetch("next_cursor")).fetch("code")
  end

  def test_a_duplicated_zone_identity_is_two_rows_filtered_by_id
    original = box(100, 1)
    make_zone(original)
    copy = box(200, 1)
    @model.entities << copy
    PhComposer::Zones::ZONE_STORE.write(copy, PhComposer::Zones::ZONE_STORE.read(original))
    id = PhComposer::Zones::ZONE_STORE.read(original).fetch("id")

    rows = read(ZONES, "ids" => [id]).dig("value", "zones")

    assert_equal [[100], [200]], rows.map { |row| row.dig("reference", "zone_path") }
    assert_equal %w[ambiguous ambiguous], rows.map { |row| row.fetch("state") }
    paths = read(ZONES, "paths" => [[200]]).dig("value", "zones").map { |row| row.dig("reference", "zone_path") }
    assert_equal [[200]], paths
  end

  def test_faces_page_past_the_maximum_and_projections_carry_no_geometry
    make_zone(box(100, 501))
    first = read(FACES, "limit" => 500, "fields" => ["face_type"]).fetch("value")
    second = read(FACES, "limit" => 500, "fields" => ["face_type"],
                         "cursor" => first.fetch("next_cursor")).fetch("value")

    assert_equal [500, 1, 501], [first.fetch("faces").length, second.fetch("faces").length, first.fetch("total")]
    assert_equal %w[reference values], first.fetch("faces").first.keys.sort
    assert_nil second.fetch("next_cursor")
  end

  def test_faces_filter_by_zone_and_by_face_id
    make_zone(box(100, 2))
    make_zone(box(200, 3))
    zone_id = read(ZONES).dig("value", "zones").find { |row| row.dig("reference", "zone_path") == [200] }.fetch("id")
    faces = read(FACES, "zone_ids" => [zone_id]).dig("value", "faces")
    classified = invoke("ph_composer.zones.faces.classify",
                        "faces" => [faces.first.fetch("reference")],
                        "intent" => { "face_type" => { "mode" => "set", "value" => "Wall" } })
    face_id = classified.dig("value", "face_ids", 0)

    assert_equal 3, faces.length
    found = read(FACES, "ids" => [face_id]).dig("value", "faces").map { |row| row.dig("reference", "entity_id") }
    assert_equal [face_id], found
    assert_equal 2, read(FACES, "zone_paths" => [[100]]).dig("value", "total")
  end

  # A projected read refuses an invalid stored record exactly as the whole-row read does.
  def test_a_projected_read_refuses_an_invalid_record_like_the_whole_read
    make_zone(box(100, 1))
    face = @model.entities.to_a.first.entities.to_a.first
    PhComposer::Zones::Faces::FACE_STORE.write(face, "id" => "fac_Ab12Cd34Ef56", "schema_version" => 1,
                                                     "face_type" => "Bogus")

    assert_equal "validation.failed", read(FACES).fetch("code")
    assert_equal "validation.failed", read(FACES, "fields" => ["boundary_condition"]).fetch("code")
  end

  def test_unsupported_arguments_are_refused
    assert_equal "params.invalid", read(ZONES, "sort" => "name").fetch("code")
    assert_equal "params.invalid", read(FACES, "fields" => ["area_m2"]).fetch("code")
  end

  def test_the_panel_reads_complete_projections
    make_zone(box(100, 2))

    assert_equal "ph_composer.zones.all", PhComposer::Registry.current.snapshot_sections
                                                              .fetch("ph_composer.zones.overview").query
    assert_equal "ph_composer.zones.faces.all", PhComposer::Registry.current.snapshot_sections
                                                                    .fetch("ph_composer.zones.faces.faces").query
    assert_equal 2, read("ph_composer.zones.faces.all").dig("value", "faces").length
  end

  private

  def read(name, params = {})
    API.query(:context => @context, :name => name, :params => params)
  end

  def invoke(name, params)
    @sequence += 1
    API.invoke(:context => @context, :name => name, :params => params,
               :request => { "sequence" => @sequence, "expected_revision" => @session.revision })
  end

  def box(pid, face_count)
    faces = face_count.times.map do |index|
      points = [[0, 0], [2, 0], [2, 2]].map { |x, y| Geom::Point3d.new(x, y, index) }
      Sketchup::Face.new(pid + index + 1, {}, :points => points)
    end
    Sketchup::Group.new(pid, Sketchup::Entities.new(faces))
  end

  def make_zone(group)
    @model.entities << group
    invoke("ph_composer.zones.make", "parent_path" => [], "entity_ids" => [group.persistent_id])
  end
end
