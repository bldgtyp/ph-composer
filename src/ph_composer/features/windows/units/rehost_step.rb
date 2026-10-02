# frozen_string_literal: true

require_relative "records"
require_relative "occurrences"
require_relative "definition_geometry"
require_relative "world_geometry"
require_relative "../placement/host"
require_relative "../placement/fit"

module PhComposer
  module Windows
    module Units
      # Re-glue existing geometry in the same native storage. The caller supplies public host state and other outlines.
      class RehostStep
        attr_reader :affected

        def initialize(model:, reference:, expected_record:, host:, type:, existing_polygons_m: [],
                       expected_scope: nil, expected_state: nil)
          @reference = DeepCopy.call(reference)
          @expected_record = DeepCopy.call(Units.validate!(expected_record))
          @type = DeepCopy.call(type)
          unless @type.fetch("id") == @expected_record.fetch("window_type_id") && Types::KIND.problems(@type).empty?
            raise CodedError.new("validation.failed", "Choose the authored Type referenced by this Window unit.")
          end
          items = Occurrences.all(model).select { |item| item.path == @reference.fetch("entity_path") }
          unless items.length == 1 && [items.first.record.fetch("id"), @expected_record.fetch("id")].include?(
            @reference.fetch("unit_id"))
            changed!("The Window re-host occurrence no longer resolves uniquely.")
          end
          item = items.first
          mutable!(item)
          @reference["unit_id"] = @expected_record.fetch("id")
          @plan = DefinitionPlan.build(@type)
          @native_before = native(item)
          @locator = host.locator or raise ArgumentError, "A re-host target must be located."
          @host_path = host.parent_path.dup
          @host_id = host.entity.persistent_id
          @host_reference, @host_values = DeepCopy.call(host.reference), DeepCopy.call(host.values)
          @host_geometry = DeepCopy.call(host.geometry.to_h)
          @host_transform = host.transform.to_a
          @existing_polygons = DeepCopy.call(existing_polygons_m)
          @expected_scope, @expected_state = expected_scope, DeepCopy.call(expected_state)
          if expected_scope.nil? != expected_state.nil?
            raise ArgumentError, "A host scope and expected state must be paired."
          end
          check_host_values!
          check_fit!(model, item)
          @affected = [{ "kind" => REFERENCE_KIND, "id" => @expected_record.fetch("id"), "change" => "rehosted",
            "reference" => DeepCopy.call(@reference) }]
        end

        def descriptor
          DeepCopy.call("name" => "rehost_window_unit", "reference" => @reference,
            "expected_record" => @expected_record, "type" => @type, "native_before" => @native_before,
            "host" => @host_reference, "host_values" => @host_values, "host_path" => @host_path,
            "host_id" => @host_id, "host_geometry" => @host_geometry, "host_transform" => @host_transform,
            "existing_polygons_m" => @existing_polygons, "scope_path" => @expected_scope&.path,
            "scope_before" => @expected_state)
        end

        def temporary_ids
          []
        end

        def apply(model, _slots)
          item = Occurrences.resolve(model, @reference, :mutable => true)
          unless item.record == @expected_record && native(item) == @native_before
            changed!("The Window record or native state changed after re-host preview.")
          end
          if @expected_scope && !@expected_scope.unchanged?(model, @expected_state)
            changed!("The public host state changed after re-host preview.")
          end
          face = check_fit!(model, item)
          item.entity.glued_to = face
          unless item.entity.glued_to == face
            raise CodedError.new("geometry.failed", "The native Window instance could not glue to its new host Face.")
          end
          keys = %w[matrix definition_id definition_before]
          unless native(item).slice(*keys) == @native_before.slice(*keys)
            raise CodedError.new("geometry.failed", "Native re-host changed the Window matrix or geometry.")
          end
        end

        private

        def check_fit!(model, item)
          unless item.path[0...-1] == @host_path
            raise CodedError.new("window.rehost_parent",
              "Re-host requires a Face in the Window's existing parent storage.")
          end
          unless Types::KIND.store.read(model, @type.fetch("id")) == @type
            changed!("The authored Window Type changed after re-host preview.")
          end
          unless DefinitionGeometry.matches?(item.entity.definition, :type_id => @type.fetch("id"), :plan => @plan)
            raise CodedError.new("window.definition_changed",
              "Reset the Window geometry to its Type before re-hosting.")
          end
          located = @locator.call(model, @host_reference, :mutable => true)
          face, transform = located.entity, located.transform
          geometry = FaceGeometry.capture(face, transform)
          unless geometry.to_h == @host_geometry && transform.to_a == @host_transform
            changed!("The re-host Face geometry changed after preview.")
          end
          outline = WorldGeometry.map(@plan, item.transform.to_a).outer_polygon_m
          Placement::Fit.check!(geometry, outline, :existing_polygons_m => @existing_polygons)
          face
        end

        def check_host_values!
          return unless @host_values["boundary_condition"] == "Surface"

          raise CodedError.new("window.surface_host", "A paired Surface Face cannot host a Window unit.")
        end

        def native(item)
          entity = item.entity
          { "matrix" => entity.transformation.to_a, "world_matrix" => item.transform.to_a,
            "definition_id" => entity.definition.persistent_id,
            "definition_before" => DefinitionGeometry.capture(entity.definition),
            "glued_face_id" => entity.glued_to&.persistent_id }
        end

        def mutable!(item)
          if item.shared_storage
            raise CodedError.new("target.shared_definition", "Make the Window parent storage unique before re-hosting.")
          end
          raise CodedError.new("target.locked", "The Window unit or its parent is locked.") if item.locked
        end

        def changed!(message)
          raise CodedError.new("target.changed", "#{message} Nothing was written.")
        end
      end
    end
  end
end
