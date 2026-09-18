# frozen_string_literal: true

module PhComposer
  # The HtmlDialog panel: one client of the public interface (CONTRACTS.md C2), showing the active
  # Model. It connects to each session it shows with its own caller handle and gives its mutations
  # their sequence numbers; the page's request ids only correlate a result with the view that asked.
  #
  # The panel never owns Model behavior. Features render into it through snapshot sections, and a
  # programmatic caller never opens or raises it.
  module Panel
    WIDTH = 1280
    HEIGHT = 800
    MIN_WIDTH = 360
    MIN_HEIGHT = 520
    PAGE = File.join(ROOT, "html", "index.html")
    # Host events after which the shown Model's snapshot is stale.
    REFRESH_EVENTS = %i[transaction_committed transaction_undone transaction_redone active_path_changed].freeze
    MAX_PENDING_NOTICES = 20
    SESSION_CHANGED = "The panel now shows a different Model."

    class << self
      def install
        return if @installed

        Sessions.on_refresh { |session| refresh(session) }
        Sessions.on_notice { |session, message, tone| notice(session, message, tone) }
        REFRESH_EVENTS.each { |kind| Sessions.on_host_event(kind) { |session| session.request_refresh } }
        @installed = true
      end

      # Opens the panel, or brings an open one forward. Only a user command calls this.
      def show
        if @dialog
          @dialog.bring_to_front
        else
          @dialog = build_dialog
          @dialog.show
        end
        @dialog
      end

      def open?
        !@dialog.nil?
      end

      # A development composition entry adds a script that runs in the page each time it opens, after
      # the kit has started. Shipping features declare their modules in html/ instead.
      def add_development_script(path)
        development_scripts << File.expand_path(path) unless development_scripts.include?(File.expand_path(path))
      end

      # Republishes the shown Model's snapshot when `session` is that Model.
      def refresh(session)
        return unless @ready && session && session.equal?(Sessions.current)

        publish("panel.snapshot", snapshot(session))
      end

      # A session's notice reaches the open panel if it shows that session; otherwise it waits, bounded,
      # until the panel next shows it. It never opens the panel.
      def notice(session, message, tone)
        item = { "session" => session.id, "message" => message.to_s, "tone" => tone.to_s }
        if @ready && session.equal?(Sessions.current)
          publish("panel.notice", item)
        else
          pending_notices << item
          pending_notices.shift while pending_notices.length > MAX_PENDING_NOTICES
        end
      end

      def reset_for_test
        @dialog&.close
        @dialog = nil
        @ready = false
        @contexts = {}
        @sequences = {}
        @pending_notices = []
        @development_scripts = []
      end

      private

      def build_dialog
        dialog = UI::HtmlDialog.new(
          :dialog_title => EXTENSION_NAME, :preferences_key => "#{EXTENSION_ID}.panel", :scrollable => true,
          :resizable => true, :width => WIDTH, :height => HEIGHT, :min_width => MIN_WIDTH,
          :min_height => MIN_HEIGHT, :style => UI::HtmlDialog::STYLE_WINDOW
        )
        dialog.set_file(PAGE)
        # Bound to this dialog: a message from a page that has since closed is ignored.
        dialog.add_action_callback("ph_composer_message") { |_context, raw| receive(dialog, raw) }
        dialog.set_on_closed { closed(dialog) }
        @ready = false
        dialog
      end

      def closed(dialog)
        return unless @dialog.equal?(dialog)

        @dialog = nil
        @ready = false
      end

      def receive(dialog, raw)
        return unless @dialog.equal?(dialog)

        type, payload = PanelMessages.parse(raw)
        case type
        when "panel.ready" then ready
        when "action.invoke" then invoke(payload)
        when "preferences.set" then set_preference(payload)
        end
      rescue PanelMessages::Malformed => error
        publish("panel.failure", "message" => error.message)
      rescue StandardError => error
        Diagnostics.exception("panel_message", error)
        publish("panel.failure", "message" => "The panel could not complete that request.")
      end

      def ready
        @ready = true
        development_scripts.each { |path| @dialog.execute_script(File.read(path)) }
        session = Sessions.current
        return unless session

        publish("panel.snapshot", snapshot(session))
        delivered, waiting = pending_notices.partition { |item| item["session"] == session.id }
        @pending_notices = waiting
        delivered.each { |item| publish("panel.notice", item) }
      end

      # The panel acts only on the Model it shows. The result follows the authoritative snapshot, so the
      # page confirms an edit against values the Model already holds (CONTRACTS.md C3).
      def invoke(payload)
        session = Sessions.current
        unless session && payload["session"] == session.id
          outcome = Outcome.refused("session.inactive", SESSION_CHANGED, :revision => nil, :mutation => true)
          return publish_result(payload, outcome)
        end

        outcome = API.invoke(
          :context => context_for(session), :name => payload["name"].to_s, :params => payload.fetch("params", {}),
          :request => { "sequence" => next_sequence(session), "expected_revision" => payload["expected_revision"] }
        )
        session.refresh.cancel
        publish("panel.snapshot", snapshot(session))
        publish_result(payload, outcome)
      end

      def publish_result(payload, outcome)
        publish("action.result", "request_id" => payload["request_id"], "session" => payload["session"],
                                 "outcome" => outcome)
      end

      def set_preference(payload)
        Preferences.set(payload["key"], payload["value"], :scope => payload["scope"], :system => payload["system"])
        publish_preferences(payload, "completed", "Display preference saved.")
      rescue UserError => error
        publish_preferences(payload, "refused", error.message)
      end

      def publish_preferences(payload, status, message)
        publish("preferences.result", "request_id" => payload["request_id"], "status" => status,
                                      "message" => message, "preferences" => Preferences.snapshot)
      end

      def snapshot(session)
        Snapshot.build(context_for(session)).merge(
          "product" => EXTENSION_NAME, "version" => VERSION, "file_name" => File.basename(session.model.path.to_s),
          "edit_path" => edit_path(session.model), "preferences" => Preferences.snapshot
        )
      end

      # The names of the groups and components the user has opened for editing, outermost first.
      def edit_path(model)
        Array(model.active_path).map do |instance|
          name = instance.respond_to?(:name) ? instance.name.to_s : ""
          name = instance.definition.name.to_s if name.empty? && instance.respond_to?(:definition)
          name
        end
      end

      # The panel's caller handle for a session, issued on first use and kept while the session lives.
      def context_for(session)
        @contexts ||= {}
        @contexts.delete_if { |id, _context| Sessions.find(id).nil? }
        @contexts[session.id] ||= API.connect(:session_id => session.id)
      end

      def next_sequence(session)
        @sequences ||= {}
        @sequences[session.id] = @sequences.fetch(session.id, 0) + 1
      end

      def publish(type, payload)
        @dialog&.execute_script(PanelMessages.script(type, payload))
      end

      def pending_notices
        @pending_notices ||= []
      end

      def development_scripts
        @development_scripts ||= []
      end
    end
  end

  on_reset("panel") { Panel.reset_for_test }
end
