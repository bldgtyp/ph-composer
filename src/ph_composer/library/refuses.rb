# frozen_string_literal: true

module PhComposer
  module Library
    # The codes library operations refuse with, beyond the common sets of their kind (context/CONTRACTS.md,
    # "Outcomes and codes"). Copying runs the receiving kind's own callbacks, so COPY includes the shared
    # codes their create, replace and assign paths answer. A code under the receiving feature's own noun
    # also reaches the caller, but the foundation names no feature, so COPY cannot list it.
    module Refuses
      PAGE = %w[query.cursor_expired query.limit_invalid].freeze
      PROVIDERS = %w[library.provider_ambiguous library.provider_failed library.provider_invalid].freeze
      LOAD = (PROVIDERS + %w[library.kind_unavailable library.provider_unavailable]).freeze
      CATALOG = (LOAD + PAGE + %w[library.catalog_stale]).freeze
      IN_FILE = (CATALOG + %w[library.adapter_invalid library.callback_invalid library.row_semantic_invalid
                             record.unreadable]).freeze
      COPY = (LOAD + %w[copy.rule_missing extension.invalid geometry.invalid identity.conflict library.adapter_invalid
                        library.callback_invalid library.catalog_stale library.local_choice_required
                        library.mutation_owner library.review_required library.row_semantic_invalid library.row_unavailable
                        record.unreadable
                        reference.invalid target.ambiguous target.changed target.locked target.not_found
                        target.shared_definition target.wrong_hierarchy target.wrong_kind target.wrong_zone
                        validation.failed]).freeze
      EXPORTABLE = %w[library.adapter_invalid library.catalog_too_many_rows library.kind_unavailable
                      record.unreadable target.not_found].freeze
      EXPORT_PREVIEW = (EXPORTABLE + %w[library.destination_invalid library.export_write_failed location.kind_mismatch
                                        location.revoked location.setup_unavailable location.setup_unreadable
                                        location.unavailable location.unknown location.used]).freeze
      EXPORT_FILE = (EXPORTABLE + %w[export.replace_required library.destination_changed
                                     library.destination_invalid library.export_write_failed
                                     library.file_malformed library.file_too_large library.format_invalid
                                     library.schema_unsupported library.update_destination_invalid
                                     library.update_destination_required revision.stale]).freeze
    end
  end
end
