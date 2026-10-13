# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/window_record_fixtures"
require_relative "support/assembly_assignment_fixtures"

# Windows::Authoring, the one coordinator above the definition operations: the copied-identity repair
# first, the record proposal, then the placed Units following. The operations below it propose records
# only, which the last tests check without any placed Unit.
class WindowAuthoringTest < PhComposerTestCase
  include WindowRecordFixtures
  include AssemblyAssignmentFixtures

  U = PhComposer::Windows::Units
  PREFIX = "ph_composer.windows"
  OPERATIONS = %w[products/operations.rb types/operations.rb].freeze

  def setup
    super
    assignment_setup
    PhComposer::Registry.install([W]) unless PhComposer::Registry.installed?(W::FEATURE_ID)
    points = [[0, 0, 0], [3000, 0, 0], [3000, 3000, 0], [0, 3000, 0]].map { |point| Geom::Point3d.new(*point) }
    @group = Sketchup::Group.new(1000, Sketchup::Entities.new([Sketchup::Face.new(1001, {}, :points => points)]))
    @model.entities << @group
    assert_equal "completed", assignment_invoke("ph_composer.zones.make", "parent_path" => [],
                                                                          "entity_ids" => [1000]).fetch("status")
    assignment_classify(assignment_faces, "face_type" => { "mode" => "set", "value" => "Wall" },
                                          "boundary_condition" => { "mode" => "set", "value" => "Outdoors" })
    @host = assignment_faces.first.fetch("reference")
    @type_id = assignment_invoke("#{PREFIX}.types.create", "values" => { "name" => "Coordinated" })
               .dig("value", "id")
  end

  def place(x_m)
    result = assignment_invoke("#{PREFIX}.units.place", "host" => @host, "type_id" => @type_id,
                                                        "anchor" => "sill_center",
                                                        "offsets" => { "x_m" => x_m, "y_m" => 1.0 })
    assert_equal "completed", result.fetch("status"), result.inspect
  end

  def type
    PhComposer::Records::Engine.new(@model, PhComposer::Registry.current.catalog).find(W::TYPE_KIND, @type_id)
  end

  # A request and proposal as dispatch builds them, so a test can read the steps the coordinator added.
  def proposed(name)
    session = PhComposer::Sessions.for(@model)
    request = PhComposer::HandlerRequest.for(session, :owner => W::FEATURE_ID, :name => name,
                                                      :proposal => PhComposer::Operations::Proposal.new)
    yield request, request.proposal
    request.proposal.steps.map { |step| step.class.name.split("::").last }
  end

  def copy_first_unit
    original = U::Occurrences.all(@model).first
    copy = @group.entities.add_instance(original.entity.definition,
                                        Geom::Transformation.translation([200, 0, 0]) * original.entity.transformation)
    copy.glued_to = original.entity.glued_to
    U.write(copy, original.record)
    copy
  end

  def test_a_type_resize_with_two_anchored_units_adds_one_type_change_step_with_both
    place(0.8)
    place(2.0)
    steps = proposed("#{PREFIX}.types.update") do |request, proposal|
      value = W::Authoring.update_type(request, proposal, :id => @type_id, :values => { "columns_m" => [1.2] },
                                                          :expected_values => { "columns_m" => type["columns_m"] })
      assert_equal 2, value.fetch("unit_count")
    end
    assert_equal ["TypeChangeStep"], steps
  end

  # A rename renames the generated component, so only a field that is neither geometry nor name is free.
  def test_a_notes_only_type_edit_moves_no_unit
    place(0.8)
    steps = proposed("#{PREFIX}.types.update") do |request, proposal|
      W::Authoring.update_type(request, proposal, :id => @type_id, :values => { "notes" => "Checked" },
                                                  :expected_values => {})
    end
    refute_includes steps, "TypeChangeStep"
  end

  # With its last Unit removed the Type still owns its generated definition, which the delete removes.
  def test_a_type_delete_without_retarget_cleans_up_its_definition
    place(0.8)
    reference = assignment_query("#{PREFIX}.units.list").fetch("units").first.fetch("reference")
    assert_equal "completed", assignment_invoke("#{PREFIX}.units.remove", "units" => [reference]).fetch("status")
    steps = proposed("#{PREFIX}.types.delete") do |request, proposal|
      W::Authoring.delete_type(request, proposal, :id => @type_id)
    end
    assert_includes steps, "TypeCleanupStep"
  end

  def test_a_copied_unit_is_repaired_once_whatever_the_command_composes
    place(0.8)
    copy_first_unit
    steps = proposed("#{PREFIX}.frames.create") do |request, proposal|
      W::Authoring.create_product(request, proposal, "frames", :values => { "name" => "Repairing frame" })
      W::Authoring.update_settings(request, proposal, :values => W::Settings.read(@model),
                                                      :expected_values => W::Settings.read(@model))
    end
    assert_equal 1, steps.count("IdentityStep")
  end

  def test_a_frame_create_with_a_locked_copy_refuses_then_repairs_once_unlocked
    place(0.8)
    copy = copy_first_unit
    copy.locked = true
    refused = assignment_invoke("#{PREFIX}.frames.create", "values" => { "name" => "Blocked frame" })
    assert_equal %w[refused target.locked none], refused.values_at("status", "code", "effect"), refused.inspect
    assert_empty W::Products::KINDS.fetch("frames").store.ids(@model)

    copy.locked = false
    created = assignment_invoke("#{PREFIX}.frames.create", "values" => { "name" => "Blocked frame" })
    assert_equal "committed", created.fetch("effect"), created.inspect
    assert_equal 2, U::Occurrences.all(@model).map { |item| item.record.fetch("id") }.uniq.length
  end

  def test_the_definition_operations_propose_records_only
    OPERATIONS.each do |file|
      source = File.read(File.join(SOURCE_ROOT, "ph_composer/features/windows", file), :encoding => "UTF-8")
      refute_match(/Units::/, source, "#{file} names placement")
    end
    steps = proposed("#{PREFIX}.types.update") do |request, proposal|
      W::Types::Operations.update(request, proposal, :id => @type_id, :values => { "columns_m" => [1.2] },
                                                     :expected_values => { "columns_m" => type["columns_m"] })
      W::Products::Operations.create(request, proposal, "frames", :values => { "name" => "Record only" })
    end
    assert_empty steps
  end
end
