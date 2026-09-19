# frozen_string_literal: true

module PhComposer
  # The panel's view of one Model session: each registered snapshot section is the result of its
  # query, run through the same public interface every client uses. A section that fails reports its
  # own outcome; the others are unaffected.
  module Snapshot
    module_function

    def build(context)
      registry = Registry.current
      sections = registry.snapshot_sections.values.to_h do |section|
        [section.name, section_outcome(context, section)]
      end
      session = Sessions.find(context.session_id)
      { "session" => context.session_id, "revision" => session&.revision, "sections" => sections }
    end

    # A section whose query fails (a handler bug, a value that misses its declared result schema) reports
    # the failed outcome the dispatcher gives every client; the error goes to the log there.
    def section_outcome(context, section)
      API.query(:context => context, :name => section.query, :params => section.params)
    end
  end
end
