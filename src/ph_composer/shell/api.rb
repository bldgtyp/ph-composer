# frozen_string_literal: true

module PhComposer
  # The public application interface (CONTRACTS.md C2, context/AGENT_INTERFACE.md). The panel, Ruby
  # scripts and future external adapters all call these methods; none of them needs the panel open.
  #
  #   found = PhComposer::API.discover
  #   context = PhComposer::API.connect(session_id: found["sessions"].first["id"])
  #   page = PhComposer::API.query(context: context, name: "ph_composer.records.list",
  #                                params: { "kind" => "example.foundation.part" })
  #   result = PhComposer::API.invoke(context: context, name: "example.foundation.update_parts",
  #                                   params: { "edits" => [...] },
  #                                   request: { "sequence" => 1, "expected_revision" => page["revision"] })
  #
  # Every call except `discover`, `describe` and `connect` answers with the Outcome shape
  # (shell/outcome.rb). Values cross this boundary as JSON: string keys, SI numbers, record ids,
  # never live SketchUp objects.
  module API
    MAJOR = 1
    MINOR = 0

    module_function

    # Versions, open Model sessions and everything registered, by name. Full schemas come from
    # `describe`, so discovery stays small however many operations are installed. Like `describe`,
    # it answers with a copy: a caller that edits what it was given changes nothing registered.
    def discover
      registry = Registry.current
      DeepCopy.call(
        "api" => { "major" => MAJOR, "minor" => MINOR },
        "extension" => { "id" => EXTENSION_ID, "version" => VERSION },
        "contract_versions" => [Declarations::CONTRACT_VERSION],
        "sessions" => Sessions.all.map { |session| session_summary(session) },
        "features" => registry.features.values.map do |feature|
          { "id" => feature.id, "contract_version" => feature.contract_version, "requires" => feature.requires }
        end,
        "queries" => registry.queries.values.map { |query| summary(query) },
        "view_commands" => registry.view_commands.values.map { |command| summary(command) },
        "actions" => registry.actions.values.map do |action|
          summary(action).merge("side_effects" => action.side_effects)
        end,
        "record_kinds" => registry.record_kinds.values.map do |kind|
          { "id" => kind.id, "owner" => registry.owner_of(kind.id), "label" => kind.label,
            "schema_version" => kind.schema_version }
        end,
        "extensions" => registry.extensions.values.map do |extension|
          { "namespace" => extension.namespace, "owner" => registry.owner_of(extension.namespace),
            "schema_version" => extension.schema_version, "export_relevance" => extension.export_relevance }
        end,
        "snapshot_sections" => registry.snapshot_sections.values.map { |section| section.name }
      )
    end

    # The full declaration of one registered query, action, view command or record kind, or nil when
    # none has the name. The schemas are copies; validation keeps its own.
    def describe(name:)
      registry = Registry.current
      if (operation = registry.queries[name] || registry.actions[name] || registry.view_commands[name])
        return DeepCopy.call(operation_description(operation))
      end

      kind = registry.record_kinds[name]
      kind && DeepCopy.call(
        "kind" => "record_kind", "id" => kind.id, "owner" => registry.owner_of(kind.id), "label" => kind.label,
        "schema_version" => kind.schema_version, "values" => kind.values_schema,
        "references" => kind.references.map do |reference|
          { "key" => reference.key, "target_kind" => reference.target_kind, "cardinality" => reference.cardinality }
        end
      )
    end

    # Issues a caller handle for an open Model session and returns the context to call with. This is
    # the trusted in-process entry; a future external adapter must authenticate before calling it.
    # `view` grants the viewport-state commands: selection, camera and the active Colour-by mode. It is
    # separate from `read` because a read never moves either (context/AGENT_INTERFACE.md), and separate
    # from `model_write` because nothing it does reaches the SKP.
    def connect(session_id:, capabilities: %w[read view model_write])
      session = Sessions.find(session_id)
      raise CodedError.new("session.unknown", "That Model session is closed or was never opened.") unless session

      OperationContext.new(:api_major => MAJOR, :session_id => session.id,
                           :caller => session.callers.issue(capabilities)).freeze
    end

    def query(context:, name:, params: {})
      Dispatch.new.query(context, name, params)
    end

    # Changes what the host shows and never the Model, so it takes no request: see Declarations::ViewCommand.
    def view(context:, name:, params: {})
      Dispatch.new.view(context, name, params)
    end

    def preview(context:, name:, params: {})
      Dispatch.new.preview(context, name, params)
    end

    # `request` is `{"sequence" => n, "expected_revision" => r}`: `n` counts this caller's mutations
    # from 1 and a retry repeats it; `r` is the revision the caller last read.
    def invoke(context:, name:, params:, request:)
      Dispatch.new.invoke(context, name, params, request)
    end

    def outcome(context:, request:)
      Dispatch.new.outcome(context, request)
    end

    def session_summary(session)
      {
        "id" => session.id, "revision" => session.revision, "file_name" => File.basename(session.model.path.to_s),
        "active" => session.model.equal?(Sketchup.active_model), "busy" => !session.busy_reason.nil?
      }
    end

    def summary(operation)
      { "name" => operation.name, "owner" => operation.owner, "description" => operation.description }
    end

    def operation_description(operation)
      {
        "kind" => operation_kind(operation),
        "name" => operation.name, "owner" => operation.owner, "description" => operation.description,
        "params" => operation.params, "result" => operation.result, "examples" => operation.examples
      }.merge(
        operation.is_a?(Declarations::Action) ? { "side_effects" => operation.side_effects,
                                                   "confirmation" => operation.confirmation } : {}
      )
    end

    def operation_kind(operation)
      return "action" if operation.is_a?(Declarations::Action)
      return "view_command" if operation.is_a?(Declarations::ViewCommand)

      "query"
    end
    private_class_method :session_summary, :summary, :operation_description, :operation_kind
  end
end
