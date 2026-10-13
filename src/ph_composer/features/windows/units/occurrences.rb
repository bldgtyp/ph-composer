# frozen_string_literal: true

module PhComposer
  module Windows
    module Units
      # `transform` is the instance's world transform; `parent_transform` the world transform of the
      # collection holding it, which a re-placed or re-defined instance is written relative to.
      Occurrence = Struct.new(:entity, :path, :transform, :parent_transform, :record, :shared_storage, :locked,
                              keyword_init: true) do
        def reference
          { "unit_id" => record.fetch("id"), "entity_path" => path.dup }
        end

        def entry
          Records::ReferenceEntry.new(:kind => REFERENCE_KIND, :key => path, :record => record)
        end
      end

      # Includes units outside Zones and every placement of shared storage. A pasted orphan must
      # still prevent deletion of its type; a copied identity is reported without repairing it.
      module Occurrences
        module_function

        def all(model)
          walk(model.entities, [], Geom::Transformation.new, false, false, [])
        end

        # The occurrences inside the container at `path` only, with the transform, sharing and lock
        # carried down to it as `all` would; nothing outside it is read. Empty when `path` is gone.
        def under(model, path)
          entities = model.entities
          transform = Geom::Transformation.new
          shared = locked = false
          path.each do |id|
            entity = entities.to_a.find do |item|
              (item.is_a?(Sketchup::Group) || item.is_a?(Sketchup::ComponentInstance)) && item.persistent_id == id
            end
            return [] unless entity

            transform *= entity.transformation
            locked ||= entity.locked?
            shared ||= entity.is_a?(Sketchup::ComponentInstance) || entity.definition.instances.length > 1
            entities = entity.is_a?(Sketchup::Group) ? entity.entities : entity.definition.entities
          end
          walk(entities, path.dup, transform, shared, locked, [])
        end

        # Every Unit record id anywhere outside `path`, read leniently: an unreadable record elsewhere
        # is skipped, since only whether an id is held matters here.
        def held_ids(model, except:)
          ids = []
          pending = [[model.entities, []]]
          until pending.empty?
            entities, path = pending.shift
            entities.to_a.each do |entity|
              next unless entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)

              current = path + [entity.persistent_id]
              next if current[0, except.length] == except

              record = begin
                STORE.read(entity)
              rescue CodedError
                nil
              end
              ids << record["id"] if record.is_a?(Hash) && record["id"].is_a?(String)
              pending << [entity.is_a?(Sketchup::Group) ? entity.entities : entity.definition.entities, current]
            end
          end
          ids
        end

        # Replacing/removing a generated container must not silently erase nested identities.
        # Walk native storage once, including nested unused definitions, without adopting it.
        def assert_leaf!(item)
          pending = [item.entity.definition.entities]
          seen = {}
          until pending.empty?
            entities = pending.shift
            next if seen[entities.object_id]

            seen[entities.object_id] = true
            entities.each do |entity|
              next unless entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)

              unless entity.get_attribute(STORE.dictionary, STORE.key).nil?
                raise CodedError.new("window.nested_units",
                                     "Recover nested Window Units before removing or replacing their containing " \
                                     "Window.")
              end
              pending << entity.definition.entities
            end
          end
        end

        def resolve(model, reference, mutable: false)
          path = reference.fetch("entity_path")
          found = all(model).select { |item| item.path == path }
          raise CodedError.new("target.not_found", "The Window unit occurrence no longer exists.") if found.empty?
          raise CodedError.new("target.ambiguous", "The Window occurrence path is ambiguous.") unless found.length == 1

          item = found.first
          unless item.record.fetch("id") == reference.fetch("unit_id")
            raise CodedError.new("target.changed", "The Window unit identity has changed.")
          end

          mutable!(item) if mutable
          item
        end

        # Shared storage would carry a write to every other placement, and a lock forbids it.
        def mutable!(item)
          if item.shared_storage
            raise CodedError.new("target.shared_definition",
                                 "Make the Window's parent storage unique before editing it. Nothing was written.")
          end
          return unless item.locked

          raise CodedError.new("target.locked", "The Window unit or its parent is locked. Nothing was written.")
        end

        def walk(entities, path, transform, shared, locked, found)
          entities.each do |entity|
            next unless entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)

            current = path + [entity.persistent_id]
            carried = transform * entity.transformation
            child_locked = locked || entity.locked?
            record = Units.read(entity)
            if record
              unless entity.is_a?(Sketchup::ComponentInstance)
                raise CodedError.new("target.wrong_kind", "A Window unit record is stored on a Group.")
              end

              found << Occurrence.new(:entity => entity, :path => current, :transform => carried,
                                      :parent_transform => transform, :record => record, :shared_storage => shared,
                                      :locked => child_locked)
            end
            definition_shared = entity.is_a?(Sketchup::ComponentInstance) ||
                                (entity.respond_to?(:definition) && entity.definition.instances.length > 1)
            children = entity.is_a?(Sketchup::Group) ? entity.entities : entity.definition.entities
            walk(children, current, carried, shared || definition_shared, child_locked, found)
          end
          found
        end
        private_class_method :walk
      end

      TARGET = Records::ReferenceTarget.new(
        :id => REFERENCE_KIND, :label => "Window unit", :schema_version => 1, :values => RECORD_KIND.values_schema,
        :occurrence => Shapes.object({ "unit_id" => Shapes::TEXT,
                                       "entity_path" => { "type" => "array", "minItems" => 1,
                                                          "items" => { "type" => "integer" } } }),
        :records => ->(model) { Occurrences.all(model).map(&:entry) },
        :validate => ->(record) { RECORD_KIND.problems(record) }, :references => RECORD_KIND.references
      )
    end
  end
end
