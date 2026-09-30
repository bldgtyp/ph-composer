# frozen_string_literal: true

require "json"

module PhComposer
  module Export
    # The metadata policy for the canonical HBJSON (R-D2). The translator's bytes are what is written;
    # this reads a parsed copy and never re-serializes. `user_data` may hold only the dotted leaf keys
    # export contributors declare (an empty map, at any level, declares nothing); every other key
    # ArtifactHygiene prohibits, extension envelopes and usernames among them, refuses at any depth;
    # and every string passes the local-path check on its own. A refusal names the JSON path.
    #
    # Its own walk rather than JsonWalk: keys are compared as keys, so a dot or bracket inside one
    # cannot hide it, and a parsed document has no cycle to guard against. Paths are built only for
    # the message, so a large HBJSON costs one pass and no per-node string.
    module HbjsonMetadata
      module_function

      # Raises CodedError `export.privacy_undeclared` naming the first problem.
      def validate!(hbjson, declared_keys)
        visit(JSON.parse(hbjson), declared_keys, [])
        true
      rescue JSON::ParserError
        refuse("The canonical HBJSON is not valid JSON.")
      end

      # `trail` is the keys and indexes from the root, kept as a list and joined only for a message.
      def visit(node, declared_keys, trail)
        case node
        when Hash
          node.each do |key, item|
            name = key.to_s
            if name == "user_data"
              check_user_data!(item, declared_keys, trail + [name])
            elsif prohibited?(name)
              refuse("The canonical HBJSON carries #{name} at #{path(trail + [name])}, which is never exported.")
            end
            visit(item, declared_keys, trail.push(name))
            trail.pop
          end
        when Array
          node.each_with_index do |item, index|
            visit(item, declared_keys, trail.push(index))
            trail.pop
          end
        when String
          if Diagnostics.absolute_path?(node)
            refuse("The canonical HBJSON contains a local file path at #{path(trail)}.")
          end
        end
      end

      def prohibited?(name)
        key = name.downcase
        ArtifactHygiene::PROHIBITED_KEYS.any? do |prohibited|
          key == prohibited || key.start_with?("#{prohibited}.", "#{prohibited}[")
        end
      end

      def check_user_data!(value, declared_keys, trail)
        unless value.is_a?(Hash)
          refuse("The canonical HBJSON carries user_data at #{path(trail)} that is not an object.")
        end

        undeclared = leaf_keys(value) - declared_keys
        return if undeclared.empty?

        refuse("The canonical HBJSON carries undeclared user_data #{undeclared.first} at #{path(trail)}.")
      end

      # "a.b" for {"a" => {"b" => 1}}; a nested map contributes its leaves, and an empty one none.
      def leaf_keys(value, prefix = nil)
        value.flat_map do |key, item|
          name = prefix ? "#{prefix}.#{key}" : key.to_s
          item.is_a?(Hash) ? leaf_keys(item, name) : [name]
        end
      end

      def path(trail)
        trail.reduce("$") { |text, step| step.is_a?(Integer) ? "#{text}[#{step}]" : "#{text}.#{step}" }
      end

      def refuse(message)
        raise CodedError.new("export.privacy_undeclared", message)
      end
      private_class_method :visit, :prohibited?, :check_user_data!, :leaf_keys, :path, :refuse
    end
  end
end
