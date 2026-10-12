# frozen_string_literal: true

require_relative "test_helper"

# The native "Make Zone independent…" item drives the same public read, preview and action a script
# uses, and asks once before it writes.
class ZoneIndependenceMenuTest < PhComposerTestCase
  MENU = PhComposer::Zones::IndependenceMenu
  ZONE_STORE = PhComposer::Zones::ZONE_STORE

  def setup
    super
    @model = Sketchup.active_model
    faces = 3.times.map { |index| Sketchup::Face.new(101 + index) }
    @original = Sketchup::Group.new(100, Sketchup::Entities.new(faces))
    @copy = Sketchup::Group.new(200, @original.entities)
    record = { "id" => "zon_#{'a' * 12}", "schema_version" => 1, "name" => "Unit A",
               "building_segment" => "Main Building", "level" => nil, "ground_depth_mm" => 0.0,
               "user_data" => {}, "extension_data" => {} }
    [@original, @copy].each do |group|
      ZONE_STORE.write(group, record)
      @model.entities << group
    end
    @model.selection.add(@copy)
    @session = PhComposer::Sessions.for(@model)
    treat_duplicates_as_existing(@model)
  end

  def test_offered_on_a_selected_zone_group
    assert MENU.available?(@session)
    @model.selection.clear
    @model.selection.add(@original.entities.to_a.first)
    refute MENU.available?(@session)
  end

  def test_confirming_the_review_makes_the_selected_copy_independent
    UI.messagebox_result = IDYES

    MENU::Client.new(@session).run

    refute_equal ZONE_STORE.read(@original).fetch("id"), ZONE_STORE.read(@copy).fetch("id")
    refute_equal @original.definition.persistent_id, @copy.definition.persistent_id
    assert UI.messages.any? { |message| message.include?("\"Unit A\" will get its own Faces") }
    assert UI.messages.any? { |message| message.include?("Make Zone Independent") }
  end

  def test_cancelling_the_review_writes_nothing
    UI.messagebox_result = IDNO

    MENU::Client.new(@session).run

    assert_equal ZONE_STORE.read(@original), ZONE_STORE.read(@copy)
    assert_equal @original.definition.persistent_id, @copy.definition.persistent_id
  end

  def test_a_zone_it_cannot_act_on_shows_what_to_do_instead
    @copy.locked = true

    MENU::Client.new(@session).run

    assert_match(/Unlock it first/, UI.messages.last)
    assert_equal ZONE_STORE.read(@original), ZONE_STORE.read(@copy)
  end
end
