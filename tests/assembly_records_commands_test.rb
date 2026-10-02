# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/assembly_record_fixtures"

class AssemblyRecordsCommandsTest < PhComposerTestCase
  include AssemblyRecordFixtures

  def setup
    super
    @record = fixture_assembly(reference_layers)
    @layer = @record["layers"][0]
    @segment = @layer["segments"][0]
  end

  def test_layer_gestures_take_explicit_ids_and_leave_input_detached
    added = Assemblies::Commands.add_layer(@record, :anchor_layer_id => @layer["id"], :side => "outside")
    assert_equal 4, added.record["layers"].length
    assert_equal @layer["id"], added.record["layers"][1]["id"]
    assert_equal 3, @record["layers"].length
    edited = Assemblies::Commands.update_layer(@record, :layer_id => @layer["id"], :thickness_mm => 50)
    assert_equal 50, edited.record["layers"][0]["thickness_mm"]
    moved = Assemblies::Commands.move_layer(@record, :layer_id => @layer["id"], :direction => "inward")
    assert_equal @layer["id"], moved.record["layers"][1]["id"]
    removed = Assemblies::Commands.remove_layer(@record, :layer_id => @layer["id"])
    assert_equal 2, removed.record["layers"].length
    assert_equal @record["layers"].reverse, Assemblies::Commands.flip_layers(@record).record["layers"]
    assert_equal "last_layer_outside", Assemblies::Commands.flip_orientation(@record).record["orientation"]
  end

  def test_segments_edit_width_flags_material_and_mirror_by_explicit_ids
    added = Assemblies::Commands.add_segment(@record, :layer_id => @layer["id"], :width_mm => 38)
    layer = added.record["layers"][0]
    assert_equal 2, layer["segments"].length
    edited = Assemblies::Commands.update_segment(added.record, :layer_id => layer["id"],
                                                               :segment_id => layer["segments"][1]["id"], :values => { "width_mm" => 150, "steel_stud_spacing_mm" => 600 })
    assert_equal 600, edited.record["layers"][0]["segments"][1]["steel_stud_spacing_mm"]
    assigned = Assemblies::Commands.set_segment_material(edited.record, :materials => fixture_materials,
                                                                        :layer_id => layer["id"], :segment_id => layer["segments"][1]["id"], :material_id => material_id("wood"))
    assert_equal material_id("wood"), assigned.record["layers"][0]["segments"][1]["material_id"]
    mirrored = Assemblies::Commands.mirror_segments(assigned.record)
    assert_equal assigned.record["layers"][0]["segments"].reverse, mirrored.record["layers"][0]["segments"]
    removed = Assemblies::Commands.remove_segment(assigned.record, :layer_id => layer["id"],
                                                                   :segment_id => layer["segments"][1]["id"])
    assert_equal 1, removed.record["layers"][0]["segments"].length
  end

  def test_wrong_ids_last_members_and_two_steel_spacings_refuse
    error = assert_raises(PhComposer::CodedError) do
      Assemblies::Commands.update_layer(@record, :layer_id => "lyr_MISSING00000", :thickness_mm => 50)
    end
    assert_equal "target.not_found", error.code
    assert_raises(PhComposer::CodedError) do
      Assemblies::Commands.remove_segment(@record, :layer_id => @layer["id"], :segment_id => "seg_MISSING00000")
    end
    assert_raises(PhComposer::CodedError) do
      Assemblies::Commands.remove_segment(@record, :layer_id => @layer["id"], :segment_id => @segment["id"])
    end
    one = fixture_assembly([[140, [[850, "wool"], [150, "wood"]]]])
    one["layers"][0]["segments"][0]["steel_stud_spacing_mm"] = 600
    assert_raises(PhComposer::CodedError) do
      Assemblies::Commands.update_segment(one, :layer_id => one["layers"][0]["id"],
                                               :segment_id => one["layers"][0]["segments"][1]["id"], :values => { "steel_stud_spacing_mm" => 600 })
    end
  end

  def test_air_barrier_is_cleared_on_layer_removal_and_remapped_on_duplicate
    marked = Assemblies::Commands.set_air_barrier(@record, :layer_id => @layer["id"], :face => "interior").record
    assert_nil Assemblies::Commands.remove_layer(marked, :layer_id => @layer["id"]).record["air_barrier"]
    marked["photo_collections"] = { "site" => ["photo"] }
    copy = Assemblies::Commands.duplicate_assembly_values(Assemblies::Assembly::Schema::KIND.values(marked), [])
    assert_equal copy["layers"][0]["id"], copy["air_barrier"]["layer_id"]
    refute_equal @layer["id"], copy["layers"][0]["id"]
    assert_equal({}, copy["photo_collections"])
  end

  def test_membrane_is_single_segment_and_snaps_to_one_mm
    result = Assemblies::Commands.set_segment_material(@record, :materials => fixture_materials,
                                                                :layer_id => @layer["id"], :segment_id => @segment["id"], :material_id => material_id("membrane"))
    # The existing 12 mm layer stays because only layers above 25 mm snap.
    assert_equal 12, result.record["layers"][0]["thickness_mm"]
    thick = @record["layers"][1]
    result = Assemblies::Commands.set_segment_material(@record, :materials => fixture_materials,
                                                                :layer_id => thick["id"], :segment_id => thick["segments"][0]["id"], :material_id => material_id("membrane"))
    assert_equal 1.0, result.record["layers"][1]["thickness_mm"]
    assert_raises(PhComposer::CodedError) do
      Assemblies::Commands.add_segment(result.record, :materials => fixture_materials, :layer_id => thick["id"])
    end
  end

  def test_duplicate_name_canonicalizes_existing_names_and_the_base
    records = [{ "name" => " TRIMMED (copy) " }, { "name" => " Trimmed (copy 2) " }]
    assert_equal "Trimmed (copy 3)", Assemblies::Commands.duplicate_name(" Trimmed ", records)
  end
end
