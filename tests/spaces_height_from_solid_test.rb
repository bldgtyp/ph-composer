# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/space_fixtures"

# Height from solid: a Volume's height from a closed solid's world volume over its net floor area, in one Undo
# step, with the solid left untouched.
class SpacesHeightFromSolidTest < PhComposerTestCase
  include SpaceFixtures

  API = PhComposer::API
  CUBIC_INCHES = INCHES**3
  LOFT_VOLUME = { "volume_id" => "vol_FFFFFFFFFFFF", "entity_path" => [2000, 2100, 2110] }.freeze

  def setup
    super
    @model = Sketchup.active_model
    @session = PhComposer::Sessions.for(@model)
    @context = API.connect(:session_id => @session.id)
    @sequence = 0
    reference_model
    @loft = @model.entities.to_a.last.entities.to_a.first
  end

  # A closed Group of `m3` in the Loft's Space, under `wrapper` when given.
  def solid(m3, id: 2200, wrapper: nil)
    group = Sketchup::Group.new(id)
    group.solid_volume = m3 * CUBIC_INCHES if m3
    holder = wrapper ? wrapper.tap { |outer| outer.entities << group } : group
    @loft.entities << holder
    wrapper ? [2000, 2100, wrapper.persistent_id, id] : [2000, 2100, id]
  end

  def preview(path, volume = LOFT_VOLUME)
    API.query(:context => @context, :name => "ph_composer.spaces.volumes.height_from_solid_preview",
              :params => { "volume" => volume, "solid" => path })
  end

  def apply(path, expected = 3.0)
    @sequence += 1
    API.invoke(:context => @context, :name => "ph_composer.spaces.volumes.height_from_solid",
               :params => { "volume" => LOFT_VOLUME, "solid" => path,
                            "expected_values" => { "avg_ceiling_height_m" => expected } },
               :request => { "sequence" => @sequence, "expected_revision" => @session.revision })
  end

  # Looked up afresh: the stub's Undo restores the Model's entities as new objects.
  def loft
    @model.entities.to_a.last.entities.to_a.first
  end

  def loft_height
    PhComposer::Spaces::VOLUME_STORE.read(loft.entities.to_a.first)["avg_ceiling_height_m"]
  end

  def test_the_wedge_of_36_m3_over_12_m2_gives_3_m_and_reports_both_numbers
    value = preview(solid(36.0)).fetch("value")
    assert_in_delta 3.0, value.fetch("height_m"), 1e-9
    assert_in_delta 36.0, value.fetch("solid_volume_m3"), 1e-9
    assert_in_delta 12.0, value.fetch("net_floor_area_m2"), 1e-9
  end

  def test_the_net_floor_area_is_used_not_the_gross
    segment = @loft.entities.to_a.first.entities.to_a.first
    PhComposer::Spaces::FLOOR_SEGMENT_STORE.write(segment, segment_record("F", :net_area_factor => 0.5))
    assert_in_delta 6.0, preview(solid(36.0)).dig("value", "height_m"), 1e-9
  end

  def test_an_open_solid_an_empty_one_and_a_volume_with_no_floor_each_refuse_and_write_nothing
    operations = @model.operations.length
    assert_equal "space.solid_invalid", apply(solid(nil)).fetch("code"), "not a closed solid"
    assert_equal "space.solid_invalid", apply(solid(0.0, :id => 2201)).fetch("code"), "no volume"
    empty = { "volume_id" => "vol_EEEEEEEEEEEE", "entity_path" => [2000, 2100, 2120] }
    @loft.entities << volume_group(2120, volume_record("E", :number => 2), [])
    assert_equal "space.net_area_zero", preview(solid(36.0, :id => 2202), empty).fetch("code")
    assert_equal operations, @model.operations.length
    assert_in_delta 3.0, loft_height, 1e-9
  end

  def test_a_solid_under_a_scaled_or_rotated_wrapper_measures_in_world_units
    scaled = Sketchup::Group.new(2300, Sketchup::Entities.new, {}, :transformation => Geom::Transformation.scaling(2))
    assert_in_delta 8 * 4.5 / 12.0, preview(solid(4.5, :wrapper => scaled)).dig("value", "height_m"), 1e-9
    turn = Geom::Transformation.new([0, 1, 0, 0, -1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1])
    rotated = Sketchup::Group.new(2400, Sketchup::Entities.new, {}, :transformation => turn)
    assert_in_delta 3.0, preview(solid(36.0, :id => 2401, :wrapper => rotated)).dig("value", "height_m"), 1e-9
  end

  def test_a_stale_expected_height_refuses
    result = apply(solid(48.0), 2.0)
    assert_equal %w[refused target.changed], result.values_at("status", "code")
    assert_in_delta 3.0, loft_height, 1e-9
  end

  def test_one_undo_restores_the_height_and_the_solid_is_untouched
    path = solid(48.0)
    operations = @model.operations.length
    result = apply(path)
    assert_equal "completed", result.fetch("status"), result.inspect
    assert_in_delta 4.0, loft_height, 1e-9
    assert_equal operations + 1, @model.operations.length
    @model.undo
    assert_in_delta 3.0, loft_height, 1e-9
    assert_nil loft.entities.to_a.last.attribute_dictionaries, "the solid carries no dictionary"
  end

  def test_the_menu_offers_itself_on_one_volume_and_one_solid_and_confirms_before_writing
    menu = PhComposer::Spaces::HeightFromSolidMenu
    solid(48.0)
    @model.active_path = [@model.entities.to_a.last, loft]
    volume_group = loft.entities.to_a.first
    @model.selection.add(volume_group)
    assert_nil menu.pair(@session), "one Volume alone"
    @model.selection.add(loft.entities.to_a.last)
    refute_nil menu.pair(@session)
    operations = @model.operations.length
    UI.messagebox_result = IDNO
    menu::Client.new(@session).run
    assert_equal operations, @model.operations.length, "declined: nothing written"
    assert(UI.messages.last.include?("becomes 4 m"), UI.messages.last)
    UI.messagebox_result = IDYES
    assert_equal "completed", menu::Client.new(@session).run.fetch("status")
    assert_in_delta 4.0, loft_height, 1e-9
  end

  def test_the_menu_says_what_to_select_when_the_selection_is_not_a_volume_and_a_solid
    menu = PhComposer::Spaces::HeightFromSolidMenu
    solid(48.0)
    @model.active_path = [@model.entities.to_a.last, loft]
    operations = @model.operations.length
    empty = menu::Client.new(@session).run
    assert_equal "selection.invalid", empty.fetch("code")
    assert_equal empty.fetch("message"), UI.messages.last, "the panel route's own words"
    @model.selection.add(loft.entities.to_a.last)
    alone = menu::Client.new(@session).run
    assert_equal "selection.invalid", alone.fetch("code")
    assert_equal menu::NO_VOLUME, UI.messages.last
    stray = Sketchup::Face.new(2600)
    loft.entities << stray
    @model.selection.add([loft.entities.to_a.first, stray])
    menu::Client.new(@session).run
    assert_equal menu::ONLY_PAIR, UI.messages.last, "a Volume and a solid with a Face selected too"
    assert_equal operations, @model.operations.length
  end

  def test_the_selected_solid_is_the_one_container_that_is_not_a_space_or_volume
    path = solid(36.0)
    @model.active_path = [@model.entities.to_a.last, loft]
    @model.selection.add(loft.entities.to_a.first)
    read = -> { API.query(:context => @context, :name => "ph_composer.spaces.selected_solid") }
    assert_equal "selection.invalid", read.call.fetch("code"), "a Volume alone is no solid"
    @model.selection.add(loft.entities.to_a.last)
    assert_equal path, read.call.dig("value", "solid")
  end

  def test_a_selected_container_with_an_unreadable_record_refuses_as_unreadable
    @model.active_path = [@model.entities.to_a.last, loft]
    corrupt = Sketchup::Group.new(2500)
    corrupt.set_attribute(PhComposer::Spaces::SPACE_STORE.dictionary, "record", "{not json")
    loft.entities << corrupt
    @model.selection.add(corrupt)
    result = API.query(:context => @context, :name => "ph_composer.spaces.selected_solid")
    assert_equal "record.unreadable", result.fetch("code")
  end
end
