# frozen_string_literal: true

require_relative "../../../core/face_geometry"
require_relative "../../../core/vector3"
require_relative "anchors"

module PhComposer
  module Windows
    module Units
      # SketchUp column-major bases are dimensionless; only matrix translation is in inches.
      module WorldGeometry
        TOLERANCE = 1e-9
        MappedPlan = Struct.new(:outer_polygon_m, :panes, :keyword_init => true)
        TransformState = Struct.new(:scaled, :sheared, :mirrored, :keyword_init => true) do
          def rigid?
            !scaled && !sheared
          end
        end

        module_function

        def polygon(local_m, matrix)
          transform = matrix_values(matrix)
          transform_polygon(local_m, transform)
        end

        def map(plan, matrix)
          transform = matrix_values(matrix)
          panes = plan.panes.map do |pane|
            DefinitionPlan::Pane.new(:element_id => pane.element_id.dup.freeze,
              :polygon_m => transform_polygon(pane.polygon_m, transform)).freeze
          end.freeze
          MappedPlan.new(:outer_polygon_m => transform_polygon(plan.outer_polygon_m, transform), :panes => panes).freeze
        end

        def anchor(plan, anchor, matrix)
          transform = matrix_values(matrix)
          local = Anchors.point(anchor, :width_m => plan.width_m, :height_m => plan.height_m)
          transform_point(local, transform)
        end

        # Postmultiply by the local translation: scaled, sheared and reflected bases all preserve the world anchor.
        def reanchor(matrix, before:, after:, anchor:)
          transform = matrix_values(matrix)
          delta = Anchors.resize_delta(anchor, :before => before, :after => after)
          changed = transform.dup
          3.times do |axis|
            shift_m = 3.times.sum { |column| transform[column * 4 + axis] * delta[column] }
            changed[12 + axis] += shift_m / FaceGeometry::INCH_TO_M
          end
          matrix_values(changed).freeze
        end

        def transform_state(matrix)
          transform = matrix_values(matrix)
          axes = basis(transform)
          lengths = axes.map { |axis| Vector3.length(axis) }
          normalized = axes.zip(lengths).map { |axis, size| axis.map { |value| value / size } }
          sheared = Vector3.dot(normalized[0], normalized[1]).abs > TOLERANCE
          # Units are flat in XY. Changing only the unused normal basis changes no aperture size or shear.
          TransformState.new(:scaled => lengths.take(2).any? { |size| (size - 1.0).abs > TOLERANCE },
            :sheared => sheared, :mirrored => determinant(normalized).negative?).freeze
        end

        def matrix_values(matrix)
          unless matrix.is_a?(Array) && matrix.length == 16 && matrix.all? { |value| numeric?(value) }
            invalid!("The instance transform must contain sixteen finite numbers.")
          end
          values = matrix.map(&:to_f)
          invalid!("The instance transform must be affine.") unless values.values_at(3, 7, 11, 15) == [0, 0, 0, 1]
          normalized = basis(values).map do |axis|
            size = Vector3.length(axis)
            invalid!("The instance transform has a degenerate basis.") unless size.positive? && size.finite?
            axis.map { |value| value / size }
          end
          invalid!("The instance transform has a degenerate basis.") if determinant(normalized).zero?
          values
        end

        def transform_polygon(points, matrix)
          unless points.is_a?(Array) && points.length >= 3
            invalid!("The local polygon must contain at least three metre points.")
          end
          points.map { |point| transform_point(point, matrix) }.freeze
        end

        def transform_point(point, matrix)
          unless point.is_a?(Array) && point.length == 3 && point.all? { |value| numeric?(value) }
            invalid!("The local point must contain three finite metre coordinates.")
          end
          result = 3.times.map do |axis|
            3.times.sum { |column| matrix[column * 4 + axis] * point[column] } +
              matrix[12 + axis] * FaceGeometry::INCH_TO_M
          end
          unless result.all? { |value| numeric?(value) }
            invalid!("The transformed point exceeds finite metre coordinates.")
          end
          result.freeze
        end

        def numeric?(value)
          (value.is_a?(Integer) || value.is_a?(Float)) && value.to_f.finite?
        end

        def basis(matrix)
          [matrix.take(3), matrix[4, 3], matrix[8, 3]]
        end

        def determinant(axes)
          a, b, c = axes
          a[0] * (b[1] * c[2] - b[2] * c[1]) - a[1] * (b[0] * c[2] - b[2] * c[0]) +
            a[2] * (b[0] * c[1] - b[1] * c[0])
        end

        def invalid!(message)
          raise CodedError.new("geometry.invalid", "#{message} Nothing was written.")
        end

        private_class_method :matrix_values, :transform_polygon, :transform_point, :numeric?, :basis, :determinant,
                             :invalid!
      end
    end
  end
end
