# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/space_fixtures"

# The bounded Spaces reads (context/AGENT_INTERFACE.md, "Focused reads"): `list` answers summaries
# within the reply budget with sums no filter changes, and the scoped reads answer one Space's
# Volumes, one Space's or Volume's Floor Segments and the findings, each paged the same way.
class SpacesPagedReadsTest < PhComposerTestCase
  include SpaceFixtures

  API = PhComposer::API
  MODEL_SUMS = [34.0, 32.0, 95.6].freeze
  HALL = { "space_id" => "spc_HHHHHHHHHHHH", "entity_path" => [1000, 1300] }.freeze

  def setup
    super
    @model = Sketchup.active_model
    @session = PhComposer::Sessions.for(@model)
    @context = API.connect(:session_id => @session.id)
  end

  def test_the_model_sums_never_change_with_ids_limit_or_a_cursor_walk
    reference_model
    sums = [{}, { "ids" => ["spc_FFFFFFFFFFFF"] }, { "ids" => [] }, { "limit" => 1 }].map do |params|
      model_sums(read("list", params))
    end
    walked = walk("list", { "limit" => 1 }, "spaces")

    assert_equal [MODEL_SUMS] * 4, sums
    assert_equal [MODEL_SUMS] * 4, walked.map { |value| model_sums(value) }
    numbers = walked.flat_map { |value| value["spaces"].map { |row| row.dig("values", "number") } }
    assert_equal %w[101 102 103 201], numbers
  end

  def test_a_summary_counts_its_children_and_carries_only_the_fields_asked_for
    reference_model
    hall = read("list", { "ids" => ["spc_HHHHHHHHHHHH"] }).fetch("spaces").first
    projected = read("list", { "ids" => ["spc_HHHHHHHHHHHH"], "fields" => ["metrics"] }).fetch("spaces").first

    assert_equal [2, 2, "Main Building"], hall.values_at("volume_count", "floor_segment_count", "building_segment")
    refute(%w[volumes findings user_data extension_data extension_status].any? { |key| hall.key?(key) })
    assert_equal %w[id metrics reference schema_version], projected.keys.sort
  end

  def test_a_page_names_the_sums_of_its_own_zones_and_segments
    reference_model
    loft = read("list", { "ids" => ["spc_FFFFFFFFFFFF"] })

    assert_equal ["Zone B"], loft.fetch("zones").map { |zone| zone["name"] }
    assert_equal [12.0], loft.fetch("zones").map { |zone| zone["floor_area_m2"].round(6) }
    assert_equal ["Main Building"], loft.fetch("building_segments").map { |row| row["name"] }
  end

  def test_one_spaces_volumes_and_floor_segments_read_by_reference
    reference_model
    volumes = read("volumes.list", { "space" => HALL }).fetch("volumes")
    by_space = read("floor_segments.list", { "space" => HALL }).fetch("floor_segments")
    second = volumes.last.fetch("reference")
    by_volume = read("floor_segments.list", { "volume" => second }).fetch("floor_segments")

    assert_equal [1, 1], volumes.map { |volume| volume["floor_segment_count"] }
    assert_equal %w[fsg_HHHHHHHHHHHH fsg_IIIIIIIIIIII], by_space.map { |row| row["id"] }
    assert_equal %w[fsg_IIIIIIIIIIII], by_volume.map { |row| row["id"] }
  end

  def test_a_scope_must_name_one_parent_that_still_carries_its_id
    reference_model

    assert_equal "params.invalid", query("floor_segments.list", {})["code"]
    assert_equal "params.invalid", query("floor_segments.list", { "space" => HALL,
                                                                  "volume" => HALL.merge("volume_id" => "x") })["code"]
    assert_equal "target.changed",
                 query("volumes.list", { "space" => HALL.merge("space_id" => "spc_XXXXXXXXXXXX") })["code"]
    assert_equal "target.not_found",
                 query("volumes.list", { "space" => HALL.merge("entity_path" => [1000, 9]) })["code"]
  end

  def test_findings_read_for_the_model_or_one_space_and_by_code
    reference_model
    everything = read("findings.list", {}).fetch("findings")
    hall = read("findings.list", { "space" => HALL }).fetch("findings")
    codes = everything.map { |finding| finding["code"] }.uniq

    refute_empty everything
    assert(everything.all? { |finding| finding["reference"].is_a?(Hash) })
    assert(hall.all? { |finding| finding.dig("reference", "entity_path")&.first(2) == [1000, 1300] })
    chosen = read("findings.list", { "codes" => [codes.first] }).fetch("findings")
    assert_equal [codes.first], chosen.map { |finding| finding["code"] }.uniq
  end

  def test_many_spaces_page_within_the_byte_budget_and_walk_whole
    many_spaces(300)
    first = read("list", { "limit" => 500 })
    walked = walk("list", { "limit" => 500 }, "spaces")

    assert_operator JSON.generate(first["spaces"]).bytesize, :<=, PhComposer::Pages::MAX_PAGE_BYTES
    refute_nil first["next_cursor"]
    assert_equal 300, walked.sum { |value| value["spaces"].length }
    assert_equal 300, walked.flat_map { |value| value["spaces"].map { |row| row["id"] } }.uniq.length
  end

  def test_a_cursor_answers_only_the_same_read_scope_and_fields
    many_spaces(60)
    cursor = read("list", { "fields" => ["values"] }).fetch("next_cursor")

    refute_nil cursor
    assert_equal "params.invalid", query("list", { "fields" => ["metrics"], "cursor" => cursor })["code"]
    @session.host_event(:transaction_committed)
    assert_equal "query.cursor_expired", query("list", { "fields" => ["values"], "cursor" => cursor })["code"]
  end

  private

  def query(read, params)
    API.query(:context => @context, :name => "ph_composer.spaces.#{read}", :params => params)
  end

  def read(read, params)
    result = query(read, params)
    assert_equal "completed", result["status"], result.inspect
    result.fetch("value")
  end

  def walk(read, params, key)
    pages = [read(read, params)]
    pages << read(read, params.merge("cursor" => pages.last["next_cursor"])) while pages.last["next_cursor"]
    assert(pages.all? { |value| value.key?(key) })
    pages
  end

  def model_sums(value)
    value.fetch("model").values_at("floor_area_m2", "weighted_area_m2", "net_volume_m3").map { |n| n.round(6) }
  end

  # `count` Spaces with long Unicode names in one Zone, each with one Volume and one Floor Segment.
  def many_spaces(count)
    spaces = Array.new(count) do |index|
      id = format("%012d", index)
      record = { "id" => "spc_#{id}", "schema_version" => 1, "name" => "Wohnzimmer Süd #{'é' * 40} #{index}",
                 "number" => index.to_s, "default_height_m" => 2.5, "next_volume_sequence" => 2 }
      volume = { "id" => "vol_#{id}", "schema_version" => 1, "number" => 1, "display_name" => "",
                 "floor_id" => "flr_#{id}", "avg_ceiling_height_m" => 2.5 }
      segment = { "id" => "fsg_#{id}", "schema_version" => 1, "display_name" => "", "weighting_factor" => 1.0,
                  "net_area_factor" => 1.0 }
      space_group(10_000 + (index * 10), record,
                  [volume_group(10_001 + (index * 10), volume,
                                [floor_face(10_002 + (index * 10), rectangle(index, 0, 1, 1), segment)])])
    end
    @model.entities << zone_group(1000, "A", spaces)
  end
end
