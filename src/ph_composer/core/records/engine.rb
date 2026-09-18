# frozen_string_literal: true

require "json"

module PhComposer
  module Records
    # Reads records and proposes changes to them for one Model. It owns identity, reference checks,
    # metadata and extension-data rules (CONTRACTS.md C5). Reads never repair or write. Proposals add
    # writes to a ChangeSet and never write; `apply` writes a validated set and is called only inside
    # the dispatcher's operation (shell/dispatch.rb).
    #
    # Refusals raise CodedError with a code from CONTRACTS.md "Outcome vocabulary".
    class Engine
      def initialize(model, catalog)
        @model = model
        @catalog = catalog
      end

      # ---------------------------------------------------------------- reads

      # The stored record, or a refusal naming why it cannot be used.
      def find(kind_id, id)
        kind = @catalog.kind(kind_id)
        record = read(kind, id)
        raise CodedError.new("target.not_found", "There is no #{kind.label} with id #{id}.") unless record

        problems = kind.problems(record)
        return record if problems.empty?

        raise CodedError.new("record.unreadable", "#{kind.label} #{id} cannot be used: #{problems.first}.",
                             "findings" => problems)
      end

      def kind(kind_id)
        @catalog.kind(kind_id)
      end

      def ids(kind_id)
        @catalog.kind(kind_id).store.ids(@model)
      end

      # The caller's view of a stored record: values apart from metadata, absent metadata as empty, and
      # each extension envelope's status. The stored record is not changed.
      def view(kind_id, record)
        extension_data = record.fetch("extension_data", {})
        {
          "kind" => kind_id,
          "id" => record.fetch("id"),
          "schema_version" => record.fetch("schema_version"),
          "values" => DeepCopy.call(@catalog.kind(kind_id).values(record)),
          "user_data" => DeepCopy.call(record.fetch("user_data", {})),
          "extension_data" => DeepCopy.call(extension_data),
          "extension_status" => extension_data.to_h do |namespace, envelope|
            [namespace, Extension.status(envelope, @catalog.extension(namespace))]
          end
        }
      end

      # ---------------------------------------------------------------- proposals

      def propose_create(kind_id, change_set, values:, user_data: nil)
        staging(change_set) do
          kind = @catalog.kind(kind_id)
          id = Identity.fresh(kind.id_prefix, reserved_ids(kind, change_set))
          check_value_keys!(kind, values)
          record = { "id" => id, "schema_version" => kind.schema_version }.merge(DeepCopy.call(values))
          record["user_data"] = checked_user_data(user_data) unless user_data.nil?
          propose(kind, change_set, nil, record)
          id
        end
      end

      # An ordinary edit. `values` replaces the named fields (nil removes an optional one); `user_data`,
      # when given, replaces the whole mapping. Extension payloads the edit does not name are carried
      # through as they were stored, whether or not their extension is installed. `expected_values`
      # are the values the caller last read; any that differ now refuse the edit.
      def propose_update(kind_id, id, change_set, values: {}, user_data: nil, extension_payloads: {},
                         expected_values: {})
        staging(change_set) do
          kind = @catalog.kind(kind_id)
          before = find(kind_id, id)
          check_expected!(kind, before, expected_values)
          after = DeepCopy.call(before)
          check_value_keys!(kind, values)
          values.each { |key, value| value.nil? ? after.delete(key) : after[key] = DeepCopy.call(value) }
          after["user_data"] = checked_user_data(user_data) unless user_data.nil?
          extension_payloads.each { |namespace, payload| set_extension_payload(after, namespace, payload) }
          propose(kind, change_set, before, after)
        end
      end

      # Duplicates records as one collection: every new id is allocated first, then each reference
      # between copied records points to the new counterpart while references outside the copy stay
      # shared. `user_data` is copied unchanged. A copy that needs copy rules the installed extensions
      # do not provide is refused whole. Returns the old-to-new id mapping.
      def propose_duplicate(kind_id, ids, change_set)
        staging(change_set) do
          kind = @catalog.kind(kind_id)
          originals = ids.uniq.map { |id| find(kind_id, id) }
          originals.each { |record| check_copy_rules!(kind, record) }
          reserved = reserved_ids(kind, change_set)
          mapping = originals.to_h { |record| [record.fetch("id"), Identity.fresh(kind.id_prefix, reserved)] }
          copies = originals.map do |record|
            copy = kind.references.reduce(DeepCopy.call(record)) { |value, field| field.remap(value, mapping) }
            copy["id"] = mapping.fetch(record.fetch("id"))
            copy.fetch("extension_data", {}).each_value do |envelope|
              references = envelope.fetch("references", [])
              envelope["payload"] = Extension.remap(envelope.fetch("payload"), references, mapping)
            end
            propose(kind, change_set, nil, copy, :check_references => false)
            copy
          end
          # A copy may name a counterpart staged after it, so references are checked once all are staged.
          copies.each { |copy| check_references!(kind, copy, change_set) }
          mapping
        end
      end

      # Raises one namespace's payload to the installed version on each record, through the declared
      # migrations, validating the result. Any failure refuses the whole proposal, so the stored data
      # stays as it was. Returns each record's result: migrated, current or absent.
      def propose_migration(kind_id, ids, namespace, change_set)
        staging(change_set) do
          kind = @catalog.kind(kind_id)
          extension = @catalog.extension(namespace)
          ids.uniq.to_h do |id|
            before = find(kind_id, id)
            envelope = before.dig("extension_data", namespace)
            next [id, "absent"] unless envelope

            status = Extension.status(envelope, extension)
            refuse_extension!(namespace, id, status) unless %w[understood outdated].include?(status)
            next [id, "current"] if status == "understood"

            after = DeepCopy.call(before)
            after["extension_data"][namespace] = extension.envelope(migrated_payload(extension, envelope, id))
            propose(kind, change_set, before, after)
            [id, "migrated"]
          end
        end
      end

      # ---------------------------------------------------------------- writes

      def apply(change_set)
        change_set.writes.each { |write| @catalog.kind(write.kind).store.write(@model, write.after) }
      end

      # Whether every record the change set names is stored exactly as it was before. The dispatcher
      # checks this after an abort before it reports the operation as rolled back.
      def unchanged?(change_set)
        change_set.writes.all? { |write| read(@catalog.kind(write.kind), write.id) == write.before }
      rescue JSON::ParserError
        false
      end

      private

      # Runs a proposal; a refusal it raises also marks the change set refused (ChangeSet#refuse).
      def staging(change_set)
        yield
      rescue Error => error
        change_set.refuse(error)
        raise
      end

      def read(kind, id)
        kind.store.read(@model, id)
      rescue JSON::ParserError
        raise CodedError.new("record.unreadable", "#{kind.label} #{id} is not valid JSON.")
      end

      def propose(kind, change_set, before, after, check_references: true)
        problems = kind.problems(after)
        unless problems.empty?
          raise CodedError.new("validation.failed", "#{kind.label} #{after['id']} is not valid: #{problems.first}.",
                               "findings" => problems)
        end

        check_references!(kind, after, change_set) if check_references
        change_set.put(kind.id, :before => before, :after => after)
      end

      def check_references!(kind, record, change_set)
        targets = kind.references.flat_map do |reference|
          reference.ids(record).map { |id| [reference.target_kind, id] }
        end
        record.fetch("extension_data", {}).each do |namespace, envelope|
          next unless Extension.status(envelope, @catalog.extension(namespace)) == "understood"

          targets.concat(Extension.referenced_ids(envelope.fetch("payload"), envelope.fetch("references", [])))
        end
        targets.each do |target_kind, id|
          next if change_set.find(target_kind, id) || stored?(target_kind, id)

          message = "#{kind.label} #{record['id']} names #{target_kind} #{id}, which does not exist."
          raise CodedError.new("reference.invalid", message, "target_kind" => target_kind, "id" => id)
        end
      end

      # Identity and metadata change only through their own arguments, never as a value.
      def check_value_keys!(kind, values)
        reserved = values.keys & RecordKind::RESERVED_KEYS
        return if reserved.empty?

        raise CodedError.new("params.invalid", "#{kind.label} values cannot set #{reserved.join(', ')}.")
      end

      def check_expected!(kind, record, expected_values)
        changed = expected_values.keys.reject { |key| record[key] == expected_values[key] }
        return if changed.empty?

        raise CodedError.new("target.changed", "#{kind.label} #{record['id']} has changed since it was read " \
                                               "(#{changed.join(', ')}).", "fields" => changed)
      end

      def check_copy_rules!(kind, record)
        record.fetch("extension_data", {}).each do |namespace, envelope|
          extension = @catalog.extension(namespace)
          status = Extension.status(envelope, extension)
          next if status == "understood" && extension.copy == :remap

          raise CodedError.new(
            "copy.rule_missing",
            "#{kind.label} #{record['id']} carries #{namespace} data (#{status}) that cannot be copied safely.",
            "id" => record["id"], "namespace" => namespace, "status" => status
          )
        end
      end

      def set_extension_payload(record, namespace, payload)
        extension = @catalog.extension(namespace)
        current = record.dig("extension_data", namespace)
        status = current && Extension.status(current, extension)
        writable = extension && [nil, "understood"].include?(status)
        refuse_extension!(namespace, record["id"], status || "unavailable") unless writable
        problems = extension.problems(payload)
        unless problems.empty?
          raise CodedError.new("validation.failed", "#{namespace} data is not valid: #{problems.first}.",
                               "findings" => problems)
        end

        (record["extension_data"] ||= {})[namespace] = extension.envelope(DeepCopy.call(payload))
      end

      def migrated_payload(extension, envelope, id)
        steps = envelope.fetch("schema_version")...extension.schema_version
        payload = steps.reduce(DeepCopy.call(envelope["payload"])) do |value, version|
          extension.migrations.fetch(version).call(value)
        end
        problems = extension.problems(payload)
        return payload if problems.empty?

        message = "#{extension.namespace} data on #{id} is not valid after migration: #{problems.first}."
        raise CodedError.new("extension.migration_failed", message, "findings" => problems)
      rescue StandardError => error
        raise if error.is_a?(CodedError)

        message = "#{extension.namespace} data on #{id} could not be migrated (#{error.class})."
        raise CodedError.new("extension.migration_failed", message)
      end

      def refuse_extension!(namespace, id, status)
        if status == "outdated"
          message = "#{namespace} data on #{id} is stored at an older version; migrate it before changing it."
          raise CodedError.new("extension.migration_required", message, "namespace" => namespace)
        end
        if status == "unavailable"
          raise CodedError.new("extension.unavailable", "#{namespace} is not installed, so its data on #{id} " \
                                                        "cannot be changed.", "namespace" => namespace)
        end

        message = "#{namespace} data on #{id} uses a version the installed extension cannot read."
        raise CodedError.new("extension.schema_unsupported", message, "namespace" => namespace)
      end

      def checked_user_data(user_data)
        problems = user_data.is_a?(Hash) ? JsonValue.problems(user_data) : ["$ must be a JSON object"]
        return DeepCopy.call(user_data) if problems.empty?

        raise CodedError.new("params.invalid", "User data must be plain JSON: #{problems.first}.",
                             "findings" => problems)
      end

      def stored?(kind_id, id)
        @catalog.kind?(kind_id) && !read(@catalog.kind(kind_id), id).nil?
      end

      def reserved_ids(kind, change_set)
        kind.store.ids(@model) + change_set.writes.map(&:id)
      end
    end
  end
end
