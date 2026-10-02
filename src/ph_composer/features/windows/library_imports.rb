# frozen_string_literal: true

module PhComposer
  module Windows
    # Provider rows stay unresolved in the Installs draft. Save resolves their immutable catalog
    # generations through the generic copy participant, retaining provenance and one Undo step.
    module LibraryImports
      module_function

      def copy_schema
        text = { "type" => "string", "minLength" => 1 }
        Shapes.object({ "provider_id" => text, "kind" => { "type" => "string", "enum" => ["psi_install_types"] },
          "generation" => { "type" => "integer", "minimum" => 1 }, "library_id" => text, "record_id" => text,
          "choice" => { "type" => "string", "enum" => %w[create keep_local use_library] },
          "local_id" => text, "expected_values" => Shapes::OBJECT }, :optional => %w[local_id expected_values])
      end

      def schema
        Shapes.list(Shapes.object({ "client_id" => Shapes::ID, "copy" => copy_schema }))
      end

      def resolve(request, proposal, imports, creates)
        rows = imports + creates
        InstallSave.duplicate_targets!(rows, "client_id")
        known = request.engine.ids(PSI_INSTALL_KIND)
        imports.to_h do |row|
          if known.include?(row.fetch("client_id"))
            raise CodedError.new("params.invalid", "A temporary identity collides with a saved product.")
          end
          result = request.participant("ph_composer.library.copy_into_proposal").call(
            request, proposal, row.fetch("copy"))
          id = result.fetch("local_id")
          raise CodedError.new("library.local_choice_required", "Choose a product for each staged import.") unless id
          [row.fetch("client_id"), id]
        end
      end
    end
  end
end
