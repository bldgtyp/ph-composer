# frozen_string_literal: true

module PhComposer
  # The shared Colour-by service: a contribution seam beside feature, provider and exporter
  # (context/EXTENSIBILITY.md, "Colour-by modes"). A feature declares a mode in its own `install`:
  #
  #   feature.colour_mode("ph_composer.zones.by_zone", label: "Zone", entity_kind: "zone",
  #                       colours: ColourBy::Palette.ramp) do |model|
  #     Zones::Occurrences.zones(model).map do |zone|
  #       ColourBy::Entry.new(entity: zone.entity, transform: zone.transform,
  #                           value: zone.record.fetch("id"), label: zone.record.fetch("name"))
  #     end
  #   end
  #
  # The service owns registration, the host overlay, the viewport HUD and cache invalidation. A mode
  # owns a pure projection over its own feature's entities. Nothing here knows a face type, a
  # boundary condition or a Zone, and the shared renderer has no branch per mode.
  #
  # Turning a mode on changes no record, writes no material and opens no operation, so it is not a
  # registered action. It is a view command (Declarations::ViewCommand), reached from the native
  # Colour by menu, from the panel and from any client with `view` access, and read back through the
  # registered `ph_composer.colour_by.state` query.
  module ColourBy
    FEATURE_ID = "#{EXTENSION_ID}.colour_by"
    STATE = "#{FEATURE_ID}.state"
    # Host events that can change what a mode would paint. Service also listens for the session's
    # post-commit change publication, since a native commit callback may arrive before the revision
    # advances. A hidden tag need not advance the revision, so `tags_changed` forces a rebuild.
    #
    # `model_activated` is deliberately absent. A Model that changed while it was inactive reported
    # that through its own observers at the time, so switching back to it has nothing to rebuild.
    INVALIDATING_EVENTS = %i[transaction_committed transaction_undone transaction_redone
                             active_path_changed].freeze

    STATE_RESULT = {
      "type" => "object",
      "required" => %w[mode modes rows],
      "properties" => {
        "mode" => { "type" => %w[string null], "description" => "The active mode's name, or null when off." },
        "label" => { "type" => %w[string null] },
        "entity_kind" => { "type" => %w[string null] },
        "modes" => { "type" => "array", "items" => { "type" => "object" },
                     "description" => "Every registered mode: name, label and entity kind." },
        "rows" => { "type" => "array", "items" => { "type" => "object" },
                    "description" => "The active mode's legend: value, label, colour, count and state." }
      }
    }.freeze

    ACTIVATE_PARAMS = {
      "type" => "object", "additionalProperties" => false, "required" => ["mode"],
      "properties" => {
        "mode" => { "type" => %w[string null],
                    "description" => "The mode to turn on, or null to turn Colour-by off." }
      }
    }.freeze

    ROW = {
      "type" => "object", "additionalProperties" => false, "required" => %w[value state],
      "properties" => {
        "value" => { "type" => %w[string null], "description" => "The legend row's value; null is unclassified." },
        "state" => { "type" => "string", "enum" => %w[classified incomplete unclassified] }
      }
    }.freeze
    SELECT_ROW_PARAMS = {
      "type" => "object", "additionalProperties" => false, "required" => ["row"], "properties" => { "row" => ROW }
    }.freeze
    SELECT_ROW_RESULT = {
      "type" => "object", "additionalProperties" => false, "required" => ["selected"],
      "properties" => { "selected" => { "type" => "integer" } }
    }.freeze
    # No row shows everything again, which is what leaving "Show only this" means.
    ISOLATE_PARAMS = {
      "type" => "object", "additionalProperties" => false, "properties" => { "row" => ROW }
    }.freeze

    module_function

    def install(registry)
      feature = registry.feature(FEATURE_ID, :contract_version => Declarations::CONTRACT_VERSION)
      feature.query(STATE, :description => "The active Colour-by mode, every registered mode and the legend.",
                           :params => { "type" => "object", "additionalProperties" => false, "properties" => {} },
                           :result => STATE_RESULT, :examples => [{}]) do |request|
        state(request.session)
      end
      feature.view_command("#{FEATURE_ID}.activate",
                           :description => "Turn one Colour-by mode on, or turn Colour-by off.",
                           :params => ACTIVATE_PARAMS, :result => STATE_RESULT,
                           :examples => [{ "mode" => nil }]) do |request|
        activate(request.session, request.params.fetch("mode"))
      end
      feature.view_command("#{FEATURE_ID}.select_row",
                           :description => "Select and zoom to the entities one legend row stands for.",
                           :params => SELECT_ROW_PARAMS, :result => SELECT_ROW_RESULT,
                           :examples => [{ "row" => { "value" => "Wall", "state" => "classified" } }]) do |request|
        row = request.params.fetch("row")
        { "selected" => self.for(request.session).select_row(row.fetch("value"), row.fetch("state")) }
      end
      feature.view_command("#{FEATURE_ID}.isolate",
                           :description => "Show one legend row on its own, or show every row again.",
                           :params => ISOLATE_PARAMS, :result => STATE_RESULT, :examples => [{}]) do |request|
        row = request.params["row"]
        self.for(request.session).isolate(row && [row.fetch("value"), row.fetch("state")])
        state(request.session)
      end
      feature.snapshot_section("#{FEATURE_ID}.legend", :query => STATE)
      INVALIDATING_EVENTS.each do |kind|
        feature.on_host_event(kind) { |session| self.for(session).invalidate! }
      end
      feature.on_host_event(:tags_changed) { |session| self.for(session).invalidate!(:force => true) }
    end

    # This Model's Colour-by state, created inert on first reach. Nothing draws until a mode is on.
    def for(session)
      session.feature_state(:colour_by) { Service.new(session) }
    end

    # The panel's route to the mode switch, and the answer it renders the legend from. A name the
    # registry does not hold refuses through the service, naming what was asked for.
    def activate(session, name)
      service = self.for(session)
      name.nil? ? service.deactivate : service.activate(name)
      state(session)
    end

    def state(session)
      service = self.for(session)
      service.legend.merge("modes" => modes)
    end

    # Every registered mode, in registration order: what a menu or a panel offers.
    def modes
      Registry.current.colour_modes.values.map do |mode|
        { "name" => mode.name, "label" => mode.label, "entity_kind" => mode.entity_kind }
      end
    end

    # The mode the user last chose, so a mode turned on is the one their palette last touched
    # Colour-by itself is off at rest.
    def remembered_mode
      name = Preferences.colour_by_mode
      name && Registry.current.colour_modes.key?(name) ? name : nil
    end
  end
end
