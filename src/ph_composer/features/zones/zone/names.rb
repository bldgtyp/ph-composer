# frozen_string_literal: true

module PhComposer
  module Zones
    # Native Group names are current; schema-v1 records retain the compatibility name. Projection
    # is pure. Only clearing a native name needs deferred host work, joined to the user's Undo step.
    module Names
      module_function

      def valid?(name)
        name.is_a?(String) && !name.empty?
      end

      def project(record, native_name)
        Schema.validate!(record)
        DeepCopy.call(record).merge("name" => valid?(native_name) ? native_name : record.fetch("name"))
      end

      def read(entity)
        record = ZONE_STORE.read(entity)
        record && project(record, entity.respond_to?(:name) ? entity.name : nil)
      end

      def state(session)
        session.feature_state(:zones_names) { State.new(session) }
      end

      def track(model, group)
        state(Sessions.for(model)).observe(group)
      end

      def install(feature)
        %i[session_created model_activated transaction_committed transaction_undone transaction_redone].each do |event|
          feature.on_host_event(event) { |session| state(session).schedule }
        end
        Sessions.all.each { |session| state(session).baseline }
      end

      class Observer < Sketchup::EntityObserver
        def initialize(state)
          @state = state
        end

        def onChangeEntity(entity)
          @state.name_changed(entity)
        end

        def onEraseEntity(_entity)
          @state.schedule
        end
      end

      class ContainersObserver < Sketchup::EntitiesObserver
        def initialize(state)
          @state = state
        end

        def onElementAdded(_entities, entity)
          @state.added(entity)
        end
      end

      class State
        def initialize(session)
          @session = session
          @timer = CoalescedTimer.new
          @observer = Observer.new(self)
          @containers_observer = ContainersObserver.new(self)
          @containers = []
          @groups = {}
          @last_valid = {}
          @seen_native = {}
          @blank = {}
          @restoring = false
        end

        def schedule
          return false if @restoring

          @timer.schedule { settle }
        end

        # Composition is outside a native observer callback; establish existing Groups here so
        # their first native rename is observed even when it is immediately followed by clearing.
        def baseline
          @timer.cancel
          discover
        end

        def pending?
          @restoring || @blank.keys.any? { |id| @seen_native[id] }
        end

        # Named creation observes the new Group before returning to native input. Other native
        # copies and opened files are discovered in the deferred transaction pass.
        def observe(group)
          id = group.persistent_id
          previous = @groups[id]
          if previous && !previous.equal?(group)
            unobserve(previous)
          end
          group.add_observer(@observer) unless previous.equal?(group)
          @groups[id] = group
          name_changed(group)
        end

        # Native clipboard-pasted Groups carry their instance dictionary when added. Observing that
        # one new Group immediately preserves a subsequent rename/clear pair before discovery.
        def added(entity)
          record = stored_record(entity) if entity.is_a?(Sketchup::Group)
          if record && Names.valid?(record["name"])
            @last_valid[entity.persistent_id] ||= record.fetch("name")
            observe(entity)
          end
          schedule if entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
        end

        # One entity property is recorded in the callback, including intermediate valid renames
        # before a coalesced timer runs. No attributes, hierarchy or native names are written here.
        def name_changed(group)
          id = group.persistent_id
          if Names.valid?(group.name)
            @last_valid[id] = group.name.dup
            @seen_native[id] = true
            @blank.delete(id)
          else
            @blank[id] = true
          end
          schedule if @blank[id] && !@restoring
        end

        def settle
          @timer.cancel
          discover
          return if @blank.empty?

          restore
        rescue StandardError => error
          Diagnostics.exception("zone_name_restore", error)
          @session.notice("The Zone name could not be restored. Enter a nonempty native name.", :tone => :warning)
        end

        def detach
          @timer.cancel
          @groups.each_value { |group| unobserve(group) }
          @containers.each { |entities| unobserve_container(entities) }
          @containers.clear
          @groups.clear
          @last_valid.clear
          @seen_native.clear
          @blank.clear
        end

        private

        def discover
          found = []
          containers = []
          scan(@session.model.entities, found, containers)
          (@containers - containers).each { |entities| unobserve_container(entities) }
          (containers - @containers).each { |entities| entities.add_observer(@containers_observer) }
          @containers = containers
          live = found.map(&:persistent_id)
          (@groups.keys - live).each do |id|
            unobserve(@groups.delete(id))
            @last_valid.delete(id)
            @seen_native.delete(id)
            @blank.delete(id)
          end
          found.each do |group|
            @last_valid[group.persistent_id] ||= ZONE_STORE.read(group).fetch("name")
            observe(group)
          end
        end

        def scan(entities, found, containers)
          return if containers.include?(entities)

          containers << entities
          entities.each do |entity|
            if entity.is_a?(Sketchup::Group)
              record = stored_record(entity)
              found << entity if record && Names.valid?(record["name"])
              scan(entity.entities, found, containers)
            elsif entity.is_a?(Sketchup::ComponentInstance)
              scan(entity.definition.entities, found, containers)
            end
          end
        end

        def stored_record(entity)
          record = ZONE_STORE.read(entity)
          record if record.is_a?(Hash) && Schema.problems(record).empty?
        rescue CodedError
          nil # Invalid records remain the public query/export validator's responsibility.
        end

        def unobserve(group)
          group.remove_observer(@observer) unless group.respond_to?(:valid?) && !group.valid?
        end

        def unobserve_container(entities)
          entities.remove_observer(@containers_observer)
        rescue TypeError => error
          # Entities has no valid? predicate. The host deletes its observer with the collection
          # when a Model closes or a definition is removed; only that native refusal is harmless.
          raise unless error.message == "reference to deleted Entities"
        end

        def restore
          targets = @blank.keys.map { |id| [@groups.fetch(id), @last_valid.fetch(id)] }
          return if targets.empty?

          @restoring = true
          @session.exclusive do
            @session.mutate do
              restore_operation(targets)
              true
            end
          end
          @session.changed(:zones, :names)
        ensure
          @restoring = false
        end

        # A transparent operation must never abort its source operation (SketchUp Model API,
        # abort_operation). Validate before opening it and always close it by committing, even if
        # a host setter fails. A failure leaves the unresolved blank pending for native correction.
        def restore_operation(targets)
          unless targets.all? { |group, name| Names.valid?(name) && group.name.to_s.empty? }
            raise InternalError, "The Zone name restoration target changed."
          end
          model = @session.model
          started = model.start_operation("Restore Zone Name", true, false, true)
          raise InternalError, "SketchUp refused to restore the Zone name." unless started

          begin
            targets.each { |group, name| group.name = name }
          ensure
            raise InternalError, "SketchUp refused to close Zone name restoration." unless model.commit_operation
          end
        end
      end
    end
  end
end
