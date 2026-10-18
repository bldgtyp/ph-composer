# frozen_string_literal: true

require_relative "pages"

module PhComposer
  # Where a Model session stands, as one read, registered as a foundation capability: which Model it
  # is, its revision and view generation, whether it can take work now, the edit path the user is in,
  # and the selection in pages (context/AGENT_INTERFACE.md, "Model context"). It reads only; it never
  # moves the edit path, the selection or the camera.
  #
  # A selection page is bound to the revision and the view generation it was read at, so a cursor
  # expires when the selection changes even though the Model did not.
  module ContextCommands
    FEATURE_ID = "ph_composer.context"
    READ = "#{FEATURE_ID}.read"
    MAXIMUM_LIMIT = 200
    LIMIT = { "type" => "integer", "minimum" => 1, "maximum" => MAXIMUM_LIMIT,
              "description" => "Selected entities per page, 1 to #{MAXIMUM_LIMIT}; #{Pages::DEFAULT_LIMIT} when " \
                               "absent. A page also stops before its rows pass #{Pages::MAX_PAGE_BYTES} bytes." }.freeze

    extend SchemaShapes

    module_function

    def install(registry)
      feature = registry.feature(FEATURE_ID, :contract_version => Declarations::CONTRACT_VERSION)
      feature.query(READ, :description => "Where this Model session stands: the Model's file name and path, " \
                                          "its revision and view generation, whether it is busy and why, the " \
                                          "edit path from the root, and the selection in pages. Reads only.",
                          :params => object({ "limit" => LIMIT, "cursor" => Pages::CURSOR },
                                            :optional => %w[limit cursor]),
                          :result => result, :refuses => %w[query.cursor_expired query.limit_invalid],
                          :while_busy => true,
                          :examples => [{}, { "limit" => 50 }]) { |request| read(request) }
    end

    def read(request)
      session = request.session
      model = session.model
      rows = model.selection.to_a.map { |entity| entity_row(entity) }.sort_by { |row| row["persistent_id"] }
      # A cursor position is a String or an Array (shell/pages.rb), so the id travels in one.
      page, next_cursor = Pages.bounded(request, READ, rows, :key => ->(row) { [row["persistent_id"]] },
                                                             :revision => [session.revision, session.view_generation])
      { "session" => { "id" => session.id, "file_name" => File.basename(model.path.to_s), "path" => model.path.to_s,
                       "revision" => session.revision, "view_generation" => session.view_generation,
                       "active" => model.equal?(Sketchup.active_model) },
        "readiness" => readiness(session, model),
        "edit_path" => Array(model.active_path).map { |instance| entity_row(instance) },
        "selection" => { "count" => rows.length, "entities" => page, "next_cursor" => next_cursor } }
    end

    # Whether a change could start now: not while another runs or deferred work waits, and the tool the
    # user has active, which some commands also refuse during.
    def readiness(session, model)
      reason = session.busy_reason
      tools = model.respond_to?(:tools) ? model.tools : nil
      { "busy" => !reason.nil?, "reason" => reason,
        "active_tool" => tools.respond_to?(:active_tool_name) ? tools.active_tool_name.to_s : nil }
    end

    # One entity as the context names it: its persistent id, its SketchUp type and its name, if any.
    def entity_row(entity)
      name = entity.respond_to?(:name) ? entity.name.to_s : ""
      definition = entity.respond_to?(:definition) ? entity.definition : nil
      name = definition.name.to_s if name.empty? && definition.respond_to?(:name)
      { "persistent_id" => entity.persistent_id, "type" => entity.typename, "name" => name }
    end

    def entity
      object({ "persistent_id" => { "type" => "integer", "description" => "The entity's persistent id." },
               "type" => { "type" => "string", "description" => "SketchUp's type name, such as Group or Face." },
               "name" => { "type" => "string", "description" => "The instance or definition name; empty if none." } })
    end

    def session_shape
      generation = { "type" => "integer", "description" => "Advances when the selection changes, without a revision." }
      object({ "id" => { "type" => "string" }, "file_name" => { "type" => "string" },
               "path" => { "type" => "string", "description" => "The Model's file path; empty until it is saved." },
               "revision" => { "type" => "integer" }, "view_generation" => generation,
               "active" => { "type" => "boolean" } })
    end

    def readiness_shape
      tool = { "type" => %w[string null], "description" => "The SketchUp tool the user has active." }
      object({ "busy" => { "type" => "boolean" }, "reason" => { "type" => %w[string null] }, "active_tool" => tool })
    end

    def selection_shape
      object({ "count" => { "type" => "integer", "minimum" => 0 },
               "entities" => list(entity, :description => "This page, by persistent id."),
               "next_cursor" => Pages::NEXT_CURSOR })
    end

    def result
      path = list(entity, :description => "The open Groups and Components from the root, outermost first; empty " \
                                          "at the root.")
      object({ "session" => session_shape, "readiness" => readiness_shape, "edit_path" => path,
               "selection" => selection_shape })
    end
  end
end
