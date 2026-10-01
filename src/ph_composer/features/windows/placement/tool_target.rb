# frozen_string_literal: true

require_relative "host"
require_relative "../units/definition_plan"

module PhComposer
  module Windows
    module Placement
      # Semantic reads happen at choose/button-down, never on pointer moves. A picked SDK path
      # indexes the cached public Face rows; Hosts then resolves only that native path.
      class ToolTarget
        def initialize(session, context)
          @session, @context = session, context
        end

        def refresh(type_id)
          @zones = query("ph_composer.zones.all").fetch("zones")
          faces = query("ph_composer.zones.faces.all").fetch("faces")
          @faces = faces
          @by_path = faces.to_h do |row|
            reference = row.fetch("reference")
            [reference.fetch("zone_path") + reference.fetch("entity_path"), reference]
          end
          type = Records::Engine.new(@session.model, Registry.current.catalog).find(TYPE_KIND, type_id)
          @plan = Units::DefinitionPlan.build(type)
          @revision = @session.revision
          @edit_path = Array(@session.model.active_path).map(&:persistent_id)
          @plan
        end

        def current?
          @revision == @session.revision && @edit_path == Array(@session.model.active_path).map(&:persistent_id)
        end

        def resolve(picked, fixed_host = nil)
          return unless picked
          reference = @by_path.fetch(picked.fetch(:path).map(&:persistent_id), nil)
          unless reference
            raise CodedError.new("target.wrong_zone",
              "That Face is in no Zone. Make it a Zone before placing a Window.")
          end
          if fixed_host && fixed_host != reference
            raise CodedError.new("target.changed", "Point at the Face chosen for this Place tool.")
          end
          host(reference)
        end

        def host(reference)
          request = Struct.new(:model).new(@session.model)
          Hosts.resolve(request, reference, :zone_rows => @zones, :face_rows => @faces)
        end

        private

        def query(name)
          result = API.query(:context => @context, :name => name)
          unless result.fetch("status") == "completed"
            raise CodedError.new(result.fetch("code"), result.fetch("message"))
          end
          result.fetch("value")
        end
      end
    end
  end
end
