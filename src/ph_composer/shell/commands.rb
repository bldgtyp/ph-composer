# frozen_string_literal: true

module PhComposer
  # The native commands: one Extensions submenu entry that opens the panel. A feature's menu placement
  # arrives with the first action that needs one (CONTRACTS.md "Implemented in P0-D").
  module Commands
    OPEN_PANEL = "Open PH-Composer"

    class << self
      attr_reader :open_panel

      def install
        return if @installed

        @open_panel = UI::Command.new(OPEN_PANEL) { Panel.show }
        @open_panel.menu_text = OPEN_PANEL
        @open_panel.tooltip = OPEN_PANEL
        @open_panel.status_bar_text = "Open the PH-Composer panel for the active Model"
        UI.menu("Extensions").add_submenu(EXTENSION_NAME).add_item(@open_panel)
        @installed = true
      end

      def reset_for_test
        @installed = false
        @open_panel = nil
      end
    end
  end

  on_reset("commands") { Commands.reset_for_test }
end
