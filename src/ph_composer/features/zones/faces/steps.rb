# frozen_string_literal: true

module PhComposer
  module Zones
    module Faces
      # Every Face one gesture touches, written in one step so a drag over forty Faces, and the
      # counterparts its retirements drag in, are one Undo entry and one all-or-nothing apply.
      class ClassifyStep
        attr_reader :affected

        def initialize(updates:)
          @updates = updates.map { |update| DeepCopy.call(update).freeze }.freeze
          @affected = @updates.map do |update|
            { "kind" => "face", "id" => update.fetch("after").fetch("id"),
              "change" => update.fetch("change"),
              "reference" => update.fetch("reference").merge("entity_id" => update.fetch("after").fetch("id")) }
          end
        end

        def descriptor
          { "name" => "classify_faces", "updates" => @updates }
        end

        def temporary_ids
          @updates.reject { |update| update.fetch("before") }.map { |update| update.fetch("after").fetch("id") }
        end

        # Resolve and check every target before writing any of them: a Face that moved since the
        # preview must abort the gesture, not leave the first half of it painted.
        #
        # That split is also what makes one index safe here. The resolution loop runs before the
        # first write, so the Model does not change underneath it, and the write loop uses the
        # occurrences it already holds rather than resolving again. A step that mutates as it goes,
        # as the adjacency cut does, must not be given one.
        def apply(model, _slots)
          index = Zones::Index.new(model)
          resolved = @updates.map do |update|
            reference = update.fetch("reference")
            occurrence = Zones::Occurrences.resolve_face(model, reference, :mutable => true,
                                                                :allow_unassigned => true, :index => index)
            current = FACE_STORE.read(occurrence.entity)
            unless current == update.fetch("before")
              raise CodedError.new("target.changed", "A Face changed after the gesture was previewed.")
            end

            [occurrence, update]
          end
          resolved.each do |occurrence, update|
            FACE_STORE.write(occurrence.entity, update.fetch("after"))
            stamp = update.fetch("stamp")
            Zones::STAMP_STORE.write(occurrence.entity, stamp) if stamp
          end
        end
      end

      class ReverseFaceStep
        attr_reader :affected

        def initialize(reference:)
          @reference = DeepCopy.call(reference).freeze
          @affected = [{ "kind" => "face", "id" => @reference["entity_id"], "change" => "updated",
                         "reference" => @reference }]
        end

        def descriptor
          { "name" => "reverse_face", "reference" => @reference }
        end

        def apply(model, _slots)
          occurrence = Zones::Occurrences.resolve_face(model, @reference, :mutable => true, :allow_unassigned => true)
          occurrence.entity.reverse!
        end
      end
    end
  end
end
