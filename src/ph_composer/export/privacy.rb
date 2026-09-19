# frozen_string_literal: true

module PhComposer
  module Export
    # The allowlist between the translator's result document and the report. A schema maps each allowed
    # key to `nil` (a scalar or a list of scalars, never an object), a Hash (a required object), an
    # `Optional` (an object that may be absent or null) or a one-element Array (a list whose rows match
    # the element). A key no schema names refuses the export. The shell owns the fields below, which the
    # translation package's result document always carries (python/ph_composer_translation/result.py);
    # each export contributor declares its own top-level fields at registration, and the allowlist is
    # composed on each check.
    module Privacy
      Optional = Struct.new(:schema)

      module_function

      def fields(names)
        names.to_h { |name| [name.to_s, nil] }
      end

      SHELL = fields(%w[schema_version run_id state]).merge(
        "summary" => fields(%w[objects unavailable findings publishable]),
        "sections" => [fields(%w[id objects unavailable])],
        "findings" => [fields(%w[code section object_id message blocks_export])],
        "failure" => Optional.new(fields(%w[stage code detail]))
      ).freeze

      def schema(registry = Registry.current)
        registry.export_contributors.values.reduce(SHELL) { |composed, contributor| composed.merge(contributor.result) }
      end

      # Raises CodedError `export.privacy_undeclared` for a field no declaration names, or when the
      # document carries a prohibited key or a local path (ArtifactHygiene).
      def validate!(document, registry = Registry.current)
        check(document, schema(registry), "result")
        ArtifactHygiene.validate!(document)
        true
      rescue KeyError => error
        raise CodedError.new("export.privacy_undeclared", "The export result is missing #{error.key}.")
      end

      # Every reason `schema` is not a privacy schema. Empty means it is one.
      def schema_problems(schema, label = "result")
        return ["#{label} must be an object schema"] unless schema.is_a?(Hash)

        schema.flat_map do |key, child|
          path = "#{label}.#{key}"
          next ["#{path}: field names are strings"] unless key.is_a?(String)

          case child
          when nil then []
          when Hash then schema_problems(child, path)
          when Optional then schema_problems(child.schema, path)
          when Array then child.length == 1 ? schema_problems(child.first, path) : ["#{path}: a list names one row"]
          else ["#{path}: #{child.class} is not a schema"]
          end
        end
      end

      def check(value, schema, label)
        refuse("#{label} must be an object.") unless value.is_a?(Hash)
        extras = value.keys.map(&:to_s) - schema.keys
        refuse("#{label} contains undeclared fields: #{extras.sort.join(', ')}.") unless extras.empty?

        schema.each do |key, child|
          path = "#{label}.#{key}"
          case child
          when Hash then check(value.fetch(key), child, path)
          when Optional then check(value[key], child.schema, path) unless value[key].nil?
          when Array then Array(value[key]).each { |row| check(row, child.first, path) }
          when nil then check_scalar(value[key], path)
          end
        end
      end
      private_class_method :check

      # A value slot holds text, a number, a boolean, null or a list of those. An object hidden in one
      # would carry fields no declaration names.
      def check_scalar(value, label)
        nested = value.is_a?(Array) ? value.any? { |item| item.is_a?(Hash) || item.is_a?(Array) } : value.is_a?(Hash)
        refuse("#{label} must be a value, not an object.") if nested
      end
      private_class_method :check_scalar

      def refuse(message)
        raise CodedError.new("export.privacy_undeclared", message)
      end
      private_class_method :refuse
    end
  end
end
