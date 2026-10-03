# frozen_string_literal: true

module PhComposer
  module Assemblies
    # The codes Material and Assembly operations refuse with, beyond the common sets of their kind
    # (context/CONTRACTS.md, "Outcomes and codes"). Every write goes through the record engine.
    module Refuses
      PAGE = %w[query.cursor_expired query.limit_invalid].freeze
      CREATE = %w[record.unreadable reference.invalid validation.failed].freeze
      # An edit, and every Layer and Layer-Segment gesture, which edits one Assembly. An edit or copy checks
      # every reference the record carries, an extension's included, and an entity id may now occur twice.
      EDIT = %w[record.unreadable reference.invalid target.ambiguous target.changed target.not_found
                validation.failed].freeze
      DUPLICATE = %w[copy.rule_missing extension.invalid record.unreadable reference.invalid target.ambiguous
                     target.not_found validation.failed].freeze
      # A delete asks every referring feature to retarget, so it answers their reference codes too.
      DELETE = %w[copy.rule_missing record.unreadable reference.in_use reference.invalid target.changed
                  target.not_found target.wrong_kind validation.failed].freeze
    end
  end
end
