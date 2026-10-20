# frozen_string_literal: true

require "open3"

# The development fault controls against the stub host: explicit arming on a checked synthetic baseline, the
# interception each fault makes, restore read back against the baseline, residual resources reported, and a
# restore that does not match failing. Product behavior under the faults belongs to the production cases.
class FaultControlsTest < PhComposerTestCase
  Faults = PhComposerFaults

  def setup
    super
    Faults.instance_variable_set(:@armed, {})
    @model = Sketchup::Model.new
    @model.path = "/private/tmp/ph_composer_fault_fixture.skp"
    Sketchup.active_model = @model
    @session = PhComposer::Sessions.for(@model)
  end

  def teardown
    Faults::NAMES.each { |name| Faults.restore(name) }
    @runtime&.stop
    super
  end

  def test_loading_the_file_arms_nothing_and_installs_no_interceptor
    script = <<~RUBY
      require "test_helper"
      ENV["PHC_HOST_BRIDGE_NO_AUTOSTART"] = "1"
      load #{File.expand_path('../fault_controls.rb', __dir__).inspect}
      prepended = [PhComposer::RuntimeHost.ancestors, PhComposer::Panel.singleton_class.ancestors,
                   Sketchup.singleton_class.ancestors].flatten & [PhComposerFaults::SilentRuntime,
                   PhComposerFaults::LostReply, PhComposerFaults::FailedWrite]
      puts "LOADED " + prepended.length.to_s + " " + PhComposerFaults.observe("silent_runtime")["status"]
    RUBY
    out, status = Open3.capture2e(RbConfig.ruby, "-Itests", "-Itools/hostkit/tests", "-e", script)

    assert status.success?, out
    assert_includes out, "LOADED 0 inert"
  end

  def test_a_working_model_or_a_malformed_target_is_refused
    @model.path = "/Users/someone/Documents/House.skp"
    refused = Faults.arm("failed_write", "session" => @session.id, "key" => "unit_system")
    assert_equal "refused", refused.fetch("status")
    assert_match(/not a synthetic fixture/, refused.fetch("error"))

    @model.path = "/private/tmp/ph_composer_fault_fixture.skp"
    [["nope", {}], ["failed_write", { "session" => @session.id, "key" => "license" }],
     ["silent_runtime", { "session" => @session.id, "drop" => ["runtime.closed"] }],
     ["lost_reply", { "session" => @session.id, "request" => "#{SecureRandom.uuid}:panel:1" }],
     ["failed_write", { "session" => "'; exit", "key" => "unit_system" }]].each do |name, target|
      assert_equal "refused", Faults.arm(name, target).fetch("status"), name
    end
    refute Faults.observe("failed_write").fetch("armed")
  end

  def test_silent_runtime_drops_the_named_messages_and_restore_reports_a_live_runtime
    armed = Faults.arm("silent_runtime", "session" => @session.id, "drop" => ["runtime.ready"])
    assert_equal({ "live_runtimes" => 0 }, armed.fetch("baseline"))
    @runtime = PhComposer::RuntimeHost.new(:session_id => @session.id).start
    page_says("runtime.ready")

    assert_equal "loading", @runtime.state, "the ready message never reached the runtime"
    assert_equal ["runtime.ready"], Faults.observe("silent_runtime").fetch("hits").map { |hit| hit.fetch("type") }

    restore = Faults.restore("silent_runtime").fetch("restore")
    refute restore.fetch("restored"), "a runtime still live is a residual resource"
    assert_equal ["1 runtime(s) still live for the session"], restore.fetch("problems")
  end

  def test_silent_runtime_restores_cleanly_and_the_runtime_then_answers
    Faults.arm("silent_runtime", "session" => @session.id, "drop" => ["runtime.ready"])
    @runtime = PhComposer::RuntimeHost.new(:session_id => @session.id).start
    page_says("runtime.ready")
    @runtime.stop
    restored = Faults.restore("silent_runtime")

    assert restored.dig("restore", "restored")
    assert restored.fetch("fresh_process_required"), "the inert interceptor stays until a fresh process"
    @runtime = PhComposer::RuntimeHost.new(:session_id => @session.id).start
    page_says("runtime.ready")
    refute_equal "loading", @runtime.state, "after restore the message is delivered"
  end

  def test_a_dirty_baseline_is_refused
    @runtime = PhComposer::RuntimeHost.new(:session_id => @session.id).start
    refused = Faults.arm("silent_runtime", "session" => @session.id, "drop" => ["runtime.ready"])

    assert_equal "refused", refused.fetch("status")
    assert_match(/baseline is not clean/, refused.fetch("error"))
  end

  def test_failed_write_refuses_the_preference_and_restore_checks_the_stored_value
    Sketchup.write_default(PhComposer::Preferences::SECTION, "unit_system", "IP")
    armed = Faults.arm("failed_write", "session" => @session.id, "key" => "unit_system")
    assert_equal({ "stored" => "IP" }, armed.fetch("baseline"))

    assert_raises(PhComposer::UserError) { PhComposer::Preferences.set("unit_system", "SI") }
    assert_equal "IP", PhComposer::Preferences.unit_system
    assert Faults.restore("failed_write").dig("restore", "restored")
    PhComposer::Preferences.set("unit_system", "SI")
    assert_equal "SI", PhComposer::Preferences.unit_system, "after restore the write is stored"
  end

  def test_a_restore_whose_target_changed_does_not_pass
    Faults.arm("failed_write", "session" => @session.id, "key" => "colour_by_mode")
    # Something other than the fault changed the stored value while it was armed.
    defaults = Sketchup.instance_variable_get(:@defaults) || Sketchup.instance_variable_set(:@defaults, {})
    defaults[[PhComposer::Preferences::SECTION, "colour_by_mode"]] = "x"

    restore = Faults.restore("failed_write").fetch("restore")
    refute restore.fetch("restored")
    assert_equal ["the stored colour_by_mode differs from its baseline"], restore.fetch("problems")
  end

  def test_a_failed_restore_keeps_its_baseline_until_the_target_is_repaired
    Faults.arm("failed_write", "session" => @session.id, "key" => "colour_by_mode")
    defaults = Sketchup.instance_variable_get(:@defaults) || Sketchup.instance_variable_set(:@defaults, {})
    defaults[[PhComposer::Preferences::SECTION, "colour_by_mode"]] = "x"

    refute Faults.restore("failed_write").dig("restore", "restored")
    again = Faults.restore("failed_write")
    refute again.dig("restore", "restored"), "a second restore cannot pass without a repair"
    assert_equal "restore_failed", again.fetch("status")
    assert_match(/restore failed/, Faults.arm("failed_write", "session" => @session.id, "key" => "colour_by_mode")
                                         .fetch("error"))
    assert_equal false, Faults.send(:armed).dig("failed_write", "live"), "interception stopped at the first restore"

    defaults.delete([PhComposer::Preferences::SECTION, "colour_by_mode"])
    repaired = Faults.restore("failed_write")
    assert repaired.dig("restore", "restored")
    assert_equal "inert", repaired.fetch("status")
  end

  def test_an_unreadable_preference_is_neither_a_baseline_nor_a_read_back
    defaults = Sketchup.instance_variable_get(:@defaults) || Sketchup.instance_variable_set(:@defaults, {})
    defaults[[PhComposer::Preferences::SECTION, "table_views"]] = 'one "quoted"'
    assert_match(/cannot be read back/, Faults.arm("failed_write", "session" => @session.id, "key" => "table_views")
                                              .fetch("error"))

    defaults.delete([PhComposer::Preferences::SECTION, "table_views"])
    Faults.arm("failed_write", "session" => @session.id, "key" => "table_views")
    defaults[[PhComposer::Preferences::SECTION, "table_views"]] = 'another "quoted"'
    refute Faults.restore("failed_write").dig("restore", "restored")
  end

  def test_receipts_keep_the_evidence_and_share_nothing_with_the_controls
    Sketchup.write_default(PhComposer::Preferences::SECTION, "unit_system", "IP")
    armed = Faults.arm("failed_write", "session" => @session.id, "key" => "unit_system")
    armed.fetch("baseline")["stored"] = "SI"
    Faults.observe("failed_write").fetch("baseline")["stored"] = "SI"
    Sketchup.write_default(PhComposer::Preferences::SECTION, "unit_system", "SI")

    receipt = Faults.restore("failed_write")
    assert_equal "IP", receipt.dig("baseline", "stored"), "a changed receipt did not change the baseline"
    assert_equal [1, false, false],
                 [receipt.fetch("interceptions"), receipt.fetch("armed"), receipt.fetch("pending_restore")]
    assert_equal({ "session" => @session.id, "key" => "unit_system" }, receipt.fetch("target"))
  end

  def test_each_fault_leaves_other_targets_alone
    Faults.arm("failed_write", "session" => @session.id, "key" => "unit_system")
    Sketchup.write_default(PhComposer::Preferences::SECTION, "table_views", "x")
    Faults.arm("lost_reply", "session" => @session.id, "request" => "#{@session.id}:panel:1")
    PhComposer::Panel.send(:publish_result, { "request_id" => "#{@session.id}:panel:2" }, {})
    Faults.arm("silent_runtime", "session" => @session.id, "drop" => ["runtime.ready"])
    other = PhComposer::Sessions.for(Sketchup::Model.new)
    @runtime = PhComposer::RuntimeHost.new(:session_id => other.id).start
    @runtime.instance_variable_get(:@dialog).fire(PhComposer::RuntimeHost::CALLBACK,
                                                  JSON.generate("type" => "runtime.ready",
                                                                "payload" => { "session" => other.id }))

    assert_equal [0, 0, 0], Faults::NAMES.map { |name| Faults.observe(name).fetch("interceptions") }
    refute_equal "loading", @runtime.state, "another session's runtime still hears ready"
  end

  def test_a_passing_restore_owes_nothing_and_its_receipt_keeps_the_evidence
    Faults.arm("failed_write", "session" => @session.id, "key" => "unit_system")
    Sketchup.write_default(PhComposer::Preferences::SECTION, "unit_system", "SI")
    receipt = Faults.restore("failed_write")

    assert receipt.dig("restore", "restored")
    assert_equal ["inert", false, false, 1],
                 [receipt.fetch("status"), receipt.fetch("armed"), receipt.fetch("pending_restore"),
                  receipt.fetch("interceptions")]
    assert_equal Faults::REVISION, receipt.fetch("revision")
  end

  def test_a_read_back_that_raises_is_a_failed_restore
    Faults.arm("failed_write", "session" => @session.id, "key" => "unit_system")
    Faults.stub(:residual, ->(*) { raise IOError }) do
      restore = Faults.restore("failed_write").fetch("restore")
      refute restore.fetch("restored")
      assert_equal ["the read-back raised IOError"], restore.fetch("problems")
    end
  end

  def test_only_host_run_fixtures_and_known_target_keys_are_accepted
    @model.path = "/Users/someone/Dropbox/ph-composer/_private/clients/House.skp"
    assert_match(/not a synthetic fixture/, Faults.arm("failed_write", "session" => @session.id, "key" => "unit_system")
                                                  .fetch("error"))
    @model.path = "/Users/someone/Dropbox/ph-composer/_private/host/run/fixture.skp"
    assert_match(/does not take extra/,
                 Faults.arm("failed_write", "session" => @session.id, "key" => "unit_system", "extra" => 1)
                       .fetch("error"))
  end

  def test_failed_write_leaves_another_models_writes_alone
    Faults.arm("failed_write", "session" => @session.id, "key" => "unit_system")
    Sketchup.active_model = Sketchup::Model.new

    PhComposer::Preferences.set("unit_system", "IP")
    assert_equal "IP", PhComposer::Preferences.unit_system
    assert_equal 0, Faults.observe("failed_write").fetch("interceptions")
  end

  def test_a_stopped_runtime_that_still_holds_a_resource_is_residual
    Faults.arm("silent_runtime", "session" => @session.id, "drop" => ["runtime.ready"])
    @runtime = PhComposer::RuntimeHost.new(:session_id => @session.id).start
    @runtime.define_singleton_method(:stopped?) { true }
    @runtime.define_singleton_method(:resources) { { "dialog" => 1 } }

    refute Faults.restore("silent_runtime").dig("restore", "restored")
  ensure
    @runtime&.singleton_class&.send(:remove_method, :stopped?)
    @runtime&.singleton_class&.send(:remove_method, :resources)
  end

  def test_lost_reply_reads_back_the_panel_state
    Faults.arm("lost_reply", "session" => @session.id, "request" => "#{@session.id}:panel:9")
    PhComposer::Panel.stub(:open?, true) do
      restore = Faults.restore("lost_reply").fetch("restore")
      refute restore.fetch("restored")
      assert_equal ["the panel's open state differs from its baseline"], restore.fetch("problems")
    end
  end

  def test_interceptions_past_the_hit_log_are_counted
    Faults.arm("failed_write", "session" => @session.id, "key" => "table_views")
    25.times { Sketchup.write_default(PhComposer::Preferences::SECTION, "table_views", "x") }
    observed = Faults.observe("failed_write")

    assert_equal [25, Faults::MAX_HITS, 5],
                 [observed.fetch("interceptions"), observed.fetch("hits").length, observed.fetch("omitted_hits")]
  end

  def test_lost_reply_drops_one_result_for_its_request_only
    request = "#{@session.id}:panel:7"
    dialog = RecordingDialog.new
    PhComposer::Panel.instance_variable_set(:@dialog, dialog)
    Faults.arm("lost_reply", "session" => @session.id, "request" => request)

    PhComposer::Panel.send(:publish_result, { "request_id" => request, "session" => @session.id }, {})
    PhComposer::Panel.send(:publish_result, { "request_id" => request, "session" => @session.id }, {})

    assert_equal 1, dialog.scripts.length, "only the first result for the request is lost"
    observed = Faults.observe("lost_reply")
    assert observed.fetch("spent")
    assert_equal [request], observed.fetch("hits").map { |hit| hit.fetch("request") }
    assert Faults.restore("lost_reply").dig("restore", "restored")
  ensure
    PhComposer::Panel.instance_variable_set(:@dialog, nil)
  end

  def test_restore_of_a_fault_never_armed_says_so
    restore = Faults.restore("lost_reply").fetch("restore")
    refute restore.fetch("restored"), "with no arm baseline here, nothing can be read back"
    assert_match(/no arm baseline in this process/, restore.fetch("problems").first)
    assert_equal "refused", Faults.restore("unknown").fetch("status")
  end

  private

  RecordingDialog = Struct.new(:scripts) do
    def initialize
      super([])
    end

    def execute_script(script)
      scripts << script
    end
  end

  def page_says(type)
    dialog = @runtime.instance_variable_get(:@dialog)
    dialog.fire(PhComposer::RuntimeHost::CALLBACK,
                JSON.generate("type" => type, "payload" => { "session" => @session.id }))
  end
end
