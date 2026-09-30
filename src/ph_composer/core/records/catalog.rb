# frozen_string_literal: true

module PhComposer
  module Records
    # The record kinds and extensions installed in this process. The registry publishes into it
    # (shell/registry.rb); the engine reads it and never looks up a kind any other way.
    class Catalog
      def initialize(kinds: [], extensions: [], reference_targets: [])
        @kinds = kinds.to_h { |kind| [kind.id, kind] }
        @reference_targets = reference_targets.to_h { |target| [target.id, target] }
        @extensions = extensions.to_h { |extension| [extension.namespace, extension] }
      end

      def kinds
        @kinds.values
      end

      def reference_targets
        @reference_targets.values
      end

      def reference_target(id)
        @reference_targets[id]
      end

      def extensions
        @extensions.values
      end

      def kind(id)
        @kinds.fetch(id) { raise CodedError.new("params.invalid", "There is no record kind #{id.inspect}.") }
      end

      # The descriptor of a catalog kind or a registered entity target, or nil.
      def descriptor(id)
        return @kinds[id].descriptor if @kinds.key?(id)

        @reference_targets[id]&.descriptor
      end

      def kind?(id)
        @kinds.key?(id)
      end

      # The installed extension for a namespace, or nil when none is installed.
      def extension(namespace)
        @extensions[namespace]
      end
    end
  end
end
