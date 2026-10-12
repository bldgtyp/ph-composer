# frozen_string_literal: true

# Development only; never shipped (tools/ is outside the RBZ). P2 host spike for
# planning/bugs/copied-zone-edit-refusal/PLAN.md. Load it through the bridge:
#
#   eval 'load "<repo>/tools/spikes/copied-zone-independence/spike.rb"'
#   eval 'CopiedZoneSpike.install'          # start recording host events
#   ... a native gesture ...
#   eval 'CopiedZoneSpike.report'           # events since the last report, then the Zone occurrences
#   eval 'CopiedZoneSpike.arm(fault: nil, on_failure: :commit)'   # S3/S4 prototype repair
#   eval 'CopiedZoneSpike.uninstall'
#
# The prototype repair is the P3/P4 shape under test, not a product implementation: on a commit that
# follows an added Group or ComponentInstance, a coalesced zero-delay timer finds Zone ids held by
# more than one occurrence where exactly one occurrence was in the baseline, and repairs the others in
# one transparent operation (make_unique, then the shipping repair_identity planner and step). Faults
# raise at a named stage so S4 can read what commit or abort leaves behind.
module CopiedZoneSpike
  FAULTS = %i[after_make_unique after_zone_write mid_faces before_commit].freeze

  class << self
    attr_reader :events

    def install
      uninstall if @installed
      @events = []
      @sequence = 0
      @model = Sketchup.active_model
      @model_observer = ModelWatch.new
      @entities_observer = EntitiesWatch.new
      @app_observer = AppWatch.new
      @watched = []
      @model.add_observer(@model_observer)
      Sketchup.add_observer(@app_observer)
      watch_containers(@model)
      @baseline = occurrences(@model).map { |zone| [zone[:path], zone[:id]] }
      @installed = true
      { "watched_containers" => @watched.length, "baseline" => @baseline }
    end

    def uninstall
      return false unless @installed

      @timer && UI.stop_timer(@timer)
      @timer = nil
      @model.remove_observer(@model_observer) if @model.valid?
      Sketchup.remove_observer(@app_observer)
      @watched.each do |entities|
        entities.remove_observer(@entities_observer)
      rescue StandardError
        nil
      end
      @watched = []
      @armed = nil
      @installed = false
      true
    end

    def record(kind, detail = {})
      @sequence += 1
      @events << { "n" => @sequence, "t" => Time.now.strftime("%H:%M:%S.%L"), "event" => kind }.merge(detail)
    end

    # Events since the last report, then the Zone occurrences as they stand.
    def report(model = Sketchup.active_model)
      taken = @events.dup
      @events.clear
      { "events" => taken, "zones" => occurrences(model), "undo" => undo_name(model) }
    end

    def undo_name(_model)
      # The Undo item text is not readable through the Ruby API; the panel/menu is checked natively.
      nil
    end

    # Every Zone occurrence: path, id, Group and definition persistent ids, origin and the Face ids.
    def occurrences(model)
      PhComposer::Zones::Occurrences.zones(model).map do |zone|
        entity = zone.entity
        faces = PhComposer::Zones::Occurrences.faces(zone).map do |face|
          record = PhComposer::Zones::Faces::FACE_STORE.read(face.entity)
          [face.entity.persistent_id, record && record["id"], record && record["boundary_condition"]]
        end
        { :path => zone.path, :id => zone.record["id"], :name => zone.record["name"],
          :definition => entity.definition.persistent_id, :instances => entity.definition.instances.length,
          :origin => entity.transformation.origin.to_a.map { |value| value.to_f.round(3) },
          :shared => zone.shared_definition, :nested => zone.nested, :locked_parent => zone.locked_parent,
          :faces => faces }
      end
    end

    def watch_containers(model)
      scan(model.entities)
    end

    def scan(entities)
      return if @watched.include?(entities)

      entities.add_observer(@entities_observer)
      @watched << entities
      entities.each do |entity|
        if entity.is_a?(Sketchup::Group)
          scan(entity.entities)
        elsif entity.is_a?(Sketchup::ComponentInstance)
          scan(entity.definition.entities)
        end
      end
    end

    def added(entity)
      detail = { "class" => entity.class.name.split("::").last }
      if entity.respond_to?(:persistent_id)
        detail["pid"] = entity.persistent_id
      end
      if entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
        detail["zone_dictionary"] = !entity.attribute_dictionary(PhComposer::Zones::ZONE_DICTIONARY).nil?
        detail["zone_id"] = PhComposer::Zones::ZONE_STORE.read(entity)&.fetch("id", nil)
        detail["definition"] = entity.definition.persistent_id
        detail["origin"] = entity.transformation.origin.to_a.map { |value| value.to_f.round(3) }
        @added_container = true
      end
      record("element_added", detail)
      # A native paste adds its Group after the transaction commits (measured), so a commit-only
      # trigger would miss it: schedule from the addition too.
      schedule if @added_container
    end

    # ---------------------------------------------------------------- the prototype repair (S3, S4)

    # fault: one of FAULTS or nil; on_failure: :commit, :abort or :restore (write the copies' captured
    # records back, then commit: the native copy survives with distinct storage and its copied identity).
    def arm(fault: nil, on_failure: :commit, after: 1)
      raise ArgumentError, "unknown fault #{fault}" if fault && !FAULTS.include?(fault)

      @armed = { :fault => fault, :on_failure => on_failure, :mid => after }
      @baseline = occurrences(@model).map { |zone| [zone[:path], zone[:id]] }
      @armed
    end

    def disarm
      @armed = nil
    end

    def committed
      schedule if @added_container
    end

    def schedule
      return unless @armed && !@repairing && @timer.nil?

      @added_container = false
      @timer = UI.start_timer(0.0, false) do
        @timer = nil
        settle
      end
      record("repair_scheduled")
    end

    def rebaseline(reason)
      @added_container = false
      @baseline = occurrences(@model).map { |zone| [zone[:path], zone[:id]] }
      record("rebaselined", "reason" => reason)
    end

    def copies
      current = PhComposer::Zones::Occurrences.zones(@model)
      current.group_by { |zone| zone.record["id"] }.flat_map do |id, group|
        next [] if group.length < 2

        in_baseline = group.select { |zone| @baseline.include?([zone.path, id]) }
        next [] unless in_baseline.length == 1

        group - in_baseline
      end
    end

    def settle
      found = copies
      record("repair_detected", "paths" => found.map(&:path))
      return rebaseline("nothing to repair") if found.empty?

      @repairing = true
      outcome = repair(found)
      record("repair_finished", outcome)
      rebaseline("after repair")
    rescue StandardError => error
      record("repair_error", "error" => "#{error.class}: #{error.message}")
    ensure
      @repairing = false
    end

    def repair(found)
      session = PhComposer::Sessions.for(@model)
      registry = PhComposer::Registry.current
      action = registry.actions.fetch("ph_composer.zones.repair_identity")
      started = @model.start_operation("Make Zone Independent", true, false, true)
      stage = "started"
      begin
        found.each { |zone| zone.entity.make_unique if zone.shared_definition }
        stage = "made_unique"
        captured = capture(found)
        fault!(:after_make_unique)
        found.each do |zone|
          proposal = PhComposer::Operations::Proposal.new
          request = PhComposer::HandlerRequest.for(session, :owner => action.owner, :name => action.name,
                                                            :registry => registry,
                                                            :params => { "zone_path" => zone.path },
                                                            :proposal => proposal)
          PhComposer::Zones.repair_identity(request, proposal, :zone_path => zone.path)
          with_faults { proposal.apply(@model, request.engine) }
        end
        stage = "applied"
        fault!(:before_commit)
        committed_ok = @model.commit_operation
        { "started" => started, "stage" => stage, "commit" => committed_ok }
      rescue StandardError => error
        restored = restore(captured) if @armed[:on_failure] == :restore && captured
        closed = if @armed[:on_failure] == :abort
                   @model.abort_operation
                   "aborted"
                 else
                   @model.commit_operation ? "committed" : "commit refused"
                 end
        { "started" => started, "stage" => stage, "failure" => "#{error.class}: #{error.message}",
          "closed" => closed, "restored" => restored }
      end
    end

    # Every record the repair can write on each copy, after storage isolation and before any write.
    def capture(found)
      found.map do |zone|
        current = PhComposer::Zones::Occurrences.zones(@model).find { |other| other.path == zone.path }
        faces = PhComposer::Zones::Occurrences.faces(current).map do |face|
          [face.entity, PhComposer::Zones::Faces::FACE_STORE.read(face.entity),
           PhComposer::Zones::STAMP_STORE.read(face.entity)]
        end
        [current.entity, PhComposer::Zones::ZONE_STORE.read(current.entity), faces]
      end
    end

    def restore(captured)
      count = 0
      captured.each do |entity, record, faces|
        PhComposer::Zones::ZONE_STORE.write(entity, record)
        faces.each do |face, face_record, stamp|
          face_record ? PhComposer::Zones::Faces::FACE_STORE.write(face, face_record) :
                        PhComposer::Zones::Faces::FACE_STORE.delete(face)
          stamp ? PhComposer::Zones::STAMP_STORE.write(face, stamp) : PhComposer::Zones::STAMP_STORE.delete(face)
          count += 1
        end
      end
      count
    end

    def fault!(stage)
      raise "injected fault at #{stage}" if @armed && @armed[:fault] == stage
    end

    # after_zone_write and mid_faces fire inside the shipping step's writes.
    def with_faults
      zone_store = PhComposer::Zones::ZONE_STORE
      face_store = PhComposer::Zones::Faces::FACE_STORE
      fault = @armed[:fault]
      count = 0
      limit = @armed[:mid]
      zone_store.singleton_class.send(:alias_method, :__spike_write, :write)
      face_store.singleton_class.send(:alias_method, :__spike_write, :write)
      zone_store.define_singleton_method(:write) do |entity, record|
        __spike_write(entity, record)
        raise "injected fault at after_zone_write" if fault == :after_zone_write
      end
      face_store.define_singleton_method(:write) do |entity, record|
        count += 1
        raise "injected fault at mid_faces (face #{count})" if fault == :mid_faces && count > limit

        __spike_write(entity, record)
      end
      yield
    ensure
      [zone_store, face_store].each do |store|
        store.singleton_class.send(:remove_method, :write)
        store.singleton_class.send(:alias_method, :write, :__spike_write)
        store.singleton_class.send(:remove_method, :__spike_write)
      end
    end

    # ---------------------------------------------------------------- S7

    # Times the full Zones walk the watcher would run, and one duplicate detection pass.
    def time_walk(model = Sketchup.active_model, repeat: 5)
      walk = Array.new(repeat) { measure { PhComposer::Zones::Occurrences.zones(model) } }
      faces = Array.new(repeat) do
        measure do
          PhComposer::Zones::Occurrences.zones(model).each { |zone| PhComposer::Zones::Occurrences.faces(zone) }
        end
      end
      zones = PhComposer::Zones::Occurrences.zones(model)
      { "zones" => zones.length, "walk_ms" => walk.sort, "walk_with_faces_ms" => faces.sort }
    end

    def measure
      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      yield
      ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start) * 1000).round(1)
    end
  end

  class ModelWatch < Sketchup::ModelObserver
    def onTransactionStart(_model)
      CopiedZoneSpike.record("transaction_start")
    end

    def onTransactionCommit(_model)
      CopiedZoneSpike.record("transaction_commit")
      CopiedZoneSpike.committed
    end

    def onTransactionAbort(_model)
      CopiedZoneSpike.record("transaction_abort")
    end

    def onTransactionEmpty(_model)
      CopiedZoneSpike.record("transaction_empty")
    end

    def onTransactionUndo(_model)
      CopiedZoneSpike.record("transaction_undo")
      CopiedZoneSpike.rebaseline("undo")
    end

    def onTransactionRedo(_model)
      CopiedZoneSpike.record("transaction_redo")
      CopiedZoneSpike.rebaseline("redo")
    end
  end

  class EntitiesWatch < Sketchup::EntitiesObserver
    def onElementAdded(_entities, entity)
      CopiedZoneSpike.added(entity)
    end
  end

  class AppWatch < Sketchup::AppObserver
    def onNewModel(model)
      CopiedZoneSpike.record("app_new_model", "title" => model.title)
    end

    def onOpenModel(model)
      CopiedZoneSpike.record("app_open_model", "title" => model.title)
    end

    def onActivateModel(model)
      CopiedZoneSpike.record("app_activate_model", "title" => model.title)
    end
  end
end
