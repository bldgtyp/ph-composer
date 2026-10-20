# frozen_string_literal: true

# Development only, never shipped: named fault controls for native failure cases, driven through the
# development bridge (`host_bridge.py fault arm|observe|restore`). Each fault has three separate operations:
#
#   arm      checks a clean baseline on a synthetic target, records it, then makes the fault live
#   observe  reports whether it is armed, its target and the bounded record of what it intercepted
#   restore  makes it inert, reads the target back against the baseline and reports residual resources;
#            `restored` is false when anything does not match, and a case must stop there
#
# Faults:
#   lost_reply      the panel's next action.result for one request id is dropped (a reply lost in transit)
#   silent_runtime  chosen runtime page messages for one session are dropped (a runtime that stops answering)
#   failed_write    Sketchup.write_default answers false for one display-preference key (a refused write)
#
# Loading this file defines the module and changes nothing. The interceptors are prepended on the first arm
# and stay in the process, inert, after restore: Ruby cannot remove a prepended module, so normal-build
# restoration remains a fresh process with the installed RBZ, which `restore` says. A target must be a
# synthetic fixture (a Model under a `_private/` folder or the temporary folder), never a user's working
# Model. Product behavior under these faults is asserted by the owning production cases, not here.
module PhComposerFaults
  SCHEMA = 1
  KIND = "ph-composer.fault-control"
  NAMES = %w[lost_reply silent_runtime failed_write].freeze
  RUNTIME_MESSAGES = %w[runtime.ready runtime.translation].freeze
  PREFERENCE_KEYS = %w[unit_system colour_by_mode table_views dimension_formats].freeze
  SYNTHETIC = %r{/_private/|\A/private/tmp/|\A/tmp/}.freeze
  MAX_HITS = 20

  # The interceptors. Each asks whether its fault is live for this call and, if so, records the hit and
  # answers the fault's result instead of the normal one.
  module LostReply
    def publish_result(payload, outcome)
      return super unless PhComposerFaults.intercept("lost_reply", "request" => payload["request_id"])

      nil
    end
    private :publish_result
  end

  module SilentRuntime
    def receive(raw)
      type = begin
        JSON.parse(raw.to_s)["type"]
      rescue StandardError
        nil
      end
      return super unless PhComposerFaults.intercept("silent_runtime", "session" => session_id, "type" => type)

      nil
    end
    private :receive
  end

  module FailedWrite
    def write_default(section, key, value)
      return super unless section == PhComposer::Preferences::SECTION &&
                          PhComposerFaults.intercept("failed_write", "key" => key.to_s)

      false
    end
  end

  class << self
    def arm(name, target = {})
      target = target.transform_keys(&:to_s)
      problem = refusal(name, target) || baseline_problem(name, target)
      return document(name, "refused", :error => problem) if problem

      install(name)
      armed[name] = { "target" => target, "baseline" => baseline(name, target), "hits" => [], "spent" => false }
      document(name, "armed")
    end

    def observe(name)
      return document(name, "refused", :error => "unknown fault") unless NAMES.include?(name)

      document(name, armed.key?(name) ? "armed" : "inert")
    end

    def restore(name)
      return document(name, "refused", :error => "unknown fault") unless NAMES.include?(name)

      state = armed.delete(name)
      return document(name, "inert", :restore => { "restored" => true, "was_armed" => false }) unless state

      problems = residual(name, state)
      outcome = { "restored" => problems.empty?, "was_armed" => true, "problems" => problems,
                  "hits" => state["hits"].length }
      document(name, "inert", :restore => outcome)
    end

    # Called by an interceptor: true when `name` is armed for this call, after recording the hit.
    def intercept(name, call)
      state = armed[name]
      return false unless state && !state["spent"] && matches?(name, state["target"], call)

      state["hits"] << call.merge("at" => Process.clock_gettime(Process::CLOCK_MONOTONIC).round(3)) if
        state["hits"].length < MAX_HITS
      state["spent"] = true if name == "lost_reply"
      true
    end

    private

    def armed
      @armed ||= {}
    end

    def installed
      @installed ||= {}
    end

    def refusal(name, target)
      return "unknown fault #{name.to_s[0, 32]}" unless NAMES.include?(name)
      return "#{name} is already armed; restore it first" if armed.key?(name)

      session = target["session"].to_s
      unless PhComposer::Diagnostics::SESSION.match?(session)
        return "session is not in the form the extension generates"
      end

      model = PhComposer::Sessions.find(session)&.model
      return "the session is not open" unless model
      return "the target Model is not a synthetic fixture" unless SYNTHETIC.match?(model.path.to_s)

      target_refusal(name, target)
    end

    def target_refusal(name, target)
      case name
      when "lost_reply"
        "request is not in the form the extension generates" unless
          PhComposer::Diagnostics::REQUEST.match?(target["request"].to_s) &&
          target["request"].to_s.start_with?("#{target['session']}:")
      when "silent_runtime"
        drop = Array(target["drop"])
        "drop names runtime.ready and/or runtime.translation" unless !drop.empty? && (drop - RUNTIME_MESSAGES).empty?
      when "failed_write"
        "key is one of #{PREFERENCE_KEYS.join(', ')}" unless PREFERENCE_KEYS.include?(target["key"])
      end
    end

    # A fault is armed only on a clean target: no live runtime for the session, nothing intercepted yet.
    def baseline_problem(name, target)
      return unless name == "silent_runtime" && live_runtimes(target["session"]).positive?

      "a runtime is already live for this session; the baseline is not clean"
    end

    def baseline(name, target)
      case name
      when "silent_runtime" then { "live_runtimes" => live_runtimes(target["session"]) }
      when "failed_write" then { "stored" => stored_preference(target["key"]) }
      else { "panel_open" => PhComposer::Panel.open? }
      end
    end

    # What restore checks against the baseline, as problems; empty when the target is as it was.
    def residual(name, state)
      target = state["target"]
      case name
      when "silent_runtime"
        live = live_runtimes(target["session"])
        live.zero? ? [] : ["#{live} runtime(s) still live for the session"]
      when "failed_write"
        if stored_preference(target["key"]) == state.dig("baseline", "stored")
          []
        else
          ["the stored #{target['key']} differs from its baseline"]
        end
      else []
      end
    end

    def stored_preference(key)
      Sketchup.read_default(PhComposer::Preferences::SECTION, key, nil)
    end

    def matches?(name, target, call)
      case name
      when "lost_reply" then call["request"] == target["request"]
      when "silent_runtime" then call["session"] == target["session"] && Array(target["drop"]).include?(call["type"])
      else call["key"] == target["key"]
      end
    end

    def live_runtimes(session)
      ObjectSpace.each_object(PhComposer::RuntimeHost).count { |host| host.session_id == session && !host.stopped? }
    end

    def install(name)
      return if installed[name]

      case name
      when "lost_reply" then PhComposer::Panel.singleton_class.prepend(LostReply)
      when "silent_runtime" then PhComposer::RuntimeHost.prepend(SilentRuntime)
      when "failed_write" then Sketchup.singleton_class.prepend(FailedWrite)
      end
      installed[name] = true
    end

    def document(name, status, error: nil, restore: nil)
      state = armed[name]
      {
        "schema" => SCHEMA, "kind" => KIND, "fault" => name.to_s[0, 32], "status" => status, "error" => error,
        "armed" => !state.nil?, "target" => state && state["target"], "baseline" => state && state["baseline"],
        "hits" => state ? state["hits"].dup : [], "spent" => state ? state["spent"] : nil,
        "interceptor_installed" => installed.fetch(name, false), "restore" => restore,
        "fresh_process_required" => installed.fetch(name, false)
      }.compact
    end
  end
end
