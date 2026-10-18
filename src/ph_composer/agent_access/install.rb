# frozen_string_literal: true

require_relative "tokens"
require_relative "dialog"

module PhComposer
  # Local agent access (context/AGENT_INTERFACE.md, "User-controlled local access"), registered as a
  # foundation capability. It declares one native menu item, which opens the Agent Access dialog, and
  # no public operation: tokens are managed only by the user in that dialog.
  module AgentAccess
    FEATURE_ID = "ph_composer.agent_access"
    MENU = "Agent Access"
    # What the dialog can be refused. No public operation raises these; they are declared so every code
    # the extension raises is described in one catalog.
    CODES = {
      "agent_access.limit" => "This machine already has the most live agent tokens it keeps; revoke one first.",
      "agent_access.token_unknown" => "No agent token has that id on this machine.",
      "agent_access.store_unreadable" => "The stored agent tokens cannot be read; reset them before issuing another.",
      "agent_access.store_unavailable" => "The agent tokens could not be read or saved on this machine.",
      "agent_access.model_unsaved" => "A token can be bound only to a Model that has been saved to a file.",
      "agent_access.model_changed" => "The open Model changed since the form showed it; nothing was issued."
    }.freeze

    module_function

    def install(registry)
      feature = registry.feature(FEATURE_ID, :contract_version => Declarations::CONTRACT_VERSION)
      CODES.each { |code, description| feature.code(code, :description => description) }
      # Kept out of the viewport's right-click menu: managing tokens has nothing to do with what is under
      # the pointer.
      # The form shows which Model "This Model only" binds, so it follows activation and Save As.
      %i[model_activated post_save].each { |event| feature.on_host_event(event) { |_session| Dialog.refresh } }
      feature.menu_item("#{FEATURE_ID}.open", :label => "Agent Access…", :menu => MENU,
                                              :available => ->(_read) { false }) { |_session| Dialog.show }
    end

    # Called after every token store write: the listener starts with the first live token, takes the
    # new snapshot and stops after the last revoke, and the dialog shows the new list.
    def tokens_changed
      Listener.refresh
      Dialog.refresh
    end

    # The listener's state for the dialog.
    def server_status
      Listener.status
    end
  end

  on_reset("agent_access.dialog") { AgentAccess::Dialog.reset_for_test }
  on_reset("agent_access.listener") { AgentAccess::Listener.reset }
end
