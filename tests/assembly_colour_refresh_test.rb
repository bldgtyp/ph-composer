# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/assembly_assignment_fixtures"

# This projection reads its contributor through the public API. A post-action rebuild therefore
# needs the mutation lock released, not merely a committed native operation.
class AssemblyColourRefreshTest < PhComposerTestCase
  include AssemblyAssignmentFixtures

  def setup
    super
    assignment_setup
    assignment_zone(100)
    @assembly_id = assignment_assembly("Colour", "color" => "#123456")
    assignment_invoke("#{FACE_PREFIX}.assign_assembly", assignment_params(assignment_faces, @assembly_id))
    @service = PhComposer::ColourBy.for(@session).activate("#{FACE_PREFIX}.by_assembly")
  end

  def test_public_edit_refreshes_the_overlay_and_native_undo_redo_keep_it_active
    rebuilt = @service.rebuilds
    result = assignment_invoke("#{ASSEMBLY_PREFIX}.update", colour_edit)

    assert_equal %w[completed committed], result.values_at("status", "effect")
    assert_colour [34, 85, 136]
    assert_equal rebuilt + 1, @service.rebuilds, "early commit and post-action publication coalesce"
    assert @model.undo
    assert_colour [18, 52, 86]
    assert @model.redo
    assert_colour [34, 85, 136]
  end

  def test_panel_first_snapshot_contains_the_updated_active_legend
    dialog = PhComposer::Panel.show
    dialog.fire("ph_composer_message", JSON.generate("type" => "panel.ready", "payload" => {}))
    dialog.scripts.clear
    dialog.fire("ph_composer_message", JSON.generate("type" => "action.invoke", "payload" => {
      "request_id" => "colour:1", "session" => @session.id, "name" => "#{ASSEMBLY_PREFIX}.update",
      "params" => colour_edit, "expected_revision" => @session.revision
    }))
    messages = dialog.scripts.map { |script| JSON.parse(script[/receive\((.*)\)\z/m, 1]) }
    snapshot = messages.find { |message| message["type"] == "panel.snapshot" }.fetch("payload")
    legend = snapshot.dig("sections", "#{PhComposer::ColourBy::FEATURE_ID}.legend", "value")

    assert_equal "#{FACE_PREFIX}.by_assembly", legend.fetch("mode")
    assert_equal [34, 85, 136], legend.fetch("rows").first.fetch("colour")
    assert_equal "committed", messages.last.dig("payload", "outcome", "effect")
    refute @session.refresh.pending?, "the panel does not need a later refresh to repair its first snapshot"
  end

  def test_change_subscriber_can_query_and_retrieve_the_retained_outcome
    observations = []
    sequence = @sequence + 1
    unsubscribe = PhComposer::Sessions.on_change do |session, source, _detail|
      next unless session.equal?(@session) && source == :action

      observations << API.query(:context => @context, :name => "#{ASSEMBLY_PREFIX}.list")
      observations << API.outcome(:context => @context, :request => { "sequence" => sequence })
    end
    result = assignment_invoke("#{ASSEMBLY_PREFIX}.update", colour_edit)

    assert_equal "completed", observations.first.fetch("status")
    assert_equal result, observations.last
  ensure
    unsubscribe&.call
  end

  private

  def colour_edit
    { "id" => @assembly_id, "values" => { "color" => "#225588" },
      "expected_values" => { "color" => "#123456" } }
  end

  def assert_colour(colour)
    assert @service.active?
    assert_equal colour, @service.rows.first.colour
    assert @service.fills.key?(colour)
  end
end
