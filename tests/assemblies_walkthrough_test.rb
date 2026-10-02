# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/assembly_record_fixtures"
require_relative "../tools/examples/authoring/assemblies_walkthrough"

class AssembliesWalkthroughTest < PhComposerTestCase
  def setup
    super
    unless PhComposer::Registry.installed?("ph_composer.assemblies")
      PhComposer::Registry.install([PhComposer::Assemblies])
    end
  end

  def test_the_walkthrough_builds_and_reads_a_mixed_assembly_and_recovers_from_stale_edit
    result = AssemblyAuthoringWalkthrough.run
    assert result.fetch("passed"), result.inspect
    assert_equal 3, result.fetch("steps").count { |step| step.fetch("step").end_with?(".create") }
    assert_equal 2, result.fetch("material_ids").length
    assert result.fetch("steps").find { |row| row.fetch("step") == "stale edit" }.fetch("passed")
    text = File.read(File.expand_path("../tools/examples/authoring/assemblies_walkthrough.rb", __dir__))
    refute_match(/PhComposer::Assemblies|PhComposer::Zones/, text)
  end
end
