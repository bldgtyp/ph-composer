# frozen_string_literal: true

module PhComposer
  module Zones
    module SelectionRegistration
      TARGET = Shapes.object({ "reference" => ZONE_REFERENCE, "expected_values" => ZONE_VALUES }).freeze
      ROW = Shapes.object({ "reference" => ZONE_REFERENCE, "values" => ZONE_VALUES }).freeze
      UPDATE = Shapes.object({ "targets" => Shapes.list(TARGET).merge("minItems" => 1),
                               "field" => { "type" => "string", "enum" => Selection::FIELDS.keys },
                               "value" => { "type" => %w[string number null] } }).freeze
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
          Selection.update_field(request, proposal)
        end
        Selection.install(feature)
        install_faces(feature)
      end

      def install_faces(feature)
        prefix = Faces::PREFIX
        feature.query("#{prefix}.selection", :description => "Validated selected Face occurrence references.",
                      :params => Shapes::NONE,
                      :result => Shapes.object({ "faces" => Shapes.list(Faces::FACE_REFERENCE) }),
                      :examples => [{}]) { |request| { "faces" => Faces::Selection.selected(request.model) } }
        feature.query("#{prefix}.attached_assignment", :description => "The pending native Face assignment handoff.",
                      :params => Shapes::NONE, :result => ASSIGNMENT,
                      :examples => [{}]) { |request| Faces::Selection.handoff(request.session).snapshot }
        feature.snapshot_section("#{prefix}.selection_assignment", :query => "#{prefix}.attached_assignment")
        feature.view_command("#{prefix}.open_attached_assignment",
                             :description => "Review a new Attached zone assignment for explicit Faces.",
                             :params => Shapes.object({ "faces" => Faces::Registration::FACES,
                                                        "revision" => { "type" => "integer" } }),
                             :result => ASSIGNMENT,
                             :examples => [{ "faces" => [Faces::Registration::EXAMPLE_FACE], "revision" => 1 }]) do |
                               request|
          Faces::Selection.open_assignment(request)
        end
        feature.view_command("#{prefix}.close_attached_assignment",
                             :description => "Close the native assignment handoff.",
                             :params => Shapes.object({ "token" => { "type" => "string" } }), :result => ASSIGNMENT,
                             :examples => [{ "token" => "example-review-token" }]) do |request|
          value = Faces::Selection.handoff(request.session).close(request.params.fetch("token"))
          request.session.changed(:zones, :attached_assignment)
          value
        end
      end
    end
  end
end
