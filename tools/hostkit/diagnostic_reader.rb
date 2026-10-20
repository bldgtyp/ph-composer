# frozen_string_literal: true

require "json"
require "securerandom"

# Development only, never shipped: a bounded, filtered read of the extension's diagnostic log for development
# probes, through the development bridge (`host_bridge.py diagnostics`). It reads the log's own projection,
# `PhComposer::Diagnostics.tail_window`, and copies each line through `Diagnostics.sanitized`, the same
# reduction the support report uses, so a read returns only the fields and values the log accepts: never log
# file bytes, never the logger's state, never a path.
#
# A cursor names this process and the number of the last line returned (`<process>:<number>`). Reading after
# it returns only later lines. A cursor from another process (SketchUp restarted) or one whose next lines
# were evicted from the bounded tail, or cleared, says so instead of implying a complete history.
module PhComposerDiagnosticReader
  SCHEMA = 1
  KIND = "ph-composer.diagnostic-read"
  SUPPORTED_LOG_SCHEMAS = [1].freeze
  SEVERITIES = %w[info warning error].freeze
  DEFAULT_LIMIT = 50
  MAX_LIMIT = 100
  MAX_EVENTS_BYTES = 128 * 1024
  CURSOR = /\A(?<process>\h{8}):(?<number>\d{1,12})\z/.freeze
  FILTERS = {
    "session" => PhComposer::Diagnostics::SESSION, "incident" => PhComposer::Diagnostics::INCIDENT,
    "run_id" => PhComposer::Diagnostics::RUN, "severity" => /\A(?:info|warning|error)\z/.freeze
  }.freeze

  class << self
    # This process's identity for cursors: random, so a restarted SketchUp never matches an old cursor.
    def process
      @process ||= SecureRandom.hex(4)
    end

    # One read. `filters` takes `session`, `incident`, `run_id`, `severity` (the least severe to include;
    # a line without one is info), `cursor` and `limit`. Answers a detached Hash; nothing is mutated.
    def read(filters = {})
      filters = filters.transform_keys(&:to_s)
      problem = refusal(filters)
      return document(filters, "refused", problem) if problem

      window = PhComposer::Diagnostics.tail_window
      position = resume(filters["cursor"], window.fetch("first"))
      lines = window.fetch("lines")
      start = [position.fetch("from") - window.fetch("first"), 0].max
      collect(filters, lines, start, window.fetch("first")).merge(
        "cursor_state" => position.fetch("state"), "gap" => position["gap"], "history" => history(window)
      ).then { |selected| document(filters, "read", nil).merge(selected) }
    end

    private

    def refusal(filters)
      unknown = filters.keys - FILTERS.keys - %w[cursor limit]
      return "unknown filter #{unknown.first[0, 32]}" unless unknown.empty?
      unless SUPPORTED_LOG_SCHEMAS.include?(PhComposer::Diagnostics::SCHEMA)
        return "the log's schema #{PhComposer::Diagnostics::SCHEMA} is not one this reader supports"
      end

      FILTERS.each do |name, pattern|
        next unless filters.key?(name)
        return "#{name} is not in the form the extension generates" unless pattern.match?(filters[name].to_s)
      end
      return "cursor is not one this reader issued" if filters.key?("cursor") && !CURSOR.match?(filters["cursor"].to_s)

      limit = filters.fetch("limit", DEFAULT_LIMIT)
      "limit must be an integer from 1 to #{MAX_LIMIT}" unless limit.is_a?(Integer) && limit.between?(1, MAX_LIMIT)
    end

    # Where to resume, and why it is not exactly after the cursor when it cannot be.
    def resume(cursor, first)
      return { "from" => first, "state" => "start" } unless cursor

      match = CURSOR.match(cursor)
      return { "from" => first, "state" => "process_restarted", "gap" => "unknown" } if match[:process] != process

      after = match[:number].to_i + 1
      return { "from" => after, "state" => "continued" } if after >= first

      { "from" => first, "state" => "evicted", "gap" => { "lines" => first - after } }
    end

    def collect(filters, lines, start, first)
      minimum = SEVERITIES.index(filters.fetch("severity", "info"))
      limit = filters.fetch("limit", DEFAULT_LIMIT)
      events = []
      bytes = 0
      counts = { "matched" => 0, "unsupported_schema" => 0, "unreadable" => 0 }
      last = start + first - 1
      truncated = false
      lines.each_with_index.drop(start).each do |line, index|
        last = first + index
        record = (text = PhComposer::Diagnostics.sanitized(line)) && JSON.parse(text)
        next counts["unreadable"] += 1 unless record
        next counts["unsupported_schema"] += 1 unless SUPPORTED_LOG_SCHEMAS.include?(record["schema"])
        next unless selected?(record, filters, minimum)

        counts["matched"] += 1
        size = text.bytesize
        if events.length >= limit || bytes + size > MAX_EVENTS_BYTES
          truncated = true
          last = first + index - 1
          break
        end
        events << record.merge("line" => first + index)
        bytes += size
      end
      counts.merge("events" => events, "truncated" => truncated, "next_cursor" => "#{process}:#{[last, 0].max}")
    end

    def selected?(record, filters, minimum)
      return false if SEVERITIES.index(record.fetch("severity", "info")).to_i < minimum

      %w[session incident run_id].all? { |name| !filters.key?(name) || record[name] == filters[name] }
    end

    def history(window)
      { "source" => "process_tail", "process" => process, "first_line" => window.fetch("first"),
        "lines" => window.fetch("lines").length, "tail_bytes" => PhComposer::Diagnostics::TAIL_BYTES }
    end

    def document(filters, status, problem)
      identity = PhComposer::BuildIdentity
      {
        "schema" => SCHEMA, "kind" => KIND, "status" => status, "error" => problem,
        "filters" => filters.slice(*FILTERS.keys, "cursor", "limit").transform_values { |value| value.to_s[0, 64] },
        "log_schema" => PhComposer::Diagnostics::SCHEMA, "supported_log_schemas" => SUPPORTED_LOG_SCHEMAS,
        "health" => PhComposer::Diagnostics.health,
        "build" => { "extension_version" => PhComposer::VERSION, "build" => identity.build,
                     "commit" => identity.commit, "manifest" => identity.manifest },
        "receipt" => "Installed-byte proof is the acceptance package comparison " \
                     "(tools/hostkit/acceptance_run.py), not this read."
      }
    end
  end
end
