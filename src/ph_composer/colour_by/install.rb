# frozen_string_literal: true

module PhComposer
  # The shared Colour-by service: the fourth contribution seam, beside feature, provider and exporter
  # (face-assignment PRD "Colour-by", Q16). A feature declares a mode in its own `install`:
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
  # registered action: it is reached through the native Colour by menu, and read back through the
  # registered `ph_composer.colour_by.state` query.
  module ColourBy
    FEATURE_ID = "#{EXTENSION_ID}.colour_by"
    STATE = "#{FEATURE_ID}.state"
    # Every host event that can change what a mode would paint. A tag being hidden need not advance
    # the session revision, so `tags_changed` forces a rebuild rather than deduplicating on one.
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

    module_function

    def install(registry)
      feature = registry.feature(FEATURE_ID, :contract_version => Declarations::CONTRACT_VERSION)
      feature.query(STATE, :description => "The active Colour-by mode, every registered mode and the legend.",
                           :params => { "type" => "object", "additionalProperties" => false, "properties" => {} },
                           :result => STATE_RESULT, :examples => [{}]) do |request|
        state(request.session)
      end
      INVALIDATING_EVENTS.each do |kind|
        feature.on_host_event(kind) { |session| self.for(session).invalidate! }
      end
      feature.on_host_event(:tags_changed) { |session| self.for(session).invalidate!(:force => true) }
    end

    # This Model's Colour-by state, created inert on first reach. Nothing draws until a mode is on.
    def for(session)
      session.feature_state(:colour_by) { Service.new(session) }
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
    # (face-assignment PRD Q12). Colour-by itself is off at rest.
    def remembered_mode
      name = Preferences.colour_by_mode
      name && Registry.current.colour_modes.key?(name) ? name : nil
    end
  end
end
