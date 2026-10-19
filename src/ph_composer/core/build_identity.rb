# frozen_string_literal: true

require "digest"
require "json"

module PhComposer
  # Which package is running, in values a support report can name without a path. The RBZ build writes
  # `build.json` beside the extension (tools/rbz/build.py): a digest of every shipped file and the source
  # commit it came from. A source checkout has no such file and reports itself as a development build.
  module BuildIdentity
    DEVELOPMENT = "development"
    UNAVAILABLE = "unavailable"
    BUILD_PATTERN = /\A[0-9a-f]{12}\z/.freeze
    COMMIT_PATTERN = /\A[0-9a-f]{7,40}(?:-dirty)?\z/.freeze

    class << self
      # Tests read a record from elsewhere rather than writing into the extension folder.
      attr_writer :record_path
    end

    module_function

    # Twelve hex characters of the package digest, or "development".
    def build
      recorded.fetch("build")
    end

    # The source commit the package was built from, or nil when unrecorded.
    def commit
      recorded.fetch("commit")
    end

    def development?
      build == DEVELOPMENT
    end

    # Twelve hex characters of the pinned runtime manifest's digest, or "unavailable".
    def manifest
      @manifest ||= begin
        Digest::SHA256.file(File.join(ROOT, "vendor", "manifest.json")).hexdigest[0, 12]
      rescue StandardError
        UNAVAILABLE
      end
    end

    def recorded
      @recorded ||= begin
        stored = JSON.parse(File.read(@record_path || File.join(ROOT, "build.json")))
        build = stored["build"].to_s
        commit = stored["commit"].to_s
        { "build" => BUILD_PATTERN.match?(build) ? build : UNAVAILABLE,
          "commit" => COMMIT_PATTERN.match?(commit) ? commit : nil }.freeze
      rescue Errno::ENOENT
        { "build" => DEVELOPMENT, "commit" => nil }.freeze
      rescue StandardError
        { "build" => UNAVAILABLE, "commit" => nil }.freeze
      end
    end

    def reset_for_test
      @recorded = nil
      @manifest = nil
      @record_path = nil
    end
  end

  on_reset("build_identity") { BuildIdentity.reset_for_test }
end
