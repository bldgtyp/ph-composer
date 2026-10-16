# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/space_fixtures"

# The Spaces export section on the reference model: one record per Space with its Zone, stored airflows only,
# Volumes with their prism and Floor Segments with their projected loops; the preflight's rows with whether
# each blocks and where it is; and the metadata boundary (context/CONTRACTS.md, "Translation sections and
# artifacts").
class SpacesExportTest < PhComposerTestCase
  include SpaceFixtures

  X = PhComposer::Spaces::ExportProjection
  API = PhComposer::API

  def setup
    super
    @model = Sketchup.active_model
    @session = PhComposer::Sessions.for(@model)
    @context = API.connect(:session_id => @session.id)
  end

  def records
    snapshot = PhComposer::Export::GeometrySnapshot.capture(@model, :revision => 0)
    catalog = PhComposer::Registry.current.catalog
    reader = PhComposer::Export::SnapshotReader.new(
      PhComposer::Export::RecordReader.new(PhComposer::Records::Engine.new(@model, catalog), catalog), snapshot
    )
    reader.within(X::SECTION) { X.records(reader) }
  end

  def test_each_space_leaves_with_its_zone_its_stored_airflows_and_its_volumes
    reference_model
    rows = records
    assert_equal %w[spc_BBBBBBBBBBBB spc_FFFFFFFFFFFF spc_HHHHHHHHHHHH spc_LLLLLLLLLLLL], rows.map { |row| row["id"] }
    living = rows.find { |row| row["name"] == "Living" }
    assert_equal "zon_AAAAAAAAAAAA", living["zone_id"]
    assert_equal 60.0, living["v_sup_m3h"]
    refute living.key?("v_eta_m3h"), "an absent rate stays absent"
    loft = rows.find { |row| row["name"] == "Loft" }
    assert_equal "zon_BBBBBBBBBBBB", loft["zone_id"]
    refute(%w[v_sup_m3h v_eta_m3h v_tran_m3h].any? { |key| loft.key?(key) })
    hall = rows.find { |row| row["name"] == "Hall" }
    assert_equal 2, hall["volumes"].length
    volume = loft["volumes"].first
    assert_equal 3.0, volume["avg_ceiling_height_m"]
    assert_equal 6, volume["geometry"].length, "the prism: base, top and four sides"
    segment = volume["floor_segments"].first
    assert(segment["loops_m"].first.all? { |point| (point[2] - 1.0).abs < 1e-9 }, "projected to its mean height")
    assert_in_delta 12.0, PhComposer::Spaces::Metrics.projected_area_m2(segment["loops_m"]), 1e-9
  end

  def test_user_data_passes_and_the_reserved_key_blocks
    reference_model
    living_group = @model.entities.to_a.first.entities.to_a.first
    record = PhComposer::Spaces::SPACE_STORE.read(living_group)
    PhComposer::Spaces::SPACE_STORE.write(living_group, record.merge("user_data" => { "client" => "A" }))
    assert_equal({ "client" => "A" }, records.find { |row| row["name"] == "Living" }["user_data"])
    PhComposer::Spaces::SPACE_STORE.write(living_group, record.merge("user_data" => { "ph_composer" => 1 }))
    assert_raises(PhComposer::Export::Blocked) { records }
  end

  def test_a_space_outside_every_zone_a_missing_height_and_a_copy_each_refuse_the_section
    @model.entities << space_group(1100, space_record("L", :number => "101"),
                                   [volume_group(1110, volume_record("L"), [floor_face(1111, rectangle(0, 0, 1, 1),
                                                                                       segment_record("L"))])])
    assert_equal "space.outside_zone", assert_raises(PhComposer::Export::Blocked) { records }.code
    @model.entities.clear!
    reference_model
    bath_volume = @model.entities.to_a.first.entities.to_a[1].entities.to_a.first
    PhComposer::Spaces::VOLUME_STORE.write(bath_volume, volume_record("B", :height => nil))
    assert_equal "space.height_missing", assert_raises(PhComposer::Export::Blocked) { records }.code
    PhComposer::Spaces::VOLUME_STORE.write(bath_volume, volume_record("B", :height => 2.4))
    zone = @model.entities.to_a.first
    living = zone.entities.to_a.first
    copy = Sketchup::Group.new(1900, living.entities)
    copy.set_attribute(PhComposer::Spaces::SPACE_STORE.dictionary, "record",
                       living.get_attribute(PhComposer::Spaces::SPACE_STORE.dictionary, "record"))
    zone.entities << copy
    treat_duplicates_as_existing(@model)
    assert_equal "space.duplicate_identity", assert_raises(PhComposer::Export::Blocked) { records }.code
  end

  def test_the_preflight_reports_each_finding_with_its_block_and_locate
    reference_model
    hall_volume = @model.entities.to_a.first.entities.to_a[2].entities.to_a.first
    PhComposer::Spaces::VOLUME_STORE.write(hall_volume, volume_record("H", :height => nil))
    value = API.query(:context => @context, :name => X::PREFLIGHT).fetch("value")
    height = value.fetch("findings").find { |row| row["code"] == "space.height_missing" }
    assert_equal true, height["blocks_export"]
    assert_equal "ph_composer.spaces.locate", height.dig("locate", "name")
    assert_equal({ "volume_id" => "vol_HHHHHHHHHHHH", "entity_path" => [1000, 1300, 1310] },
                 height.dig("locate", "params", "reference"))
    blocking = PhComposer::Spaces::Findings::BLOCKS_EXPORT
    assert(value.fetch("findings").all? { |row| row["blocks_export"] == blocking.fetch(row["code"]) })
  end

  def test_a_zone_warning_names_its_zone_and_a_stray_copy_offers_its_repair
    reference_model
    living = @model.entities.to_a.first.entities.to_a.first
    record = PhComposer::Spaces::SPACE_STORE.read(living)
    PhComposer::Spaces::SPACE_STORE.write(living, record.merge("v_sup_m3h" => 200.0, "v_eta_m3h" => 10.0))
    orphan = volume_group(5000, volume_record("O"), [])
    @model.entities << orphan
    copy = Sketchup::Group.new(5001, orphan.entities)
    copy.set_attribute(PhComposer::Spaces::VOLUME_STORE.dictionary, "record",
                       orphan.get_attribute(PhComposer::Spaces::VOLUME_STORE.dictionary, "record"))
    @model.entities << copy
    treat_duplicates_as_existing(@model)
    value = API.query(:context => @context, :name => X::PREFLIGHT).fetch("value")
    imbalance = value.fetch("findings").find { |row| row["code"] == "space.airflow_imbalance" }
    assert_equal "zon_AAAAAAAAAAAA", imbalance["object_id"]
    assert_match(/\AZone A: /, imbalance["message"])
    duplicate = value.fetch("findings").find { |row| row["code"] == "space.duplicate_identity" }
    assert_equal "vol_OOOOOOOOOOOO", duplicate["object_id"]
    assert(value.fetch("repairs").any? { |row| row["action"] == "ph_composer.spaces.make_independent" })
  end

  # Spaces writes no PH-Composer entry of its own on a Space, so a user's keys pass and a ph_composer leaf on a
  # Space refuses.
  def test_the_metadata_guard_passes_user_keys_and_refuses_an_undeclared_reserved_leaf
    assert_empty PhComposer::Registry.current.export_contributors.fetch(X::SECTION).user_data_keys
    space = { "type" => "Space", "user_data" => { "client" => "A" } }
    assert PhComposer::Export::Privacy.validate!(translation_result(JSON.generate(space)))
    space["user_data"]["ph_composer"] = { "secret" => "local" }
    assert_raises(PhComposer::CodedError) do
      PhComposer::Export::Privacy.validate!(translation_result(JSON.generate(space)))
    end
  end

  private

  def translation_result(hbjson)
    { "schema_version" => 1, "run_id" => "run", "state" => "complete",
      "summary" => { "objects" => 1, "unavailable" => 0, "findings" => 0, "publishable" => true },
      "sections" => [], "findings" => [], "failure" => nil,
      "canonical_model" => { "hbjson" => hbjson, "rooms" => 0, "faces" => 0, "surface_pairs" => 0 } }
  end
end
