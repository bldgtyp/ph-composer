# frozen_string_literal: true

module PhComposer
  module ColourBy
    # What a mode's projection returns, one per entity it paints. `transform` maps the entity's own
    # contents to world. `value` is what the mode groups and colours by; nil means the entity carries
    # no record yet, which every mode draws the same way. `label` is the legend's wording for that
    # value, defaulting to the value itself. A projection that knows a value is only half filled in
    # says so with `state: :incomplete`; the service paints that amber in every mode, because only
    # the owning feature knows what its own record still needs.
    Entry = Struct.new(:entity, :transform, :value, :label, :state, keyword_init: true)

    # One legend row: a colour, what it means, how many entities carry it, and which of the three
    # states it is in (`classified`, `incomplete` or `unclassified`).
    Row = Struct.new(:value, :label, :colour, :count, :state, keyword_init: true)

    # One Model's Colour-by state: which mode is active, the cached drawing for it, and the overlay
    # that draws it. Reached through `ColourBy.for(session)`; the session holds it as generic feature
    # state and names no mode.
    #
    # The cache is whole and keyed on the session revision, which advances on a committed change,
    # Undo, Redo and an edit-path change (CONTRACTS.md C3). A tag being hidden changes what may be
    # painted without necessarily advancing that revision, so `tags_changed` forces a rebuild.
    # Rebuilding happens when the invalidating event arrives, never inside `draw`: a draw callback
    # repairs nothing (context/TECH_STACK.md).
    #
    # The PRD also names a scene change as an invalidator and this does not cover it: no observer
    # the session subscribes to reports one. What a scene activation actually does to the drawing is
    # a question for the host gate, with the walkthrough written to ask it; if it leaves the drawing
    # stale, the mechanism is a frame change observer.
    class Service
      attr_reader :mode_name, :rows, :fills, :outlines, :unclassified_outlines
      # How many times the drawing has been rebuilt for this Model. The host walkthrough reads it to
      # tell an invalidating event that fired from one that did not.
      attr_reader :rebuilds

      def initialize(session)
        @session = session
        @rebuilds = 0
        clear
      end

      def active?
        !@mode_name.nil?
      end

      def mode
        @mode_name && Registry.current.colour_modes[@mode_name]
      end

      # Turns a mode on, remembering it as the one the user last chose. Nothing about the Model
      # changes: no record is written, no material is assigned and no operation opens.
      #
      # `remember: false` turns a mode on without recording the choice. The Classify tool forces
      # Colour-by on while it is active (PRD Q12), and what the tool forced is not what the user
      # chose, so it must not displace the remembered mode when the tool ends.
      def activate(name, remember: true)
        declaration = Registry.current.colour_modes[name]
        raise UserError, "There is no Colour-by mode named #{name}." unless declaration

        @mode_name = name
        Preferences.set("colour_by_mode", name) if remember
        attach_overlay
        rebuild
        self
      end

      def deactivate
        clear
        detach_overlay
        invalidate_view
        self
      end

      # The drawing is stale: rebuild it now, while the host event that invalidated it is being
      # handled, and repaint. Does nothing while no mode is active. Several events can report one
      # user action, so a rebuild at a revision already drawn is skipped; `force` is for what the
      # revision does not cover, such as a tag being hidden.
      def invalidate!(force: false)
        return self unless active?
        return self if !force && @built_revision == @session.revision

        rebuild
        self
      end

      def detach
        clear
        detach_overlay
        self
      end

      def legend
        {
          "mode" => @mode_name, "label" => mode&.label, "entity_kind" => mode&.entity_kind,
          "rows" => rows.map do |row|
            { "value" => row.value, "label" => row.label, "colour" => row.colour.dup,
              "count" => row.count, "state" => row.state.to_s }
          end
        }
      end

      private

      def clear
        @mode_name = nil
        @rows = []
        @fills = {}
        @outlines = {}
        @unclassified_outlines = []
        @built_revision = nil
      end

      def rebuild
        declaration = mode
        return deactivate unless declaration

        rows = {}
        fills = Hash.new { |table, colour| table[colour] = [] }
        outlines = Hash.new { |table, colour| table[colour] = [] }
        unclassified = []
        begin
          Array(declaration.projection.call(@session.model)).each do |entry|
            add_entry(declaration, entry, rows, fills, outlines, unclassified)
          end
        rescue StandardError => error
          # A rebuild runs inside the host observer that reported the change, and an error there
          # aborts every later subscriber for that event (session/sessions.rb). A mode that cannot
          # read the Model turns itself off instead of taking the rest of the extension with it.
          return failed(declaration, error)
        end
        @rows = order(declaration, rows.values)
        # The default block is only for building; a reader must not create a batch by asking for one.
        @fills = settled(fills)
        @outlines = settled(outlines)
        @unclassified_outlines = unclassified
        @built_revision = @session.revision
        @rebuilds += 1
        invalidate_view
      end

      # The mode is off, the overlay is gone and the user is told which mode stopped drawing.
      def failed(declaration, error)
        Diagnostics.log("colour_by_failed", "operation" => declaration.name, "error_class" => error.class.name)
        deactivate
        @session.notice("#{declaration.label} could not be drawn, so Colour by is off.", :tone => :warning)
        self
      end

      def settled(batches)
        batches.each_with_object({}) { |(colour, points), table| table[colour] = points }
      end

      def add_entry(declaration, entry, rows, fills, outlines, unclassified)
        state, colour = paint(declaration, entry)
        row = rows[[entry.value, state]] ||= Row.new(:value => entry.value, :label => label_for(entry),
                                                     :colour => colour, :count => 0, :state => state)
        row.count += 1
        triangles, segments = Tessellation.call(entry.entity, entry.transform)
        if state == :unclassified
          unclassified.concat(segments)
        else
          fills[colour].concat(triangles)
          outlines[colour].concat(segments)
        end
      end

      # The three states every mode shares: no record, a record the mode cannot colour, and a value
      # the mode has a hue for.
      def paint(declaration, entry)
        return [:unclassified, Palette::UNCLASSIFIED] if entry.value.nil?
        return [:incomplete, Palette::INCOMPLETE] if entry.state == :incomplete

        colour = declaration.colours.call(entry.value)
        colour ? [:classified, colour] : [:incomplete, Palette::INCOMPLETE]
      end

      def label_for(entry)
        text = entry.label || entry.value
        text.nil? ? "Unclassified" : text.to_s
      end

      def order(declaration, rows)
        return rows.sort_by(&declaration.sort) if declaration.sort

        rows.sort_by { |row| [row.state == :unclassified ? 1 : 0, -row.count, row.label] }
      end

      def attach_overlay
        return unless live_model

        @overlay ||= Overlay.new(self)
        live_model.overlays.add(@overlay)
      end

      # A closed Model still answers `respond_to?(:overlays)`, and reading them raises. The session
      # is already marked detached by the time feature state is torn down, so the Model itself is
      # what decides whether there is anything left to remove the overlay from.
      def detach_overlay
        overlay = @overlay
        @overlay = nil
        return unless overlay && live_model

        live_model.overlays.remove(overlay)
      end

      def live_model
        model = @session.model
        return nil unless model.respond_to?(:overlays)

        model.respond_to?(:valid?) && !model.valid? ? nil : model
      end

      def invalidate_view
        model = live_model
        view = model.respond_to?(:active_view) ? model.active_view : nil if model
        view&.invalidate
      end
    end
  end
end
