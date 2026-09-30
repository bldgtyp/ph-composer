# frozen_string_literal: true

require "json"

module PhComposer
  module Export
    # The metadata policy for the canonical HBJSON (R-D2). The translator's bytes are what is written;
    # this reads a parsed copy and never re-serializes. `user_data` may hold only the dotted leaf keys
    # export contributors declare (an empty map is nothing to declare); every other key
    # ArtifactHygiene prohibits, extension envelopes and usernames among them, refuses at any depth;
    # and every string passes the local-path check on its own.
    module HbjsonMetadata
      module_function

      # Raises CodedError `export.privacy_undeclared` naming the first problem.
      def validate!(hbjson, declared_keys)
        document = JSON.parse(hbjson)
        JsonWalk.each(document) do |path, node|
          key = path[/\.([^.\[\]]+)\z/, 1]
          if key == "user_data"
            check_user_data!(node, declared_keys)
          elsif key && ArtifactHygiene::PROHIBITED_KEYS.include?(key.downcase)
            refuse("The canonical HBJSON carries #{key}, which is never exported.")
          end
          refuse("The canonical HBJSON contains a local file path.") if node.is_a?(String) &&
                                                                        Diagnostics.absolute_path?(node)
        end
        true
      rescue JSON::ParserError
        refuse("The canonical HBJSON is not valid JSON.")
      end

      def check_user_data!(value, declared_keys)
        refuse("The canonical HBJSON carries user_data that is not an object.") unless value.is_a?(Hash)

        undeclared = leaf_keys(value) - declared_keys
        return if undeclared.empty?

        refuse("The canonical HBJSON carries undeclared user_data #{undeclared.first}.")
      end

      # "a.b" for {"a" => {"b" => 1}}; a nested map contributes its leaves, never itself.
      def leaf_keys(value, prefix = nil)
        value.flat_map do |key, item|
          name = prefix ? "#{prefix}.#{key}" : key.to_s
          item.is_a?(Hash) && !item.empty? ? leaf_keys(item, name) : [name]
        end
      end

      def refuse(message)
        raise CodedError.new("export.privacy_undeclared", message)
      end
      private_class_method :check_user_data!, :leaf_keys, :refuse
    end
  end
end
