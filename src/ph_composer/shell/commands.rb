# frozen_string_literal: true

module PhComposer
  # The native commands: the Extensions submenu entry that opens the panel, and the Colour by menu.
  # A feature's menu placement arrives with the first action that needs one (CONTRACTS.md
  # "Implemented in P0-D").
  module Commands
    OPEN_PANEL = "Open PH-Composer"
    COLOUR_BY = "Colour by"
    COLOUR_BY_OFF = "Off"

    class << self
      attr_reader :open_panel, :colour_by_menu

      def install
        return if @installed

        @open_panel = UI::Command.new(OPEN_PANEL) { Panel.show }
        @open_panel.menu_text = OPEN_PANEL
        @open_panel.tooltip = OPEN_PANEL
        @open_panel.status_bar_text = "Open the PH-Composer panel for the active Model"
        submenu = UI.menu("Extensions").add_submenu(EXTENSION_NAME)
        submenu.add_item(@open_panel)
        install_colour_by(submenu)
        @installed = true
      end

      # Built from whatever modes are registered, in registration order, so a feature that declares
      # one reaches this menu without a line here. Turning a mode on writes nothing to the Model, so
      # these are menu items rather than registered actions.
      def install_colour_by(submenu)
        @colour_by_menu = submenu.add_submenu(COLOUR_BY)
        Registry.current.colour_modes.each_value do |mode|
          item = @colour_by_menu.add_item(mode.label) { colour_by { |service| service.activate(mode.name) } }
          @colour_by_menu.set_validation_proc(item) { colour_by_check(mode.name) }
        end
        off = @colour_by_menu.add_item(COLOUR_BY_OFF) { colour_by(&:deactivate) }
        @colour_by_menu.set_validation_proc(off) { colour_by_check(nil) }
      end

      def colour_by
        session = Sessions.current
        return unless session

        yield ColourBy.for(session)
      rescue UserError => error
        session.notice(error.message, :tone => :warning)
      end

      def colour_by_check(name)
        session = Sessions.current
        active = session && ColourBy.for(session).mode_name
        active == name ? MF_CHECKED : MF_UNCHECKED
      end

      def reset_for_test
        @installed = false
        @open_panel = nil
        @colour_by_menu = nil
      end
    end
  end

  on_reset("commands") { Commands.reset_for_test }
end
