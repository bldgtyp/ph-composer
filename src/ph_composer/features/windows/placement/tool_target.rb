# frozen_string_literal: true

require_relative "host"
require_relative "../units/definition_plan"

module PhComposer
  module Windows
    module Placement
      # Zone state is read at choose/button-down. A pointer move reads at most one Zones `host_context`
      # row per newly picked path, which scans only the collections on that path, kept until the next
      # refresh, and previews on the Face the pick already holds. That read goes through the public
      # API, so while the session is busy a hover reports the refusal instead of a preview.
      class ToolTarget
        def initialize(session, context)
          @session, @context = session, context
        end

        def refresh(type_id)
          @rows = {}
          @zone_states = Hosts.zone_states(query(Hosts::ZONES).fetch("zones"))
          @plan = Units::DefinitionPlan.build(type_values(type_id))
          @revision = @session.revision
          @edit_path = Array(@session.model.active_path).map(&:persistent_id)
          @plan
        end

        def current?
          @revision == @session.revision && @edit_path == Array(@session.model.active_path).map(&:persistent_id)
        end

        # A preview host on the picked Face. The Place action locates it through Zones' resolver, so a
        # locked or shared host refuses there, with the owner's code, when the gesture commits.
        def resolve(picked, fixed_host = nil)
          return unless picked
          entities = picked.fetch(:path)
          path = entities.map(&:persistent_id)
          row = row(path)
          unless row
            raise CodedError.new("target.wrong_zone",
              "That Face is in no Zone. Make it a Zone before placing a Window.")
          end
          if fixed_host && fixed_host != row.fetch("reference")
            raise CodedError.new("target.changed", "Point at the Face chosen for this Place tool.")
          end
          state = Hosts.zone_state(@zone_states, row)
          Hosts.placeable!(row, state)
          transform = entities[0...-1].reduce(Geom::Transformation.new) do |carried, entity|
            carried * entity.transformation
          end
          Hosts.read(entities.last, path[0...-1], transform, row, state)
        end

        # Checks a Face reference chosen before the tool starts, from the same public row.
        def check!(reference)
          row = row(reference.fetch("zone_path") + reference.fetch("entity_path"))
          unless row && row.fetch("reference") == reference
            raise CodedError.new("target.changed", "The host Face reference no longer matches the Zone read.")
          end
          Hosts.placeable!(row, Hosts.zone_state(@zone_states, row))
        end

        private

        def row(path)
          return @rows[path] if @rows.key?(path)

          @rows[path] = query(Hosts::CONTEXT, "paths" => [path]).fetch("faces").first
        end

        def type_values(type_id)
          read = query("ph_composer.records.list", "kind" => TYPE_KIND, "ids" => [type_id])
          if (unreadable = read.fetch("unreadable").first)
            raise CodedError.new(unreadable.fetch("code"), unreadable.fetch("message"))
          end
          records = read.fetch("records")
          raise CodedError.new("target.not_found", "There is no Window Type with id #{type_id}.") if records.empty?

          records.first.fetch("values")
        end

        def query(name, params = {})
          result = API.query(:context => @context, :name => name, :params => params)
          unless result.fetch("status") == "completed"
            raise CodedError.new(result.fetch("code"), result.fetch("message"))
          end
          result.fetch("value")
        end
      end
    end
  end
end
