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
    # Host events after which the shown Model's snapshot is stale. A new session matters where activation
    # is not reported (SketchUp documents onActivateModel for macOS only).
    REFRESH_EVENTS = %i[
      session_created transaction_committed transaction_undone transaction_redone active_path_changed
    ].freeze
    MAX_PENDING_NOTICES = 20
    SESSION_CHANGED = "The panel now shows a different Model."
    # Export startup failure is reported before a task or a Model operation begins.
    EXPORT_FAILED = Outcome.build(
      "failed", "operation.failed", "Export could not start. Nothing was written.", "none", nil
    ).freeze
    # A view command reaches no record and opens no operation, so a failure there leaves the Model as it was.
    VIEW_FAILED = Outcome.build(
      "failed", "operation.failed", "The panel could not change what the viewport shows.", "none", nil
    ).freeze
    # The panel could not tell whether an action ran, so it does not claim the Model is unchanged.
    UNEXPECTED = Outcome.build(
      "failed", "operation.failed",
      "The panel could not complete that request. Check the Model before continuing.", "unknown", nil
    ).freeze

    class << self
      def install
        return if @installed

        Sessions.on_refresh { |session| refresh(session) }
        Sessions.on_notice { |session, message, tone| notice(session, message, tone) }
        REFRESH_EVENTS.each do |kind|
          Sessions.on_host_event(kind) { |session| session.request_refresh if showing?(session) }
        end
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

      # Development only: a development composition entry (tools/examples/) adds a script that runs in the
      # page each time it opens, after the kit has started. Shipping features declare their modules in
      # html/ instead; nothing in the shipping build calls this.
      def add_development_script(path)
        development_scripts << File.expand_path(path) unless development_scripts.include?(File.expand_path(path))
      end

      # Republishes the shown Model's snapshot when `session` is that Model.
      def refresh(session)
        publish_snapshot(session) if showing?(session)
      end

      # Whether an open, started panel shows this session's Model.
      def showing?(session)
        @ready && !session.nil? && session.equal?(Sessions.current)
      end

      # A session's notice reaches the open panel if it shows that session; otherwise it waits, bounded,
      # until the panel next shows it. It never opens the panel.
      def notice(session, message, tone)
        item = { "session" => session.id, "message" => message.to_s, "tone" => tone.to_s }
        if showing?(session)
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
      rescue PanelMessages::Malformed => error
        publish("panel.failure", "message" => error.message)
      else
        handle(type, payload)
      end

      # A request the page is waiting on is always answered in its own shape, so the view that asked can
      # settle; an unexpected error is logged and answered as a failure.
      def handle(type, payload)
        case type
        when "panel.ready" then ready
        when "action.invoke" then invoke(payload)
        when "view.invoke" then view(payload)
        when "preferences.set" then set_preference(payload)
        when "export.start", "export.preflight", "export.status", "export.cancel", "export.latest"
          export(type, payload)
        end
      rescue StandardError => error
        Diagnostics.exception("panel_message", error)
        case type
        when "action.invoke" then publish_result(payload, UNEXPECTED)
        when "view.invoke" then publish_view(payload, VIEW_FAILED)
        when "export.start", "export.preflight", "export.status", "export.cancel", "export.latest"
          publish_export(payload, EXPORT_FAILED)
        when "preferences.set"
          publish_preferences(payload, "failed", "The display preference could not be saved.")
        else publish("panel.failure", "message" => "The panel could not complete that request.")
        end
      end

      def ready
        @ready = true
        development_scripts.each { |path| run_development_script(path) }
        session = Sessions.current
        return unless session

        publish_snapshot(session)
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
          publish_result(payload, outcome)
          # The page was showing another Model than the active one: bring it up to date and say why the
          # change it sent was not applied.
          return unless session

          publish_snapshot(session)
          return publish("panel.notice", "session" => session.id, "message" => outcome.fetch("message"),
                                         "tone" => "warning")
        end

        outcome = API.invoke(
          :context => context_for(session), :name => payload["name"].to_s, :params => payload.fetch("params", {}),
          :request => { "sequence" => next_sequence(session), "expected_revision" => payload["expected_revision"] }
        )
        session.refresh.cancel
        publish_snapshot(session)
        publish_result(payload, outcome)
      end

      # Selection, camera and the active Colour-by mode, for the Model the panel shows. A section may read
      # what the command changed, so a snapshot follows; the revision does not move, so nothing the page has
      # in flight goes stale.
      #
      # Changing the selection raises a host event, which schedules a refresh that would publish the same
      # snapshot again a tick later: cancelling it first keeps one viewport click to one Model read. A
      # refusal publishes nothing, because a section that refused with it would replace good data with the
      # same refusal.
      def view(payload)
        session = Sessions.current
        unless session && payload["session"] == session.id
          return publish_view(payload, Outcome.refused("session.inactive", SESSION_CHANGED, :revision => nil))
        end

        outcome = API.view(:context => context_for(session), :name => payload["name"].to_s,
                           :params => payload.fetch("params", {}))
        if outcome.fetch("status") == "completed"
          session.refresh.cancel
          publish_snapshot(session)
        end
        publish_view(payload, outcome)
      end

      def publish_view(payload, outcome)
        publish("view.result", "request_id" => payload["request_id"], "session" => payload["session"],
                               "outcome" => outcome)
      end

      # Export acts on the Model the panel shows, like an action, but it is the shell's command: it opens a
      # native destination dialog, so it never runs inside a Model operation.
      def export(type, payload)
        session = Sessions.current
        outcome = if session && payload["session"] == session.id
                    export_request(type, payload, session)
                  else
                    Outcome.refused("session.inactive", SESSION_CHANGED, :revision => nil)
                  end
        publish_export(payload, outcome)
      end

      def export_request(type, payload, session)
        context = context_for(session)
        case type
        when "export.start"
          Export::Workflow.start(session, :context => context, :repairs => payload.fetch("repairs", []),
                                 :request => -> { { "sequence" => next_sequence(session),
                                                   "expected_revision" => session.revision } })
        when "export.preflight" then API.export_preflight(:context => context)
        when "export.status" then API.export_status(:context => context, :task_id => payload["task_id"])
        when "export.cancel" then API.cancel_export(:context => context, :task_id => payload["task_id"])
        when "export.latest" then API.latest_export(:context => context)
        end
      end

      def publish_export(payload, outcome)
        publish("export.result", "request_id" => payload["request_id"], "session" => payload["session"],
                                 "outcome" => outcome)
      end

      # A snapshot that cannot be built is logged and skipped; the result that follows still settles the
      # request, and the next refresh tries again.
      def publish_snapshot(session)
        publish("panel.snapshot", snapshot(session))
      rescue StandardError => error
        Diagnostics.exception("panel_snapshot", error)
      end

      def run_development_script(path)
        @dialog.execute_script(File.read(path))
      rescue StandardError => error
        Diagnostics.exception("panel_development_script", error)
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
        @contexts[session.id] ||= API.connect(:session_id => session.id,
                                             :capabilities => %w[read view model_write export])
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
