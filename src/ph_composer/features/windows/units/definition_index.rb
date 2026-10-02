# frozen_string_literal: true

module PhComposer
  module Windows
    module Units
      # Derived SKP-owned pointers identify the primary definition. Make Unique copies the type
      # stamp, so the stamp alone cannot distinguish a detached definition. Names are presentation.
      module DefinitionIndex
        STORE = Records::EntityStore.new("ph_composer.window_definitions", :key => "index")
        module_function

        def read(model)
          record = STORE.read(model)
          return {} if record.nil? && model.get_attribute(STORE.dictionary, STORE.key).nil?

          raise CodedError.new("record.unreadable", "The Window definition index is invalid.") unless valid?(record)

          record.fetch("definitions")
        end

        # Whether a stored index record has the one readable shape. Export checks its detached copy
        # with the same rule.
        def valid?(record)
          record.is_a?(Hash) && record.keys.sort == %w[definitions schema_version] &&
            record["schema_version"] == 1 && valid_mapping?(record["definitions"])
        end

        def resolve(model, type_id)
          persistent_id = read(model)[type_id]
          return nil unless persistent_id

          found = matching_definition(model, type_id, persistent_id)
          unless found
            raise CodedError.new("window.definition_missing",
              "The primary Window definition no longer matches its type.")
          end
          found
        end

        # Called only by an owning native proposal step, after its new definitions are created.
        def write(model, definitions, expected:)
          unless read(model) == expected
            raise CodedError.new("target.changed", "The Window definition index changed after preview.")
          end
          unless valid_mapping?(definitions)
            raise CodedError.new("validation.failed",
              "Window definition pointers must be distinct type/persistent-id pairs.")
          end
          definitions.each do |type_id, persistent_id|
            unless matching_definition(model, type_id, persistent_id)
              raise CodedError.new("target.changed",
                "A planned primary Window definition is missing or differently stamped.")
            end
          end
          STORE.write(model, "schema_version" => 1, "definitions" => definitions)
        end

        def valid_mapping?(value)
          value.is_a?(Hash) && value.all? do |type_id, persistent_id|
            type_id.is_a?(String) && Records::Identity.pattern("wnt").match?(type_id) &&
              persistent_id.is_a?(Integer) && persistent_id.positive?
          end && value.values.uniq.length == value.length
        end

        def matching_definition(model, type_id, persistent_id)
          found = model.definitions.to_a.select { |definition| definition.persistent_id == persistent_id }
          return nil unless found.length == 1

          stamp = DEFINITION_STORE.read(found.first)
          stamp.is_a?(Hash) && stamp["window_type_id"] == type_id ? found.first : nil
        end
        private_class_method :valid_mapping?, :matching_definition
      end
    end
  end
end
