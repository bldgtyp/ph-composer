# frozen_string_literal: true

module PhComposer
  module FaceAssignment
    class ClassifyStep
      attr_reader :affected

      def initialize(reference:, before:, after:, stamp:)
        @reference = DeepCopy.call(reference).freeze
        @before = DeepCopy.call(before)&.freeze
        @after = DeepCopy.call(after).freeze
        @stamp = DeepCopy.call(stamp).freeze
        change = before ? "updated" : "created"
        @affected = [{ "kind" => "face_assignment", "id" => after.fetch("id"), "change" => change,
                       "reference" => @reference.merge("entity_id" => after.fetch("id")) }]
      end

      def descriptor
        { "name" => "classify_face", "reference" => @reference, "before" => @before,
          "after" => @after, "stamp" => @stamp }
      end

      def temporary_ids
        @before ? [] : [@after.fetch("id")]
      end

      def apply(model, _slots)
        occurrence = Zones::Occurrences.resolve_face(model, @reference, :mutable => true, :allow_unassigned => true)
        current = FACE_STORE.read(occurrence.entity)
        raise CodedError.new("target.changed", "The Face changed after it was previewed.") unless current == @before

        FACE_STORE.write(occurrence.entity, @after)
        Zones::STAMP_STORE.write(occurrence.entity, @stamp)
      end
    end
  end
end
