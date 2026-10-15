# frozen_string_literal: true

module PhComposer
  # Reports each Group or ComponentInstance added to any container of one Model as the
  # `container_added` host event, with the entity. A native copy arrives as such an addition after its
  # transaction commits, already carrying its instance dictionaries (context/SKETCHUP_HOST_BEHAVIOR.md,
  # "Observers and edit contexts"), so a feature that reconciles copies needs the addition, not only
  # the commit. One EntitiesObserver sits on the Model's entities and on every Group's and definition's
  # entities; the set is found again after each commit, Undo, Redo and activation, in one coalesced
  # pass, and a container just added is observed at once. It names no feature and holds no Model work,
  # so it never makes the session busy.
  class ContainerWatch
    # The host events after which the set of containers may have changed.
    REDISCOVER = %i[session_created model_activated transaction_committed transaction_undone
                    transaction_redone].freeze

    class Observer < Sketchup::EntitiesObserver
      def initialize(watch)
        super()
        @watch = watch
      end

      def onElementAdded(_entities, entity)
        @watch.added(entity)
      end
    end

    def self.for(session)
      session.feature_state(:container_watch) { new(session) }
    end

    def initialize(session)
      @session = session
      @observer = Observer.new(self)
      @observed = []
      @timer = CoalescedTimer.new
    end

    # A new session is observed at once, so the first native copy after it opens is seen.
    def host_event(kind)
      return discover if kind == :session_created

      @timer.schedule { discover } if REDISCOVER.include?(kind)
    end

    def added(entity)
      return unless entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)

      fresh = []
      walk(contents(entity), fresh)
      fresh.each { |entities| observe(entities) }
      @session.host_event(:container_added, entity)
    rescue StandardError => error
      # An observer callback must not raise into SketchUp; a subscriber's failure is its own.
      Diagnostics.exception("container_added", error)
    end

    # Observes every container now in the Model and stops observing those gone.
    def discover
      @timer.cancel
      found = []
      walk(@session.model.entities, found)
      (@observed - found).each { |entities| unobserve(entities) }
      (found - @observed).each { |entities| entities.add_observer(@observer) }
      @observed = found
    end

    def detach
      @timer.cancel
      @observed.each { |entities| unobserve(entities) }
      @observed = []
    end

    private

    def walk(entities, found)
      return if found.any? { |known| known.equal?(entities) }

      found << entities
      entities.each do |entity|
        walk(contents(entity), found) if entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
      end
    end

    def observe(entities)
      return if @observed.any? { |known| known.equal?(entities) }

      entities.add_observer(@observer)
      @observed << entities
    end

    def contents(container)
      container.is_a?(Sketchup::ComponentInstance) ? container.definition.entities : container.entities
    end

    def unobserve(entities)
      entities.remove_observer(@observer)
    rescue TypeError => error
      # Entities has no valid? predicate. The host deletes its observers with the collection when a
      # Model closes or a definition is removed; only that native refusal is harmless.
      raise unless error.message == "reference to deleted Entities"
    end
  end
end
