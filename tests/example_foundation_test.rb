# frozen_string_literal: true

require_relative "test_helper"

# The development example and its walkthrough, run offline against the stub. The same script runs in
# a real host through the bridge for the phase's host evidence.
class ExampleFoundationTest < PhComposerTestCase
  def setup
    super
    load File.expand_path("../tools/examples/foundation/load.rb", __dir__)
  end

  def test_the_walkthrough_passes_every_step_with_the_panel_closed
    result = ExampleWalkthrough.run

    failed = result.fetch("steps").reject { |step| step.fetch("passed") }
    assert_empty failed
    assert_equal ["create", "read", "update", "read back", "stale second client", "retry", "duplicate", "summary"],
                 result.fetch("steps").map { |step| step.fetch("step") }
  end

  def test_the_example_needs_no_change_outside_its_own_files
    registry = PhComposer::Registry.current

    assert_equal ExampleFoundation::ID, registry.owner_of("example.foundation.update_parts")
    assert_empty PhComposer::FEATURES, "the shipping composition root still lists no feature"
  end

  def test_loading_the_example_twice_installs_it_once
    load File.expand_path("../tools/examples/foundation/load.rb", __dir__)

    assert_equal 1, PhComposer::Registry.current.features.keys.count(ExampleFoundation::ID)
  end
end
