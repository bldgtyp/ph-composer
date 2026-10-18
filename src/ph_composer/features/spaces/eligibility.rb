# frozen_string_literal: true

module PhComposer
  module Spaces
    # Whether a Face may become a Floor Segment or the floor of a new Volume, as one rule the candidate
    # read and the two actions share: a read that calls a Face eligible is accepted by the action at the
    # same revision, and one it refuses meets the same code there.
    module Eligibility
      MARK = "#{FEATURE_ID}.floors.mark"
      CREATE_VOLUME = "#{FEATURE_ID}.volumes.create"

      module_function

      # Raises the refusal `floors.mark` gives a Face directly inside `volume`.
      def floor!(scan, volume)
        unless scan.volumes.any? { |candidate| candidate.equal?(volume) }
          raise CodedError.new("target.wrong_hierarchy", "Mark floor takes Faces directly inside a Volume that " \
                                                         "is in a Space.")
        end

        Resolve.writable!(volume, scan.volumes + scan.orphan_volumes, "Volume")
      end

      # Raises the refusal `volumes.create` gives a Face loose at `space`'s root.
      def new_volume!(scan, space)
        Resolve.writable!(space, scan.spaces, "Space")
      end

      # The operation a candidate Face is for and the refusal it would meet now, or nil for none.
      def of(scan, face)
        operation = face.volume ? MARK : CREATE_VOLUME
        face.volume ? floor!(scan, face.volume) : new_volume!(scan, face.space)
        [operation, nil]
      rescue CodedError => error
        [operation, { "code" => error.code, "message" => error.message }]
      end
    end
  end
end
