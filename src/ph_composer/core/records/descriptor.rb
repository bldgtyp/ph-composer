# frozen_string_literal: true

module PhComposer
  module Records
    # What one record kind is, whoever stores it: its values schema, its identity field, how one
    # occurrence of it is named, and which of its fields name other records. A catalog kind
    # (record_kind.rb) and an entity-owned reference target (reference_target.rb) each publish one,
    # so discovery, validation and the incoming-reference scan read one shape for both. Describing
    # a kind grants no authority to create or delete what stores it.
    class Descriptor
      IDENTITY_FIELD = "id"
      ANY_OBJECT = { "type" => "object" }.freeze

      attr_reader :kind, :label, :schema_version, :values_schema, :occurrence_schema, :references

      # `references` are Records::Reference fields at the top level of a record. `occurrence_schema`
      # is nil for a catalog kind, whose records are named by id alone.
      def initialize(kind:, label:, schema_version: nil, values_schema: ANY_OBJECT, occurrence_schema: nil,
                     references: [])
        @kind = kind
        @label = label
        @schema_version = schema_version
        @values_schema = values_schema
        @occurrence_schema = occurrence_schema
        @references = references.freeze
      end

      # [[target_kind, id], ...] for every core reference `record` holds.
      def referenced_targets(record)
        references.flat_map { |reference| reference.ids(record).map { |id| [reference.target_kind, id] } }
      end

      # The public, plain-JSON form discovery publishes.
      def to_h
        {
          "kind" => kind, "label" => label, "schema_version" => schema_version, "identity_field" => IDENTITY_FIELD,
          "values" => DeepCopy.call(values_schema), "occurrence_reference" => DeepCopy.call(occurrence_schema),
          "references" => references.map do |reference|
            { "key" => reference.key, "target_kind" => reference.target_kind, "cardinality" => reference.cardinality }
          end
        }
      end
    end
  end
end
