# frozen_string_literal: true

module PhComposer
  # Keyed deferred work for one Model: observers queue jobs and return, and one coalesced zero-delay
  # pass runs them all (context/TECH_STACK.md, "Observers report; deferred work mutates"). Queuing a
  # key already queued merges the two through the caller's block. A feature keeps one in its state
  # object and forwards `pending?`, `settle` and `detach`, which `ModelSession` asks every state object,
  # so a pending pass makes reads and writes wait and a closing Model drops it. It names no feature.
  class DeferredWork
    # `run.call(jobs)` receives the queued `{ key => job }` and is the only place a job is acted on.
    def initialize(&run)
      @run = run
      @timer = CoalescedTimer.new
      @jobs = {}
      @running = false
    end

    # Queues `job` under `key`; with a block, `block.call(existing, job)` decides what stays queued.
    def queue(key, job, &merge)
      existing = @jobs[key]
      @jobs[key] = existing && merge ? merge.call(existing, job) : job
      @timer.schedule { settle }
    end

    def pending?
      @running || !@jobs.empty?
    end

    # Runs every queued job now, once. A job queued while the pass runs waits for the next pass.
    def settle
      @timer.cancel
      return if @jobs.empty? || @running

      jobs = @jobs
      @jobs = {}
      @running = true
      begin
        @run.call(jobs)
      ensure
        @running = false
      end
      @timer.schedule { settle } unless @jobs.empty?
    end

    # Drops queued work without running it: Undo, Redo and a closing Model.
    def cancel
      @timer.cancel
      @jobs = {}
    end

    def detach
      cancel
    end
  end
end
