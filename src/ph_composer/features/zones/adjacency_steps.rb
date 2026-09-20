# frozen_string_literal: true

module PhComposer
  module Zones
    class FaceRecordStep
      attr_reader :affected

      def initialize(updates:, change:)
        @updates = updates.map do |reference, before, after|
          [DeepCopy.call(reference).freeze, DeepCopy.call(before).freeze, DeepCopy.call(after).freeze]
        end.freeze
        @affected = @updates.map do |reference, _before, after|
          { "kind" => "face_assignment", "id" => after.fetch("id"), "change" => change,
            "reference" => reference }
        end
      end

      def descriptor
        { "name" => "zone_face_records", "updates" => @updates }
      end

      def apply(model, _slots)
        resolved = @updates.map do |reference, before, after|
          occurrence = Occurrences.resolve_face(model, reference, :mutable => true)
          current = FaceAssignment::FACE_STORE.read(occurrence.entity)
          raise CodedError.new("target.changed", "A Face changed after the adjacency preview.") unless current == before

          [occurrence, after]
        end
        resolved.each { |occurrence, after| FaceAssignment::FACE_STORE.write(occurrence.entity, after) }
      end
    end
  end
end
