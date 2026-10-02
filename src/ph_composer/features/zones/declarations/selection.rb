# frozen_string_literal: true

module PhComposer
  module Zones
    module SelectionRegistration
      TARGET = Shapes.object({ "reference" => ZONE_REFERENCE, "expected_values" => ZONE_VALUES }).freeze
      ROW = Shapes.object({ "reference" => ZONE_REFERENCE, "values" => ZONE_VALUES }).freeze
      UPDATE = Shapes.object({
        "targets" => Shapes.list(TARGET).merge("minItems" => 1, "description" => "Each Zone occurrence to change, " \
                                                                                "with the values last read; a " \
                                                                                "change refuses."),
        "field" => { "type" => "string", "enum" => Selection::FIELDS.keys, "description" => "The Zone value to set." },
        "value" => { "type" => %w[string number null],
                     "description" => "The new value: text for name, building_segment and level (null clears " \
                                      "level), a number in mm for ground_depth_mm." }
      }).freeze
      ASSIGNMENT = Shapes.object({ "token" => { "type" => %w[string null] },
                                   "revision" => { "type" => %w[integer null] },
                                   "faces" => Shapes.list(Faces::FACE_REFERENCE) }).freeze
      module_function

      def install(feature)
        feature.query("#{FEATURE_ID}.selection", :description => "Valid selected Zone occurrences and current values.",
                      :params => Shapes::NONE, :result => Shapes.object({ "zones" => Shapes.list(ROW) }),
                      :examples => [{}]) { |request| Selection.read(request) }
        feature.action("#{FEATURE_ID}.update_field", :description => "Set one attribute on explicit Zone occurrences.",
                       :params => UPDATE, :result => Shapes.object({ "zone_ids" => Shapes.list(Shapes::ID) }),
                       :undo_name => "Edit Selected Zones",
                       :side_effects => "Updates each Zone and its membership stamps.",
                       :examples => [{ "targets" => [{ "reference" => ZoneRegistration::EXAMPLE_REFERENCE,
                                                        "expected_values" => ZoneRegistration::EXAMPLE_VALUES }],
                                       "field" => "level", "value" => "L1" }]) do |request, proposal|
          Selection.update_field(request, proposal, :field => request.params.fetch("field"),
            :value => request.params.fetch("value"), :targets => request.params.fetch("targets"))
        end
        Selection.install(feature)
        install_faces(feature)
      end

      def install_faces(feature)
        prefix = Faces::PREFIX
        feature.query("#{prefix}.selection", :description => "Validated selected Face occurrence references.",
                      :params => Shapes::NONE,
                      :result => Shapes.object({ "faces" => Shapes.list(Faces::FACE_REFERENCE),
                                                  "targets" => Shapes.list(Faces::AssemblyRegistration::TARGET) }),
                      :examples => [{}]) { |request| Faces::Selection.read(request) }
        feature.snapshot_section("#{prefix}.selected", :query => "#{prefix}.selection")
        feature.query("#{prefix}.attached_assignment", :description => "The pending native Face assignment handoff.",
                      :params => Shapes::NONE, :result => ASSIGNMENT,
                      :examples => [{}]) { |request| Faces::Selection.handoff(request.session).snapshot }
        feature.snapshot_section("#{prefix}.selection_assignment", :query => "#{prefix}.attached_assignment")
        feature.view_command("#{prefix}.open_attached_assignment",
                             :description => "Review a new Attached zone assignment for explicit Faces.",
                             :params => Shapes.object({
                               "faces" => Faces::Registration::FACES.merge("description" => "The Faces the new " \
                                                                                         "Attached zone would be " \
                                                                                         "assigned to."),
                               "revision" => { "type" => "integer", "description" => "The revision the Faces were " \
                                                                                     "read at; a later one refuses." }
                             }),
                             :result => ASSIGNMENT,
                             :examples => [{ "faces" => [Faces::Registration::EXAMPLE_FACE], "revision" => 1 }]) do |
                               request|
          Faces::Selection.open_assignment(request, :revision => request.params.fetch("revision"),
                                                    :faces => request.params.fetch("faces"))
        end
        feature.view_command("#{prefix}.close_attached_assignment",
                             :description => "Close the native assignment handoff.",
                             :params => Shapes.object({
                               "token" => { "type" => "string", "description" => "The token open_attached_" \
                                                                                 "assignment returned; another one " \
                                                                                 "leaves the handoff open." }
                             }),
                             :result => ASSIGNMENT,
                             :examples => [{ "token" => "example-review-token" }]) do |request|
          value = Faces::Selection.handoff(request.session).close(request.params.fetch("token"))
          request.session.changed(:zones, :attached_assignment)
          value
        end
      end
    end
  end
end
