# frozen_string_literal: true

require_relative "test_helper"

# docs/AGENT_GUIDE.md names operations and tools an agent will call as written: each must exist, so the
# guide cannot drift from what discovery answers. The recipes run elsewhere: the Spaces one, public calls
# only after native fixture setup, in tests/spaces_walkthrough_test.rb; the write and export ones in
# tests/agent_access_write_tools_test.rb and tests/api_client_test.rb.
class AgentGuideTest < PhComposerTestCase
  GUIDE = File.read(File.expand_path("../docs/AGENT_GUIDE.md", __dir__))

  def setup
    super
    PhComposer.compose
  end

  def test_every_operation_the_guide_names_is_registered
    named = GUIDE.scan(/`(ph_composer\.[a-z_.]+)`/).flatten.uniq
    missing = named.reject { |name| PhComposer::API.describe(:name => name) }

    refute_empty named
    assert_empty missing
  end

  def test_every_tool_the_guide_names_is_in_the_verb_table
    named = GUIDE.scan(/`([a-z_]+)`/).flatten.uniq & %w[discover describe query preview context invoke outcome view
                                                        setup export_file export_preflight start_export
                                                        export_status cancel_export latest_export]
    unknown = named - PhComposer::AgentAccess::Tools::TABLE.keys

    assert_includes named, "invoke"
    assert_empty unknown
  end
end
