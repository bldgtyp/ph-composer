# frozen_string_literal: true

module PhComposer
  module Export
    # What never appears in the export result document, whatever a contributor declares: metadata,
    # extension envelopes, and local file paths. The canonical HBJSON inside it is HbjsonMetadata's,
    # where passed-through user_data is allowed.
    module ArtifactHygiene
      PROHIBITED_KEYS = %w[user_data extension_data path source_path file_path model_path username].freeze

      module_function

      # Raises CodedError `export.privacy_undeclared` naming the first problem.
      def validate!(value)
        JsonWalk.each(value) do |path, node|
          key = path[/\.([^.\[\]]+)\z/, 1]
          if key && PROHIBITED_KEYS.include?(key.downcase)
            raise CodedError.new("export.privacy_undeclared", "Artifact field #{key} is never exported.")
          end
          if node.is_a?(String) && Diagnostics.absolute_path?(node)
            raise CodedError.new("export.privacy_undeclared", "The artifact contains a local file path.")
          end
        end
        true
      end
    end
  end
end
