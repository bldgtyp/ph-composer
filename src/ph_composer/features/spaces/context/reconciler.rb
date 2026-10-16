# frozen_string_literal: true

module PhComposer
  module Spaces
    # The Spaces reconciler for one Model: it keeps the Volume last seen open on the edit path, and when
    # the path leaves that Volume it queues the Volume's protection as deferred work
    # (context/TECH_STACK.md, "Observers report; deferred work mutates"). The host can deliver a commit
    # before the path change on exit, with the path already outside the Volume, so every commit, Undo,
    # Redo and path change looks. Only a Volume left unlocked is queued, so a pass that would write
    # nothing never makes the session busy. Undo and Redo look as a commit does, the predecessor's rule:
    # an Undo that leaves a Volume must not leave it unprotected. They also look at every Volume exposed:
    # seen open and not protected by Spaces since. A Redo can restore such a Volume's unlocked state with
    # the path already outside it and no baseline left to say so. A Volume Spaces protected on the way out
    # is no longer exposed, so a later `volumes.unprotect` and its Undo and Redo are the user's to keep,
    # and so is one unprotected and not yet opened. The Zones copy watcher instead drops
    # its pass on Undo and Redo, because its repair must never follow a gesture the user took back.
    class Reconciler
      def initialize(session)
        @session = session
        @baseline = nil
        @exposed = []
        @saving = false
        @work = DeferredWork.new { |jobs| jobs.each_value { |volume| protect_unless_open(volume) } }
      end

      def self.for(session)
        session.feature_state(:spaces_context) { new(session) }
      end

      def observed
        return if @saving

        current, = Protection.open_volume(path)
        @exposed << current if current && @exposed.none? { |volume| volume.equal?(current) }
        prior = @baseline
        @baseline = current
        return unless prior && !prior.equal?(current) && Protection.valid?(prior) && !prior.locked?

        @work.queue(prior.persistent_id, prior)
      end

      # Undo and Redo: as a commit, then every exposed Volume that is unlocked and off the path.
      def reverted
        observed
        return if @saving

        @exposed.select! { |volume| Protection.valid?(volume) }
        @exposed.each do |volume|
          next if volume.locked? || path.any? { |entity| entity.equal?(volume) }

          @work.queue(volume.persistent_id, volume)
        end
      end

      # A save, an autosave included, leaves the user where they are (D3a-19): pending protection of
      # Volumes already left runs, so the file holds them protected, and the Volume still open is left
      # unlocked, so the host restores the context after the save. Inside onPreSaveModel the host reports
      # an empty path, so the settled writes' callbacks are not observed, and a job still queued for the
      # Volume open on screen (left and entered again, or queued at open) cannot tell it is open: the
      # baseline is that Volume, and settling skips it. A Volume saved open is protected when the Model is
      # next opened (`opened`).
      def pre_save
        @saving = true
        @work.settle
      rescue StandardError => error
        Diagnostics.exception("space_pre_save", error)
        @session.notice("Save could not protect a Volume.", :tone => :error)
      ensure
        @saving = false
      end

      # A Model opened with Volumes unlocked, as a save inside a Volume leaves them: each one off the path is
      # queued for protection.
      def opened
        Occurrences.scan(model, :strict => false).then { |scan| scan.volumes + scan.orphan_volumes }.each do |found|
          volume = found.entity
          next unless Protection.valid?(volume) && !volume.locked? && path.none? { |entity| entity.equal?(volume) }

          @work.queue(volume.persistent_id, volume)
        end
        observed
      end

      # Spaces protected `volume` itself, on a pass, at a save or at the EditContext boundary.
      def protected(volume)
        @exposed.reject! { |entity| entity.equal?(volume) }
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
        @exposed = []
      end

      private

      def model
        @session.model
      end

      def path
        Array(model.active_path)
      end

      # The path is read again right before the write: the user may have entered the Volume again. During a
      # save the host reports an empty path, so the Volume last seen open is skipped by identity too.
      def protect_unless_open(volume)
        return if path.any? { |entity| entity.equal?(volume) } || (@saving && volume.equal?(@baseline))

        Protection.protect(model, volume)
        protected(volume)
        @session.changed(:spaces)
      end
    end
  end
end
