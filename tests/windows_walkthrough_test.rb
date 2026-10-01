# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/window_record_fixtures"
require_relative "../tools/examples/authoring/windows_walkthrough"

class WindowsWalkthroughTest < PhComposerTestCase
  include WindowRecordFixtures

  def test_panel_closed_public_walkthrough_without_zone_and_undo_redo
    PhComposer::Registry.install([W]) unless PhComposer::Registry.installed?(W::FEATURE_ID)
    model = Sketchup.active_model
    assert_empty model.entities.to_a
    result = WindowAuthoringWalkthrough.run
    assert result.fetch("passed"), result.inspect
    assert_equal 7, result.fetch("steps").count { |step| step["effect"] == "committed" }
    engine = PhComposer::Records::Engine.new(model, PhComposer::Registry.current.catalog)
    before = engine.find(W::TYPE_KIND, result.fetch("type_id"))
    model.undo
    assert engine.find(W::TYPE_KIND, result.fetch("type_id"))["elements"].all? { |element|
 element["installs"].values.none? }
    model.redo
    assert_equal before, engine.find(W::TYPE_KIND, result.fetch("type_id"))
    text = File.read(File.expand_path("../tools/examples/authoring/windows_walkthrough.rb", __dir__))
    refute_match(/PhComposer::Windows|PhComposer::Zones|Sketchup/, text)
  end
end
