# frozen_string_literal: true

module PhComposer
  module Assemblies
    # The Material wire contract contains semantic authored values only. Mapping admits this
    # allowlist, never source, identity or arbitrary metadata. The coordinator owns attribution and
    # copies only these wire fields (apart from wire id) into its sanitized source snapshot.
    module MaterialsLibrary
      NAME = "#{FEATURE_ID}.library_materials"
      FIELDS = Commands::MATERIAL_EDITABLE
      NUMBERS = %w[conductivity_w_mk density_kg_m3 specific_heat_j_kgk emissivity].freeze
      module_function

      def map(row)
        values = Materials::Schema.defaults(row.slice(*FIELDS)).slice(*FIELDS)
        category = values.fetch("category")
        values["category"] = Materials::Schema::CATEGORIES.key?(category) ? category : ""
        values["color"] = values.fetch("color").downcase
        NUMBERS.each { |key| values[key] = values[key].nil? ? nil : values[key].to_f }
        unless SchemaFields.problems(values).empty?
          raise CodedError.new("library.row_semantic_invalid", "The library row violates the Material value contract.")
        end
        values
      end

      def reverse(record)
        map(record).merge("id" => record.fetch("id"))
      end

      def fingerprint(values)
        normalized = map(values)
        CanonicalJson.digest(FIELDS.map { |field| [field, normalized.fetch(field)] })
      end

      def schema
        Materials::Schema::KIND.values_schema.tap do |shape|
          shape["properties"] = shape.fetch("properties").slice(*FIELDS)
          shape["required"] = FIELDS
        end
      end

      def wire_schema
        shape = schema
        shape["properties"]["category"] = { "type" => "string" }
        shape["properties"]["id"] = { "type" => "string", "minLength" => 1 }
        shape["required"] = %w[id name]
        shape
      end

      def callback(params, result, &handler)
        Declarations::LibraryCallback.new(:params => params, :result => result, :handler => handler)
      end

      def local_read
        expected = Materials::Schema::KIND.descriptor.patch_schema
        expected["properties"] = expected.fetch("properties").slice(*FIELDS)
        row = Shapes.object({ "id" => Shapes::TEXT, "mapped" => schema, "expected_values" => expected,
                              "source" => Materials::Schema::KIND.values_schema.fetch("properties").fetch("source") },
                            :optional => ["source"])
        callback(Shapes::NONE, Shapes.list(row)) do |request, _proposal|
          Operations.records(request, MATERIAL_KIND).map do |record|
            projection = { "id" => record.fetch("id"), "mapped" => map(record),
                           "expected_values" => DeepCopy.call(record.slice(*FIELDS)) }
            projection["source"] = DeepCopy.call(record["source"]) if record.key?("source")
            projection
          end
        end
      end

      def replace
        params = Shapes.update(Materials::Schema::KIND, FIELDS)
        params.fetch("properties").delete("user_data")
        params.fetch("properties").fetch("values").fetch("properties")["source"] =
          Materials::Schema::KIND.values_schema.fetch("properties").fetch("source")
        callback(params, Shapes::RESULT) do |request, proposal|
          id = request.params.fetch("id")
          record = request.engine.find(MATERIAL_KIND, id)
          values = request.params.fetch("values")
          if values["name"]
            Commands.unique_name!(values["name"], Operations.records(request, MATERIAL_KIND), :except => id)
          end
          result = Commands.update_material(record, :values => values.reject { |key, _value| key == "source" })
          changes = Operations.changed_values(Materials::Schema::KIND, record, result.record)
          changes["source"] = DeepCopy.call(values["source"]) if values.key?("source")
          request.engine.propose_update(MATERIAL_KIND, id, proposal, :values => changes,
                                        :expected_values => request.params.fetch("expected_values"))
          { "id" => id }
        end
      end

      def install(feature, registry)
        assignment = registry.declared_actions.find do |action|
          action.name == "#{FEATURE_ID}.assemblies.segments.set_material"
        end
        adapter = Declarations::LibraryAdapter.new(:wire_kind => "materials", :wire_version => 1,
          :fingerprint_version => 1, :wire_schema => wire_schema, :mapped_schema => schema,
          :fingerprint_fields => FIELDS, :map => method(:map), :reverse => method(:reverse),
          :fingerprint => method(:fingerprint), :local_read => local_read,
          :create => callback(Shapes.create(Materials::Schema::KIND), Shapes::RESULT) do |request, proposal|
            Operations.create(request, proposal, MATERIAL_KIND)
          end, :replace => replace,
          :assign => assign(assignment))
        feature.library_kind(NAME, :contract_version => 1, :record_kind => MATERIAL_KIND, :adapter => adapter)
      end

      # The coordinator names only a local identity and an opaque assignment target. Translating
      # that identity into this feature's action field stays with the owner of the assignment.
      def assign(action)
        target = DeepCopy.call(action.params)
        target.fetch("properties").delete("material_id")
        target.fetch("required").delete("material_id")
        params = Shapes.object({ "target" => target, "local_id" => Shapes::TEXT })
        callback(params, action.result) do |request, proposal|
          nested = request.dup
          nested.params = DeepCopy.call(request.params.fetch("target")).merge(
            "material_id" => request.params.fetch("local_id")
          )
          action.handler.call(nested, proposal)
        end
      end
    end
  end
end
