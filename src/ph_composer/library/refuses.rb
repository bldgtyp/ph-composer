# frozen_string_literal: true

module PhComposer
  module Library
    # Library operations own their coordination failures. Local callback failures are declared by
    # each installed kind owner and projected for the operations that run those callbacks.
    module Refuses
      CALLBACKS = { "ph_composer.library.copy" => %i[local_read create replace assign],
                    "ph_composer.library.copy_into_proposal" => %i[local_read create replace assign],
                    "ph_composer.library.in_file" => [:local_read] }.transform_values(&:freeze).freeze

      def self.callback_codes(registry, operation_name)
        callbacks = CALLBACKS.fetch(operation_name, [])
        registry.library_kinds.values.flat_map do |kind|
          callbacks.flat_map { |part| kind.adapter[part]&.refuses || [] }
        end
      end

      PAGE = %w[query.cursor_expired query.limit_invalid].freeze
      PROVIDERS = %w[library.provider_ambiguous library.provider_failed library.provider_invalid].freeze
      LOAD = (PROVIDERS + %w[library.kind_unavailable library.provider_unavailable]).freeze
      CATALOG = (LOAD + PAGE + %w[library.catalog_stale]).freeze
      IN_FILE = (CATALOG + %w[library.adapter_invalid library.callback_invalid library.row_semantic_invalid
                              record.unreadable]).freeze
      COPY = (LOAD + %w[copy.rule_missing extension.invalid identity.conflict library.adapter_invalid
                        library.callback_invalid library.catalog_stale library.local_choice_required
                        library.review_required library.row_semantic_invalid
                        library.row_unavailable proposal.contribution_replaced proposal.foreign_write record.unreadable
                        reference.invalid target.ambiguous target.changed target.locked target.not_found
                        target.shared_definition target.wrong_hierarchy target.wrong_kind
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
