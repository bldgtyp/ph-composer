# frozen_string_literal: true

module PhComposer
  module Zones
    module Faces
      # This feature's Colour-by modes: face type and boundary condition. Assembly is the third mode the
      # PRD names and arrives with assemblies in Phase 2.
      #
      # The hues are honeybee's own defaults, so a modeler sees the same colours in SketchUp, Rhino and
      # honeybee-display (PRD Q17; `honeybee-core/honeybee/face.py` and `boundarycondition.py`). Stored
      # values keep honeybee's names; the legend shows the PRD's words.
      module ColourModes
        BY_FACE_TYPE = "#{FEATURE_ID}.by_face_type"
        BY_BOUNDARY_CONDITION = "#{FEATURE_ID}.by_boundary_condition"

        FACE_TYPE_COLOURS = {
          "Wall" => [230, 180, 60], "RoofCeiling" => [128, 20, 20], "Floor" => [128, 128, 128],
          "AirBoundary" => [255, 255, 200]
        }.freeze
        FACE_TYPE_LABELS = { "RoofCeiling" => "Roof or ceiling", "AirBoundary" => "Air boundary" }.freeze

        # Attached zone takes honeybee's Other until the ventilation-colour interview gives it a hue.
        BOUNDARY_COLOURS = {
          "Outdoors" => [64, 180, 255], "Ground" => [165, 82, 0], "Adiabatic" => [255, 128, 128],
          "Surface" => [0, 128, 0], "AttachedZone" => [255, 255, 200]
        }.freeze
        BOUNDARY_LABELS = { "Adiabatic" => "To neighbour", "AttachedZone" => "Attached zone" }.freeze

        module_function

        def install(feature)
          feature.colour_mode(BY_FACE_TYPE, :label => "Face type", :entity_kind => "face",
                                            :colours => ColourBy::Palette.fixed(FACE_TYPE_COLOURS)) do |model|
            entries(model, "face_type", FACE_TYPE_LABELS)
          end
          feature.colour_mode(BY_BOUNDARY_CONDITION, :label => "Boundary condition", :entity_kind => "face",
                                                     :colours => ColourBy::Palette.fixed(BOUNDARY_COLOURS)) do |model|
            entries(model, "boundary_condition", BOUNDARY_LABELS)
          end
        end

        # One entry per Face of every Zone, whether or not it carries a record. A Face with no record is
        # the legend's unclassified count, which is how a modeler finds what is left to classify.
        def entries(model, field, labels)
          Zones::Occurrences.zones(model).flat_map do |zone|
            Zones::Occurrences.faces(zone).map do |face|
              record = FACE_STORE.read(face.entity)
              value = record && record[field]
              ColourBy::Entry.new(:entity => face.entity, :transform => face.transform, :value => value,
                                  :label => value && labels.fetch(value, value), :state => state(record, value),
                                  :path => zone.path + face.path)
            end
          end
        end

        # A Face the legend cannot finish colouring, as against one it has nothing to colour.
        #
        # A record that carries no value for this mode's field is incomplete: the user classified the
        # Face, they just have not said this part yet. Calling it unclassified would put it in the same
        # count as a Face with no record at all, and send them to Suggest classification, which never
        # touches a Face that already has one. Only a Face with no record is unclassified, and the
        # service decides that from a nil value.
        #
        # An Attached zone with no chosen record is the same kind of half-filled state and blocks
        # canonical export, so it reads the same way.
        def state(record, value)
          return nil unless record
          return :incomplete if value.nil?

          value == "AttachedZone" && record["attached_zone_id"].nil? ? :incomplete : nil
        end
      end
    end
  end
end
