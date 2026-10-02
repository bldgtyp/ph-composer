# frozen_string_literal: true

module PhComposer
  module Windows
    # Pure grid gestures from the predecessor. Each returns detached authored values; the record
    # schema checks final coverage and references at the proposal boundary.
    module GridOperations
      module_function

      def refuse(message)
        raise CodedError.new("validation.failed", message)
      end

      def apply(record, command, values, identity:)
        copy = DeepCopy.call(record)
        values = DeepCopy.call(values)
        case command
        when "dimension" then dimension(copy, values)
        when "set_element_name" then set_element(copy, values, "name", values.fetch("name"))
        when "set_element_glazing" then set_element(copy, values, "glazing_id", values.fetch("glazing_id"))
        when "set_element_operation" then set_element(copy, values, "operation", values.fetch("operation"))
        when "set_element_frame" then set_element_frame(copy, values)
        when "flip" then flip(copy)
        when "kind" then kind(copy, values)
        when "merge" then merge(copy, values, identity)
        when "split" then split(copy, values, identity)
        when "insert" then insert(copy, values, identity)
        when "remove" then remove(copy, values)
        when "paste" then paste(copy, values)
        else refuse("Unknown Window Type command.")
        end
        copy
      end

      def cells(record, ids)
        refuse("Select unique elements first.") unless ids.is_a?(Array) && !ids.empty? && ids.uniq == ids
        ids.map do |id|
          record.fetch("elements").find { |cell| cell.fetch("id") == id } ||
            raise(CodedError.new("target.not_found", "The selected element no longer exists."))
        end
      end

      def axis(values)
        refuse("Choose rows or columns.") unless %w[rows_m columns_m].include?(values["axis"])
        values.fetch("axis")
      end

      def dimension(record, values)
        key = axis(values)
        index = values.fetch("index")
        unless index.is_a?(Integer) && index.between?(0, record.fetch(key).length - 1)
          refuse("Choose an existing band.")
        end
        record[key][index] = values.fetch("value")
      end

      # An Empty element is wall area: it takes a name and nothing else.
      def set_element(record, values, field, value)
        cell = cells(record, [values.fetch("element_id")]).first
        refuse("Empty is wall area, without products.") if cell["kind"] == "empty" && field != "name"
        cell[field] = value
      end

      def set_element_frame(record, values)
        cell = cells(record, [values.fetch("element_id")]).first
        refuse("Empty is wall area, without products.") if cell["kind"] == "empty"
        cell.fetch("frames")[values.fetch("side")] = values.fetch("frame_id")
      end

      def flip(record)
        record.fetch("columns_m").reverse!
        record.fetch("elements").each do |cell|
          a, b = cell.fetch("column_span")
          cell["column_span"] = [record["columns_m"].length - 1 - b, record["columns_m"].length - 1 - a]
          %w[frames installs].each do |field|
            cell[field]["left"], cell[field]["right"] = cell[field]["right"], cell[field]["left"]
          end
          next unless cell["operation"]
          cell["operation"]["directions"].map! { |side| { "left" => "right", "right" => "left" }.fetch(side, side) }
        end
      end

      def kind(record, values)
        refuse("Choose Glazed or Empty.") unless %w[glazed empty].include?(values["kind"])
        cells(record, values.fetch("ids")).each do |cell|
          next if cell.fetch("kind") == values.fetch("kind")
          cell["kind"] = values.fetch("kind")
          cell["frames"] = Types::SIDES.to_h { |side| [side, nil] }
          cell["installs"] = Types::SIDES.to_h { |side| [side, nil] }
          cell["glazing_id"] = cell["operation"] = nil
        end
      end

      def merge(record, values, identity)
        selected = cells(record, values.fetch("ids"))
        unless selected.length >= 2 && selected.map { |cell| cell.fetch("kind") }.uniq.length == 1
          refuse("Select at least two elements of the same kind.")
        end
        r0 = selected.map { |cell| cell["row_span"].first }.min
        r1 = selected.map { |cell| cell["row_span"].last }.max
        c0 = selected.map { |cell| cell["column_span"].first }.min
        c1 = selected.map { |cell| cell["column_span"].last }.max
        area = selected.sum do |cell|
          (cell["row_span"].last - cell["row_span"].first + 1) *
            (cell["column_span"].last - cell["column_span"].first + 1)
        end
        refuse("Selection must cover one rectangle without gaps.") unless area == (r1 - r0 + 1) * (c1 - c0 + 1)
        merged = DeepCopy.call(selected.min_by { |cell| [cell["row_span"].first, cell["column_span"].first] })
        merge_installs(selected, merged, [r0, r1], [c0, c1])
        merged.merge!("id" => identity.call("wel"), "row_span" => [r0, r1], "column_span" => [c0, c1])
        record["elements"] = record.fetch("elements").reject { |cell| values["ids"].include?(cell["id"]) } + [merged]
      end

      def merge_installs(selected, merged, rows, columns)
        Types::SIDES.each_with_index do |side, i|
          boundary, internal = selected.partition do |cell|
            Grid.edge(cell.fetch("row_span"), cell.fetch("column_span"), i) == Grid.edge(rows, columns, i)
          end
          assignments = boundary.map { |cell| cell.fetch("installs")[side] }.uniq
          if assignments.length != 1
            refuse("#{side.capitalize} installation assignments differ. Resolve them in Installs before merging.")
          end
          # A stored internal slot may matter after splitting; do not discard it during merge.
          if internal.any? { |cell| cell.fetch("installs")[side] }
            refuse("Stored internal installations need review before merging.")
          end
          merged["installs"][side] = assignments.first
        end
      end

      def split(record, values, identity)
        source = cells(record, [values.fetch("element_id")]).first
        r0, r1 = source.fetch("row_span")
        c0, c1 = source.fetch("column_span")
        refuse("Split needs a merged element spanning more than one cell.") if r0 == r1 && c0 == c1
        replacements = (r0..r1).flat_map do |row|
          (c0..c1).map do |column|
            child = DeepCopy.call(source)
            child.merge!("id" => identity.call("wel"), "row_span" => [row, row], "column_span" => [column, column])
            Types::SIDES.each_with_index do |side, i|
              unless Grid.edge([row, row], [column, column], i) == Grid.edge([r0, r1], [c0, c1], i)
                child["installs"][side] = nil
              end
            end
            child
          end
        end
        record["elements"] = record.fetch("elements").reject { |cell| cell["id"] == source["id"] } + replacements
      end

      def band_keys(values)
        key = axis(values)
        [key, key == "rows_m" ? "row_span" : "column_span", key == "rows_m" ? "columns_m" : "rows_m"]
      end

      def insert(record, values, identity)
        key, span_key, other_key = band_keys(values)
        index = values.fetch("index")
        refuse("Choose a grid boundary.") unless index.is_a?(Integer) && index.between?(0, record.fetch(key).length)
        if record.fetch("elements").any? { |cell| cell[span_key].first < index && cell[span_key].last >= index }
          refuse("Split elements crossing this boundary before inserting.")
        end
        layout = Grid.new(record)
        before = record.fetch("elements").to_h { |cell| [cell.fetch("id"), layout.classify(cell)] }
        record[key].insert(index, values.fetch("value"))
        record.fetch("elements").each { |cell| cell[span_key].map! { |n| n >= index ? n + 1 : n } }
        record.fetch(other_key).length.times do |n|
          row, column = key == "rows_m" ? [index, n] : [n, index]
          record["elements"] << Types.blank(row, column, :identity => identity)
        end
        layout = Grid.new(record)
        record.fetch("elements").each do |cell|
          next unless (edges = before[cell.fetch("id")])
          layout.classify(cell).each_with_index do |classification, i|
            cell["installs"][Types::SIDES[i]] = nil if edges[i] == :perimeter && classification != :perimeter
          end
        end
      end

      def remove(record, values)
        key, span_key, = band_keys(values)
        index = values.fetch("index")
        unless index.is_a?(Integer) && index.between?(0, record.fetch(key).length - 1)
          refuse("Choose an existing band.")
        end
        refuse("The last band cannot be removed.") if record.fetch(key).length == 1
        if record.fetch("elements").any? { |cell| cell.fetch("installs").values.any? }
          refuse("This layout carries installation assignments. Review remapping in Installs before removing bands.")
        end
        record[key].delete_at(index)
        record["elements"].reject! { |cell| cell[span_key] == [index, index] }
        record["elements"].each do |cell|
          a, b = cell.fetch(span_key)
          cell[span_key] = [a > index ? a - 1 : a, b >= index ? b - 1 : b]
        end
      end

      def paste(record, values)
        source = cells(record, [values.fetch("source_id")]).first
        refuse("Empty cannot supply products.") if source.fetch("kind") == "empty"
        targets = cells(record, values.fetch("ids"))
        if targets.any? { |cell| cell.fetch("kind") == "empty" || cell.fetch("id") == source.fetch("id") }
          refuse("Choose glazed targets other than the source.")
        end
        layout = Grid.new(record)
        source_edges = layout.classify(source)
        targets.each do |target|
          target_edges = layout.classify(target)
          unless source.fetch("installs").values.all?(&:nil?) && target.fetch("installs").values.all?(&:nil?)
            unless source_edges == target_edges && !source_edges.include?(:partial)
              refuse("Installation topology differs. Use the staged Installs workflow to review the mapping.")
            end
          end
          %w[glazing_id frames operation installs].each { |key| target[key] = DeepCopy.call(source[key]) }
        end
      end
    end
  end
end
