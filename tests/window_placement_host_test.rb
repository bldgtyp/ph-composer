# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/window_record_fixtures"
require_relative "support/assembly_assignment_fixtures"
require_relative "../src/ph_composer/features/windows/placement/host"

class WindowPlacementHostTest < PhComposerTestCase
  include AssemblyAssignmentFixtures
  W = PhComposer::Windows
  HOSTS = W::Placement::Hosts

  def setup
    super
    assignment_setup
    PhComposer::Registry.install([W]) unless PhComposer::Registry.installed?(W::FEATURE_ID)
  end

  def request
    PhComposer::HandlerRequest.new(:model => @model, :session => @session, :revision => @session.revision,
      :registry => PhComposer::Registry.current, :owner => W::FEATURE_ID, :query_stack => [], :params => {},
      :engine => PhComposer::Records::Engine.new(@model, PhComposer::Registry.current.catalog))
  end

  def test_unclassified_host_uses_public_face_state_without_assignment_write
    group, faces = assignment_zone(100)
    reference = assignment_faces.first.fetch("reference")
    count = @model.operations.length
    host = HOSTS.resolve(request, reference)
    assert_same faces.first, host.entity
    assert_equal [group.persistent_id], host.parent_path
    assert_empty host.values
    assert_nil STORE.read(faces.first)
    assert_equal count, @model.operations.length
  end

  def test_nested_unique_wrapper_is_resolved_in_world_geometry
    group, faces = assignment_zone(200, 1, :nested => true)
    wrapper = group.entities.to_a.first
    wrapper.transformation = Geom::Transformation.translation([10, 20, 30])
    host = HOSTS.resolve(request, assignment_faces.first.fetch("reference"))
    assert_equal [group.persistent_id, wrapper.persistent_id], host.parent_path
    assert_same faces.first, host.entity
    assert_equal [10, 20, 30].map { |value| value * PhComposer::INCH_TO_M }, host.geometry.outer_loop.first
  end

  def test_surface_host_refuses_from_public_semantics
    rows = assignment_pair(300)
    error = assert_raises(PhComposer::CodedError) { HOSTS.resolve(request, rows.first.fetch("reference")) }
    assert_equal "window.surface_host", error.code
  end

  def test_stale_reference_and_locked_parent_refuse
    group, = assignment_zone(400)
    row = assignment_faces.first
    assignment_classify([row], "face_type" => { "mode" => "set", "value" => "Wall" })
    error = assert_raises(PhComposer::CodedError) { HOSTS.resolve(request, row.fetch("reference")) }
    assert_equal "target.changed", error.code
    group.locked = true
    error = assert_raises(PhComposer::CodedError) { HOSTS.resolve(request, assignment_faces.first.fetch("reference")) }
    assert_equal "target.locked", error.code
  end

  def test_shared_unstamped_parent_below_zone_refuses
    group, = assignment_zone(500, 1, :nested => true)
    wrapper = group.entities.to_a.first
    group.entities << Sketchup::Group.new(700, wrapper.entities)
    reference = assignment_faces.first.fetch("reference")
    error = assert_raises(PhComposer::CodedError) { HOSTS.resolve(request, reference) }
    assert_equal "target.shared_definition", error.code
  end
end
