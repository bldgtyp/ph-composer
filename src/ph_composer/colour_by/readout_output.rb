# frozen_string_literal: true

module PhComposer
  module ColourBy
    # A readout's output, checked where the service builds it, inside the readout's failure boundary,
    # rather than inside `draw`: anchors at finite points, and every part plain text or a quantity the
    # units module knows (core/units.rb) with a finite value. Pure.
    module ReadoutOutput
      module_function

      def check!(result)
        raise ArgumentError, "A readout returns a ColourBy::Readout." unless result.is_a?(Readout)

        Array(result.anchors).each do |anchor|
          point = anchor.point
          finite = %i[x y z].all? { |axis| point.respond_to?(axis) && point.public_send(axis).to_f.finite? }
          raise ArgumentError, "A readout anchor needs a finite point." unless finite

          check_parts!(anchor.parts)
        end
        Array(result.hud).each { |parts| check_parts!(parts) }
        result
      end

      def check_parts!(parts)
        Array(parts).each do |part|
          next if part.is_a?(String)

          quantity, value = part
          valid = part.is_a?(Array) && part.length == 2 && Units::DEFINITIONS.key?(quantity.to_s) &&
                  value.is_a?(Numeric) && value.to_f.finite?
          raise ArgumentError, "A readout part is text or a known quantity with a finite value." unless valid
        end
      end
      private_class_method :check_parts!
    end
  end
end
