# frozen_string_literal: true

require "json"

module PhComposer
  # One running Python runtime: a loopback asset server and the dialog that loads the runtime page
  # (html/runtime/) from it. Nothing starts one when the extension loads or the panel opens; in this
  # build the export task and the development probe start it only when requested.
  #
  # It is bound to one Model session by id and holds no reference to the Model or the session, so a
  # closed Model is never kept alive by it. `stop` releases the dialog, the server, its pump timer and
  # its connections, and reports what was running and what still is.
  class RuntimeHost
    PAGE = "html/runtime/index.html"
    CALLBACK = "ph_composer_runtime"
    INBOUND = %w[runtime.ready runtime.result runtime.translation].freeze

    attr_reader :session_id, :state, :results

    # `on_message` receives each page message as `(type, payload)`. The factories exist for tests.
    def initialize(session_id:, on_message: nil, server: nil, dialog_factory: nil)
      @session_id = session_id.to_s
      @on_message = on_message
      @server = server || AssetServer.new(ROOT)
      @dialog_factory = dialog_factory || method(:build_dialog)
      @state = "idle"
      @results = []
      @queued = []
    end

    # Opens the runtime page. Refuses a payload whose files differ from the manifest before serving any.
    def start
      raise ArgumentError, "A runtime starts once; build a new one." unless @state == "idle"
      raise RuntimeManifest::Invalid, "runtime assets differ from the manifest: #{@server.invalid_assets.join(', ')}" \
        unless @server.invalid_assets.empty?

      @server.start
      @dialog = @dialog_factory.call
      @dialog.add_action_callback(CALLBACK) { |_context, raw| receive(raw) }
      @dialog.set_on_closed do
        stop
        @on_message&.call("runtime.closed", "session" => @session_id)
      end
      @dialog.set_url(@server.url(PAGE, "session" => @session_id))
      @dialog.show
      @state = "loading"
      self
    rescue StandardError
      stop
      raise
    end

    # Asks the page for one probe: boot if needed, then one round trip through the translation package.
    # A probe sent before the page is ready waits for it.
    def probe(request_id, deadline_ms: RuntimeGate.fetch("boot_deadline_ms"))
      message = { "type" => "runtime.probe", "payload" => { "request_id" => request_id, "deadline_ms" => deadline_ms } }
      @state == "ready" ? deliver(message) : @queued << message
      request_id
    end

    def translate(request_id, document, deadline_ms: RuntimeGate.fetch("boot_deadline_ms"))
      message = { "type" => "runtime.translate", "payload" => { "request_id" => request_id,
                                                                "document" => document, "deadline_ms" => deadline_ms } }
      @state == "ready" ? deliver(message) : @queued << message
      request_id
    end

    # Stops everything this runtime started and reports it. `before` is what was live when stop began;
    # `after` must be all zero and `dialog_open` false, or something outlived the runtime.
    def stop
      # Closing the dialog runs its on-closed handler, which calls stop again: that call does nothing.
      return @stopped if @stopped || @stopping

      @stopping = true
      before = resources
      state_at_stop = @state
      @state = "stopped"
      dialog = @dialog
      begin
        close(dialog) if dialog
      ensure
        # The server stops whatever the dialog did, and the report measures the dialog itself.
        @server.stop
        @queued.clear
        dialog_open = dialog.respond_to?(:visible?) && dialog.visible? ? true : false
        @dialog = nil unless dialog_open
        @stopped = { "state_at_stop" => state_at_stop, "before" => before, "after" => resources,
                     "dialog_open" => dialog_open, "session" => @session_id }
      end
      @stopped
    end

    def stopped?
      @state == "stopped"
    end

    # Counts of what this runtime holds: its dialog and the server's timer, acceptor, clients and socket.
    def resources
      @server.snapshot.fetch("resources").merge("dialog" => @dialog ? 1 : 0)
    end

    def server_snapshot
      @server.snapshot
    end

    private

    # A page or window that cannot be told to stop must not keep the server alive: each step is logged
    # and the next still runs.
    def close(dialog)
      begin
        deliver_to(dialog, "type" => "runtime.stop", "payload" => {})
      rescue StandardError => error
        Diagnostics.exception("runtime_stop_message", error)
      end
      dialog.close
    rescue StandardError => error
      Diagnostics.exception("runtime_dialog_close", error)
    end

    def build_dialog
      UI::HtmlDialog.new(
        :dialog_title => "#{EXTENSION_NAME} runtime", :preferences_key => "#{EXTENSION_ID}.runtime",
        :scrollable => false, :resizable => true, :width => 420, :height => 160, :style => UI::HtmlDialog::STYLE_UTILITY
      )
    end

    def receive(raw)
      return if stopped?

      message = JSON.parse(raw.to_s)
      type = message["type"]
      return unless INBOUND.include?(type) && message["payload"].is_a?(Hash)

      payload = message["payload"]
      return unless payload["session"] == @session_id

      ready if type == "runtime.ready"
      @results << payload if type == "runtime.result"
      @on_message&.call(type, payload)
    rescue StandardError => error
      Diagnostics.exception("runtime_message", error)
    end

    def ready
      @state = "ready"
      @queued.shift(@queued.length).each { |message| deliver(message) }
    end

    def deliver(message)
      deliver_to(@dialog, message)
    end

    def deliver_to(dialog, message)
      dialog.execute_script("window.PhComposerRuntime && PhComposerRuntime.receive(#{JSON.generate(message)})")
    end
  end
end
