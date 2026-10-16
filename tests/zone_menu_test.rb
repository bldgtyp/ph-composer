# frozen_string_literal: true

require_relative "test_helper"

class ZoneMenuTest < PhComposerTestCase
  API = PhComposer::API
  ZONES = PhComposer::Zones

  def setup
    super
    @model = Sketchup.active_model
    @session = PhComposer::Sessions.for(@model)
    @group = Sketchup::Group.new(100, Sketchup::Entities.new([Sketchup::Face.new(101)]))
    @model.entities << @group
    @model.selection.add(@group)
    @client = ZONES::ZoneMenu::Client.new(@session)
    @declaration = PhComposer::Registry.current.menu_items.fetch("ph_composer.zones.make_menu")
  end

  def test_valid_selection_offers_make_zone_under_ph_composer
    menu = UI::Menu.new("Context")
    menus = PhComposer::Commands.install_feature_menus(menu, :contextual => true)

    assert @declaration.available.call(read)
    assert_equal "Make Zone", menus.fetch(PhComposer::EXTENSION_NAME).entries.first.first
    assert_equal({ "parent_path" => [], "entity_ids" => [100] }, ZONES.make_target(@model))
    assert_empty @model.operations
  end

  def test_group_menu_uses_public_action_in_one_undo_step_with_panel_closed
    @declaration.handler.call(@session)

    assert_equal "Zone 1", ZONES::ZONE_STORE.read(@group).fetch("name")
    assert_equal "Zone 1", @group.name
    assert_equal [["Make Zone", true, :committed]], @model.operations
    refute PhComposer::Panel.open?
    assert @model.undo
    assert_nil ZONES::ZONE_STORE.read(@model.entities.to_a.first)
    refute @model.undo
    assert @model.redo
    assert_equal "Zone 1", ZONES::ZONE_STORE.read(@model.entities.to_a.first).fetch("name")
  end

  def test_loose_faces_and_edges_can_be_grouped_from_the_menu
    face = Sketchup::Face.new(201)
    edge = Sketchup::Edge.new(202, Geom::Point3d.new(0, 0, 0), Geom::Point3d.new(1, 0, 0))
    @model.entities << face << edge
    select(face, edge)

    assert @declaration.available.call(read)
    result = @client.make

    assert_equal "completed", result.fetch("status")
    zone = @model.entities.to_a.grep(Sketchup::Group).find { |group| ZONES::ZONE_STORE.read(group) }
    assert_equal [face, edge], zone.entities.to_a
    assert_equal 1, @model.operations.length
  end

  def test_invalid_selection_omits_the_item
    face = Sketchup::Face.new(301)
    @model.entities << face
    [[], [@group, face], [Sketchup::Face.new(302)]].each do |selection|
      select(*selection)

      refute @declaration.available.call(read)
      menus = PhComposer::Commands.install_feature_menus(UI::Menu.new("Context"), :contextual => true)
      # Another feature (Create Space) may offer a selected Face an item in the same submenu.
      items = menus.key?(PhComposer::EXTENSION_NAME) ? menus.fetch(PhComposer::EXTENSION_NAME).entries : []
      refute_includes items.map { |entry| entry.is_a?(Array) ? entry.first : entry }, "Make Zone"
    end
    assert_empty @model.operations
  end

  def test_locked_group_is_not_offered
    @group.locked = true

    refute @declaration.available.call(read)
    assert_empty @model.operations
  end

  def test_component_instance_is_not_offered
    definition = Sketchup::ComponentDefinition.new(Sketchup::Entities.new)
    component = Sketchup::ComponentInstance.new(350, definition)
    @model.entities << component
    select(component)

    refute @declaration.available.call(read)
    assert_empty @model.operations
  end

  def test_existing_zone_is_not_offered
    assert_equal "completed", @client.make.fetch("status")

    refute @declaration.available.call(read)
    assert_equal 1, @model.operations.length
  end

  def test_a_group_containing_a_zone_is_not_offered
    assert_equal "completed", @client.make.fetch("status")
    parent = Sketchup::Group.new(400, Sketchup::Entities.new)
    @model.entities << parent
    parent.entities << @group
    select(parent)

    refute @declaration.available.call(read)
    assert_equal 1, @model.operations.length
  end

  def test_selection_inside_an_existing_zone_is_not_offered
    assert_equal "completed", @client.make.fetch("status")
    @model.active_path = [@group]
    select(@group.entities.to_a.first)

    refute @declaration.available.call(read)
    assert_equal 1, @model.operations.length
  end

  def test_losing_selection_after_menu_build_does_not_write
    assert @declaration.available.call(read)
    select
    notices = []
    @session.stub(:notice, ->(message, **_options) { notices << message }) do
      API.stub(:invoke, ->(**_args) { flunk "The lost selection must not invoke Make Zone." }) { @client.make }
    end

    assert notices.first.end_with?("Nothing was written.")
    assert_equal notices.first, Sketchup.status_texts.last
    assert_empty @model.operations
    assert_nil ZONES::ZONE_STORE.read(@group)
  end

  def test_query_revision_and_target_are_used_by_the_public_action
    params = { "parent_path" => [900], "entity_ids" => [901] }
    read = { "status" => "completed", "revision" => 37, "value" => { "make_zone" => params } }
    invocation = nil
    invoke = lambda do |**args|
      invocation = args
      { "status" => "completed", "message" => "Done." }
    end
    API.stub(:query, read) { API.stub(:invoke, invoke) { @client.make } }

    assert_equal "ph_composer.zones.make", invocation.fetch(:name)
    assert_equal params, invocation.fetch(:params)
    assert_equal({ "sequence" => 1, "expected_revision" => 37 }, invocation.fetch(:request))
  end

  def test_query_refusal_is_reported_without_invocation
    failed = { "status" => "refused", "message" => "The Model has deferred work. Nothing was written." }
    API.stub(:query, failed) do
      API.stub(:invoke, ->(**_args) { flunk "A failed read must not invoke Make Zone." }) do
        assert_equal failed, @client.make
      end
    end

    assert_equal failed.fetch("message"), Sketchup.status_texts.last
    assert_empty @model.operations
  end

  def test_model_change_after_target_read_refuses_without_writing
    read = API.query(:context => API.connect(:session_id => @session.id), :name => "ph_composer.zones.list")
    @session.host_event(:transaction_committed)

    result = API.stub(:query, read) { @client.make }

    assert_equal "revision.stale", result.fetch("code")
    assert_equal "none", result.fetch("effect")
    assert_empty @model.operations
    assert_nil ZONES::ZONE_STORE.read(@group)
  end

  private

  def select(*entities)
    @model.selection.clear
    entities.each { |entity| @model.selection.add(entity) }
  end

  def read
    PhComposer::HandlerRequest.for(@session, :owner => @declaration.owner, :name => @declaration.name)
  end
end
