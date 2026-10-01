# frozen_string_literal: true

module PhComposer
  module Assemblies
    # Record values and patches derive from the kind descriptor. The authoring actions leave
    # identity, references and metadata validation to the same engine available to contributors.
    module RecordRegistration
      module_function

      def install(feature)
        declare(feature, "materials", Materials::Schema::KIND, Commands::MATERIAL_EDITABLE, "mat_Ab12Cd34Ef56")
        declare(feature, "assemblies", Assembly::Schema::KIND, Commands::ASSEMBLY_EDITABLE, Shapes::EXAMPLE_ID)
      end

      def declare(feature, collection, kind, editable, example_id)
        prefix = "#{FEATURE_ID}.#{collection}"
        feature.action("#{prefix}.create", :description => "Create one #{kind.label}, with default authoring values.",
                       :params => Shapes.create(kind), :result => Shapes::RESULT,
                       :undo_name => "Create #{kind.label}", :side_effects => "Creates one catalog record.",
                       :examples => [{ "values" => { "name" => "Example #{kind.label}" } }]) do |request, proposal|
          Operations.create(request, proposal, kind.id)
        end
        feature.action("#{prefix}.update", :description => "Edit one #{kind.label}; changed expected values refuse.",
                       :params => Shapes.update(kind, editable), :result => Shapes::RESULT,
                       :undo_name => "Edit #{kind.label}", :side_effects => "Updates values and optional metadata.",
                       :examples => [{ "id" => example_id, "values" => { "name" => "Edited" },
                                       "expected_values" => { "name" => "Original" } }]) do |request, proposal|
          Operations.update(request, proposal, kind.id)
        end
        declare_duplicate(feature, prefix, kind, example_id)
        declare_delete(feature, prefix, kind, example_id)
      end

      def declare_duplicate(feature, prefix, kind, example_id)
        properties = { "id" => Shapes::ID }
        if kind.id == MATERIAL_KIND
          properties.merge!("name" => { "type" => "string", "minLength" => 1 },
                            "copy_datasheets" => { "type" => "boolean" })
        end
        feature.action("#{prefix}.duplicate", :description => "Duplicate one #{kind.label} with independent identity.",
                       :params => Shapes.object(properties, :optional => %w[name copy_datasheets]),
                       :result => Shapes::RESULT, :undo_name => "Duplicate #{kind.label}",
                       :side_effects => "Creates one catalog record, preserving shared definition references.",
                       :examples => [{ "id" => example_id }]) do |request, proposal|
          Operations.duplicate(request, proposal, kind.id)
        end
      end

      def declare_delete(feature, prefix, kind, example_id)
        properties = { "id" => Shapes::ID, "expected_values" => kind.descriptor.patch_schema }
        properties["replacement_id"] = Shapes::ID if kind.id == MATERIAL_KIND
        feature.action("#{prefix}.delete", :description => "Delete #{kind.label}; remaining references refuse.",
                       :params => Shapes.object(properties, :optional => %w[expected_values replacement_id]),
                       :result => Shapes::RESULT, :undo_name => "Delete #{kind.label}",
                       :side_effects => "Deletes the record; Material replacement rewrites all uses atomically.",
                       :examples => [{ "id" => example_id }]) do |request, proposal|
          if kind.id == MATERIAL_KIND
            Operations.delete_material(request, proposal)
          else
            Operations.delete_assembly(request, proposal)
          end
        end
      end
    end
  end
end
