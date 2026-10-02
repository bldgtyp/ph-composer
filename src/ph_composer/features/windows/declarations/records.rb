# frozen_string_literal: true

require_relative "../units/type_retargeter"

module PhComposer
  module Windows
    module RecordRegistration
      module_function

      def install(feature)
        (Products::KINDS.keys + ["types"]).each { |collection| declare(feature, collection) }
        Units::TypeRetargeter.install(feature)
      end

      def declare(feature, collection)
        kind = Operations.kind(collection)
        prefix = "#{FEATURE_ID}.#{collection}"
        example_id = "#{kind.id_prefix}_Ab12Cd34Ef56"
        feature.action("#{prefix}.create", :description => "Create one #{kind.label} with local defaults.",
          :params => Shapes.create(kind), :result => Shapes::RESULT, :undo_name => "Create #{kind.label}",
          :side_effects => "Creates one Model-owned definition.",
          :examples => [{ "values" => { "name" => "Example #{kind.label}" } }]) do |request, proposal|
          Operations.create(request, proposal, collection)
        end
        feature.action("#{prefix}.update", :description => "Edit guarded authored values of one #{kind.label}.",
          :params => Shapes.update(kind), :result => collection == "types" ? Shapes::TYPE_RESULT : Shapes::RESULT,
          :undo_name => "Edit #{kind.label}",
          :side_effects => "Updates one definition and preserves its metadata.",
          :examples => [{ "id" => example_id, "values" => { "name" => "Edited" },
          "expected_values" => { "name" => "Original" } }]) do |request, proposal|
          Operations.update(request, proposal, collection)
        end
        feature.action("#{prefix}.duplicate", :description => "Duplicate a #{kind.label} with independent identity.",
          :params => Shapes.object({ "id" => Shapes::ID, "name" => { "type" => "string", "minLength" => 1 },
          "copy_datasheets" => { "type" => "boolean" } },
            :optional => %w[name copy_datasheets]),
          :result => Shapes::RESULT, :undo_name => "Duplicate #{kind.label}",
          :side_effects => "Copies definition metadata and retains shared products; new elements get fresh ids.",
          :examples => [{ "id" => example_id }]) { |request, proposal| Operations.duplicate(request, proposal,
            collection) }
        replacement = collection == "types" ? { "type" => %w[string null] } : Shapes::ID
        feature.action("#{prefix}.delete", :description => "Delete #{kind.label}; live references require replacement.",
          :params => Shapes.object({ "id" => Shapes::ID, "expected_values" => kind.descriptor.patch_schema,
          "replacement_id" => replacement },
            :optional => %w[expected_values replacement_id]),
          :result => Shapes::RESULT, :undo_name => "Delete #{kind.label}",
          :side_effects => "Rewrites referring definitions and defaults, then deletes atomically.",
          :examples => [{ "id" => example_id }]) { |request, proposal| Operations.delete(request, proposal,
            collection) }
      end
    end
  end
end
