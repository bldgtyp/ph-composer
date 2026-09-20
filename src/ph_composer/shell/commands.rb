# frozen_string_literal: true

module PhComposer
  # The native commands: the Extensions submenu entry that opens the panel, the Colour by menu built
  # from whatever modes are registered, and the submenus built from whatever menu items are.
  #
  # Nothing here names a feature or carries a feature's words. A feature that wants a native menu
  # declares `menu_item` in its own `install`, and it appears here and in the viewport context menu
  # with no line added below (context/EXTENSIBILITY.md).
  module Commands
    OPEN_PANEL = "Open PH-Composer"
    COLOUR_BY = "Colour by"
    COLOUR_BY_OFF = "Off"

    class << self
      attr_reader :open_panel, :colour_by_menu, :feature_menus

      def install
        return if @installed

        @open_panel = UI::Command.new(OPEN_PANEL) { Panel.show }
        @open_panel.menu_text = OPEN_PANEL
        @open_panel.tooltip = OPEN_PANEL
        @open_panel.status_bar_text = "Open the PH-Composer panel for the active Model"
        submenu = UI.menu("Extensions").add_submenu(EXTENSION_NAME)
        submenu.add_item(@open_panel)
        install_colour_by(submenu)
        @feature_menus = install_feature_menus(submenu)
        # The same submenus on a right-click over a Face, which is where a modal painting tool is
        # reached from in SketchUp's own grammar. SketchUp selects what was right-clicked before it
        # builds the menu, so the selection is what says whether a Face is under the cursor.
        UI.add_context_menu_handler { |menu| install_feature_menus(menu) if face_selected? }
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

      # One submenu per declared `menu` name, its items in registration order. The submenu name and
      # every label come from the declaring feature; this groups them and knows nothing else.
      def install_feature_menus(parent)
        Registry.current.menu_items.each_value.group_by(&:menu).map do |name, declarations|
          menu = parent.add_submenu(name)
          declarations.each do |declaration|
            item = menu.add_item(declaration.label) { with_session { |session| declaration.handler.call(session) } }
            menu.set_validation_proc(item) { item_check(declaration) } if declaration.state
            menu.add_separator if declaration.separator_after
          end
          [name, menu]
        end.to_h
      end

      def item_check(declaration)
        session = Sessions.current
        session ? declaration.state.call(session) : MF_UNCHECKED
      end

      def face_selected?
        model = Sketchup.active_model
        model && model.selection.to_a.any? { |entity| entity.is_a?(Sketchup::Face) }
      end

      def with_session
        session = Sessions.current
        return unless session

        yield session
      rescue UserError => error
        session.notice(error.message, :tone => :warning)
      end

      def colour_by
        with_session { |session| yield ColourBy.for(session) }
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
        @feature_menus = nil
      end
    end
  end

  on_reset("commands") { Commands.reset_for_test }
end
