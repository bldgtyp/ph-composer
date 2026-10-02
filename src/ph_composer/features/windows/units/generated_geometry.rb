# frozen_string_literal: true

require_relative "records"
require_relative "definition_plan"

module PhComposer
  module Windows
    module Units
      # Derived generation dimensions survive native cross-Model paste. Bounds cannot recover
      # Empty regions or an all-Empty Type. These dimensions permit explicit repair, never export
      # or silent replacement of an absent authored Type.
      module GeneratedGeometry
        module_function

        def plan(definition, type_id:)
          stamp = DEFINITION_STORE.read(definition)
          size = stamp.is_a?(Hash) && stamp["generated_size_m"]
          unknown! unless stamp.is_a?(Hash) && stamp["window_type_id"] == type_id && valid_size?(size)
          width = size.fetch("width_m")
          height = size.fetch("height_m")
          validate_native!(definition, width, height)
          polygon = [[0.0, -height, 0.0], [width, -height, 0.0], [width, 0.0, 0.0], [0.0, 0.0, 0.0]]
          DefinitionPlan::Plan.new(:width_m => width, :height_m => height,
                                   :outer_polygon_m => polygon.map(&:freeze).freeze, :panes => [].freeze,
                                   :signature => nil).freeze
        end

        def valid_size?(size)
          size.is_a?(Hash) && size.keys.sort == %w[height_m width_m] && size.values.all? do |value|
            (value.is_a?(Integer) || value.is_a?(Float)) && value.to_f.finite? && value.positive?
          end
        end

        def validate_native!(definition, width, height)
          definition.entities.each do |entity|
            vertices = case entity
                       when Sketchup::Face then entity.loops.flat_map(&:vertices)
                       when Sketchup::Edge then [entity.start, entity.end]
                       else unknown!
                       end
            vertices.each do |vertex|
              x, y, z = [vertex.position.x, vertex.position.y, vertex.position.z].map { |value| value.to_f * INCH_TO_M }
              tolerance = FaceGeometry::QUANTUM_M
              unknown! unless [x, y, z].all?(&:finite?) && z.abs <= tolerance &&
                              x.between?(-tolerance, width + tolerance) && y.between?(-height - tolerance, tolerance)
            end
          end
        end

        def unknown!
          raise CodedError.new("window.type_geometry_unknown",
                               "Window geometry has no trustworthy generated outline; choose a new placement " \
                               "explicitly.")
        end

        private_class_method :valid_size?, :validate_native!, :unknown!
      end
    end
  end
end
