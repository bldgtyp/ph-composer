# frozen_string_literal: true

require_relative "../../../core/errors"
require_relative "../types/grid"

module PhComposer
  module Windows
    module Units
      # Detached metre geometry for an already validated Type. The existing Grid owns its XY origin and winding.
      module DefinitionPlan
        Pane = Struct.new(:element_id, :polygon_m, :keyword_init => true)
        ElementGeometry = Struct.new(:element_id, :row_span, :column_span, :keyword_init => true)
        Signature = Struct.new(:rows_m, :columns_m, :elements, :keyword_init => true)
        Plan = Struct.new(:width_m, :height_m, :outer_polygon_m, :panes, :signature, :keyword_init => true)

        module_function

        def build(record)
          rows = record.fetch("rows_m")
          columns = record.fetch("columns_m")
          unless valid_bands?(rows) && valid_bands?(columns)
            raise CodedError.new("validation.failed",
              "Complete every Window Type dimension with a finite positive size before generating a Window Unit. " \
              "Nothing was written.")
          end
          grid = Grid.new(record)
          glazed = record.fetch("elements").select { |cell| cell.fetch("kind") == "glazed" }
          panes = glazed.map do |cell|
            Pane.new(:element_id => cell.fetch("id").dup.freeze, :polygon_m => polygon(grid.rectangle(cell))).freeze
          end.freeze
          Plan.new(:width_m => columns.sum, :height_m => rows.sum, :outer_polygon_m => polygon(grid.outer_rectangle),
            :panes => panes, :signature => signature(rows, columns, glazed)).freeze
        end

        def positive_dimension?(value)
          (value.is_a?(Integer) || value.is_a?(Float)) && value.to_f.finite? && value.positive?
        end

        def valid_bands?(bands)
          bands.is_a?(Array) && !bands.empty? && bands.all? { |value| positive_dimension?(value) } &&
            positive_dimension?(bands.sum)
        end

        def polygon(corners)
          corners.map { |x, y| [x, y, 0.0].freeze }.freeze
        end

        # Pane stamps depend on ids and spans as well as dimensions. Record order and product metadata do not.
        def signature(rows, columns, glazed)
          elements = glazed.sort_by { |cell| cell.fetch("id") }.map do |cell|
            ElementGeometry.new(:element_id => cell.fetch("id").dup.freeze,
              :row_span => cell.fetch("row_span").dup.freeze,
              :column_span => cell.fetch("column_span").dup.freeze).freeze
          end.freeze
          Signature.new(:rows_m => rows.dup.freeze, :columns_m => columns.dup.freeze, :elements => elements).freeze
        end
        private_class_method :valid_bands?, :polygon, :signature
      end
    end
  end
end
