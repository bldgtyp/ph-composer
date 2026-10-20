# frozen_string_literal: true

require "digest"

module PhComposer
  module ColourBy
    # The colours the shared service owns: the two states every mode has, and the two helpers a mode
    # builds its colour function from. A mode's own hues belong to the feature that declares it, so
    # nothing here names a face type, a boundary condition or a Zone.
    module Palette
      # A value the mode does not colour: the entity carries a record but not enough of one to paint.
      INCOMPLETE = [255, 176, 0].freeze
      # No record at all. Drawn as a hatch and solid boundary rather than a fill.
      UNCLASSIFIED = [130, 130, 130].freeze
      # Isolation washes out the underlying geometry, without the outlines a mode colour carries.
      # It is a separate rendering pass, never a substitute colour in a mode's palette.
      ISOLATION_WASH = [255, 255, 255].freeze
      ISOLATION_WASH_ALPHA = 205
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

      # A colour function over the categorical ramp, stable for a given value. Values are coloured one at a
      # time, so two can share a hue; a projection that sees every value uses `spread` instead.
      def ramp
        ->(value) { value.nil? ? nil : RAMP[slot(value)] }
      end

      # A ramp colour for each of `values`, distinct up to the ramp's length, for an entry's own `colour`.
      # Each value prefers the slot `ramp` gives it; when two prefer one slot, the later in sorted order
      # takes the next free one. A value usually keeps its colour as others come and go; one that arrives
      # or leaves can move a value it clashes with, directly or along a run of occupied slots.
      def spread(values)
        taken = {}
        values.compact.uniq.sort_by(&:to_s).each_with_object({}) do |value, colours|
          index = slot(value)
          index = (index + 1) % RAMP.length while taken.key?(index) && taken.length < RAMP.length
          taken[index] = true
          colours[value] = RAMP[index]
        end.freeze
      end

      # A byte sum collides for ids that differ only in order; a digest spreads them.
      def slot(value)
        Digest::SHA256.digest(value.to_s).unpack1("N") % RAMP.length
      end
      private_class_method :slot
    end
  end
end
