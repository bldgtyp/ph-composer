# frozen_string_literal: true

require "digest"
require "json"

module PhComposer
  # The pinned runtime manifest, `vendor/manifest.json`: every asset the runtime may load, with its
  # size, SHA-256 and MIME type, and the performance gates. `tools/runtime/vendor.py` writes it; the
  # asset server serves only what it declares, and `RuntimeGate` reads its gates.
  module RuntimeManifest
    PATH = File.join("vendor", "manifest.json")

    # The installed manifest is missing, unreadable or malformed: a packaging fault.
    class Invalid < InternalError; end

    module_function

    # The manifest under `root`, validated.
    def read(root)
      root = File.expand_path(root)
      manifest = JSON.parse(File.read(File.join(root, PATH), :encoding => "UTF-8"))
      raise Invalid, "runtime manifest is not an object" unless manifest.is_a?(Hash)
      raise Invalid, "runtime manifest schema is not supported" unless manifest["schema_version"] == 1
      raise Invalid, "runtime manifest control path is invalid" unless manifest["manifest_asset"] == PATH

      assets = manifest["assets"]
      raise Invalid, "runtime manifest assets are missing" unless assets.is_a?(Hash) && !assets.empty?

      assets.each { |relative, entry| validate_entry(root, relative, entry) }
      manifest
    rescue JSON::ParserError, SystemCallError => error
      raise Invalid, "runtime manifest could not be read: #{error.class}: #{error.message}"
    end

    # Each declared asset that is missing or whose bytes differ from the manifest, with the reason.
    def invalid_assets(root, assets)
      root = File.expand_path(root)
      assets.each_with_object({}) do |(relative, entry), invalid|
        absolute = File.expand_path(File.join(root, relative))
        unless File.file?(absolute)
          invalid[relative] = "missing_asset"
          next
        end
        body = File.binread(absolute)
        unless body.bytesize == entry.fetch("bytes") && Digest::SHA256.hexdigest(body) == entry.fetch("sha256")
          invalid[relative] = "asset_integrity_failed"
        end
      end
    end

    # A declared path must stay inside the extension folder, and its entry must name a size, a hash
    # and a MIME type the server can send.
    def validate_entry(root, relative, entry)
      absolute = File.expand_path(File.join(root, relative.to_s))
      unless relative.is_a?(String) && absolute.start_with?(root + File::SEPARATOR)
        raise Invalid, "runtime manifest contains an unsafe asset"
      end
      unless entry.is_a?(Hash) && entry["bytes"].is_a?(Integer) && entry["sha256"].to_s.match?(/\A[0-9a-f]{64}\z/) &&
             entry["mime"].is_a?(String) && !entry["mime"].empty?
        raise Invalid, "runtime manifest contains an invalid asset entry: #{relative}"
      end
    end
  end
end
