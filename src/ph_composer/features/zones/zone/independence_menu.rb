# frozen_string_literal: true

module PhComposer
  module Zones
    # The native client for Make Zone independent, offered on one selected Zone Group whose identity
    # another occurrence also holds. It reads the same public row, previews, asks once and invokes with
    # the preview's revision and digest; every check and write belongs to the registered action, as it
    # does when a script calls it with the panel closed.
    module IndependenceMenu
      ACTION = "#{FEATURE_ID}.make_independent"
      LABEL = "Make Zone independent…"

      module_function

      def install(feature)
        feature.menu_item("#{FEATURE_ID}.make_independent_menu", :label => LABEL, :menu => "Repair",
                                                                 :available => ->(read) {
                                                                                 available?(read.session)
                                                                               }) do |session|
          session.feature_state(:zones_independence_menu) { Client.new(session) }.run
        end
      end

      # A cheap read: one selected Group carrying a Zone record. The client asks the public read for
      # the rest, and a refusal there is shown rather than hidden.
      def available?(session)
        selected = session.model.selection.to_a
        selected.length == 1 && selected.first.is_a?(Sketchup::Group) && !ZONE_STORE.read(selected.first).nil?
      end

      class Client
        def initialize(session)
          @session = session
          @context = API.connect(:session_id => session.id)
          @sequence = 0
        end

        def run
          row = selected_row
          return unless row

          independence = row["independence"]
          return UI.messagebox("This Zone already has an identity of its own. Nothing was changed.") unless independence
          return UI.messagebox(independence.fetch("reason")) unless independence.fetch("available")

          params = { "zone_path" => row.dig("reference", "zone_path") }
          preview = API.preview(:context => @context, :name => ACTION, :params => params)
          return show(preview) unless preview["status"] == "completed"
          return unless UI.messagebox(review(row, preview.fetch("value")), MB_YESNO) == IDYES
          return UI.messagebox("The active Model changed. Start again in its Model.") unless
            Sketchup.active_model.equal?(@session.model)

          @sequence += 1
          show(API.invoke(:context => @context, :name => ACTION, :params => params,
                          :request => { "sequence" => @sequence, "expected_revision" => preview.fetch("revision"),
                                        "proposal_digest" => preview.fetch("proposal_digest") }))
        rescue StandardError => error
          UI.messagebox("Make Zone independent could not complete: #{error.message}")
        end

        private

        def selected_row
          group = @session.model.selection.to_a.first
          path = Occurrences.active_path(@session.model) + [group.persistent_id]
          result = API.query(:context => @context, :name => "#{FEATURE_ID}.list", :params => { "paths" => [path] })
          unless result["status"] == "completed"
            show(result)
            return nil
          end

          row = result.dig("value", "zones").first
          UI.messagebox("The selected Group is not a Zone occurrence this read can name.") unless row
          row
        end

        def review(row, value)
          lines = ["The selected \"#{row.dig('values', 'name')}\" will get its own Faces and a new identity. " \
                   "The other occurrence keeps the current identity."]
          retired = value.fetch("retired_pairs")
          lines << "#{retired} Surface pair(s) on the selected Zone's Faces will be retired; run Solve " \
                   "adjacencies again." if retired.positive?
          lines << "Proceed?"
          lines.join("\n\n")
        end

        def show(result)
          UI.messagebox(result.fetch("message"))
        end
      end
    end
  end
end
