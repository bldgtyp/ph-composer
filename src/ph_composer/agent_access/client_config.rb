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

      # The environment-variable form expands `${PH_COMPOSER_TOKEN}` when Claude Code connects, so the
      # token stays out of ~/.claude.json (checked against 2.1.300: connected with the variable set, failed
      # without it).
      def claude_code(port, token)
        server = JSON.generate("type" => "http", "url" => url(port),
                               "headers" => { "Authorization" => "Bearer ${#{TOKEN_VARIABLE}}" })
        { "client" => "Claude Code",
          "forms" => [
            { "title" => "Run in a terminal",
              "text" => "claude mcp add --transport http --scope user #{SERVER_NAME} #{url(port)} " \
                        "--header \"Authorization: Bearer #{token}\"" },
            { "title" => "Or, to keep the token out of Claude Code's settings, run this",
              "text" => "claude mcp add-json --scope user #{SERVER_NAME} '#{server}'" },
            export_form(token)
          ],
          "check" => "claude mcp get #{SERVER_NAME}",
          "remove" => "claude mcp remove --scope user #{SERVER_NAME}" }
      end

      # The variable both clients' environment forms read. A shell profile only reaches terminals opened
      # after it is edited, so the line is also run once where the client will start.
      def export_form(token)
        { "title" => "and add this to your shell profile, such as ~/.zshrc, then run it in this terminal too",
          "text" => "export #{TOKEN_VARIABLE}=#{token}" }
      end

      # Pasted into the file by hand: `codex mcp add` and `codex mcp remove` rewrite the whole of
      # ~/.codex/config.toml, dropping its comments and reordering its tables (observed on 0.163.0).
      def codex(port, token)
        block = "[mcp_servers.#{SERVER_NAME}]\nurl = \"#{url(port)}\"\n"
        { "client" => "Codex",
          "forms" => [
            { "title" => "Add to ~/.codex/config.toml",
              "text" => "#{block}bearer_token_env_var = \"#{TOKEN_VARIABLE}\"" },
            export_form(token),
            { "title" => "Or instead of both, this block with the token in it",
              "text" => "#{block}http_headers = { Authorization = \"Bearer #{token}\" }" }
          ],
          "check" => "codex mcp get #{SERVER_NAME}",
          "remove" => "Delete the [mcp_servers.#{SERVER_NAME}] block from ~/.codex/config.toml" }
      end
    end
  end
end
