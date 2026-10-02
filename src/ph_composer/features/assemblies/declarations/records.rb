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
          Operations.create(request, proposal, kind.id, :values => request.params.fetch("values"),
                                                        :user_data => request.params["user_data"])
        end
        feature.action("#{prefix}.update", :description => "Edit one #{kind.label}; changed expected values refuse.",
                       :params => Shapes.update(kind, editable), :result => Shapes::RESULT,
                       :undo_name => "Edit #{kind.label}", :side_effects => "Updates values and optional metadata.",
                       :examples => [{ "id" => example_id, "values" => { "name" => "Edited" },
                                       "expected_values" => { "name" => "Original" } }]) do |request, proposal|
          params = request.params
          Operations.update(request, proposal, kind.id, :id => params.fetch("id"), :values => params.fetch("values"),
            :expected_values => params.fetch("expected_values"), :user_data => params["user_data"])
        end
        declare_duplicate(feature, prefix, kind, example_id)
        declare_delete(feature, prefix, kind, example_id)
      end

      def declare_duplicate(feature, prefix, kind, example_id)
        properties = { "id" => Shapes.id(kind.id_prefix, "The #{kind.label} to copy.") }
        if kind.id == MATERIAL_KIND
          properties.merge!(
            "name" => { "type" => "string", "minLength" => 1,
                        "description" => "The copy's name; \"<name> (copy)\" when absent. Names are unique." },
            "copy_datasheets" => { "type" => "boolean", "description" => "Keep the datasheet links on the copy; " \
                                                                       "false when absent." }
          )
        end
        feature.action("#{prefix}.duplicate", :description => "Duplicate one #{kind.label} with independent identity.",
                       :params => Shapes.object(properties, :optional => %w[name copy_datasheets]),
                       :result => Shapes::RESULT, :undo_name => "Duplicate #{kind.label}",
                       :side_effects => "Creates one catalog record, preserving shared definition references.",
                       :examples => [{ "id" => example_id }]) do |request, proposal|
          Operations.duplicate(request, proposal, kind.id, :id => request.params.fetch("id"),
            :name => request.params["name"], :copy_datasheets => request.params.fetch("copy_datasheets", false))
        end
      end

      def declare_delete(feature, prefix, kind, example_id)
        properties = { "id" => Shapes.id(kind.id_prefix, "The #{kind.label} to delete."),
                       "expected_values" => Shapes.expected(kind) }
        properties["replacement_id"] = if kind.id == MATERIAL_KIND
                                         Shapes.id("mat", "The Material every Layer-Segment using the deleted one " \
                                                          "takes instead. Needed while any Assembly uses it.")
                                       else
                                         Shapes.id("asm", "The Assembly every Face using the deleted one takes " \
                                                          "instead, or null to clear those Faces' Assembly. " \
                                                          "Needed while any Face uses it.", :nullable => true)
                                       end
        feature.action("#{prefix}.delete", :description => "Delete #{kind.label}; remaining references refuse.",
                       :params => Shapes.object(properties, :optional => %w[expected_values replacement_id]),
                       :result => Shapes::RESULT, :undo_name => "Delete #{kind.label}",
                       :side_effects => "Replacement or explicit clearing rewrites uses and deletes atomically.",
                       :examples => [{ "id" => example_id }]) do |request, proposal|
          params = request.params
          target = { :id => params.fetch("id"), :expected_values => params.fetch("expected_values", {}),
                     :replacement_id => params["replacement_id"] }
          if kind.id == MATERIAL_KIND
            Operations.delete_material(request, proposal, **target)
          else
            Operations.delete_assembly(request, proposal, **target, :retarget => params.key?("replacement_id"))
          end
        end
      end
    end
  end
end
