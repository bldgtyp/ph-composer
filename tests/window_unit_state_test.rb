# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/window_record_fixtures"
require_relative "../src/ph_composer/features/windows/units/definition_writer"
require_relative "../src/ph_composer/features/windows/units/state"

class WindowUnitStateTest < PhComposerTestCase
  include WindowRecordFixtures
  U = PhComposer::Windows::Units

  def setup
    super
    @model = Sketchup.active_model
    @type = window_record
    @definition = U::DefinitionWriter.create(:model => @model, :type => @type,
                                             :plan => U::DefinitionPlan.build(@type))
    @unit = @model.entities.add_instance(@definition, Geom::Transformation.new)
    U.write(@unit, "id" => "wun_AAAAAAAAAAAA", "schema_version" => 1,
                   "window_type_id" => @type.fetch("id"), "anchor" => "sill_center")
    @host = @model.entities.add_face([[-100, -100, 0], [100, -100, 0],
                                      [100, 100, 0], [-100, 100, 0]].map { |point| Geom::Point3d.new(*point) })
    @unit.glued_to = @host
    @geometry = PhComposer::FaceGeometry.capture(@host, Geom::Transformation.new)
  end

  def findings(**options)
    item = U::Occurrences.all(@model).first
    U::State.findings(item, **{ :type => @type, :canonical_definition => @definition,
                                :host_geometry => @geometry, :host_values => { "face_type" => "Wall", "boundary_condition" => "Outdoors" } }
      .merge(options))
  end

  def codes(**options)
    findings(**options).map { |finding| finding.fetch("code") }
  end

  def test_clean_hosted_unit_and_shared_id_reads_leave_model_unchanged
    before = U::MutationScope.new(:definition_ids => [@definition.persistent_id]).capture(@model)
    assert_empty codes
    reference = { "unit_id" => "wun_AAAAAAAAAAAA", "entity_path" => [@unit.persistent_id] }
    assert_equal [{ "code" => "window.copy_id_pending", "repair" => {
      "name" => "ph_composer.windows.units.repair_copied_identities", "params" => { "units" => [reference] }
    } }],
                 findings(:shared_id => true)
    assert_equal before, U::MutationScope.new(:definition_ids => [@definition.persistent_id]).capture(@model)
  end

  def test_missing_glue_off_plane_overhang_and_overlap_are_distinct
    @unit.glued_to = nil
    assert_equal ["window.unhosted"], codes
    @unit.glued_to = @host
    @unit.transformation = Geom::Transformation.translation([0, 0, 1])
    assert_equal ["window.off_host"], codes
    @unit.transformation = Geom::Transformation.translation([200, 0, 0])
    assert_equal ["window.overhang"], codes
    @unit.transformation = Geom::Transformation.new
    polygon = U::WorldGeometry.map(U::DefinitionPlan.build(@type), @unit.transformation.to_a).outer_polygon_m
    assert_equal ["window.overlap"], codes(:existing_polygons_m => [polygon])
  end

  def test_unknown_type_detached_and_actual_pane_edit_findings
    assert_equal ["window.unknown_type"], codes(:type => nil)
    assert_equal ["window.definition_detached"], codes(:canonical_definition => nil)
    @definition.entities.grep(Sketchup::Face).first.reverse!
    assert_equal ["window.geometry_differs"], codes
  end

  def test_scaled_and_mirrored_transform_findings_are_not_silent_repairs
    matrix = Geom::Transformation.new.to_a
    matrix[0] = -1.2
    @unit.transformation = Geom::Transformation.new(matrix)
    result = findings.to_h { |finding| [finding.fetch("code"), finding.fetch("repair")] }
    assert_equal %w[window.scaled window.mirrored], result.keys
    assert_nil result.fetch("window.scaled"), "Reset to Type refuses a mirrored Window, so it is not offered"
    assert_equal "ph_composer.windows.units.new_flipped_type", result.fetch("window.mirrored").fetch("name")
    unknown = findings(:type => nil).to_h { |finding| [finding.fetch("code"), finding.fetch("repair")] }
    assert_nil unknown.fetch("window.mirrored"), "Every repair but swap needs the Window's Type"
    assert_equal "ph_composer.windows.units.swap_type", unknown.fetch("window.unknown_type").fetch("name")
    assert_equal matrix, @unit.transformation.to_a
  end

  def test_normal_only_scale_does_not_report_changed_flat_aperture_size
    matrix = Geom::Transformation.new.to_a
    matrix[10] = 2.0
    @unit.transformation = Geom::Transformation.new(matrix)
    assert_empty codes
  end
end
