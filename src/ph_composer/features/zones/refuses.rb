# frozen_string_literal: true

module PhComposer
  module Zones
    # The codes Zones operations refuse with, beyond the common sets of their kind (context/CONTRACTS.md,
    # "Outcomes and codes"). Most come from the shared paths named here; an operation adds its own.
    module Refuses
      # Walking the Zones of the Model reads every stored Zone record.
      READ = %w[record.unreadable target.wrong_kind validation.failed].freeze
      PAGE = %w[query.cursor_expired query.limit_invalid].freeze
      # Resolving an explicit Zone occurrence for an edit.
      ZONE_TARGET = %w[record.unreadable target.ambiguous target.changed target.locked target.not_found
                       target.shared_definition target.wrong_hierarchy target.wrong_kind validation.failed].freeze
      # Resolving an explicit Face occurrence, which also checks the Face is stamped for its Zone.
      FACE_TARGET = (ZONE_TARGET + %w[target.wrong_zone]).freeze
      # Classifying Faces may retire or need a Surface pair, and is bounded in size.
      CLASSIFY = (FACE_TARGET + %w[adjacency.not_surface adjacency.unresolved gesture.retirement_conflict
                                   gesture.too_large]).freeze
      SOLVE = (FACE_TARGET + %w[adjacency.stale adjacency.unresolved copy.rule_missing extension.invalid
                                geometry.invalid reference.invalid scope.incomplete target.same_zone]).freeze
      REPAIR_SPLIT_FACE = (FACE_TARGET + %w[adjacency.unresolved copy.rule_missing extension.invalid
                                            face.identity_unique identity.choice_conflicts identity.choice_required
                                            reference.invalid scope.incomplete]).freeze
      REPAIR_IDENTITY = (ZONE_TARGET - %w[target.changed target.locked] +
                         %w[copy.rule_missing extension.invalid reference.invalid zone.identity_unique]).freeze
      RESTORE = %w[record.unreadable target.changed target.not_found target.wrong_kind validation.failed
                   zone.identity_in_use zone.restore_unsafe zone.options_adoption_required reference.invalid].freeze
      # Editing, copying and deleting an Attached zone through the record engine. An edit or copy checks
      # every reference the record carries, an extension's included, and an entity id may now occur twice.
      RECORD_EDIT = %w[record.unreadable reference.invalid target.ambiguous target.changed target.not_found
                       validation.failed].freeze
      RECORD_COPY = %w[copy.rule_missing extension.invalid record.unreadable reference.invalid target.ambiguous
                       target.not_found validation.failed].freeze
      RECORD_DELETE = %w[copy.rule_missing record.unreadable reference.in_use target.not_found target.wrong_kind
                         validation.failed].freeze
    end
  end
end
