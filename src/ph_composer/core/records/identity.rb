# frozen_string_literal: true

require "securerandom"

module PhComposer
  module Records
    # Record ids are a kind prefix, an underscore and twelve alphanumerics: `exp_Ab12Cd34Ef56`. An id
    # is durable: it survives edits, save and reopen, and a duplicate always receives a new one.
    module Identity
      module_function

      def mint(prefix)
        "#{prefix}_#{SecureRandom.alphanumeric(12)}"
      end

      def pattern(prefix)
        /\A#{Regexp.escape(prefix)}_[A-Za-z0-9]{12}\z/
      end

      # A new id not already in `reserved`, which then reserves it.
      def fresh(prefix, reserved)
        loop do
          id = mint(prefix)
          next if reserved.include?(id)

          reserved << id
          return id
        end
      end
    end
  end
end
