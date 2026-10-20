# frozen_string_literal: true

require "json"
require "securerandom"

# Development only, never shipped: a bounded, filtered read of the extension's diagnostic log for development
# probes, through the development bridge (`host_bridge.py diagnostics`). It reads the log's own projection,
# `PhComposer::Diagnostics.tail_window`, and copies each line through `Diagnostics.sanitized`, the same
# reduction the support report uses, so a read returns only the fields and values the log accepts: never log
# file bytes, never the logger's state, never a path.
#
# A cursor names this process and the number of the next line to read (`<process>:<number>`), so a read of
# an empty tail still resumes at its first line. A cursor from another process (SketchUp restarted), or one
# whose next lines were evicted from the bounded tail or cleared, says so instead of implying a complete
# history. `newest` instead returns the most recent matching records, for a summary beside a wait.
#
# Loading this file needs nothing from the extension, so the helpers load even when PH-Composer did not;
# a read then answers `unavailable`.
module PhComposerDiagnosticReader
  SCHEMA = 1
  KIND = "ph-composer.diagnostic-read"
  SUPPORTED_LOG_SCHEMAS = [1].freeze
  SEVERITIES = %w[info warning error].freeze
  DEFAULT_LIMIT = 50
  MAX_LIMIT = 100
  MAX_EVENTS_BYTES = 128 * 1024
  CURSOR = /\A(?<process>\h{8}):(?<number>\d{1,12})\z/.freeze
  SEVERITY = /\A(?:info|warning|error)\z/.freeze

  class << self
    # This process's identity for cursors: random, so a restarted SketchUp never matches an old cursor.
    def process
      @process ||= SecureRandom.hex(4)
    end

    # One read. `filters` takes `session`, `incident`, `run_id`, `severity` (the least severe to include;
    # a line without one is info), `cursor` and `limit`. Answers a detached Hash; nothing is mutated.
    def read(filters = {})
      filters = filters.transform_keys(&:to_s)
      unless defined?(PhComposer::Diagnostics) && PhComposer::Diagnostics.respond_to?(:tail_window)
        return { "schema" => SCHEMA, "kind" => KIND, "status" => "unavailable",
                 "error" => "the extension's diagnostic log is not loaded in this process" }
      end
      problem = refusal(filters)
      return detached(document(filters, "refused", problem)) if problem

      window = PhComposer::Diagnostics.tail_window
      selected = if filters["newest"]
                   newest(filters, window)
                 else
                   position = resume(filters["cursor"], window.fetch("first"))
                   start = [position.fetch("from") - window.fetch("first"), 0].max
                   collect(filters, window.fetch("lines"), start, window.fetch("first"))
                     .merge("cursor_state" => position.fetch("state"), "gap" => position["gap"])
                 end
      detached(document(filters, "read", nil).merge(selected).merge("history" => history(window)))
    end

    private

    # A copy sharing no object with the log, the build identity or this reader, so a caller that changes the
    # result changes nothing else.
    def detached(value)
      JSON.parse(JSON.generate(value))
    end

    def filters_accepted
      { "session" => PhComposer::Diagnostics::SESSION, "incident" => PhComposer::Diagnostics::INCIDENT,
        "run_id" => PhComposer::Diagnostics::RUN, "severity" => SEVERITY }
    end

    def refusal(filters)
      unknown = filters.keys - filters_accepted.keys - %w[cursor limit newest]
      return "unknown filter #{unknown.first[0, 32]}" unless unknown.empty?
      unless SUPPORTED_LOG_SCHEMAS.include?(PhComposer::Diagnostics::SCHEMA)
        return "the log's schema #{PhComposer::Diagnostics::SCHEMA} is not one this reader supports"
      end

      return "newest is true or absent, and takes no cursor" if filters.key?("newest") &&
                                                                (filters["newest"] != true || filters.key?("cursor"))

      filters_accepted.each do |name, pattern|
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

      from = match[:number].to_i
      return { "from" => from, "state" => "continued" } if from >= first

      { "from" => first, "state" => "evicted", "gap" => { "lines" => first - from } }
    end

    def collect(filters, lines, start, first)
      minimum = SEVERITIES.index(filters.fetch("severity", "info"))
      limit = filters.fetch("limit", DEFAULT_LIMIT)
      events = []
      bytes = 0
      counts = { "matched" => 0, "unsupported_schema" => 0, "unreadable" => 0 }
      following = first + [start, lines.length].min
      truncated = false
      each_record(lines, start, first, counts) do |record, number|
        next unless selected?(record, filters, minimum)

        counts["matched"] += 1
        event = record.merge("line" => number)
        size = returned_bytes(event)
        if events.length >= limit || bytes + size > MAX_EVENTS_BYTES
          truncated = true
          following = number
          break
        end
        events << event
        bytes += size
      end
      # Past every line scanned, unsupported and unreadable ones included, unless a match was left for later.
      following = first + lines.length unless truncated
      counts.merge("events" => events, "truncated" => truncated, "next_cursor" => "#{process}:#{following}")
    end

    # The most recent matching records, oldest first, within the limit and byte bound; no cursor.
    def newest(filters, window)
      minimum = SEVERITIES.index(filters.fetch("severity", "info"))
      counts = { "matched" => 0, "unsupported_schema" => 0, "unreadable" => 0 }
      matched = []
      each_record(window.fetch("lines"), 0, window.fetch("first"), counts) do |record, number|
        next unless selected?(record, filters, minimum)

        counts["matched"] += 1
        event = record.merge("line" => number)
        matched << [event, returned_bytes(event)]
      end
      kept = []
      bytes = 0
      matched.reverse_each do |record, size|
        break if kept.length >= filters.fetch("limit", DEFAULT_LIMIT) || bytes + size > MAX_EVENTS_BYTES

        kept.unshift(record)
        bytes += size
      end
      counts.merge("events" => kept, "truncated" => kept.length < matched.length, "cursor_state" => "newest")
    end

    # Each readable line of a supported schema from `start`, reduced by the log's own sanitizer, with its line
    # number. A line the sanitizer left without an event name (the logger keeps an invalid one as
    # `[INVALID]`, which the reduction drops) is counted as unreadable, not returned half-formed.
    def each_record(lines, start, first, counts)
      lines.each_with_index.drop(start).each do |line, index|
        record = (text = PhComposer::Diagnostics.sanitized(line)) && JSON.parse(text)
        next counts["unreadable"] += 1 unless record.is_a?(Hash) && record["event"].is_a?(String)
        next counts["unsupported_schema"] += 1 unless SUPPORTED_LOG_SCHEMAS.include?(record["schema"])

        yield record, first + index
      end
    end

    # What one returned event adds to the events array as JSON, its separator included.
    def returned_bytes(event)
      JSON.generate(event).bytesize + 1
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
        "filters" => filters.slice(*filters_accepted.keys, "cursor", "limit", "newest")
                            .transform_values { |value| value.to_s[0, 64] },
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
