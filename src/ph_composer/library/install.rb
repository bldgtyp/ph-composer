# frozen_string_literal: true

require_relative "coordinator"
require_relative "setup"
require_relative "schemas"
require_relative "setup_commands"
require_relative "export_registration"
require_relative "copy_participant"

module PhComposer
  module Library
    FEATURE_ID = "ph_composer.library"
    TEXT = { "type" => "string", "minLength" => 1 }.freeze
    OBJECT = { "type" => "object" }.freeze
    GENERATION = { "type" => "integer", "minimum" => 1 }.freeze

    module_function

    def object(properties, optional: [])
      { "type" => "object", "properties" => properties, "additionalProperties" => false,
        "required" => properties.keys - optional }
    end

    def selected_params
      object({ "provider_id" => TEXT, "kind" => TEXT, "generation" => GENERATION }, :optional => ["generation"])
    end

    def page_params
      properties = selected_params.fetch("properties").merge("limit" => Pages::LIMIT, "cursor" => Pages::CURSOR)
      object(properties, :optional => %w[generation limit cursor])
    end

    def copy_params
      properties = selected_params.fetch("properties").merge(
        "library_id" => TEXT, "record_id" => TEXT,
        "choice" => { "type" => "string", "enum" => %w[create keep_local use_library] },
        "local_id" => TEXT, "expected_values" => OBJECT, "assignment" => OBJECT
      )
      object(properties, :optional => %w[local_id expected_values assignment])
    end

    def install(registry)
      feature = registry.feature(FEATURE_ID, :contract_version => 1)
      feature.library_provider(FileProvider::PROVIDER_KIND, :contract_version => 1, :kinds => ["*"]) do
        current = Registry.current
        kinds = current.library_kinds.values.map { |row| row.adapter.wire_kind }
        adapters = ->(kind) { current.library_kinds.values.find { |row| row.adapter.wire_kind == kind }&.adapter }
        Setup.file_providers(:kinds => kinds, :adapters => adapters)
      end
      feature.query("#{FEATURE_ID}.providers", :description => "Configured libraries without transport addresses.",
                    :params => object({}), :result => Schemas.providers,
                    :examples => [{}]) do |r|
        State.for(r.session).metadata(r.registry)
      end
      install_commands(feature)
      feature.snapshot_section("#{FEATURE_ID}.provider_catalogs", :query => "#{FEATURE_ID}.providers")
      feature.query("#{FEATURE_ID}.catalog", :description => "A bounded page of one immutable library catalog.",
                    :params => page_params, :result => Schemas.page,
                    :examples => [{ "provider_id" => "example", "kind" => "example_parts", "limit" => 100 }]) do |r|
        catalog_page(r, "#{FEATURE_ID}.catalog")
      end
      feature.query("#{FEATURE_ID}.in_file", :description => "Resolve catalog rows against local definitions.",
                    :params => page_params, :result => Schemas.page(:resolved => true),
                    :examples => [{ "provider_id" => "example", "kind" => "example_parts", "limit" => 100 }]) do |r|
        in_file(r)
      end
      feature.setup_command("#{FEATURE_ID}.load", :description => "Read a configured library into session memory.",
        :params => object(selected_params.fetch("properties").slice("provider_id", "kind")),
        :result => Schemas.summary,
        :examples => [{ "provider_id" => "example", "kind" => "example_parts" }]) do |r|
        State.for(r.session).refresh(r.params.fetch("provider_id"), r.params.fetch("kind"), r.registry)
             .reject { |key, _value| key == "rows" }
      end
      feature.action("#{FEATURE_ID}.copy", :description => "Copy or reuse one library record with optional assignment.",
        :params => copy_params, :result => Schemas.copy_result, :undo_name => "Copy Library Record",
        :side_effects => "Copies or replaces local definitions and optional assignments in one Undo step.",
        :examples => [{ "provider_id" => "example", "kind" => "example_parts", "generation" => 1,
                       "library_id" => "synthetic", "record_id" => "one", "choice" => "create" }]) do |r, proposal|
        Coordinator.copy(r, proposal)
      end
    end

    def install_commands(feature)
      feature.proposal_participant("#{FEATURE_ID}.copy_into_proposal", &CopyParticipant.method(:call))
      SetupCommands.install(feature)
      ExportRegistration.install(feature)
    end
    private_class_method :install_commands

    # A catalog generation is immutable, so a row's position in it is a stable page key. The cursor
    # is bound to the generation, and, for `in_file`, whose resolution reads local definitions, to
    # the Model revision as well.
    def catalog_page(request, query, revision: nil)
      p = request.params
      entry = State.for(request.session).fetch(p.fetch("provider_id"), p.fetch("kind"), request.registry,
                                                :generation => p["generation"])
      rows = entry.fetch("rows").each_with_index.to_a
      page, next_cursor = Pages.slice(request, query, rows, :key => ->((_row, index)) { [index] },
                                                            :revision => [entry.fetch("generation"), revision])
      entry.merge("rows" => page.map(&:first), "total" => rows.length, "next_cursor" => next_cursor)
    end

    def in_file(request)
      page = catalog_page(request, "#{FEATURE_ID}.in_file", :revision => request.revision)
      declaration = State.kind(request.params.fetch("kind"), request.registry)
      locals = CallbackInvoker.call(request, declaration, declaration.adapter.local_read, {}, :readonly => true)
      provider = State.for(request.session).provider(request.params.fetch("provider_id"), request.registry)
      rows = page.fetch("rows").map do |row|
        mapped = declaration.adapter.map.call(DeepCopy.call(row.fetch("snapshot")))
        valid = JsonValue.problems(mapped).empty? &&
                JsonSchema.validate(mapped, declaration.adapter.mapped_schema).empty?
        unless valid
          raise Error.new("library.adapter_invalid", "The kind adapter returned invalid mapped values.")
        end
        source = { "provider_kind" => provider.provider_kind, "library_id" => row.fetch("library_id"),
                   "record_kind" => request.params.fetch("kind"), "record_id" => row.fetch("record_id") }
        row.merge("resolution" => Coordinator.resolve(declaration.adapter, source, mapped, locals))
      end
      page.merge("rows" => rows)
    end
  end
end
