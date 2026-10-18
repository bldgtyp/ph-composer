# frozen_string_literal: true

module PhComposer
  module AgentAccess
    # The tools an agent sees: the public API's verbs, each with a small fixed schema
    # (context/AGENT_INTERFACE.md, "User-controlled local access"). Operation schemas are not copied
    # here; an agent reads them with `describe`, so an outside feature's operations work with no change
    # to this table. This table is the allowlist the Executor runs and `tools/list` shows.
    module Tools
      OPERATION_KINDS = %w[queries view_commands setup_commands file_exports actions].freeze
      INDEX_KEYS = %w[api extension capabilities sessions features schemas].freeze

      module_function

      def string(description)
        { "type" => "string", "minLength" => 1, "description" => description }
      end

      def object(properties, required)
        { "type" => "object", "additionalProperties" => false, "required" => required, "properties" => properties }
      end

      SESSION = string("The Model session id, from discover's sessions.")
      NAME = string("The operation's name, from discover.")
      PARAMS = { "type" => "object", "description" => "The operation's params, as describe's params schema says." }
      READ_ONLY = { "readOnlyHint" => true, "openWorldHint" => false }.freeze

      # Without an owner, a compact index: every operation's name by kind and owner. With one, that
      # owner's full entries. The whole discovery document is larger than one tool result may be.
      def discover(arguments, token)
        document = API.discover
        document = document.merge("sessions" => served(document.fetch("sessions"), token))
        page = if (owner = arguments["owner"])
                 owned(document, owner)
               else
                 document.slice(*INDEX_KEYS).merge("operations" => index(document),
                                                   "next" => "Call discover with an owner for its operations' " \
                                                             "descriptions, then describe one operation by name " \
                                                             "for its params and result.")
               end
        page.merge("connection" => token.slice("id", "label", "capabilities", "model_name"))
      end

      # The sessions a token may act on: a Model-only token sees only its own Model's.
      def served(sessions, token)
        sessions.select { |row| (session = Sessions.find(row["id"])) && Tokens.serves?(token, session) }
      end

      def index(document)
        OPERATION_KINDS.to_h do |kind|
          [kind, document.fetch(kind).group_by { |entry| entry["owner"] }
                         .transform_values { |entries| entries.map { |entry| entry["name"] } }]
        end
      end

      def owned(document, owner)
        unless document.fetch("features").any? { |feature| feature["id"] == owner }
          raise CodedError.new("params.invalid", "There is no feature #{owner[0, 80].inspect}; discover lists them.")
        end

        { "owner" => owner }.merge(OPERATION_KINDS.to_h do |kind|
          [kind, document.fetch(kind).select { |entry| entry["owner"] == owner }]
        end)
      end

      def describe(arguments)
        API.describe(:name => arguments.fetch("name")) ||
          Outcome.refused("request.unknown_operation", "There is no operation named " \
                                                       "#{arguments.fetch('name')[0, 120].inspect}.", :revision => nil)
      end

      def tool(name, description, input_schema, session:, &run)
        Executor::Tool.new(:name => name, :description => description, :capability => "read",
                           :input_schema => input_schema, :session => session, :annotations => READ_ONLY,
                           :run => run).freeze
      end

      TABLE = [
        tool("discover", "Start here. Lists the open Model sessions by file name, the features and every " \
                         "operation's name. Pass owner (a feature id) for that feature's operation descriptions.",
             object({ "owner" => string("A feature id from this tool's features list.") }, []),
             :session => false) { |_context, arguments, token| discover(arguments, token) },
        tool("describe", "The full declaration of one operation: what it does, its params and result schemas, " \
                         "examples and refusals. Read it before calling the operation.",
             object({ "name" => NAME }, ["name"]), :session => false) { |_context, arguments| describe(arguments) },
        tool("query", "Runs a read-only query on one Model session. Nothing in the Model changes.",
             object({ "session" => SESSION, "name" => NAME, "params" => PARAMS }, %w[session name]),
             :session => true) do |context, arguments|
          API.query(:context => context, :name => arguments["name"], :params => arguments.fetch("params", {}))
        end,
        tool("preview", "Shows what an action would change on one Model session without changing anything, with " \
                        "the proposal digest an invoke can carry.",
             object({ "session" => SESSION, "name" => NAME, "params" => PARAMS }, %w[session name]),
             :session => true) do |context, arguments|
          API.preview(:context => context, :name => arguments["name"], :params => arguments.fetch("params", {}))
        end,
        tool("context", "Where one Model session stands: its file name and path, revision, whether it is busy, " \
                        "the edit path from the root and the selection, in pages. Read it before acting on the " \
                        "selection or the open Group.",
             object({ "session" => SESSION, "limit" => { "type" => "integer" },
                      "cursor" => string("next_cursor from the previous page.") }, ["session"]),
             :session => true) do |context, arguments|
          API.query(:context => context, :name => ContextCommands::READ,
                    :params => arguments.slice("limit", "cursor"))
        end,
        tool("export_preflight", "Checks whether one Model session can export now and what would block it, " \
                                 "optionally against an approved destination's id.",
             object({ "session" => SESSION, "location" => string("An approved location id.") }, ["session"]),
             :session => true) do |context, arguments|
          API.export_preflight(:context => context, :location => arguments["location"])
        end
      ].to_h { |entry| [entry.name, entry] }.freeze
    end
  end
end
