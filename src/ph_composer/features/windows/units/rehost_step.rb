# frozen_string_literal: true

require_relative "records"
require_relative "occurrences"
require_relative "definition_geometry"
require_relative "native_unit"
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

          item = NativeUnit.resolve!(Occurrences.all(model), @reference, :expected_record => @expected_record)
          @reference["unit_id"] = @expected_record.fetch("id")
          @plan = DefinitionPlan.build(@type)
          @native_before = NativeUnit.preimage(item)
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
          unless item.record == @expected_record && NativeUnit.preimage(item) == @native_before
            NativeUnit.changed!("The Window record or native state changed after re-host preview.")
          end
          if @expected_scope && !@expected_scope.unchanged?(model, @expected_state)
            NativeUnit.changed!("The public host state changed after re-host preview.")
          end
          face = check_fit!(model, item)
          item.entity.glued_to = face
          unless item.entity.glued_to == face
            raise CodedError.new("geometry.failed", "The native Window instance could not glue to its new host Face.")
          end

          keys = %w[matrix definition_id definition_before]
          unless NativeUnit.preimage(item).slice(*keys) == @native_before.slice(*keys)
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
            NativeUnit.changed!("The authored Window Type changed after re-host preview.")
          end
          unless DefinitionGeometry.matches?(item.entity.definition, :type_id => @type.fetch("id"), :plan => @plan)
            raise CodedError.new("window.definition_changed",
                                 "Reset the Window geometry to its Type before re-hosting.")
          end
          located = @locator.call(model, @host_reference, :mutable => true)
          face, transform = located.entity, located.transform
          geometry = FaceCapture.call(face, transform)
          unless geometry.to_h == @host_geometry && transform.to_a == @host_transform
            NativeUnit.changed!("The re-host Face geometry changed after preview.")
          end
          outline = WorldGeometry.map(@plan, item.transform.to_a).outer_polygon_m
          Placement::Fit.check!(geometry, outline, :existing_polygons_m => @existing_polygons)
          face
        end

        def check_host_values!
          return unless @host_values["boundary_condition"] == "Surface"

          raise CodedError.new("window.surface_host", "A paired Surface Face cannot host a Window unit.")
        end
      end
    end
  end
end
