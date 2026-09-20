# frozen_string_literal: true

require "json"
require "open3"

module PhComposer
  # User-wide display preferences (planning/features/units/PRD.md I2 to I6, I10): local to this computer,
  # shared by every panel and open Model, restored after restart. They live in SketchUp's own preference
  # store, so choosing one never dirties an SKP, adds an Undo step or advances a session revision.
  #
  # A dimension scope is one editor's remembered length format, such as a graphical builder's. The panel
  # names the scope; a scope is a dotted name under the owning feature's id, like every declared name.
  module Preferences
    SECTION = EXTENSION_ID
    UNIT_SYSTEMS = %w[SI IP].freeze
    DEFAULT_UNIT_SYSTEM = "SI"
    DIMENSION_FORMATS = { "SI" => %w[mm cm m].freeze, "IP" => %w[in ft ft-in in-frac].freeze }.freeze
    # Keep in step with `units.dimensionDefaults` in html/units.js: the panel picks a format before the
    # first snapshot arrives, so the two defaults must agree.
    DEFAULT_DIMENSION_FORMAT = { "SI" => "mm", "IP" => "in" }.freeze
    # Remembered scopes are few; the cap stops a misbehaving client from growing the stored map without bound.
    MAX_SCOPES = 32
    MAX_STORED_BYTES = 4096

    class << self
      def unit_system
        stored = Sketchup.read_default(SECTION, "unit_system", DEFAULT_UNIT_SYSTEM)
        UNIT_SYSTEMS.include?(stored) ? stored : DEFAULT_UNIT_SYSTEM
      end

      # The Colour-by mode the user last turned on, or nil. Colour-by itself is off at rest; only the
      # choice is remembered (face-assignment PRD Q12).
      def colour_by_mode
        stored = Sketchup.read_default(SECTION, "colour_by_mode", nil)
        stored.is_a?(String) && Registry::ID_PATTERN.match?(stored) ? stored : nil
      end

      # Every remembered scope's format per system; a scope never chosen is absent and takes the default.
      def dimension_formats
        raw = Sketchup.read_default(SECTION, "dimension_formats", nil)
        return {} unless raw.is_a?(String) && raw.bytesize <= MAX_STORED_BYTES * 2

        sanitize(JSON.parse(raw.unpack1("m0")))
      rescue StandardError
        {}
      end

      # Records one preference or raises UserError with the reason. Writes nothing else.
      def set(key, value, scope: nil, system: nil)
        case key
        when "unit_system"
          raise UserError, "Display units must be SI or IP." unless UNIT_SYSTEMS.include?(value)

          Sketchup.write_default(SECTION, "unit_system", value)
        when "dimension_format"
          write_dimension_format(value, scope, system)
        when "colour_by_mode"
          raise UserError, "That Colour-by mode name is not valid." unless value.is_a?(String) &&
                                                                          Registry::ID_PATTERN.match?(value)

          Sketchup.write_default(SECTION, "colour_by_mode", value)
        else
          raise UserError, "That display preference is not recognized."
        end
        value
      end

      def snapshot
        { "unit_system" => unit_system, "dimension_formats" => dimension_formats, "number_format" => number_format }
      end

      def reset_for_test
        @number_format = nil
        @apple_locale_reader = nil
      end

      attr_writer :apple_locale_reader

      private

      def write_dimension_format(value, scope, system)
        raise UserError, "Choose SI or IP for the dimension format." unless UNIT_SYSTEMS.include?(system)
        raise UserError, "The dimension scope name is not valid." unless scope.is_a?(String) &&
                                                                         Registry::ID_PATTERN.match?(scope)
        raise UserError, "Choose a valid #{system} dimension format." unless DIMENSION_FORMATS[system].include?(value)

        formats = dimension_formats
        raise UserError, "Too many dimension formats are remembered." if !formats.key?(scope) &&
                                                                          formats.length >= MAX_SCOPES

        formats[scope] = DEFAULT_DIMENSION_FORMAT.merge(formats.fetch(scope, {})).merge(system => value)
        # SketchUp 26.1 stores a string containing a double quote but reads it back as nil, so the JSON
        # is kept as strict base64 (context/SKETCHUP_HOST_BEHAVIOR.md).
        Sketchup.write_default(SECTION, "dimension_formats", [JSON.generate(formats)].pack("m0"))
      end

      def sanitize(parsed)
        return {} unless parsed.is_a?(Hash)

        parsed.each_with_object({}) do |(scope, formats), result|
          next unless Registry::ID_PATTERN.match?(scope.to_s) && formats.is_a?(Hash)
          break result if result.length >= MAX_SCOPES

          result[scope] = UNIT_SYSTEMS.to_h do |system|
            stored = formats[system]
            [system, DIMENSION_FORMATS[system].include?(stored) ? stored : DEFAULT_DIMENSION_FORMAT[system]]
          end
        end
      end

      # The computer's regional convention for typed and displayed numbers (I10). Stored values and JSON
      # never use it.
      def number_format
        @number_format ||= {
          "decimal" => Sketchup::RegionalSettings.decimal_separator.to_s,
          "locale" => resolved_locale
        }.freeze
      end

      def resolved_locale
        locale = apple_locale
        locale = Sketchup.get_locale if locale.nil? || locale.empty?
        normalize_locale(locale) || "en-US"
      rescue StandardError
        normalize_locale(Sketchup.get_locale) || "en-US"
      end

      # macOS keeps the region the user chose in AppleLocale; SketchUp's own locale is its UI language.
      # Elsewhere, or when the read fails, SketchUp's locale stands.
      def apple_locale
        return @apple_locale_reader.call if @apple_locale_reader

        output, _error, status = Open3.capture3("/usr/bin/defaults", "read", "-g", "AppleLocale")
        status.success? ? output.to_s.lines.first.to_s.strip : nil
      rescue StandardError
        nil
      end

      def normalize_locale(value)
        raw = value.to_s.strip
        return nil if raw.empty?

        base, modifiers = raw.split("@", 2)
        parts = base.split(".", 2).first.to_s.tr("_", "-").split("-").reject(&:empty?)
        return nil if parts.empty?

        parts[0] = parts[0].downcase
        parts[1..-1] = parts[1..-1].map { |part| normalize_subtag(part) }
        apply_region_override(parts, modifiers).join("-")
      end

      def normalize_subtag(part)
        if part.match?(/\A[A-Za-z]{2}\z/) || part.match?(/\A\d{3}\z/)
          part.upcase
        elsif part.match?(/\A[A-Za-z]{4}\z/)
          part[0].upcase + part[1..-1].downcase
        else
          part
        end
      end

      # macOS writes a separately chosen region as "@rg=dezzzz"; it replaces the language's region.
      def apply_region_override(parts, modifiers)
        override = modifiers.to_s[/\A(?:.*;)?rg=([A-Za-z]{2}|\d{3})[A-Za-z]{4}(?:;.*)?\z/, 1]
        return parts unless override

        region_index = parts.index { |part| part.match?(/\A(?:[A-Z]{2}|\d{3})\z/) }
        if region_index
          parts[region_index] = override.upcase
        else
          parts << override.upcase
        end
        parts
      end
    end
  end

  on_reset("preferences") { Preferences.reset_for_test }
end
