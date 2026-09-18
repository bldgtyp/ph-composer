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
        [section.name, API.query(:context => context, :name => section.query, :params => section.params)]
      end
      session = Sessions.find(context.session_id)
      { "session" => context.session_id, "revision" => session&.revision, "sections" => sections }
    end
  end
end
