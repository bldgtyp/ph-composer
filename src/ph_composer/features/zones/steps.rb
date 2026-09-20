# frozen_string_literal: true

module PhComposer
  module Zones
    class MakeZoneStep
      attr_reader :affected

      def initialize(parent_path:, entity_ids:, record:)
        @parent_path = parent_path.freeze
        @entity_ids = entity_ids.freeze
        @record = DeepCopy.call(record).freeze
        @affected = [{ "kind" => "zone", "id" => record.fetch("id"), "change" => "grouped" }]
      end

      def descriptor
        { "name" => "make_zone", "parent_path" => @parent_path, "entity_ids" => @entity_ids, "record" => @record }
      end

      def temporary_ids
        [@record.fetch("id")]
      end

      def apply(model, slots)
        verify_edit_path!(model)
        entities = Operations::EntityScope.new(@parent_path).resolve(model)
        selected = @entity_ids.map { |id| Occurrences.unique_entity(entities, id) }
        group = existing_group(selected) || entities.add_group(selected)
        if group.respond_to?(:locked?) && group.locked?
          raise CodedError.new("target.locked", "The selected Group is locked.")
        end
        raise CodedError.new("target.changed", "The selected Group is already a Zone.") if ZONE_STORE.read(group)

        ZONE_STORE.write(group, @record)
        group.name = @record.fetch("name") if group.respond_to?(:name=)
        reference = { "zone_id" => @record.fetch("id"), "zone_path" => @parent_path + [group.persistent_id] }
        slots[@record.fetch("id")] = reference
        @affected = [{ "kind" => "zone", "id" => @record.fetch("id"), "change" => "grouped",
                       "reference" => reference }]
      end

      private

      def existing_group(selected)
        return selected.first if selected.length == 1 && selected.first.is_a?(Sketchup::Group)
        return nil if selected.all? { |entity| entity.is_a?(Sketchup::Face) || entity.is_a?(Sketchup::Edge) }

        raise CodedError.new("target.wrong_kind", "Make Zone accepts one Group or loose Faces and Edges.")
      end

      def verify_edit_path!(model)
        return if Occurrences.active_path(model) == @parent_path

        raise CodedError.new("target.edit_path_changed", "The active edit path changed before Make Zone.")
      end
    end

    class UpdateZoneStep
      attr_reader :affected

      def initialize(reference:, before:, after:)
        @reference = DeepCopy.call(reference).freeze
        @before = DeepCopy.call(before).freeze
        @after = DeepCopy.call(after).freeze
        @affected = [{ "kind" => "zone", "id" => after.fetch("id"), "change" => "updated",
                       "reference" => @reference }]
      end

      def descriptor
        { "name" => "update_zone", "reference" => @reference, "before" => @before, "after" => @after }
      end

      def apply(model, _slots)
        occurrence = Occurrences.resolve_zone(model, @reference, :mutable => true)
        current = ZONE_STORE.read(occurrence.entity)
        raise CodedError.new("target.changed", "The Zone changed after it was previewed.") unless current == @before

        ZONE_STORE.write(occurrence.entity, @after)
        occurrence.entity.name = @after.fetch("name") if occurrence.entity.respond_to?(:name=)
        stamp = Schema.stamp(@after)
        Occurrences.faces(occurrence).each do |face|
          existing = STAMP_STORE.read(face.entity)
          STAMP_STORE.write(face.entity, stamp) if existing && existing["zone_id"] == @after.fetch("id")
        end
      end
    end
  end
end
