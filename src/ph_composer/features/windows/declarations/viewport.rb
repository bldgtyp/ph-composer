# frozen_string_literal: true

require_relative "../place_tool"
require_relative "../units/locate"

module PhComposer
  module Windows
    module ViewportRegistration
      PREFIX = "#{FEATURE_ID}.place_tool"
      MENU = "Place Windows"
      module_function

      def install(feature, registry)
        face = DeepCopy.call(registry.record_descriptor("ph_composer.zones.faces.face").occurrence_schema)
        nullable_face = face.merge("type" => %w[object null])
        state = Shapes.object({ "active" => { "type" => "boolean" },
          "type_id" => { "type" => %w[string null] }, "anchor" => { "type" => "string", "enum" => Units::Anchors::ALL },
          "host" => nullable_face })
        params = Shapes.object({ "type_id" => Shapes::ID,
          "anchor" => { "type" => "string", "enum" => Units::Anchors::ALL }, "host" => nullable_face },
          :optional => %w[anchor host])
        feature.query("#{PREFIX}.get", :description => "This Model's Place tool choice and active state.",
          :params => Shapes::NONE, :result => state, :examples => [{}]) do |request|
          Windows.place_tool(request.session).state
        end
        feature.snapshot_section(PREFIX, :query => "#{PREFIX}.get")
        feature.view_command("#{PREFIX}.choose", :description => "Choose a Type and anchor, then start Place.",
          :params => params, :result => state, :examples => [{ "type_id" => "wnt_Ab12Cd34Ef56" }]) do |request|
          Windows.place_tool(request.session).choose(request.params.fetch("type_id"),
            :anchor => request.params.fetch("anchor", PlaceTool::DEFAULT_ANCHOR), :host => request.params["host"])
        end
        feature.view_command("#{PREFIX}.stop", :description => "Stop Place and abandon its pending gesture.",
          :params => Shapes::NONE, :result => state, :examples => [{}]) do |request|
          Windows.place_tool(request.session).stop
        end
        locate(feature)
        menus(feature)
      end

      def locate(feature)
        reference = Units::TARGET.descriptor.occurrence_schema
        feature.view_command("#{FEATURE_ID}.units.locate",
          :description => "Select and zoom to explicit Window occurrences.",
          :params => Shapes.object({ "units" => Shapes.list(reference).merge("minItems" => 1, "maxItems" => 500) }),
          :result => Shapes.object({ "units" => Shapes.list(reference) }),
          :examples => [{ "units" => [UnitRegistration::EXAMPLE_UNIT] }]) do |request|
          Units::Locate.call(request.model, request.params.fetch("units"))
        end
      end

      def menus(feature)
        feature.menu_item("#{PREFIX}.menu", :label => "Place Window…", :menu => MENU,
          :available => ->(session) { !type_rows(session).empty? }) { |session| choose_from_menu(session) }
        feature.menu_entries("#{PREFIX}.face_menu", :menu => MENU,
          :available => ->(session) { !selected_face(session).nil? }) do |session|
          host = selected_face(session)
          type_rows(session).map do |row|
            id = row.fetch("id")
            Declarations::MenuEntry.new(:label => "Place #{row.fetch('name')}", :handler => ->(target) {
              invoke_choice(target, { "type_id" => id, "host" => host })
            })
          end
        end
        feature.menu_item("#{PREFIX}.exit_menu", :label => "Stop Place", :menu => MENU,
          :available => ->(session) { Windows.place_tool(session).active? }) do |session|
          Windows.place_tool(session).stop
        end
      end

      def type_rows(session)
        engine = Records::Engine.new(session.model, Registry.current.catalog)
        engine.ids(TYPE_KIND).map { |id| engine.find(TYPE_KIND, id).slice("id", "name") }
      end

      def selected_face(session)
        selected = session.model.selection.to_a
        return unless selected.length == 1 && selected.first.is_a?(Sketchup::Face)
        result = API.query(:context => API.connect(:session_id => session.id),
          :name => "ph_composer.zones.faces.selection")
        return unless result.fetch("status") == "completed"
        faces = result.fetch("value").fetch("faces")
        faces.first if faces.length == 1
      end

      def choose_from_menu(session)
        rows = type_rows(session)
        return if rows.empty?
        choices = [rows.map { |row| row.fetch("name") }.join("|")]
        choice = UI.inputbox(["Window Type"], [rows.first.fetch("name")], choices,
          "Place Window")
        return unless choice
        selected = rows.find { |row| row.fetch("name") == choice.first }
        return unless selected
        params = { "type_id" => selected.fetch("id") }
        host = selected_face(session)
        params["host"] = host if host
        invoke_choice(session, params)
      end

      def invoke_choice(session, params)
        result = API.view(:context => API.connect(:session_id => session.id), :name => "#{PREFIX}.choose",
          :params => params)
        unless result.fetch("status") == "completed"
          Sketchup.status_text = result.fetch("message")
          session.notice(result.fetch("message"), :tone => :warning)
        end
        result
      end
    end
  end
end
