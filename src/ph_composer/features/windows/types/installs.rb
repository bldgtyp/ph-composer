# frozen_string_literal: true

module PhComposer
  module Windows
    # Detached draft edits. The panel owns its session; one registered save submits its final
    # product and edge values together. Internal shared assignments are never invented or painted.
    module Installs
      module_function

      def each_edge(record)
        layout = Grid.new(record)
        record.fetch("elements").each do |element|
          next if element.fetch("kind") == "empty"

          layout.classify(element).each_with_index { |classification, i|
            yield element, Types::SIDES[i], classification
          }
        end
      end

      def validate(record)
        each_edge(record) do |element, side, classification|
          if classification == :partial
            raise CodedError.new("validation.failed", "Partly shared edges need a proved installation mapping.")
          end
          if classification == :shared && element.fetch("installs")[side]
            raise CodedError.new("validation.failed", "Shared edges cannot store an installation assignment.")
          end
        end
        record
      end

      def paint(record, element_id, side, install_id)
        unless Types::SIDES.include?(side)
          raise CodedError.new("params.invalid", "Choose a canonical edge.")
        end

        copy = DeepCopy.call(record)
        element = copy.fetch("elements").find { |cell| cell.fetch("id") == element_id }
        raise CodedError.new("target.not_found", "The element no longer exists.") unless element

        raise CodedError.new("validation.failed",
                             "Empty elements have no installation edges.") if element["kind"] == "empty"
        classification = Grid.new(copy).classify(element).fetch(Types::SIDES.index(side))
        unless classification == :perimeter
          raise CodedError.new("validation.failed", "Only perimeter edges can be painted.")
        end

        element.fetch("installs")[side] = install_id
        copy
      end

      def apply_all(record, install_id)
        copy = DeepCopy.call(record)
        each_edge(copy) do |element, side, classification|
          element.fetch("installs")[side] = install_id if classification == :perimeter
        end
        validate(copy)
      end

      def topology(record)
        layout = Grid.new(record)
        [record.fetch("rows_m"), record.fetch("columns_m"), record.fetch("elements").map do |element|
          [element.fetch("kind"), element.fetch("row_span"), element.fetch("column_span"),
           layout.classify(element).map(&:to_s)]
        end.sort_by { |entry| [entry[1], entry[2]] }]
      end

      def copy(source, target)
        unless topology(source) == topology(target)
          raise CodedError.new("validation.failed", "Copy targets need an identical grid and edge topology.")
        end

        validate(source)
        result = DeepCopy.call(target)
        assignments = source.fetch("elements").to_h do |element|
          [[element.fetch("kind"), element.fetch("row_span"), element.fetch("column_span")], element.fetch("installs")]
        end
        result.fetch("elements").each do |element|
          element["installs"] = DeepCopy.call(assignments.fetch(
            [element.fetch("kind"), element.fetch("row_span"), element.fetch("column_span")]
          ))
        end
        result
      end
    end
  end
end
