# frozen_string_literal: true

require_relative "place_step"
require_relative "mutation_scope"
require_relative "restore_geometry"
require_relative "restore_panes"
require_relative "restore_pane_scope"

module PhComposer
  module Windows
    module Units
      # A specialized placement with the same canonical definition, native glue and identity
      # guards. The caller owns one transaction and the returned rollback scopes.
      class RestoreStep < PlaceStep
        attr_reader :scopes

        def initialize(model:, host:, type:, record:, pane_paths:, existing_polygons_m:)
          allowed = %w[id schema_version window_type_id anchor]
          unless record["anchor"] == Anchors::DEFAULT && (record.keys - allowed).empty?
            raise CodedError.new("validation.failed",
                                 "Restore creates a new unit with its default anchor and no old data.")
          end
          @pane_paths = DeepCopy.call(pane_paths)
          @face_id = host.entity.persistent_id
          validate_paths!(host.parent_path)
          faces = resolve_panes(host.entities)
          panes = RestorePanes.new(host.entities, faces, host.transform, type.fetch("id"),
                                   DefinitionPlan.build(type))
          @panes_before = DeepCopy.call(panes.snapshot)
          @restore_matrix = RestoreGeometry.infer(DefinitionPlan.build(type), panes.polygons, host.geometry)
          point = WorldGeometry.anchor(DefinitionPlan.build(type), Anchors::DEFAULT, @restore_matrix)
          super(:model => model, :host => host, :type => type, :record => record, :point_m => point,
                :existing_polygons_m => existing_polygons_m, :world_matrix => @restore_matrix)
          @affected.first["change"] = "restored"
          @scopes = [PhComposer::Operations::EntityScope.new(host.parent_path),
                     MutationScope.new(:definition_ids => definition_ids),
                     RestorePaneScope.new(host.parent_path, @pane_paths.map(&:last), type)].freeze
        end

        def descriptor
          super.merge("name" => "restore_window_unit", "pane_paths" => DeepCopy.call(@pane_paths),
                      "panes_before" => DeepCopy.call(@panes_before), "world_matrix" => @restore_matrix.dup)
        end

        def apply(model, slots)
          located = @locator.call(model, @host_reference, :mutable => true)
          entities, transform = located.entities, located.transform
          panes = RestorePanes.new(entities, resolve_panes(entities), transform, @type.fetch("id"), @plan)
          unless panes.snapshot == @panes_before
            NativeUnit.changed!("The loose stamped panes changed after preview.")
          end
          super
          panes.erase(entities)
          @affected.first["change"] = "restored"
        end

        private

        def validate_paths!(parent_path)
          valid = @pane_paths.is_a?(Array) && !@pane_paths.empty? && @pane_paths.uniq.length == @pane_paths.length &&
                  @pane_paths.all? { |path|
                    path.is_a?(Array) && path.length == parent_path.length + 1 &&
                      path.take(parent_path.length) == parent_path && path.all? { |id|
                                                                        id.is_a?(Integer) && id.positive?
                                                                      }
                  }
          unless valid
            raise CodedError.new("validation.failed", "Choose complete pane paths in the host's own storage.")
          end
        end

        def resolve_panes(entities)
          @pane_paths.map do |path|
            found = entities.to_a.select { |entity| entity.persistent_id == path.last }
            NativeUnit.changed!("A stamped pane no longer resolves uniquely.") unless found.length == 1
            face = found.first
            RestoreGeometry.refuse! unless face.is_a?(Sketchup::Face) && face.persistent_id != @face_id
            face
          end
        end
      end
    end
  end
end
