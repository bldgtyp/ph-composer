# frozen_string_literal: true

require "securerandom"
require "digest"

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

      # A stable proposal identity for geometry creation. Preview and invoke at the same revision
      # derive the same id without retaining state; a later revision derives another id.
      def derived(prefix, value)
        "#{prefix}_#{Digest::SHA256.hexdigest(CanonicalJson.generate(value))[0, 12]}"
      end
    end
  end
end
