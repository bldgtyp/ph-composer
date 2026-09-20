# frozen_string_literal: true

module PhComposer
  module ColourBy
    # The colours the shared service owns: the two states every mode has, and the two helpers a mode
    # builds its colour function from. A mode's own hues belong to the feature that declares it, so
    # nothing here names a face type, a boundary condition or a Zone.
    module Palette
      # A value the mode does not colour: the entity carries a record but not enough of one to paint.
      INCOMPLETE = [255, 176, 0].freeze
      # No record at all. Drawn as a stippled outline rather than a fill, so it reads as absent.
      UNCLASSIFIED = [130, 130, 130].freeze
      # Everything the user set aside while one legend row is shown on its own (PRD Q18). It is the
      # same grey in every mode, because "not the one I am looking at" is not a value any mode owns.
      MUTED = [200, 200, 200].freeze
      FILL_ALPHA = 110
      OUTLINE_ALPHA = 220

      # A categorical ramp for modes whose values are open, such as Zone names. Picking by a stable
      # digest of the value keeps a Zone the same colour as Zones around it come and go.
      RAMP = [
        [31, 119, 180], [255, 127, 14], [44, 160, 44], [214, 39, 40], [148, 103, 189],
        [140, 86, 75], [227, 119, 194], [127, 127, 127], [188, 189, 34], [23, 190, 207]
      ].freeze

      module_function

      # A colour function over a fixed table: the mode's own hues, nil for anything else.
      def fixed(table)
        frozen = table.freeze
        ->(value) { frozen[value] }
      end

      # A colour function over the categorical ramp, stable for a given value.
      def ramp
        ->(value) { value.nil? ? nil : RAMP[value.to_s.sum % RAMP.length] }
      end
    end
  end
end
