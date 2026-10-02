# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/assembly_assignment_fixtures"

# Colour-by projections and native menu tests read through a foundation read request, so redrawing
# the overlay or opening the context menu issues no caller handle.
class ReadContextTest < PhComposerTestCase
  include AssemblyAssignmentFixtures

  def setup
    super
    assignment_setup
    assignment_zone(100)
    id = assignment_assembly("Colour", "color" => "#123456")
    assignment_invoke("#{FACE_PREFIX}.assign_assembly", assignment_params(assignment_faces, id))
  end

  def test_projections_and_context_menus_leave_the_caller_registry_unchanged
    service = PhComposer::ColourBy.for(@session).activate("#{FACE_PREFIX}.by_assembly")
    @model.selection.add(@model.entities.first.entities.first)
    callers = @session.callers.count

    3.times do
      service.invalidate!(:force => true)
      PhComposer::Commands.install_feature_menus(UI::Menu.new("Context"), :contextual => true)
    end

    assert_equal 1, service.rows.first.count
    assert_equal callers, @session.callers.count
  end

  # The shell builds read requests; a feature that built its own could assert any owner.
  def test_features_neither_build_read_requests_nor_reach_global_registry_state
    root = File.expand_path("../src/ph_composer", __dir__)
    sources = Dir[File.join(root, "{features,library}", "**", "*.rb")].to_h { |path| [path, File.read(path)] }

    assert_empty(sources.select { |_path, text| text.match?(/HandlerRequest\.for|Request\.new\(/) }.keys)
    assert_empty(sources.select { |_path, text| text.include?("instance_variable_") }.keys)
    assert_empty(sources.select { |path, text| path.include?("/features/") && text.include?("Registry.current") }.keys)
  end
end
