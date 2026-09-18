# frozen_string_literal: true

require "securerandom"

module PhComposer
  # One open Model: its session identity, revision, callers, retained outcomes, refresh timer and
  # observers. What a feature keeps per Model lives in that feature's state object, reached through
  # `feature_state`, so a new feature adds no line here.
  #
  # The revision is one whole-Model counter (CONTRACTS.md C3). It advances on a committed mutation,
  # Undo, Redo and an edit-path change, and never on a read, a selection change or a save.
  class ModelSession
    attr_reader :model, :id, :revision, :refresh, :observers, :callers, :outcomes

    def initialize(model)
      @model = model
      @id = SecureRandom.uuid
      @revision = 1
      @own_commits_pending = 0
      @mutating = false
      @refresh = CoalescedTimer.new
      @observers = []
      @feature_state = {}
      @callers = CallerRegistry.new
      @outcomes = OutcomeStore.new
    end

    # Built by the block on first use and kept for the life of the session.
    def feature_state(name)
      @feature_state[name] ||= yield
    end

    def valid?
      !@detached && (!@model.respond_to?(:valid?) || @model.valid?)
    end

    def add_observers(model_observer, selection_observer)
      @observers = [model_observer, selection_observer]
    end

    # Why an authoritative read or write cannot run now, or nil when it can. A feature state object
    # with deferred Model work answers `pending?`; the session refuses until that work settles.
    def busy_reason
      return "Another change to this Model is still running." if @mutating

      deferred = @feature_state.each_value.any? { |state| state.respond_to?(:pending?) && state.pending? }
      deferred ? "This Model has deferred work that has not finished." : nil
    end

    # Runs the block as this session's one mutation; the block answers whether it committed. A
    # committed operation advances the revision once, here. SketchUp may deliver the commit callback
    # inside the block or after it returns, so the callback is recognized as ours either way instead
    # of advancing the revision a second time.
    def mutate
      @mutating = true
      @commits_during_mutation = 0
      committed = yield
      if committed
        @revision += 1
        @own_commits_pending += 1 if @commits_during_mutation.zero?
      end
      committed
    ensure
      @mutating = false
    end

    # Completes deferred Model work before something reads the Model as a whole.
    def settle
      @feature_state.each_value { |state| state.settle if state.respond_to?(:settle) }
    end

    def host_event(kind, *arguments)
      advance_revision_for(kind)
      Sessions.notify_host_event(self, kind, *arguments)
    end

    def changed(source, detail = nil)
      Sessions.notify_change(self, source, detail)
      request_refresh
    end

    def notice(message, tone: :info)
      Sessions.notify_notice(self, message, tone)
    end

    def request_refresh
      return if @detached

      @refresh.schedule { Sessions.notify_refresh(self) }
    end

    def detach
      @detached = true
      @feature_state.each_value { |state| state.detach if state.respond_to?(:detach) }
      @refresh.cancel
    end

    private

    def advance_revision_for(kind)
      case kind
      when :transaction_committed
        if @mutating
          @commits_during_mutation += 1
        elsif @own_commits_pending.positive?
          @own_commits_pending -= 1
        else
          @revision += 1
        end
      when :transaction_undone, :transaction_redone, :active_path_changed
        @revision += 1
      end
    end
  end
end
