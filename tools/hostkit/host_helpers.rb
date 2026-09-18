# frozen_string_literal: true

# Development helpers for driving the real host through the bridge. Not shipped with the extension.
#
# `host_bridge.py launch` loads this file after the bridge answers; every method is reachable as
# `PhComposerHost.<name>` from `host_bridge.py eval`. Helpers read the host and the extension's
# public state; none writes to the Model. Feature helpers arrive with their features.

require "fileutils"

module PhComposerHost
  class << self
    attr_accessor :evidence_dir

    def model
      Sketchup.active_model
    end

    # What a host gate records about the process and the extension it loaded. Only the Model's
    # file name is reported: absolute paths stay out of evidence.
    def state
      {
        "sketchup" => Sketchup.version,
        "ruby" => RUBY_VERSION,
        "extension" => extension_state,
        "model" => model_state
      }
    end

    def shot(name, dir = evidence_dir)
      raise ArgumentError, "set PhComposerHost.evidence_dir or pass dir" unless dir

      FileUtils.mkdir_p(dir)
      file = File.join(dir, name.end_with?(".png") ? name : name + ".png")
      model.active_view.zoom_extents
      model.active_view.write_image(file, 1200, 800, false)
      file
    end

    private

    def extension_state
      return { "registered" => false } unless defined?(PhComposer::EXTENSION)

      extension = PhComposer::EXTENSION
      {
        "registered" => true,
        "id" => PhComposer::EXTENSION_ID,
        "version" => PhComposer::VERSION,
        "loaded" => extension.respond_to?(:loaded?) ? extension.loaded? : nil,
        "features" => defined?(PhComposer::FEATURES) ? PhComposer::FEATURES.map(&:name) : nil
      }
    end

    def model_state
      return nil unless model

      {
        "file_name" => File.basename(model.path.to_s),
        "modified" => model.modified?,
        "active_path_depth" => Array(model.active_path).length
      }
    end
  end
end
