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
        Names.track(model, group)
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
        current = occurrence.record
        raise CodedError.new("target.changed", "The Zone changed after it was previewed.") unless current == @before

        ZONE_STORE.write(occurrence.entity, @after)
        occurrence.entity.name = @after.fetch("name") if occurrence.entity.respond_to?(:name=)
        Names.track(model, occurrence.entity)
        stamp = Schema.stamp(@after)
        Occurrences.faces(occurrence).each do |face|
          existing = STAMP_STORE.read(face.entity)
          STAMP_STORE.write(face.entity, stamp) if existing && existing["zone_id"] == @after.fetch("id")
        end
      end
    end

    # Gives one copied Zone occurrence an identity of its own. Every write lands inside that
    # occurrence's path, so the Zone it was copied from and that Zone's pairs are left exactly as
    # they were. The copy's own pairs go: a copied adjacency envelope was never a relationship.
    class RepairIdentityStep
      attr_reader :affected

      def initialize(reference:, plan:)
        @reference = DeepCopy.call(reference).freeze
        @old_id = plan.fetch(:old_id)
        @record = DeepCopy.call(plan.fetch(:record)).freeze
        @faces = plan.fetch(:faces).map { |face| DeepCopy.call(face).freeze }.freeze
        @affected = [{ "kind" => "zone", "id" => @record.fetch("id"), "change" => "updated",
                       "reference" => @reference.merge("zone_id" => @record.fetch("id")) }]
        @affected.concat(@faces.filter_map { |face| face_affected(face) })
      end

      def descriptor
        { "name" => "repair_zone_identity", "reference" => @reference, "old_id" => @old_id,
          "record" => @record, "faces" => @faces }
      end

      def temporary_ids
        []
      end

      def apply(model, _slots)
        zone = Repair.occurrence_at(model, @reference.fetch("zone_path"))
        unless zone.record.fetch("id") == @old_id
          raise CodedError.new("target.changed", "The Zone identity changed after the repair was previewed.")
        end

        resolved = @faces.map { |face| [resolve_member(zone, face), face] }
        ZONE_STORE.write(zone.entity, @record)
        resolved.each do |occurrence, face|
          after = face.fetch(:after)
          Faces::FACE_STORE.write(occurrence.entity, after) if after
          STAMP_STORE.write(occurrence.entity, face.fetch(:stamp))
        end
      end

      private

      def face_affected(face)
        after = face.fetch(:after)
        return nil unless after

        { "kind" => "face", "id" => after.fetch("id"), "change" => "updated",
          "reference" => face.fetch(:reference).merge("zone_id" => @record.fetch("id"),
                                                     "entity_id" => after.fetch("id")) }
      end

      def resolve_member(zone, face)
        occurrence = Occurrences.face_at(zone, face.fetch(:reference).fetch("entity_path"), :mutable => true)
        current = Faces::FACE_STORE.read(occurrence.entity)
        unless current == face.fetch(:before)
          raise CodedError.new("target.changed", "A Face changed after the repair was previewed.")
        end

        occurrence
      end
    end
  end
end
