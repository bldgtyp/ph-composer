# frozen_string_literal: true

module PhComposer
  module Zones
    module Options
      # Full occurrence inventory, including stamps hidden from Restore by a live copied Zone id.
      module Inventory
        module_function

        def rows(model)
          walk(model.entities, [], false, false, [])
        end

        def walk(entities, path, shared, locked, found)
          entities.each do |entity|
            current = path + [entity.persistent_id]
            container = entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
            zone = container && ZONE_STORE.read(entity)
            stamp = STAMP_STORE.read(entity)
            [[ZONE_STORE, zone, true], [STAMP_STORE, stamp, false]].each do |store, record, is_zone|
              next unless record

              valid = is_zone ? Schema.problems(record).empty? : Schema.stamp?(record)
              Options.refuse("record.unreadable", "Zone or membership stamp at #{current} is unreadable") unless valid
              found << { :entity => entity, :path => current, :store => store, :record => record,
                         :zone => is_zone, :shared => shared, :locked => locked || (container && entity.locked?) }
            end
            next unless container

            child_shared = shared || Occurrences.shared_storage?(entity)
            children = entity.is_a?(Sketchup::Group) ? entity.entities : entity.definition.entities
            walk(children, current, child_shared, locked || entity.locked?, found)
          end
          found
        end

        def stamp_entries(model)
          rows(model).reject { |row| row.fetch(:zone) }.map do |row|
            projected = row.fetch(:record).merge("id" => row.fetch(:record).fetch("zone_id"))
            Records::ReferenceEntry.new(:kind => STAMP_KIND, :key => row.fetch(:path), :record => projected)
          end
        end

        def stamp_problems(record)
          return ["Invalid membership stamp projection"] unless record["id"] == record["zone_id"]

          Schema.stamp?(record.reject { |key, _| key == "id" }) ? [] : ["Invalid membership stamp"]
        end

        def usage(model, collection, id)
          field = collection == "building_segment" ? "building_segment_id" : "level_id"
          inventory = rows(model)
          live_ids = inventory.select { |row| row.fetch(:zone) }.map { |row| row.fetch(:record).fetch("id") }
          matching = inventory.select { |row| row.fetch(:record)[field] == id }
          { "live" => matching.count { |row| row.fetch(:zone) },
            "recoverable" => matching.reject { |row| row.fetch(:zone) }
                                     .map { |row| row.fetch(:record).fetch("zone_id") }.uniq.count { |zone_id|
                               !live_ids.include?(zone_id)
                             } }
        end
      end

      class RewriteStep
        def initialize(writes)
          @writes = writes.map do |row, after|
            { :path => row.fetch(:path), :store => row.fetch(:store),
              :before => DeepCopy.call(row.fetch(:record)), :after => DeepCopy.call(after) }
          end
        end

        def descriptor
          { "name" => "rewrite_zone_options", "writes" => @writes.map { |write|
            { "path" => write.fetch(:path), "dictionary" => write.fetch(:store).dictionary,
              "before" => write.fetch(:before), "after" => write.fetch(:after) }
          } }
        end

        def affected
          @writes.map { |write|
            { "kind" => "zone_options", "id" => write.fetch(:after).fetch("id",
                                                                          write[:after]["zone_id"]),
              "change" => "updated" }
          }
        end

        def apply(model, _slots)
          resolved = @writes.map do |write|
            path = write.fetch(:path)
            parent = Occurrences.entities_at(model, path[0...-1])
            entity = Occurrences.unique_entity(parent, path.last)
            unless write.fetch(:store).read(entity) == write.fetch(:before)
              Options.refuse("target.changed", "A Zone or membership stamp changed after preview")
            end
            [write, entity]
          end
          resolved.each { |write, entity| write.fetch(:store).write(entity, write.fetch(:after)) }
        end
      end
    end
  end
end
