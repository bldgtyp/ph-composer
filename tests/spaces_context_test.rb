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

  # Opening a protected Volume is two calls: the action unlocks it as its own Undo step, the view command
  # opens it.
  def enter(volume)
    result = invoke("ph_composer.spaces.volumes.unprotect", "volume" => reference(volume))
    assert_equal "completed", result["status"], result.inspect
    view("ph_composer.spaces.context.open", "reference" => reference(volume))
  end

  def test_unprotect_unlocks_in_one_named_step_and_open_opens_the_path
    refused = API.view(:context => @context, :name => "ph_composer.spaces.context.open",
                       :params => { "reference" => reference(@first) })
    assert_equal %w[refused space.volume_protected], refused.values_at("status", "code")
    before = @model.operations.length
    assert_equal({ "path" => [100, 110, 111] }, enter(@first))
    refute @first.locked?
    assert_equal [@zone, @space, @first], @model.active_path
    assert_equal [["Unprotect Volume", true, :committed]], @model.operations[before..-1]
  end

  def test_unprotect_needs_model_write
    viewer = API.connect(:session_id => @session.id, :capabilities => %w[read view])
    result = API.invoke(:context => viewer, :name => "ph_composer.spaces.volumes.unprotect",
                        :params => { "volume" => reference(@first) },
                        :request => { "sequence" => 1, "expected_revision" => @session.revision })
    assert_equal %w[refused request.capability_denied], result.values_at("status", "code")
    assert @first.locked?
  end

  def test_a_direct_switch_protects_the_first_volume_and_finds_nothing_moved
    enter(@first)
    enter(@second)
    assert @first.locked?
    refute @second.locked?
    assert_equal [@zone, @space, @second], @model.active_path
    codes = API.query(:context => @context, :name => "ph_composer.spaces.all").dig("value", "spaces", 0, "volumes")
               .flat_map { |volume| volume.fetch("findings").map { |finding| finding["code"] } }
    assert_empty codes
  end

  def test_leaving_by_any_callback_order_queues_one_transparent_protection
    enter(@first)
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

  # Protection still pending for one Volume while another is open: settling it commits inside the save,
  # and that commit must not cost the open Volume its protection in the saved file.
  def test_save_protects_pending_and_open_volumes_before_the_file_is_written
    enter(@first)
    @second.locked = false
    @model.instance_variable_set(:@active_path, [@zone, @space, @second])
    @session.host_event(:active_path_changed)
    assert reconciler.pending?
    saved = nil
    Sketchup.stub(:store_model, ->(_path, _model) { saved = [@first.locked?, @second.locked?] }) do
      @model.save(File.join(Dir.tmpdir, "spaces-context-pending.skp"))
    end
    assert_equal [true, true], saved
  end

  # Undo leaves the Volume with nothing on the path to remember it by; Redo then restores its unlocked
  # state. The stub's Undo moves the path to the root, as the host's can.
  def test_redo_that_restores_an_unlocked_volume_off_the_path_protects_it
    enter(@first)
    @model.instance_variable_set(:@active_path, [@zone, @space])
    @first.locked = true
    @session.host_event(:transaction_undone)
    refute reconciler.pending?
    @first.locked = false
    @session.host_event(:transaction_redone)
    assert reconciler.pending?
    UI.run_timers
    assert @first.locked?
  end

  # Leaving protected the Volume, so a later Unprotect is the user's own state, and its Redo keeps it.
  def test_redo_of_unprotect_after_an_earlier_visit_keeps_the_volume_unprotected
    enter(@first)
    view("ph_composer.spaces.context.close")
    invoke("ph_composer.spaces.volumes.unprotect", "volume" => reference(@first))
    @first.locked = true
    @session.host_event(:transaction_undone)
    @first.locked = false
    @session.host_event(:transaction_redone)
    refute reconciler.pending?
    refute @first.locked?
  end

  def test_an_unprotected_volume_not_yet_opened_survives_an_ordinary_commit
    invoke("ph_composer.spaces.volumes.unprotect", "volume" => reference(@first))
    @session.host_event(:transaction_committed)
    @session.host_event(:active_path_changed)
    refute reconciler.pending?
    refute @first.locked?
  end

  def test_save_protects_the_open_volume_without_moving_the_path_then_closes_it
    enter(@first)
    @model.save(File.join(Dir.tmpdir, "spaces-context-test.skp"))
    assert @first.locked?
    assert_equal [@zone, @space], @model.active_path
  end

  def test_close_and_open_move_the_path_and_protect_on_the_way_out
    enter(@first)
    assert_equal({ "path" => [100, 110] }, view("ph_composer.spaces.context.close"))
    assert @first.locked?
    assert_equal({ "path" => [100] }, view("ph_composer.spaces.context.close"))
    assert_equal({ "path" => [100, 110] },
                 view("ph_composer.spaces.context.open", "reference" => { "space_id" => "spc_SSSSSSSSSSSS",
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

  # Two Spaces sharing a definition place one Volume entity at two paths; only the path opened is open.
  def test_a_volume_is_open_only_at_the_occurrence_path_opened
    copy = Sketchup::Group.new(120, @space.entities)
    SPACES::SPACE_STORE.write(copy, SPACES::SPACE_STORE.read(@space))
    @zone.entities << copy
    @first.locked = false
    @model.active_path = [@zone, @space, @first]
    volumes = API.query(:context => @context, :name => "ph_composer.spaces.all").dig("value", "spaces")
                 .map { |space| space.fetch("volumes").first }
    assert_equal({ [100, 110, 111] => true, [100, 120, 111] => false },
                 volumes.to_h { |volume| [volume.dig("reference", "entity_path"), volume["open"]] })
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

  # Locate never unlocks: the path opens up to the first locked Group and that Group is selected.
  def test_locate_selects_the_protected_volume_for_its_floor_segment_and_unlocks_nothing
    before = @model.operations.length
    segment = { "floor_segment_id" => "fsg_AAAAAAAAAAAA", "entity_path" => [100, 110, 111, 112] }
    assert_equal({ "path" => [100, 110] }, view("ph_composer.spaces.locate", "reference" => segment))
    assert @first.locked?
    assert_equal [@first], @model.selection.to_a
    assert_equal before, @model.operations.length
  end

  def test_locate_reaches_the_references_a_misplaced_and_an_orphan_floor_segment_report
    loose = floor_face(120, rectangle(0, 4, 1, 1), segment_record("M"))
    orphan = volume_group(130, volume_record("O", :number => 3), [floor_face(131, rectangle(4, 4, 1, 1),
                                                                             segment_record("O"))])
    orphan.locked = false
    @zone.entities << loose
    @model.entities << orphan
    spaces = API.query(:context => @context, :name => "ph_composer.spaces.all").fetch("value")
    misplaced = spaces.fetch("findings").find { |finding| finding["code"] == "space.segment_misplaced" }
    assert misplaced, spaces.inspect
    assert_equal({ "path" => [100] }, view("ph_composer.spaces.locate", "reference" => misplaced.fetch("reference")))
    assert_equal [loose], @model.selection.to_a
    inside = { "floor_segment_id" => "fsg_OOOOOOOOOOOO", "entity_path" => [130, 131] }
    assert_equal({ "path" => [130] }, view("ph_composer.spaces.locate", "reference" => inside))
  end

  def test_detach_drops_pending_protection
    enter(@first)
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
