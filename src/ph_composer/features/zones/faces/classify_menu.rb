# frozen_string_literal: true

module PhComposer
  module Zones
    module Faces
      # The native selection client sets one attribute per action. With no selection, an Extensions
      # menu choice loads the secondary paint tool through the same public view command as the panel.
      module ClassifyMenu
        MENU = "Classify faces"
        OFF = "Exit Classify tool"
        FIELDS = {
          "face_type" => { "values" => ASSIGNABLE_FACE_TYPES, "labels" => ColourModes::FACE_TYPE_LABELS,
                           "noun" => "face type" },
          "boundary_condition" => { "values" => ASSIGNABLE_BOUNDARIES - %w[AttachedZone],
                                    "labels" => ColourModes::BOUNDARY_LABELS, "noun" => "boundary condition" }
        }.freeze

        module_function

        def install(feature)
          FIELDS.each do |field, spec|
            spec.fetch("values").each { |value| declare(feature, field, value, spec) }
          end
          feature.menu_entries("#{PREFIX}.assembly_menu", :menu => MENU,
                               :available => ->(read) { classifiable?(read.session) }) do |read|
            Selection.client(read.session).assembly_entries
          end
          feature.menu_entries("#{PREFIX}.attached_choices", :menu => MENU,
                               :available => ->(read) { classifiable?(read.session) }) do |read|
            Selection.client(read.session).attached_entries
          end
          feature.menu_item("#{PREFIX}.new_attached_zone_menu", :label => "New attached zone…", :menu => MENU,
                            :available => ->(read) { classifiable?(read.session) }) do |session|
            Selection.client(session).open_assignment
          end
          feature.menu_entries("#{PREFIX}.classify_off", :menu => MENU,
                               :available => ->(read) { Faces.classify_tool(read.session).active? }) do |_read|
            [Declarations::MenuEntry.new(:label => OFF, :handler => ->(session) { Faces.classify_tool(session).stop })]
          end
        end

        def declare(feature, field, value, spec)
          label = spec.fetch("labels").fetch(value, value)
          feature.menu_item("#{PREFIX}.classify_#{field}_#{value.downcase}",
                            :label => label, :menu => MENU,
                            :available => ->(read) { classifiable?(read.session) }) do |session|
            Selection.client(session).classify(field, value)
          end
        end

        # Whether a right-click landed on something this palette paints, which is a Face and nothing
        # else. SketchUp selects what was right-clicked before it builds the menu, so the selection is
        # the signal.
        #
        # At the Model root a right-click on a Zone selects the Group, not a Face, so the palette is
        # not offered there: the Group is what the user pointed at, and Erase, Hide and Explode are
        # what they are likely to want. Opening the Zone and right-clicking a Face offers it.
        # Measured on 26.1.188, 2026-09-20.
        def classifiable?(session)
          Selection.available?(session)
        end
      end
    end
  end
end
