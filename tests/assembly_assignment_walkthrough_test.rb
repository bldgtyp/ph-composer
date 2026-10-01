# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/assembly_assignment_fixtures"
require_relative "../tools/examples/authoring/assembly_assignment_walkthrough"

class AssemblyAssignmentWalkthroughTest < PhComposerTestCase
  include AssemblyAssignmentFixtures

  def test_public_client_preserves_surface_pair_and_replaces_all_assignment_references
    assignment_setup
    assignment_pair(100)
    result = PhComposerAssemblyAssignmentWalkthrough.run(:session_id => @session.id)
    assert_equal true, result.fetch("passed"), result.inspect
    assert_equal 2, result.fetch("faces").length
  end
end
