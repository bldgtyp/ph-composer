# frozen_string_literal: true

module PhComposer
  module Export
    # Bounded process-local handles. File recovery does not depend on this in-memory task history.
    class Tasks
      LIMIT = 20
      RETENTION_SECONDS = 30 * 60

      def self.for(session)
        session.feature_state("#{EXTENSION_ID}.export.tasks") { new(session) }
      end

      def initialize(session)
        @session = session
        @tasks = {}
      end

      def start(destination:, replace: false, runtime_factory: nil)
        prune
        if @tasks.values.any? { |task| !task.terminal? }
          raise Blocked.new("export.busy", "An export is already running for this Model.")
        end
        unless destination.is_a?(String) && !destination.empty?
          raise Blocked.new("params.invalid", "Choose an explicit HBJSON destination.")
        end
        unless replace == true || replace == false
          raise Blocked.new("params.invalid", "Replacement consent must be true or false.")
        end
        if @session.busy_reason
          raise Blocked.new("session.busy", @session.busy_reason)
        end
        task = Task.new(@session, :destination => destination, :replace => replace,
                       :runtime_factory => runtime_factory)
        task.start
        @tasks[task.id] = task
        task.snapshot
      end

      def status(id)
        fetch(id).snapshot
      end

      def cancel(id)
        task = fetch(id)
        task.cancel
        task.snapshot
      end

      def latest
        prune
        @tasks.values.last&.snapshot
      end

      def detach
        @tasks.each_value(&:cancel)
        @tasks.clear
      end

      private

      def fetch(id)
        prune
        @tasks.fetch(id) do
          raise Blocked.new("task.expired", "That export handle expired or belongs to another Model session.")
        end
      end

      def prune
        now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        @tasks.delete_if { |_id, task| task.finished_at && now - task.finished_at > RETENTION_SECONDS }
        finished = @tasks.select { |_id, task| task.terminal? }.keys
        finished[0, [finished.length - LIMIT, 0].max].each { |id| @tasks.delete(id) }
      end
    end
  end
end
