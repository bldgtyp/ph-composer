# frozen_string_literal: true

require "fileutils"
require "json"
require "tmpdir"
require "time"

module PhComposer
  # The extension's log: one JSON line per event, allowed fields only, paths redacted. It is for
  # diagnosis; a user-facing message never depends on it. Strict mode, on in the offline suite,
  # raises on a field outside the allowlist instead of dropping it.
  module Diagnostics
    MAX_BYTES = 512 * 1024
    LOG_NAME = "ph-composer.log"
    ALLOWED_FIELDS = %w[
      code duration_ms error_class event extension_version operation run_id sketchup_version status
    ].freeze
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

      def log(event, fields = {})
        dropped_fields = fields.keys.map(&:to_s).reject { |name| ALLOWED_FIELDS.include?(name) }
        if strict && !dropped_fields.empty?
          raise ArgumentError, "Diagnostics field #{dropped_fields.first} is not allowed."
        end

        begin
          payload = base_payload(event)
          fields.each do |key, value|
            name = key.to_s
            next unless ALLOWED_FIELDS.include?(name)
            payload[name] = redact(value.to_s)
          end
          write_line(JSON.generate(payload) + "\n")
          dropped_fields.each do |name|
            dropped_payload = base_payload("diagnostics_field_dropped")
            dropped_payload["status"] = name
            write_line(JSON.generate(dropped_payload) + "\n")
          end
          payload
        rescue StandardError
          nil
        end
      end

      def exception(event, error)
        log(event, "status" => "failed", "error_class" => error.class.name)
      end

      def path
        return @path_override if @path_override
        File.join(data_root, "logs", LOG_NAME)
      end

      def folder
        File.dirname(path)
      end

      def reset_for_test
        @path_override = nil
        @strict = false
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

      private

      def base_payload(event)
        {
          "timestamp" => Time.now.utc.iso8601,
          "event" => redact(event.to_s),
          "extension_version" => VERSION
        }
      end

      def data_root
        plugins = Sketchup.find_support_file("Plugins") if Sketchup.respond_to?(:find_support_file)
        return File.join(File.dirname(plugins), EXTENSION_NAME) if plugins && !plugins.empty?
        File.join(Dir.tmpdir, EXTENSION_ID)
      end

      def write_line(line)
        log_path = path
        FileUtils.mkdir_p(File.dirname(log_path))
        rotate_if_needed(log_path, line.bytesize)
        File.open(log_path, "ab") { |file| file.write(line) }
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
