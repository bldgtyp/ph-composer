# frozen_string_literal: true

require_relative "occurrences"

module PhComposer
  module Windows
    module Units
      # Selection cannot name a shared definition leaf's occurrence on its own. Select and
      # zoom the next entity reachable inside the current edit path instead. For another branch,
      # zoom its Model-root ancestor without selecting outside active storage. Locate never
      # opens or changes the user's edit context.
      module Locate
        module_function

        def call(model, references)
          items = Occurrences.all(model).group_by(&:path)
          found = references.filter_map do |reference|
            matches = items.fetch(reference.fetch("entity_path"), []).select do |item|
              item.record.fetch("id") == reference.fetch("unit_id")
            end
            matches.first if matches.length == 1
          end
          active_path = Array(model.active_path).map(&:persistent_id)
          entities = found.map { |item| selection_entity(model, item.path, active_path) }.uniq
          active_entities = model.active_entities.to_a.to_h { |entity| [entity.persistent_id, entity] }
          selectable = entities.select { |entity| active_entities[entity.persistent_id] == entity }
          model.selection.clear
          unless entities.empty?
            model.selection.add(selectable) unless selectable.empty?
            model.active_view.zoom(entities)
          end
          { "units" => found.map(&:reference) }
        end

        def selection_entity(model, path, active_path)
          in_context = path.take(active_path.length) == active_path && path.length > active_path.length
          selected_index = in_context ? active_path.length : 0
          collection = model.entities
          entity = nil
          path.take(selected_index + 1).each do |id|
            matches = collection.to_a.select { |candidate| candidate.persistent_id == id }
            unless matches.length == 1
              raise CodedError.new("target.changed", "The Window occurrence ancestor no longer resolves uniquely.")
            end
            entity = matches.first
            collection = entity.entities if entity.is_a?(Sketchup::Group)
            collection = entity.definition.entities if entity.is_a?(Sketchup::ComponentInstance)
          end
          entity
        end
        private_class_method :selection_entity
      end
    end
  end
end
