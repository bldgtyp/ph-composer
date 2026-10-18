# frozen_string_literal: true

require_relative "test_helper"

# The text the Agent Access dialog shows for each supported client, pinned to Claude Code 2.1.300 and
# Codex 0.163.0 (context/AGENT_INTERFACE.md, "User-controlled local access"). A changed flag in a later
# client is a change to these goldens, made on purpose with the new version recorded.
class AgentAccessClientConfigTest < PhComposerTestCase
  ClientConfig = PhComposer::AgentAccess::ClientConfig
  TOKEN = "0123456789abcdef0123456789abcdef0123456789abcdef"

  def test_claude_code_takes_the_token_in_its_command_or_from_an_environment_variable
    claude = ClientConfig.for(:port => 46_110, :token => TOKEN).first

    assert_equal "Claude Code", claude.fetch("client")
    assert_equal ["claude mcp add --transport http --scope user ph-composer http://127.0.0.1:46110/mcp " \
                  "--header \"Authorization: Bearer #{TOKEN}\"",
                  "claude mcp add-json --scope user ph-composer '{\"type\":\"http\"," \
                  "\"url\":\"http://127.0.0.1:46110/mcp\"," \
                  "\"headers\":{\"Authorization\":\"Bearer ${PH_COMPOSER_TOKEN}\"}}'",
                  "export PH_COMPOSER_TOKEN=#{TOKEN}"], claude.fetch("forms").map { |form| form["text"] }
    assert_equal ["claude mcp get ph-composer", "claude mcp remove --scope user ph-composer"],
                 claude.values_at("check", "remove")
  end

  def test_codex_keeps_the_token_in_an_environment_variable_or_inline_in_its_config
    codex = ClientConfig.for(:port => 46_110, :token => TOKEN).last

    assert_equal "Codex", codex.fetch("client")
    block = "[mcp_servers.ph-composer]\nurl = \"http://127.0.0.1:46110/mcp\"\n"
    assert_equal ["#{block}bearer_token_env_var = \"PH_COMPOSER_TOKEN\"", "export PH_COMPOSER_TOKEN=#{TOKEN}",
                  "#{block}http_headers = { Authorization = \"Bearer #{TOKEN}\" }"],
                 codex.fetch("forms").map { |form| form["text"] }
    assert_equal ["codex mcp get ph-composer",
                  "Delete the [mcp_servers.ph-composer] block from ~/.codex/config.toml"],
                 codex.values_at("check", "remove")
  end

  def test_a_changed_port_reaches_every_form
    forms = ClientConfig.for(:port => 47_001, :token => TOKEN).flat_map { |client| client.fetch("forms") }

    assert(forms.reject { |form| form["text"].start_with?("export") }
                .all? { |form| form["text"].include?("http://127.0.0.1:47001/mcp") })
    refute(forms.any? { |form| form["text"].include?("46110") })
  end
end
