# frozen_string_literal: true

module PhComposer
  module Spaces
    # The Spaces reconciler for one Model: it keeps the Volume last seen open on the edit path, and when
    # the path leaves that Volume it queues the Volume's protection as deferred work
    # (context/TECH_STACK.md, "Observers report; deferred work mutates"). The host can deliver a commit
    # before the path change on exit, with the path already outside the Volume, so every commit, Undo,
    # Redo and path change looks. Only a Volume left unlocked is queued, so a pass that would write
    # nothing never makes the session busy. Undo and Redo look as a commit does, the predecessor's rule:
    # an Undo that leaves a Volume must not leave it unprotected. They also look at every Volume seen open
    # this session, because a Redo can restore one's unlocked state with the path already outside it and
    # no baseline left to say so. A Volume unlocked by `volumes.unprotect` and not yet opened is not one,
    # so an ordinary commit between the two calls leaves it alone. The Zones copy watcher instead drops
    # its pass on Undo and Redo, because its repair must never follow a gesture the user took back.
    class Reconciler
      def initialize(session)
        @session = session
        @baseline = nil
        @visited = []
        @saving = false
        @work = DeferredWork.new { |jobs| jobs.each_value { |volume| protect_unless_open(volume) } }
      end

      def self.for(session)
        session.feature_state(:spaces_context) { new(session) }
      end

      def observed
        return if @saving

        current, = Protection.open_volume(path)
        @visited << current if current && @visited.none? { |volume| volume.equal?(current) }
        prior = @baseline
        @baseline = current
        return unless prior && !prior.equal?(current) && Protection.valid?(prior) && !prior.locked?

        @work.queue(prior.persistent_id, prior)
      end

      # Undo and Redo: as a commit, then every Volume seen open that is unlocked and off the path.
      def reverted
        observed
        return if @saving

        @visited.select! { |volume| Protection.valid?(volume) }
        @visited.each do |volume|
          next if volume.locked? || path.any? { |entity| entity.equal?(volume) }

          @work.queue(volume.persistent_id, volume)
        end
      end

      # Inside onPreSaveModel the host reports an empty path while the Volume is still open, and a path
      # change there makes SketchUp save the reopened context in world coordinates. So pending protection
      # runs and the Volume last seen is protected synchronously, and the path is left alone. Those writes
      # commit, and their callbacks read the save's empty path, so they are not observed: the baseline is
      # the Volume still open on screen.
      def pre_save
        volume = @baseline
        @saving = true
        @work.settle
        Protection.protect(model, volume) if volume && Protection.valid?(volume)
      rescue StandardError => error
        Diagnostics.exception("space_pre_save", error)
        @session.notice("Save could not protect the open Volume.", :tone => :error)
      ensure
        @saving = false
      end

      # After the save the host restores the context; close the Volume the save protected.
      def post_save
        volume, index = Protection.open_volume(path)
        return unless volume

        EditContext.enter(model, path[0...index])
      rescue StandardError => error
        Diagnostics.exception("space_post_save", error)
        @session.notice("The saved Volume could not be closed.", :tone => :error)
      end

      def pending?
        @work.pending?
      end

      def settle
        @work.settle
      end

      def detach
        @work.detach
        @baseline = nil
        @visited = []
      end

      private

      def model
        @session.model
      end

      def path
        Array(model.active_path)
      end

      # The path is read again right before the write: the user may have entered the Volume again.
      def protect_unless_open(volume)
        return if path.any? { |entity| entity.equal?(volume) }

        Protection.protect(model, volume)
        @session.changed(:spaces)
      end
    end
  end
end
