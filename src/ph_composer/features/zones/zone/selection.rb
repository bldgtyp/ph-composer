# frozen_string_literal: true

module PhComposer
  module Zones
    # Current native selection is a read; writes retain explicit occurrence references and values.
    module Selection
      FIELDS = { "name" => "Name", "building_segment" => "Building-Segment", "level" => "Level",
                 "ground_depth_mm" => "Ground depth (mm)" }.freeze
      module_function

      def selected(model)
        entities = model.selection.to_a
        unless !entities.empty? && entities.all? { |entity| entity.is_a?(Sketchup::Group) && ZONE_STORE.read(entity) }
          raise CodedError.new("selection.invalid", "Select one or more Zone Groups. Nothing was written.")
        end
        index = Index.new(model)
        path = Occurrences.active_path(model)
        entities.map do |entity|
          record = Names.read(entity)
          reference = { "zone_id" => record.fetch("id"), "zone_path" => path + [entity.persistent_id] }
          resolve(model, reference, index)
        end
      end

      def resolve(model, reference, index)
        zone = Occurrences.resolve_zone(model, reference, :mutable => true, :index => index)
        parent = model.entities
        zone.path.each do |id|
          entity = Occurrences.unique_entity(parent, id)
          if entity.respond_to?(:locked?) && entity.locked?
            raise CodedError.new("target.locked", "A selected Zone or its parent Group is locked.")
          end
          parent = entity.is_a?(Sketchup::Group) ? entity.entities : entity.definition.entities
        end
        zone
      end

      def available?(session)
        !selected(session.model).empty?
      rescue UserError
        false
      end

      def read(request)
        { "zones" => selected(request.model).map do |zone|
          { "reference" => zone.reference, "values" => Schema.view(zone.record).fetch("values") }
        end }
      end

      def update_field(request, proposal)
        field = request.params.fetch("field")
        index = Index.new(request.model)
        targets = request.params.fetch("targets")
        if targets.map { |target| target.fetch("reference").fetch("zone_path") }.uniq.length != targets.length
          raise CodedError.new("params.invalid", "A Zone may appear only once in the batch.")
        end
        changes = targets.map do |target|
          zone = resolve(request.model, target.fetch("reference"), index)
          before = zone.record
          unless Schema.view(before).fetch("values") == target.fetch("expected_values")
            raise CodedError.new("target.changed", "A Zone changed since the selection was read.")
          end
          after = DeepCopy.call(before).merge(field => DeepCopy.call(request.params.fetch("value")))
          Schema.validate!(after)
          [zone, before, after]
        end
        changes.each do |zone, before, after|
          next if before == after

          proposal.add_step(UpdateZoneStep.new(:reference => zone.reference, :before => before, :after => after),
                            :scopes => [Operations::EntityScope.new(zone.path[0...-1])])
        end
        { "zone_ids" => changes.map { |zone, _before, _after| zone.record.fetch("id") } }
      end

      def client(session)
        session.feature_state(:zones_selection_menu) { Client.new(session) }
      end

      def install(feature)
        FIELDS.each do |field, label|
          feature.menu_item("#{FEATURE_ID}.edit_#{field}_menu", :label => "Set #{label}…", :menu => EXTENSION_NAME,
                            :available => method(:available?)) { |session| client(session).edit(field) }
        end
        feature.menu_item("#{FEATURE_ID}.solve_selected_menu", :label => "Solve adjacencies for selected Zones",
                          :menu => EXTENSION_NAME, :available => method(:available?)) do |session|
          client(session).solve
        end
      end

      class Client
        def initialize(session)
          @session = session
          @context = API.connect(:session_id => session.id)
          @sequence = 0
        end

        def edit(field)
          read = API.query(:context => @context, :name => "#{FEATURE_ID}.selection")
          return show(read) unless read["status"] == "completed"

          rows = read.fetch("value").fetch("zones")
          values = rows.map { |row| row.fetch("values").fetch(field) }.uniq
          entered = UI.inputbox([FIELDS.fetch(field)], [values.length == 1 ? values.first.to_s : ""], "Selected Zones")
          return unless entered

          value = entered.first
          value = Float(value) if field == "ground_depth_mm"
          value = nil if field == "level" && value.to_s.empty?
          params = { "field" => field, "value" => value,
                     "targets" => rows.map { |row| { "reference" => row.fetch("reference"),
                                                     "expected_values" => row.fetch("values") } } }
          invoke("#{FEATURE_ID}.update_field", params, read.fetch("revision"))
        rescue ArgumentError, TypeError
          show("status" => "refused", "message" => "Enter a valid ground depth. Nothing was written.")
        end

        def solve
          read = API.query(:context => @context, :name => "#{FEATURE_ID}.selection")
          return show(read) unless read["status"] == "completed"

          invoke("#{FEATURE_ID}.solve_adjacency",
                 { "zones" => read.fetch("value").fetch("zones").map { |row| row.fetch("reference") } },
                 read.fetch("revision"))
        end

        private

        def invoke(name, params, revision)
          unless Sketchup.active_model.equal?(@session.model)
            return show("status" => "refused", "message" => "The active Model changed. Nothing was written.")
          end
          @sequence += 1
          show(API.invoke(:context => @context, :name => name, :params => params,
                          :request => { "sequence" => @sequence, "expected_revision" => revision }))
        end

        def show(result)
          @session.notice(result.fetch("message"), :tone => result["status"] == "completed" ? :info : :warning)
          Sketchup.status_text = result.fetch("message")
          result
        end
      end
    end
  end
end
