# frozen_string_literal: true

module PhComposer
  module Export
    # The export task methods' public descriptions (PhComposer::API start_export and its siblings). A
    # file export is not a Model mutation, so these are not registered actions: they are shell-owned
    # task methods with their own grant. `API.describe(name:)` answers each from here, so a client can
    # call them from their declarations alone. Each params key is the method's keyword argument.
    module TaskContract
      TASK_ID = { "type" => "string", "description" => "task_id from start_export." }.freeze
      OUTCOME = {
        "type" => %w[object null],
        "description" => "Null until the task ends; then the outcome shape every call answers with.",
        "required" => %w[status code message effect],
        "properties" => {
          "status" => { "type" => "string", "enum" => %w[completed refused failed cancelled] },
          "code" => { "type" => "string", "description" => "export.complete, export.blocked, export.cancelled " \
                                                           "and so on." },
          "message" => { "type" => "string" }, "effect" => { "type" => "string" },
          "revision" => { "type" => %w[integer null] },
          "value" => { "type" => %w[object null],
                       "description" => "When completed: the compact result and the two artifact paths written." },
          "affected" => { "type" => "array" }, "findings" => { "type" => "array" },
          "detail" => { "type" => %w[object null] }, "proposal_digest" => { "type" => %w[string null] }
        }
      }.freeze
      STATUS = {
        "type" => "object", "additionalProperties" => false,
        "required" => %w[task_id stage count cancellable outcome],
        "description" => "One task's progress. Never carries the canonical HBJSON bytes.",
        "properties" => {
          "task_id" => { "type" => "string" },
          "stage" => { "type" => "string", "enum" => %w[queued reading translating checking writing finished] },
          "count" => { "type" => "integer", "minimum" => 0, "description" => "Entities read so far." },
          "cancellable" => { "type" => "boolean", "description" => "False once writing starts or the task ended." },
          "outcome" => OUTCOME
        }
      }.freeze
      NO_PARAMS = { "type" => "object", "additionalProperties" => false, "properties" => {} }.freeze
      TASK_PARAMS = { "type" => "object", "additionalProperties" => false, "required" => ["task_id"],
                      "properties" => { "task_id" => TASK_ID } }.freeze
      EXAMPLE_TASK = { "task_id" => "export_0123456789abcdef01234567" }.freeze

      TASKS = {
        "export_preflight" => {
          "capability" => "read", "params" => NO_PARAMS, "result" => PREFLIGHT_RESULT, "examples" => [{}],
          "description" => "Every export contributor's findings and the repairs it offers, before starting."
        },
        "start_export" => {
          "capability" => "export",
          "description" => "Start one export of the canonical HBJSON and its report to an explicit destination. " \
                           "An existing pair is replaced only with replace true; one task runs per Model at a time.",
          "params" => {
            "type" => "object", "additionalProperties" => false, "required" => ["destination"],
            "properties" => {
              "destination" => { "type" => "string", "minLength" => 1,
                                 "description" => "The .hbjson path; the report is written beside it." },
              "replace" => { "type" => "boolean", "description" => "Consent to replace an existing pair." }
            }
          },
          "result" => STATUS, "examples" => [{ "destination" => "/path/to/model.hbjson", "replace" => false }]
        },
        "export_status" => {
          "capability" => "export", "params" => TASK_PARAMS, "result" => STATUS, "examples" => [EXAMPLE_TASK],
          "description" => "Poll one task. An expired or other-Model handle refuses task.expired."
        },
        "cancel_export" => {
          "capability" => "export", "params" => TASK_PARAMS, "result" => STATUS, "examples" => [EXAMPLE_TASK],
          "description" => "Cancel a task before it starts writing; nothing is written."
        },
        "latest_export" => {
          "capability" => "export", "params" => NO_PARAMS, "result" => STATUS.merge("type" => %w[object null]),
          "examples" => [{}], "description" => "The most recent task still retained, or null."
        }
      }.freeze

      module_function

      def describe(name)
        task = TASKS[name]
        task && DeepCopy.call({ "kind" => "task", "name" => name, "owner" => "ph_composer.export" }.merge(task))
      end
    end
  end
end
