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
    # A declared name: lowercase, dotted, at most 96 characters.
    NAME = /\A(?=.{1,96}\z)[a-z0-9_]+(?:\.[a-z0-9_]+)*\z/.freeze
    REFERENCE = /\A[A-Za-z0-9_.:-]{1,96}\z/.freeze
    ERROR_CLASS = /\A(?=.{1,96}\z)[A-Z][A-Za-z0-9_]*(?:::[A-Z][A-Za-z0-9_]*)*\z/.freeze
    VERSION_TEXT = /\A[\w.+-]{1,32}\z/.freeze
    # Each reference in the exact form the extension generates it, so no other text fits one.
    SESSION = /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/.freeze
    # A request id is `<session>:<label>:<n>`; the label names the panel view that sent it, in code.
    REQUEST = /\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}:[A-Za-z][A-Za-z0-9_. -]{0,47}:\d{1,9}\z/.freeze
    RUN = /\Aexport_\h{24}\z/.freeze
    INCIDENT = /\APHC-[0-9A-F]{6}\z/.freeze
    BUILD = /\A(?:\h{12}|development|unavailable)\z/.freeze
    MANIFEST = /\A(?:\h{12}|unavailable)\z/.freeze
    # Which values each field accepts. No field takes free text: a status is a name like any other.
    VALUES = {
      "event" => NAME, "operation" => NAME, "stage" => NAME, "code" => NAME, "effect" => NAME, "status" => NAME,
      "sketchup_version" => VERSION_TEXT, "extension_version" => VERSION_TEXT,
      "severity" => /\A(?:#{SEVERITIES.join('|')})\z/, "error_class" => ERROR_CLASS,
      "session" => SESSION, "request" => REQUEST, "run_id" => RUN, "incident" => INCIDENT, "build" => BUILD,
      "manifest" => MANIFEST
    }.freeze
    INVALID = "[INVALID]"
    # A frame's method name as Ruby, JavaScript or Python reports it: one identifier-like word, no spaces.
    FRAME_METHOD = /\A[A-Za-z_$][\w$.?!=\[\]-]{0,95}\z/.freeze
    # Names a runtime gives code outside any named method.
    RUNTIME_MARKERS = %w[<main> <module> <anonymous> <lambda> <listcomp> <dictcomp> <setcomp> <genexpr>].freeze
    FRAME_FILE = %r{\A[\w-]+(?:\.[\w-]+)*(?:/[\w-]+(?:\.[\w-]+)*)*\z}.freeze
    # Where a frame's file may be, relative to the folder holding the loader: the extension's Ruby, its panel
    # pages and its translation package. A frame anywhere else, another plugin's included, is left out.
    FRAME_ROOTS = {
      "ph_composer/" => -> { File.dirname(ROOT) }, "html/" => -> { ROOT },
      "ph_composer_translation/" => -> { File.join(ROOT, "python") }
    }.freeze
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
            write_line(bounded(dropped_payload))
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
        fields.each_with_object({}) do |(name, value), kept|
          case name
          when "frames" then kept[name] = owned_frames(value) if value.is_a?(Array)
          when *VALUES.keys then kept[name] = value if value.is_a?(String) && VALUES.fetch(name).match?(value)
          end
        end
      end

      # The fields `with_context` holds now, for work that runs later to carry them (Export::Task).
      def current_context
        context.dup
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

      # The newest log lines on disk, archive first, within `max_bytes`, and how many earlier lines were left
      # out. Raises when the files exist but cannot be read; a log never written reads as empty.
      def recent_lines(max_bytes)
        lines = [path + ".1", path].select { |file| File.exist?(file) }.flat_map { |file| File.readlines(file) }
        kept = []
        total = 0
        lines.reverse_each do |line|
          break if total + line.bytesize > max_bytes

          kept.unshift(line)
          total += line.bytesize
        end
        [kept, lines.length - kept.length]
      end

      # One logged line rebuilt from the fields and values the log accepts, or nil when it is not a record.
      # A support report copies only this, so a line that somehow carries anything else is reduced.
      def sanitized(line)
        record = JSON.parse(line)
        return nil unless record.is_a?(Hash) && record["timestamp"].is_a?(String)

        kept = record.select { |name, value| reportable?(name, value) }
        # Each frame is checked on its own and at most MAX_FRAMES are copied.
        kept["frames"] = owned_frames(record["frames"]) if kept["frames"]
        JSON.generate(kept)
      rescue JSON::ParserError
        nil
      end

      # Removes the log and its archive and forgets this session's tail, answering whether both are gone.
      # A file that could not be deleted keeps the tail and is the log's last storage error. Saved support
      # reports are the user's and are not touched.
      def clear
        [path, path + ".1"].each do |file|
          File.delete(file)
        rescue Errno::ENOENT
          nil
        end
        @tail = []
        @tail_bytes = 0
        # Storage health stays as it was: only a successful write shows the log is being written again.
        true
      rescue SystemCallError => error
        @last_error = error.class.name
        false
      end

      # Drops events older than RETENTION_SECONDS from the log and its archive, and an archive left empty.
      # Runs once at load; a failure leaves the files as they were.
      def prune(now = Time.now.utc)
        cutoff = now - RETENTION_SECONDS
        [path + ".1", path].each do |file|
          next unless File.exist?(file)

          kept = File.readlines(file).select { |line| recent?(line, cutoff) }
          kept.empty? && file != path ? File.delete(file) : File.write(file, kept.join)
        end
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
      # a file the extension ships, a line number and a method name.
      def valid_frame?(frame)
        frame.is_a?(Hash) && frame.keys.sort == %w[file line method] && owned_file?(frame["file"]) &&
          frame["line"].is_a?(Integer) && frame["line"] >= 0 && owned_method?(frame["file"], frame["method"])
      end

      # A method name every dotted part of which is a runtime marker or a whole word in its file's own source,
      # or "?" when the runtime gave none, so a frame carries only words the extension wrote. Ruby frames name
      # a method by its base label.
      def owned_method?(file, method)
        return true if method == "?" || RUNTIME_MARKERS.include?(method)
        return false unless method.is_a?(String) && method.length <= 96

        source = (@sources ||= {})[file] ||= File.read(owned_path(file))
        method.split(".").all? do |part|
          RUNTIME_MARKERS.include?(part) || (part.match?(/\A[A-Za-z_$][\w$?!=]*\z/) &&
                                              source.match?(/(?<![\w$])#{Regexp.escape(part)}(?![\w$])/))
        end
      rescue SystemCallError
        false
      end

      def owned_path(file)
        return File.join(File.dirname(ROOT), file) if file == "#{EXTENSION_ID}.rb"

        File.join(FRAME_ROOTS.find { |prefix, _folder| file.start_with?(prefix) }.last.call, file)
      end

      def owned_file?(file)
        return false unless file.is_a?(String) && FRAME_FILE.match?(file)
        return File.file?(File.join(File.dirname(ROOT), file)) if file == "#{EXTENSION_ID}.rb"

        root = FRAME_ROOTS.find { |prefix, _folder| file.start_with?(prefix) }
        root ? File.file?(File.join(root.last.call, file)) : false
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
        when "frames" then value.is_a?(Array) ? owned_frames(value) : invalid(name)
        when *VALUES.keys then VALUES.fetch(name).match?(value.to_s) ? value.to_s : invalid(name)
        else redact(value.to_s)
        end
      end

      def reportable?(name, value)
        case name
        when "timestamp" then value.is_a?(String) && value.match?(/\A[\dT:.Z+-]{10,40}\z/)
        when "schema" then value.is_a?(Integer)
        when "duration_ms" then value.is_a?(Numeric)
        when "frames" then value.is_a?(Array)
        when *VALUES.keys then value.is_a?(String) && VALUES.fetch(name).match?(value)
        else false
        end
      end

      # The frames that name the extension's own files and methods, at most MAX_FRAMES; the rest are left out.
      # A frame in a file it does not own is left out; one whose method it cannot vouch for keeps its file
      # and line, with the method as "?".
      def owned_frames(value)
        value.filter_map do |frame|
          next frame if valid_frame?(frame)
          next nil unless frame.is_a?(Hash) && frame["method"]

          plain = frame.merge("method" => "?")
          plain if valid_frame?(plain)
        end.first(MAX_FRAMES)
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
        line = JSON.generate(kept.merge("status" => "event_truncated")) + "\n"
        return line if line.bytesize <= MAX_EVENT_BYTES

        JSON.generate(kept.slice("timestamp", "schema").merge("event" => "event_truncated")) + "\n"
      end

      # A frame in the extension folder or the loader, named from the folder holding them so it reads
      # `ph_composer/shell/panel.rb`; anything else is left out.
      def frame(location)
        file = location.absolute_path || location.path
        parent = File.dirname(ROOT) + "/"
        return nil unless file&.start_with?(ROOT + "/") || file == "#{parent}#{EXTENSION_ID}.rb"

        label = location.base_label.to_s
        { "file" => file.delete_prefix(parent), "line" => location.lineno,
          "method" => FRAME_METHOD.match?(label) ? label : "?" }
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
