# frozen_string_literal: true

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

      def claude_code(port, token)
        { "client" => "Claude Code",
          "forms" => [
            { "title" => "Run in a terminal",
              "text" => "claude mcp add --transport http --scope user #{SERVER_NAME} #{url(port)} " \
                        "--header \"Authorization: Bearer #{token}\"" }
          ],
          "check" => "claude mcp get #{SERVER_NAME}",
          "remove" => "claude mcp remove --scope user #{SERVER_NAME}" }
      end

      # Pasted into the file by hand: `codex mcp add` and `codex mcp remove` rewrite the whole of
      # ~/.codex/config.toml, dropping its comments and reordering its tables (observed on 0.163.0).
      def codex(port, token)
        block = "[mcp_servers.#{SERVER_NAME}]\nurl = \"#{url(port)}\"\n"
        { "client" => "Codex",
          "forms" => [
            { "title" => "Add to ~/.codex/config.toml",
              "text" => "#{block}bearer_token_env_var = \"#{TOKEN_VARIABLE}\"" },
            { "title" => "and to your shell profile, such as ~/.zshrc", "text" => "export #{TOKEN_VARIABLE}=#{token}" },
            { "title" => "Or instead of both, this block with the token in it",
              "text" => "#{block}http_headers = { Authorization = \"Bearer #{token}\" }" }
          ],
          "check" => "codex mcp get #{SERVER_NAME}",
          "remove" => "Delete the [mcp_servers.#{SERVER_NAME}] block from ~/.codex/config.toml" }
      end
    end
  end
end
