# frozen_string_literal: true

module PhComposer
  module Spaces
    # The native route to Height from solid: offered when the selection is one Volume and one other Group or
    # component; any other selection is refused with a message. It reads the public preview, shows the
    # solid's volume, the net floor area and the height in display units, asks once, and invokes the action
    # with the height it showed as the expected value.
    module HeightFromSolidMenu
      LABEL = "Height from solid…"
      ACTION = "#{FEATURE_ID}.volumes.height_from_solid"
      PREVIEW = "#{FEATURE_ID}.volumes.height_from_solid_preview"
      SELECTED_SOLID = "#{FEATURE_ID}.selected_solid"
      NO_VOLUME = "Select the Volume too, beside the solid, then choose Height from solid."
      ONLY_PAIR = "Select only the Volume and the solid beside it, then choose Height from solid."

      module_function

      def install(feature)
        feature.menu_item("#{FEATURE_ID}.height_from_solid_menu", :label => LABEL, :menu => EXTENSION_NAME,
                                                                  :available => ->(read) {
                                                                    !pair(read.session).nil?
                                                                  }) do |session|
          session.feature_state(:spaces_height_menu) { Client.new(session) }.run
        end
      end

      # The selected Volume Group and the other selected container, as [volume, solid], or nil.
      def pair(session)
        selected = session.model.selection.to_a
        return unless selected.length == 2 && selected.all? { |entity| container?(entity) }

        volumes = selected.select { |entity| VOLUME_STORE.read(entity) }
        return unless volumes.length == 1

        [volumes.first, (selected - volumes).first]
      rescue CodedError
        nil
      end

      def container?(entity)
        entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
      end

      class Client
        def initialize(session)
          @session = session
          @context = API.connect(:session_id => session.id)
          @sequence = 0
        end

        def run
          volume, solid = HeightFromSolidMenu.pair(@session)
          return refuse_selection unless volume

          open = Array(@session.model.active_path).map(&:persistent_id)
          reference = { "volume_id" => VOLUME_STORE.read(volume).fetch("id"),
                        "entity_path" => open + [volume.persistent_id] }
          params = { "volume" => reference, "solid" => open + [solid.persistent_id] }
          preview = API.query(:context => @context, :name => PREVIEW, :params => params)
          return UI.messagebox(preview.fetch("message")) unless preview.fetch("status") == "completed"

          value = preview.fetch("value")
          return unless UI.messagebox(review(value), MB_YESNO) == IDYES

          @sequence += 1
          result = API.invoke(:context => @context, :name => ACTION,
                              :params => params.merge("expected_values" => {
                                "avg_ceiling_height_m" => value.fetch("current_height_m")
                              }),
                              :request => { "sequence" => @sequence, "expected_revision" => preview.fetch("revision") })
          UI.messagebox(result.fetch("message")) unless result.fetch("status") == "completed"
          result
        end

        private

        # The menu bar offers the item whatever is selected (`available` filters only the context menu), so a
        # selection that is not one Volume and one solid says why in the panel route's own words.
        def refuse_selection
          read = API.query(:context => @context, :name => SELECTED_SOLID)
          if read.fetch("status") == "completed"
            volume = @session.model.selection.to_a.any? { |entity| VOLUME_STORE.read(entity) }
            read = Outcome.refused("selection.invalid", volume ? ONLY_PAIR : NO_VOLUME, :revision => @session.revision)
          end
          UI.messagebox(read.fetch("message"))
          read
        end

        def review(value)
          system = Preferences.unit_system
          text = ->(quantity, number) { Units.format(number, :quantity => quantity, :system => system) }
          "The solid encloses #{text.call('volume', value.fetch('solid_volume_m3'))} over the Volume's net floor " \
            "area of #{text.call('area', value.fetch('net_floor_area_m2'))}, so its average clear ceiling height " \
            "becomes #{text.call('length', value.fetch('height_m'))}. The solid is left as it is.\n\nSet the height?"
        end
      end
    end
  end
end
