# frozen_string_literal: true

require "securerandom"
require "time"

module PhComposer
  # What Help & Diagnostics shows and what a support report holds (context/TECH_STACK.md, "Help &
  # Diagnostics"). Every value here is read when asked for: nothing starts Python, opens a listener,
  # reads a Model or writes anything.
  #
  # A report is one plain-text capture: a header a maintainer reads, then the newest log lines, each
  # rebuilt from the fields the log accepts. The capture is built once and kept under its id, so the
  # preview, the copy and the saved file are the same bytes.
  module SupportReport
    FORMAT = 1
    MAX_LOG_BYTES = 256 * 1024
    MAX_PROBLEMS = 20
    SUPPORTED_FLOOR = 23
    SUPPORTED_TEXT = "SketchUp 2023 or later on macOS"
    OMITTED = "Model geometry and names, file paths, library contents, request and response data, " \
              "screenshots, tokens, environment variables and project data"
    # What a problem line says, by the event that recorded it; the event name itself stays in the log.
    PROBLEMS = [
      [/\Aoperation_failed\z/, "An edit or read could not be completed"],
      [/\Apanel_message\z/, "The panel could not complete a request"],
      [/\Apanel_/, "The panel could not show part of a page"],
      [/\Aexport_/, "Export could not finish"],
      [/\Aextension_load_failed\z/, "PH-Composer did not load"]
    ].freeze
    OTHER_PROBLEM = "An internal error was recorded"

    module_function

    # Version, build, host and log health, as the window's first view shows them.
    def about
      { "version" => VERSION, "build" => BuildIdentity.build, "development" => BuildIdentity.development?,
        "commit" => BuildIdentity.commit, "manifest" => BuildIdentity.manifest, "host" => host,
        "log" => Diagnostics.health }
    end

    def host
      version = Sketchup.version.to_s
      major = version.split(".").first.to_i
      platform = Sketchup.platform == :platform_osx ? "macOS" : "Windows"
      { "sketchup" => version, "platform" => platform, "ruby" => RUBY_VERSION,
        "supported" => platform == "macOS" && major >= SUPPORTED_FLOOR, "supported_text" => SUPPORTED_TEXT }
    end

    # The newest failures the log holds, newest first, each by its time, words and incident reference.
    def problems
      records = log_lines.first.filter_map { |line| parse(line) }
      records.select { |record| record["severity"] == "error" }.last(MAX_PROBLEMS).reverse.map do |record|
        { "time" => record["timestamp"], "label" => problem_label(record["event"].to_s),
          "incident" => record["incident"] }
      end
    end

    # A new capture, kept under its id until the next one replaces it.
    def capture(incident: nil)
      lines, omitted, unreadable = log_lines
      id = SecureRandom.hex(8)
      captured_at = Time.now.utc.iso8601
      text = header(captured_at, incident, lines, omitted, unreadable).join("\n") + "\n--- log ---\n" + lines.join
      @capture = { "capture_id" => id, "captured_at" => captured_at, "text" => text }.freeze
    end

    # The bytes a capture id names, or nil when that capture is no longer the current one.
    def text(capture_id)
      @capture && @capture["capture_id"] == capture_id ? @capture["text"] : nil
    end

    def reset_for_test
      @capture = nil
    end

    # Sanitized lines, how many earlier ones were left out, and the read error's class when the files
    # could not be read, in which case this session's in-memory lines stand in.
    def log_lines
      lines, omitted = Diagnostics.recent_lines(MAX_LOG_BYTES)
      [sanitize(lines), omitted, nil]
    rescue StandardError => error
      [sanitize(Diagnostics.tail), 0, error.class.name]
    end

    def sanitize(lines)
      lines.filter_map { |line| Diagnostics.sanitized(line) }.map { |line| "#{line}\n" }
    end

    def parse(line)
      JSON.parse(line)
    rescue JSON::ParserError
      nil
    end

    def problem_label(event)
      PROBLEMS.find { |pattern, _label| pattern.match?(event) }&.last || OTHER_PROBLEM
    end

    def header(captured_at, incident, lines, omitted, unreadable)
      details = about
      log = details["log"]
      [
        "PH-Composer support report", "Report format: #{FORMAT}", "Captured: #{captured_at}",
        "Version: #{VERSION}", "Build: #{details['build']}#{" (commit #{details['commit']})" if details['commit']}",
        "Runtime manifest: #{details['manifest']}",
        "SketchUp: #{details.dig('host', 'sketchup')} on #{details.dig('host', 'platform')}, Ruby #{RUBY_VERSION}",
        "Supported host: #{details.dig('host', 'supported') ? 'yes' : 'no'} (#{SUPPORTED_TEXT})",
        "Log: #{log['writing'] ? 'writing' : "not writing (#{log['last_error']})"}",
        "Incident: #{Diagnostics::REFERENCE.match?(incident.to_s) ? incident : 'none selected'}",
        "Events: #{events_line(lines, omitted, unreadable)}",
        "Omitted: #{OMITTED}"
      ]
    end

    def events_line(lines, omitted, unreadable)
      return "the log could not be read (#{unreadable}); showing this session's #{lines.length} events" if unreadable
      return "none recorded; an empty log does not show that nothing failed" if lines.empty?

      first, last = [lines.first, lines.last].map { |line| parse(line)&.fetch("timestamp", nil) }
      text = "#{lines.length} from #{first} to #{last}"
      omitted.positive? ? "#{text}; #{omitted} earlier lines left out" : text
    end
  end

  on_reset("support_report") { SupportReport.reset_for_test }
end
