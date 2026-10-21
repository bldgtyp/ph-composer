# frozen_string_literal: true

require "json"

module PhComposer
  module AgentAccess
    # What the Agent Access dialog shows a user to paste into each supported client, generated from the
    # port and the token just issued. Pure text: nothing here reads or writes a client's configuration.
    # The forms are the ones checked against Claude Code 2.1.300 and Codex 0.163.0
    # (context/AGENT_INTERFACE.md, "User-controlled local access"); a flag a later client renames is a
    # golden-test failure, not a silent edit.
    module ClientConfig
      SERVER_NAME = "ph-composer"
      TOKEN_VARIABLE = "PH_COMPOSER_TOKEN"

      module_function

      def url(port)
        "http://127.0.0.1:#{port}/mcp"
      end

      # One entry per client: its name, the setup forms (each a title and the text to paste), and the
      # commands that check and remove the entry.
      def for(port:, token:)
        [claude_code(port, token), codex(port, token)]
      end

      # Each client leads with the form that keeps the token out of the client's settings and ends with the
      # one that writes it there; each title says where the token is kept.
      # The environment-variable form expands `${PH_COMPOSER_TOKEN}` when Claude Code connects, so the
      # token stays out of ~/.claude.json (checked against 2.1.300: connected with the variable set, failed
      # without it).
      def claude_code(port, token)
        server = JSON.generate("type" => "http", "url" => url(port),
                               "headers" => { "Authorization" => "Bearer ${#{TOKEN_VARIABLE}}" })
        { "client" => "Claude Code",
          "forms" => [
            { "title" => "Run in a terminal. This keeps the token out of Claude Code's settings; it reads the " \
                         "variable set next.",
              "text" => "claude mcp add-json --scope user #{SERVER_NAME} '#{server}'" },
            export_form(token),
            { "title" => "Or, one command, with the token kept in Claude Code's settings file and your " \
                         "shell history.",
              "text" => "claude mcp add --transport http --scope user #{SERVER_NAME} #{url(port)} " \
                        "--header \"Authorization: Bearer #{token}\"" }
          ],
          "check" => "claude mcp get #{SERVER_NAME}",
          "remove" => "claude mcp remove --scope user #{SERVER_NAME}" }
      end

      # The variable both clients' environment forms read, set where the client will start. A shell profile
      # would set it in every later terminal, at the cost of keeping the token in that file; the shell's
      # history keeps the line either way.
      def export_form(token)
        { "title" => "Then set the variable in the terminal you start the client from. Your shell history " \
                     "keeps the token, and so does your shell profile if you add the line there.",
          "text" => "export #{TOKEN_VARIABLE}=#{token}" }
      end

      # Pasted into the file by hand: `codex mcp add` and `codex mcp remove` rewrite the whole of
      # ~/.codex/config.toml, dropping its comments and reordering its tables (observed on 0.163.0).
      def codex(port, token)
        block = "[mcp_servers.#{SERVER_NAME}]\nurl = \"#{url(port)}\"\n"
        { "client" => "Codex",
          "forms" => [
            { "title" => "Add to ~/.codex/config.toml. This names the variable, not the token.",
              "text" => "#{block}bearer_token_env_var = \"#{TOKEN_VARIABLE}\"" },
            export_form(token),
            { "title" => "Or this block instead of both, with the token kept in ~/.codex/config.toml.",
              "text" => "#{block}http_headers = { Authorization = \"Bearer #{token}\" }" }
          ],
          "check" => "codex mcp get #{SERVER_NAME}",
          "remove" => "Delete the [mcp_servers.#{SERVER_NAME}] block from ~/.codex/config.toml" }
      end
    end
  end
end
