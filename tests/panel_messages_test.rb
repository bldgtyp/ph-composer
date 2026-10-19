# frozen_string_literal: true

require_relative "test_helper"

# The page and Ruby agree on their messages by convention; these cases turn the convention into a check,
# so a misspelled type fails offline rather than in the host. The panel files are found by glob.
class PanelMessagesTest < PhComposerTestCase
  Messages = PhComposer::PanelMessages
  HTML = File.join(SOURCE_ROOT, "ph_composer", "html")

  def test_every_message_the_page_sends_is_one_ruby_accepts
    sent = sources.flat_map { |source| source.scan(/\b(?:send|transport)\("([a-z]+\.[a-z_.]+)"/).flatten }
    # A request channel sends whichever message it was made with, so the map of the ones it carries is
    # where those types are written down.
    sent += File.read(File.join(HTML, "request.js"))[/var SLOTS = \{(.*?)\};/m, 1].scan(/"([a-z_.]+)":/).flatten
    channels = File.read(File.join(HTML, "sections", "export.js"))[/var CHANNELS = \{(.*?)\};/m, 1]
    sent += channels.scan(/: "([a-z.]+)"/).flatten
    sent = sent.uniq

    assert_includes sent, "action.invoke"
    assert_empty sent - Messages::INBOUND.keys, "the page sends a type Ruby does not accept"
    assert_empty Messages::INBOUND.keys - sent, "Ruby accepts a type no page file sends"
  end

  def test_the_page_handles_exactly_the_messages_ruby_publishes
    handlers = File.read(File.join(HTML, "panel.js"))[/var HANDLERS = \{(.*?)\};/m, 1].scan(/"([a-z_.]+)":/).flatten

    assert_equal Messages::OUTBOUND.keys.sort, handlers.sort
  end

  def test_an_outbound_payload_carries_only_its_declared_keys
    script = Messages.script("panel.notice", "session" => "s", "message" => "m", "tone" => "info")

    assert_equal 'PhComposerUI.get("panel").receive({"type":"panel.notice","payload":' \
                 '{"session":"s","message":"m","tone":"info"}})', script
    assert_raises(ArgumentError) { Messages.script("panel.notice", "session" => "s", "surprise" => 1) }
    assert_raises(ArgumentError) { Messages.script("action.invoke", {}) }
  end

  private

  # The panel's own scripts. The runtime page (html/runtime/) speaks to RuntimeHost, and the Agent Access and
  # Help & Diagnostics pages to their own dialogs, not the panel; agent_access_tokens_test.rb and
  # support_dialog_test.rb check those.
  def sources
    panel_files = Dir[File.join(HTML, "**", "*.js")].reject do |path|
      path.match?(%r{/html/(runtime|agent_access|support)/})
    end
    panel_files.sort.map { |path| File.read(path) }
  end
end
