# frozen_string_literal: true

require_relative "test_helper"
require_relative "support/space_fixtures"

# Volume protection, the Spaces reconciler and the edit-context commands (context/TECH_STACK.md,
# "SketchUp Model and transaction rules").
class SpacesContextTest < PhComposerTestCase
  include SpaceFixtures

  API = PhComposer::API
  SPACES = PhComposer::Spaces

  def setup
    super
    @model = Sketchup.active_model
    @session = PhComposer::Sessions.for(@model)
    @context = API.connect(:session_id => @session.id)
    @sequence = 0
    @first = volume_group(111, volume_record("A"), [floor_face(112, rectangle(0, 0, 2, 2), segment_record("A"))])
    @second = volume_group(113, volume_record("B", :number => 2), [floor_face(114, rectangle(2, 0, 2, 2),
                                                                              segment_record("B"))])
    @space = space_group(110, space_record("S", :number => "1"), [@first, @second])
    @zone = zone_group(100, "Z", [@space])
    @model.entities << @zone
    [@first, @second].each { |volume| SPACES::VOLUME_STORE.write(volume, home(volume)) }
  end

  def home(volume)
    SPACES::VOLUME_STORE.read(volume).merge("home_transform" => volume.transformation.to_a)
  end

  def view(name, params = {})
    result = API.view(:context => @context, :name => name, :params => params)
    assert_equal "completed", result["status"], result.inspect
    result.fetch("value")
  end

  def reference(volume)
    { "volume_id" => SPACES::VOLUME_STORE.read(volume).fetch("id"), "entity_path" => [100, 110, volume.persistent_id] }
  end

  def reconciler
    SPACES::Reconciler.for(@session)
  end

  def test_entering_a_volume_unlocks_it_in_one_named_step_and_opens_the_path
    before = @model.operations.length
    assert_equal({ "path" => [100, 110, 111] }, view("ph_composer.spaces.context.enter_volume",
                                                     "volume" => reference(@first)))
    refute @first.locked?
    assert_equal [@zone, @space, @first], @model.active_path
    assert_equal [["Enter Volume", true, :committed]], @model.operations[before..-1]
  end

  def test_a_direct_switch_protects_the_first_volume_and_finds_nothing_moved
    view("ph_composer.spaces.context.enter_volume", "volume" => reference(@first))
    view("ph_composer.spaces.context.enter_volume", "volume" => reference(@second))
    assert @first.locked?
    refute @second.locked?
    assert_equal [@zone, @space, @second], @model.active_path
    codes = API.query(:context => @context, :name => "ph_composer.spaces.all").dig("value", "spaces", 0, "volumes")
               .flat_map { |volume| volume.fetch("findings").map { |finding| finding["code"] } }
    assert_empty codes
  end

  def test_leaving_by_any_callback_order_queues_one_transparent_protection
    view("ph_composer.spaces.context.enter_volume", "volume" => reference(@first))
    before = @model.operations.length
    # The host's exit: the path is already outside when the commit arrives, then the path change.
    @model.instance_variable_set(:@active_path, [@zone, @space])
    @session.host_event(:transaction_committed)
    @session.host_event(:active_path_changed)
    @session.host_event(:transaction_committed)
    assert reconciler.pending?
    refute @first.locked?
    UI.run_timers
    assert @first.locked?
    refute reconciler.pending?
    assert_equal [["Protect Volume", true, false, true]], @model.operation_starts.last(1)
    assert_equal before + 1, @model.operations.length
  end

  def test_a_pass_over_state_that_already_matches_writes_nothing
    before = @model.operations.length
    revision = @session.revision
    @session.host_event(:transaction_committed)
    @session.host_event(:active_path_changed)
    refute reconciler.pending?
    UI.run_timers
    assert_equal before, @model.operations.length
    assert_equal revision + 2, @session.revision, "only the two callbacks advanced it"
  end

  def test_save_protects_the_open_volume_without_moving_the_path_then_closes_it
    view("ph_composer.spaces.context.enter_volume", "volume" => reference(@first))
    @model.save(File.join(Dir.tmpdir, "spaces-context-test.skp"))
    assert @first.locked?
    assert_equal [@zone, @space], @model.active_path
  end

  def test_close_and_open_move_the_path_and_protect_on_the_way_out
    view("ph_composer.spaces.context.enter_volume", "volume" => reference(@first))
    assert_equal({ "path" => [100, 110] }, view("ph_composer.spaces.context.close"))
    assert @first.locked?
    assert_equal({ "path" => [100] }, view("ph_composer.spaces.context.close"))
    assert_equal({ "path" => [100, 110] },
                 view("ph_composer.spaces.context.open", "space" => { "space_id" => "spc_SSSSSSSSSSSS",
                                                                      "entity_path" => [100, 110] }))
  end

  def test_a_moved_volume_is_found_and_restore_position_clears_it_in_one_step
    @first.transformation = Geom::Transformation.translation([10, 0, 0])
    volume = API.query(:context => @context, :name => "ph_composer.spaces.all").dig("value", "spaces", 0, "volumes", 0)
    assert volume["moved"]
    assert_includes volume.fetch("findings").map { |finding| finding["code"] }, "space.volume_moved"
    before = @model.operations.length
    result = invoke("ph_composer.spaces.volumes.restore_position", "volume" => reference(@first))
    assert_equal "completed", result["status"], result.inspect
    assert_equal({ "volume_id" => "vol_AAAAAAAAAAAA", "moved" => true }, result["value"])
    assert_equal before + 1, @model.operations.length
    assert_equal Geom::Transformation.new.to_a, @first.transformation.to_a
    assert @first.locked?
  end

  def test_a_protected_volumes_floor_segment_edits_and_a_user_locked_space_refuses
    segment = { "floor_segment_id" => "fsg_AAAAAAAAAAAA", "entity_path" => [100, 110, 111, 112] }
    edited = invoke("ph_composer.spaces.update", "reference" => segment, "values" => { "weighting_factor" => 0.5 },
                                                 "expected_values" => { "weighting_factor" => 1.0 })
    assert_equal "completed", edited["status"], edited.inspect
    @space.locked = true
    refused = invoke("ph_composer.spaces.update", "reference" => segment, "values" => { "weighting_factor" => 1.0 },
                                                  "expected_values" => { "weighting_factor" => 0.5 })
    assert_equal %w[refused target.locked], refused.values_at("status", "code")
  end

  def test_an_unlocked_volume_outside_the_path_is_unprotected
    @second.locked = false
    codes = API.query(:context => @context, :name => "ph_composer.spaces.all").dig("value", "spaces", 0, "volumes", 1,
                                                                                   "findings")
    assert_equal ["space.volume_unprotected"], codes.map { |finding| finding["code"] }
  end

  # The host reports the open context's children in world coordinates; the stub does not, so the child's
  # transform is stubbed to what the host would answer.
  def test_a_child_of_the_open_context_reads_and_writes_relative_to_its_parent
    @space.transformation = Geom::Transformation.translation([0, 0, 20])
    @model.active_path = [@zone, @space]
    local = Geom::Transformation.translation([5, 0, 0])
    world = @model.edit_transform * local
    @first.stub(:transformation, world) do
      assert_equal local.to_a, SPACES::Protection.local_transform(@model, @first, [100, 110]).to_a
    end
    assert_nil SPACES::Protection.local_transform(@model, @space, [100])
    @model.active_path = [@zone, @space, @second]
    assert_nil SPACES::Protection.local_transform(@model, @first, [100, 110]), "a sibling of the open Volume"
    @model.active_path = [@zone, @space]
    written = nil
    @first.stub(:transformation=, ->(value) { written = value }) do
      SPACES::Protection.set_local_transform(@model, @first, [100, 110], local)
    end
    assert_equal world.to_a, written.to_a
  end

  def test_detach_drops_pending_protection
    view("ph_composer.spaces.context.enter_volume", "volume" => reference(@first))
    @model.instance_variable_set(:@active_path, [@zone])
    @session.host_event(:transaction_committed)
    assert reconciler.pending?
    reconciler.detach
    refute reconciler.pending?
    UI.run_timers
    refute @first.locked?
  end

  private

  def invoke(name, params)
    @sequence += 1
    API.invoke(:context => @context, :name => name, :params => params,
               :request => { "sequence" => @sequence, "expected_revision" => @session.revision })
  end
end
