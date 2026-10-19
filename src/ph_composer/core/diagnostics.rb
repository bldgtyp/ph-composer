# frozen_string_literal: true

require "fileutils"
require "json"
require "securerandom"
require "tmpdir"
require "time"
require_relative "build_identity"

module PhComposer
  # The extension's log: one JSON line per event, allowed fields only, paths redacted. It is for
  # diagnosis; a user-facing message never depends on it. Strict mode, on in the offline suite,
  # raises on a field outside the allowlist, or a value its field does not accept, instead of dropping
  # it. The same file is the support report's evidence and the developer reader's input; `schema` rises
  # when a field's meaning changes.
  #
  # Values are checked as well as keys: names (event, operation, stage, code, effect) come from
  # declarations, never from request text or record labels, and must look like one. An exception is
  # recorded by its class and extension-relative frames, never its message. Writing is best effort:
  # a failed write is remembered as the log's health and the line is still kept in a bounded in-memory
  # tail, so the support window can say the log is degraded and still show recent events.
  module Diagnostics
    SCHEMA = 1
    MAX_BYTES = 512 * 1024
    MAX_EVENT_BYTES = 8 * 1024
    MAX_FRAMES = 20
    TAIL_BYTES = 256 * 1024
    RETENTION_SECONDS = 7 * 24 * 60 * 60
    LOG_NAME = "ph-composer.log"
    ALLOWED_FIELDS = %w[
      build code duration_ms effect error_class event extension_version frames incident manifest operation
      request run_id schema session severity sketchup_version stage status
    ].freeze
    SEVERITIES = %w[info warning error].freeze
    NAME = /\A[a-z0-9_]+(?:\.[a-z0-9_]+)*\z/.freeze
    REFERENCE = /\A[A-Za-z0-9_.:-]{1,96}\z/.freeze
    ERROR_CLASS = /\A[A-Z][A-Za-z0-9_]*(?:::[A-Z][A-Za-z0-9_]*)*\z/.freeze
    # Which values each checked field accepts; the rest are free text, redacted for paths.
    VALUES = {
      "event" => NAME, "operation" => NAME, "stage" => NAME, "code" => NAME, "effect" => NAME,
      "severity" => /\A(?:#{SEVERITIES.join('|')})\z/, "error_class" => ERROR_CLASS, "incident" => REFERENCE,
      "session" => REFERENCE, "request" => REFERENCE, "run_id" => REFERENCE, "build" => REFERENCE,
      "manifest" => REFERENCE
    }.freeze
    INVALID = "[INVALID]"
    # A frame's method name as Ruby, JavaScript or Python reports it, without arguments or source.
    FRAME_METHOD = /\A[\w$.:<>?!=\[\]{} #-]{1,96}\z/.freeze
    FRAME_FILE = %r{\A[\w.-]+(?:/[\w.-]+)*\z}.freeze
    # Where the slash sits decides what it is. A value that *starts* at the filesystem root is a
    # path however short, so `/tmp` and `/Users` redact. A slash that appears after whitespace is
    # user text in a record name until it carries two or more segments, so `North /Facade` survives
    # and `plan /Users/em` does not.
    # A drive letter takes either slash (Ruby writes `C:/Users`), a UNC share starts `\\`, a home path
    # starts `~/`, and a path may follow punctuation as well as a space (`saved to:/Users/em/x`).
    ABSOLUTE_PATH_PATTERNS = [
      %r{\A/[^/\s]+}, %r{[\s(=:,;"'\[](?:/[^/\s]+){2,}}, %r{(?:\A|[^A-Za-z0-9])[A-Za-z]:[\\/]},
      %r{(?:\A|\s)\\\\[^\\\s]+}, %r{(?:\A|\s)~/}, %r{file://}
    ].freeze

    class << self
      attr_accessor :strict
      attr_writer :path_override

      # Writes one event and answers its payload, or nil when nothing could be built. Never raises
      # outside strict mode.
      def log(event, fields = {})
        fields = context.merge(fields.transform_keys(&:to_s))
        dropped_fields = fields.keys.reject { |name| ALLOWED_FIELDS.include?(name) }
        if strict && !dropped_fields.empty?
          raise ArgumentError, "Diagnostics field #{dropped_fields.first} is not allowed."
        end

        begin
          payload = base_payload(event)
          fields.each do |name, value|
            next unless ALLOWED_FIELDS.include?(name)

            payload[name] = value_for(name, value)
          end
          write_line(bounded(payload))
          dropped_fields.each do |name|
            dropped_payload = base_payload("diagnostics_field_dropped")
            # The dropped key is shown only when it looks like a field name; its value never is.
            dropped_payload["status"] = NAME.match?(name) ? name : INVALID
            write_line(JSON.generate(dropped_payload) + "\n")
          end
          payload
        rescue ArgumentError
          raise if strict

          nil
        rescue StandardError
          nil
        end
      end

      # An exception by its class and where it was raised, never its message.
      def exception(event, error, fields = {})
        log(event, { "status" => "failed", "severity" => "error", "error_class" => error.class.name,
                     "frames" => frames(error) }.merge(fields))
      end

      # Logs an unexpected failure under a new incident reference and answers the reference, which an
      # outcome's `detail` carries so the user's report and this record name the same event. A reference
      # identifies evidence; it grants nothing.
      def incident(event, error, fields = {})
        reference = "PHC-#{SecureRandom.hex(3).upcase}"
        exception(event, error, fields.merge("incident" => reference))
        reference
      end

      # Fields every event logged inside the block carries, such as the session and request being served.
      # Nested blocks add to the outer one's.
      def with_context(fields)
        previous = Thread.current[:ph_composer_diagnostics]
        Thread.current[:ph_composer_diagnostics] = context.merge(fields.transform_keys(&:to_s))
        yield
      ensure
        Thread.current[:ph_composer_diagnostics] = previous
      end

      # The fields another runtime or a page reported, keeping only values their field accepts, so what a
      # client sends can never become a refused field or an echoed string.
      def accepted(fields)
        fields.select do |name, value|
          case name
          when "frames" then valid_frames?(value)
          when *VALUES.keys then value.is_a?(String) && VALUES.fetch(name).match?(value)
          else false
          end
        end
      end

      # Extension-relative Ruby frames, innermost first, at most MAX_FRAMES. Frames outside the extension
      # are left out rather than named by an absolute path.
      def frames(error)
        Array(error.backtrace_locations).filter_map { |location| frame(location) }.first(MAX_FRAMES)
      end

      # Whether the log is being written, and the class of the last storage error since the last good write.
      def health
        { "writing" => @last_error.nil?, "last_error" => @last_error }
      end

      # The most recent lines written or attempted this session, oldest first, within TAIL_BYTES.
      def tail
        (@tail ||= []).dup
      end

      # Drops events older than RETENTION_SECONDS from the log and an archive that holds nothing newer.
      # Runs once at load; a failure leaves the files as they were.
      def prune(now = Time.now.utc)
        cutoff = now - RETENTION_SECONDS
        archive = path + ".1"
        FileUtils.rm_f(archive) if File.exist?(archive) && File.mtime(archive) < cutoff
        return unless File.exist?(path)

        kept = File.readlines(path).select { |line| recent?(line, cutoff) }
        File.write(path, kept.join)
      rescue StandardError => error
        @last_error = error.class.name
      end

      def path
        return @path_override if @path_override

        File.join(data_root, "logs", LOG_NAME)
      end

      def reset_for_test
        @path_override = nil
        @strict = false
        @last_error = nil
        @tail = []
        @tail_bytes = 0
        Thread.current[:ph_composer_diagnostics] = nil
      end

      def redact(value, secrets = [])
        text = value.to_s.dup
        Array(secrets).compact.reject(&:empty?).each do |secret|
          text.gsub!(secret.to_s, "[REDACTED]")
        end
        return "[REDACTED_PATH]" if absolute_path?(text)

        text
      end

      def absolute_path?(value)
        ABSOLUTE_PATH_PATTERNS.any? { |pattern| value.to_s.match?(pattern) }
      end

      # One frame a caller built from another runtime's stack, accepted only in the shape `frames` makes:
      # a relative file, a line number and a method name.
      def valid_frame?(frame)
        frame.is_a?(Hash) && frame.keys.sort == %w[file line method] && FRAME_FILE.match?(frame["file"].to_s) &&
          frame["line"].is_a?(Integer) && frame["line"] >= 0 && FRAME_METHOD.match?(frame["method"].to_s)
      end

      private

      def context
        Thread.current[:ph_composer_diagnostics] || {}
      end

      def base_payload(event)
        {
          "timestamp" => Time.now.utc.iso8601, "schema" => SCHEMA, "event" => value_for("event", event),
          "extension_version" => VERSION, "build" => BuildIdentity.build
        }
      end

      def value_for(name, value)
        case name
        when "duration_ms" then value.is_a?(Numeric) && value.finite? ? value : invalid(name)
        when "frames" then valid_frames?(value) ? value.first(MAX_FRAMES) : invalid(name)
        when *VALUES.keys then VALUES.fetch(name).match?(value.to_s) ? value.to_s : invalid(name)
        else redact(value.to_s)
        end
      end

      def valid_frames?(value)
        value.is_a?(Array) && value.first(MAX_FRAMES).all? { |frame| valid_frame?(frame) }
      end

      def invalid(name)
        raise ArgumentError, "Diagnostics field #{name} has a value it does not accept." if strict

        INVALID
      end

      # A line within MAX_EVENT_BYTES: frames go first, then every field but the identifying ones.
      def bounded(payload)
        line = JSON.generate(payload) + "\n"
        return line if line.bytesize <= MAX_EVENT_BYTES

        payload = payload.reject { |name, _value| name == "frames" }
        line = JSON.generate(payload) + "\n"
        return line if line.bytesize <= MAX_EVENT_BYTES

        kept = payload.slice("timestamp", "schema", "event", "extension_version", "build", "incident", "error_class")
        JSON.generate(kept.merge("status" => "event_truncated")) + "\n"
      end

      def frame(location)
        file = location.absolute_path || location.path
        return nil unless file&.start_with?(extension_parent)

        { "file" => file.delete_prefix(extension_parent), "line" => location.lineno,
          "method" => FRAME_METHOD.match?(location.label.to_s) ? location.label.to_s : "?" }
      end

      # The folder holding the loader and the extension folder, so frames read `ph_composer/shell/panel.rb`.
      def extension_parent
        File.dirname(ROOT) + "/"
      end

      def recent?(line, cutoff)
        Time.iso8601(JSON.parse(line).fetch("timestamp")) >= cutoff
      rescue StandardError
        false
      end

      def data_root
        plugins = Sketchup.find_support_file("Plugins") if Sketchup.respond_to?(:find_support_file)
        return File.join(File.dirname(plugins), EXTENSION_NAME) if plugins && !plugins.empty?

        File.join(Dir.tmpdir, EXTENSION_ID)
      end

      def write_line(line)
        remember(line)
        log_path = path
        FileUtils.mkdir_p(File.dirname(log_path))
        rotate_if_needed(log_path, line.bytesize)
        File.open(log_path, "ab") { |file| file.write(line) }
        @last_error = nil
      rescue StandardError => error
        # Not logged: a logger failure recorded through the logger would recurse.
        @last_error = error.class.name
      end

      def remember(line)
        @tail ||= []
        @tail_bytes = (@tail_bytes || 0) + line.bytesize
        @tail << line
        @tail_bytes -= @tail.shift.bytesize while @tail_bytes > TAIL_BYTES
      end

      def rotate_if_needed(log_path, incoming_bytes)
        return unless File.size(log_path) + incoming_bytes > MAX_BYTES

        archive = log_path + ".1"
        FileUtils.rm_f(archive)
        File.rename(log_path, archive)
      rescue Errno::ENOENT
        nil
      end
    end

    self.strict = false
  end

  on_reset("diagnostics") { Diagnostics.reset_for_test }
end
