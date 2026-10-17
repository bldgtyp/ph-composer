# frozen_string_literal: true

module PhComposer
  # The public application interface (context/CONTRACTS.md, "Public interface";
  # context/AGENT_INTERFACE.md). The panel, Ruby scripts and future external adapters all call these
  # methods; none of them needs the panel open.
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
    # `describe`, so discovery stays small however many operations are installed. `common_refusals`
    # holds the codes every operation of a kind can answer, once (shell/refusals.rb). Like `describe`,
    # it answers with a copy: a caller that edits what it was given changes nothing registered.
    def discover
      registry = Registry.current
      DeepCopy.call(
        "api" => { "major" => MAJOR, "minor" => MINOR },
        "extension" => { "id" => EXTENSION_ID, "version" => VERSION },
        "contract_versions" => [Declarations::CONTRACT_VERSION],
        "capabilities" => CallerRegistry::CAPABILITIES,
        "common_refusals" => Refusals::COMMON,
        "refusal_documentation" =>
          "https://github.com/bldgtyp/ph-composer/blob/main/context/CONTRACTS.md#outcomes-and-codes",
        "tasks" => { "export" => { "preflight" => "export_preflight", "start" => "start_export",
                                   "status" => "export_status", "cancel" => "cancel_export",
                                   "latest" => "latest_export", "retention_limit" => Export::Tasks::LIMIT,
                                   "retention_seconds" => Export::Tasks::RETENTION_SECONDS } },
        "sessions" => Sessions.all.map { |session| session_summary(session) },
        "features" => registry.features.values.map do |feature|
          { "id" => feature.id, "contract_version" => feature.contract_version, "requires" => feature.requires }
        end,
        "queries" => registry.queries.values.map { |query| summary(query) },
        "view_commands" => registry.view_commands.values.map { |command| summary(command) },
        "setup_commands" => registry.setup_commands.values.map { |command| summary(command) },
        "file_exports" => registry.file_exports.values.map { |command| summary(command) },
        "actions" => registry.actions.values.map do |action|
          summary(action).merge("side_effects" => action.side_effects)
        end,
        # Steps an action of a dependent feature composes into its own proposal; no client calls one.
        "participants" => registry.proposal_participants.values.map { |participant| summary(participant) },
        "record_kinds" => registry.record_kinds.values.map do |kind|
          { "id" => kind.id, "owner" => registry.owner_of(kind.id), "label" => kind.label,
            "schema_version" => kind.schema_version }
        end,
        "reference_targets" => registry.reference_targets.values.map do |target|
          { "id" => target.id, "owner" => registry.owner_of(target.id), "label" => target.label }
        end,
        "extensions" => registry.extensions.values.map do |extension|
          { "namespace" => extension.namespace, "owner" => registry.owner_of(extension.namespace),
            "schema_version" => extension.schema_version, "export_relevance" => extension.export_relevance }
        end,
        "snapshot_sections" => registry.snapshot_sections.values.map { |section| section.name }
      )
    end

    # The full declaration of one registered query, action, view command, setup command, file export,
    # record kind or entity kind, or of one export task method, or nil when none has the name. The
    # schemas are copies; validation keeps its own.
    def describe(name:)
      registry = Registry.current
      if (operation = registry.queries[name] || registry.actions[name] || registry.view_commands[name] ||
                      registry.setup_commands[name] || registry.file_exports[name] ||
                      registry.proposal_participants[name])
        return DeepCopy.call(operation_description(registry, operation))
      end

      if (task = Export::TaskContract.describe(name))
        return task
      end

      # A catalog kind and an entity-owned target describe themselves the same way (Records::Descriptor).
      if (target = registry.reference_targets[name])
        return DeepCopy.call({ "kind" => "reference_target", "owner" => registry.owner_of(name) }
                               .merge(target.descriptor.to_h))
      end

      kind = registry.record_kinds[name]
      kind && DeepCopy.call({ "kind" => "record_kind", "owner" => registry.owner_of(name) }.merge(kind.descriptor.to_h))
    end

    # Issues a caller handle for an open Model session and returns the context to call with. This is
    # the trusted in-process entry; a future external adapter must authenticate before calling it.
    # `view` grants the viewport-state commands: selection, camera and the active Colour-by mode. It is
    # separate from `read` because a read never moves either (context/AGENT_INTERFACE.md), and separate
    # from `model_write` because nothing it does reaches the SKP. `setup` grants the session- and
    # machine-state commands, such as adding a library on this machine; like `export`, it is never in
    # the default set and is granted explicitly.
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

    # Changes session or machine state and never the Model: see Declarations::SetupCommand.
    def setup(context:, name:, params: {})
      Dispatch.new.setup(context, name, params)
    end

    def export_file(context:, name:, params: {})
      Dispatch.new.file_export(context, name, params)
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

    # `location` is `{"id" => ..., "replace" => true, "expected_destination" => ...}`: a destination the
    # user approved, never a path (ph_composer.locations.list).
    def start_export(context:, location:)
      Dispatch.new.export_task(context, :start, :location => location)
    end

    # `location`, an approved destination's id, adds what that destination holds to the result.
    def export_preflight(context:, location: nil)
      Dispatch.new.export_preflight(context, location)
    end

    def export_status(context:, task_id:)
      Dispatch.new.export_task(context, :status, :task_id => task_id)
    end

    def cancel_export(context:, task_id:)
      Dispatch.new.export_task(context, :cancel, :task_id => task_id)
    end

    def latest_export(context:)
      Dispatch.new.export_task(context, :latest, {})
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

    # `refuses` is the operation's effective refusal codes, its own and those of the participants it
    # calls; `common_refusal_sets` names the sets of `discover`'s `common_refusals` it answers as well.
    def operation_description(registry, operation)
      {
        "kind" => operation_kind(operation),
        "name" => operation.name, "owner" => operation.owner, "description" => operation.description,
        "params" => operation.params, "result" => operation.result, "examples" => operation.examples,
        "refuses" => Refusals.declared(operation, registry).sort.map { |code| refusal(registry, code) },
        "common_refusal_sets" => Refusals.common_sets(operation)
      }.merge(
        operation.is_a?(Declarations::Action) ? { "side_effects" => operation.side_effects,
                                                  "confirmation" => operation.confirmation,
                                                  "transitions" => Array(operation.transitions) } : {}
      ).merge(operation.respond_to?(:approval) && operation.approval ? { "approval" => operation.approval.to_h } : {})
        .merge(operation.respond_to?(:participants) ? { "participants" => operation.participants } : {})
    end

    # A feature's code carries its owner and description; a foundation code is described in
    # context/CONTRACTS.md, "Outcomes and codes".
    def refusal(registry, code)
      declared = registry.codes[code]
      return { "code" => code, "owner" => "foundation", "description" => nil } unless declared

      { "code" => code, "owner" => declared.owner, "description" => declared.description }
    end

    def operation_kind(operation)
      return "participant" if operation.is_a?(Declarations::ProposalParticipant)

      Declarations::OPERATION_KINDS.fetch(operation.class)
    end
    private_class_method :session_summary, :summary, :operation_description, :refusal, :operation_kind
  end
end
