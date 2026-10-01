# frozen_string_literal: true

module PhComposer
  module Windows
    module InstallsRegistration
      PSI_KIND = Products::KINDS.fetch("psi_install_types")
      CREATE = Shapes.object({ "client_id" => Shapes::ID, "values" => Shapes.create_values(PSI_KIND),
                "user_data" => Shapes::OBJECT }, :optional => ["user_data"])
      UPDATE = Shapes.update(PSI_KIND)
      EDGE = Shapes.object({ "element_id" => Shapes::ID, "sides" => Types::SIDE_SCHEMA })
      TYPE = Shapes.object({ "id" => Shapes::ID, "expected_values" => Types::KIND.descriptor.patch_schema,
                "installs" => Shapes.list(EDGE) })
      PARAMS = Shapes.object({ "types" => Shapes.list(TYPE),
                "psi_install_types" => Shapes.object({
          "create" => Shapes.list(CREATE), "update" => Shapes.list(UPDATE) }),
                "expected_settings" => Settings::VALUES })
      RESULT = Shapes.object({ "type_ids" => Shapes.list(Shapes::ID),
                "psi_install_type_ids" => { "type" => "object", "additionalProperties" => Shapes::ID } })

      module_function

      def install(feature)
        feature.action("#{FEATURE_ID}.types.installs.save",
          :description => "Save the complete staged Installs session.",
          :params => PARAMS, :result => RESULT, :undo_name => "Edit Window Installations",
          :side_effects => "Creates or edits installation products and updates type edges atomically.",
          :examples => [{ "types" => [], "psi_install_types" => { "create" => [], "update" => [] },
          "expected_settings" => Settings::DEFAULTS }]) do |request, proposal|
          InstallSave.call(request, proposal)
        end
      end
    end
  end
end
