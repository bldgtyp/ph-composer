# frozen_string_literal: true

module PhComposer
  module FaceAssignment
    # The Classify tool's palette as native menu items, until the panel palette arrives with the
    # Overview UI (D7). Each item sets one field and starts the tool, so choosing a face type and
    # then a boundary condition leaves both set, and a field never chosen keeps whatever the Face
    # already has (face-assignment PRD Q10, Q21).
    #
    # The words are the glossary's and come from the same tables the Colour-by legend reads, so
    # there is one place where honeybee's `RoofCeiling` is shown as "Roof or ceiling". The stored
    # honeybee value stays the contract.
    #
    # Attached zone is deliberately not here: it needs a record picker and an inline "New attached
    # zone" route, which is panel work and lands with D7. Surface is the solver's and never the
    # palette's.
    module ClassifyMenu
      MENU = "Classify faces"
      KEEP = "Keep what the Face has"
      OFF = "Stop classifying"
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
          declare(feature, field, nil, spec)
        end
        feature.menu_item("#{FEATURE_ID}.classify_off", :label => OFF, :menu => MENU) do |session|
          FaceAssignment.classify_tool(session).stop
        end
      end

      def declare(feature, field, value, spec)
        label = value ? spec.fetch("labels").fetch(value, value) : "#{KEEP} (#{spec.fetch('noun')})"
        feature.menu_item("#{FEATURE_ID}.classify_#{field}_#{value ? value.downcase : "keep"}",
                          :label => label, :menu => MENU, :separator_after => value.nil?,
                          :state => ->(session) { check(session, field, value) }) do |session|
          FaceAssignment.classify_tool(session).choose(field, value)
        end
      end

      def check(session, field, value)
        FaceAssignment.classify_tool(session).palette.dig(field, "value") == value ? MF_CHECKED : MF_UNCHECKED
      end
    end
  end
end
