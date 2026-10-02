# frozen_string_literal: true

module PhComposer
  module Windows
    # Captured products needed by a definition. An implicit default is a dependency only on a
    # perimeter edge that has no authored assignment; shared edges resolve to zero.
    module Graph
      module_function

      def inherited_edges(record)
        result = []
        Installs.each_edge(record) do |element, side, classification|
          next if classification == :shared || element.fetch("installs")[side]
          if classification == :partial
            raise CodedError.new("validation.failed", "Partly shared edges need a proved installation mapping.")
          end

          result << [element.fetch("id"), side]
        end
        result
      end

      def dependency_ids(record, default_id)
        result = Products::KINDS.values.to_h { |kind| [kind.id, []] }
        Types.references(record).each { |kind, id| result.fetch(kind) << id }
        result.fetch(PSI_INSTALL_KIND) << default_id if default_id && !inherited_edges(record).empty?
        result.transform_values(&:uniq)
      end

      def uses(records, default_id)
        result = Hash.new { |hash, key| hash[key] = [] }
        records.each do |record|
          layout = Grid.new(record)
          record.fetch("elements").each do |element|
            next if element.fetch("kind") == "empty"

            classifications = layout.classify(element)
            { GLAZING_KIND => { "glazing" => element["glazing_id"] }, FRAME_KIND => element.fetch("frames"),
              PSI_INSTALL_KIND => element.fetch("installs") }.each do |kind, slots|
              slots.each do |side, assignment|
                inherited = kind == PSI_INSTALL_KIND && assignment.nil? &&
                            classifications.fetch(Types::SIDES.index(side)) != :shared
                id = inherited ? default_id : assignment
                next unless id

                result[[kind, id]] << { "kind" => "window_element", "type_id" => record.fetch("id"),
                                        "element_id" => element.fetch("id"), "side" => side,
                                        "name" => "#{record['name']} / #{element['name']} / #{side}#{inherited ? ' (default)' : ''}" }
              end
            end
          end
        end
        result
      end
    end
  end
end
