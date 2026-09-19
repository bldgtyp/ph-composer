# frozen_string_literal: true

module PhComposer
  # The performance ceilings the runtime is held to, read from the pinned manifest the first time
  # they are needed rather than when the extension loads.
  module RuntimeGate
    module_function

    def gates
      @gates ||= begin
        gates = RuntimeManifest.read(ROOT)["gates"]
        raise RuntimeManifest::Invalid, "runtime manifest gates are not an object" unless gates.is_a?(Hash)

        gates.freeze
      end
    end

    # The common gates with the platform's overrides applied. `platform` is what `Sketchup.platform`
    # returns, so Windows' overrides sit under `platform_win`.
    def selected(platform = Sketchup.platform)
      common = gates.reject { |key, _value| key.start_with?("platform_") }
      common.merge(gates.fetch(platform.to_s, {}))
    end

    # One gate for this platform. Raises `RuntimeManifest::Invalid` when the manifest lacks it.
    def fetch(name, platform = Sketchup.platform)
      selected(platform).fetch(name.to_s)
    rescue KeyError => error
      raise RuntimeManifest::Invalid, "runtime manifest gate is missing: #{error.key}"
    end

    def reset_for_test
      @gates = nil
    end
  end

  on_reset("runtime_gate") { RuntimeGate.reset_for_test }
end
