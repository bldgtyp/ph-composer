# frozen_string_literal: true

require_relative "callback_invoker"
require_relative "resolver"
require_relative "state"

module PhComposer
  module Library
    # Review resolves detached values. Explicit choices call only the record owner's registered
    # callbacks, with copy and assignment sharing the dispatcher's single guarded proposal.
    module Coordinator
      module_function

      def inspect_row(request)
        declaration, entry, row = selected(request)
        mapped = map(declaration.adapter, row.fetch("snapshot"))
        source = identity(request, row)
        locals = CallbackInvoker.call(request, declaration, declaration.adapter.local_read, {}, :readonly => true)
        resolution = resolve(declaration.adapter, source, mapped, locals)
        [declaration, entry, row, mapped, source, resolution]
      end

      # Compare incoming semantic content with the stored attribution, not with local edits.
      # An older fingerprint contract cannot establish whether the provider changed.
      def resolve(adapter, source, mapped, locals)
        result = Resolver.resolve(:source => source, :mapped => mapped, :locals => locals)
        fingerprint = adapter.fingerprint.call(DeepCopy.call(mapped))
        unless fingerprint.is_a?(String) && /\A[0-9a-f]{64}\z/.match?(fingerprint)
          raise Error.new("library.adapter_invalid", "The kind adapter returned an invalid semantic fingerprint.")
        end
        result.fetch("candidates").each do |candidate|
          attribution = locals.find { |row| row.fetch("id") == candidate.fetch("id") }["source"]
          compatible = attribution.is_a?(Hash) && attribution["kind"] == "library" &&
                       attribution["fingerprint_version"] == adapter.fingerprint_version &&
                       attribution["fingerprint"].is_a?(String) && /\A[0-9a-f]{64}\z/.match?(attribution["fingerprint"])
          candidate["comparison_available"] = !!compatible
          candidate["source_changed"] = compatible ? attribution["fingerprint"] != fingerprint : nil
        end
        result
      end

      def copy(request, proposal)
        declaration, entry, row, mapped, identity, resolution = inspect_row(request)
        choice = request.params.fetch("choice", "inspect")
        result = { "resolution" => resolution, "local_id" => nil, "assigned" => false }
        return result if %w[inspect cancel].include?(choice)

        id = local_id(request.params["local_id"], resolution)
        case choice
        when "create"
          unless resolution.fetch("outcome") == "create"
            raise Error.new("library.review_required", "Resolve the existing local candidates before copying.")
          end
          source = attribution(request, declaration.adapter, entry, row, identity, mapped)
          value = CallbackInvoker.call(request, declaration, declaration.adapter.create,
                                       { "values" => mapped.merge("source" => source) })
          id = value.fetch("id")
        when "keep_local"
          raise Error.new("library.local_choice_required", "Choose an existing local record.") unless id
        when "use_library"
          raise Error.new("library.local_choice_required", "Choose an existing local record.") unless id

          expected = request.params["expected_values"]
          unless reviewed_values?(expected, id, resolution)
            raise Error.new("params.invalid", "Replacement needs the reviewed local values.")
          end
          source = attribution(request, declaration.adapter, entry, row, identity, mapped)
          CallbackInvoker.call(request, declaration, declaration.adapter.replace,
                               { "id" => id, "values" => mapped.merge("source" => source),
                                 "expected_values" => expected })
        else
          raise Error.new("params.invalid", "Choose an explicit library copy action.")
        end
        result["assigned"] = assign(request, declaration, id)
        result["local_id"] = id
        result
      rescue StandardError => error
        proposal.refuse(error)
        raise
      end

      def assign(request, declaration, id)
        target = request.params["assignment"]
        return false unless target
        unless declaration.adapter.assign
          raise Error.new("library.assignment_unavailable", "This record kind does not support assignment.")
        end
        CallbackInvoker.call(request, declaration, declaration.adapter.assign, { "target" => target, "local_id" => id })
        true
      end

      def reviewed_values?(expected, id, resolution)
        return false unless expected.is_a?(Hash) && !expected.empty?

        candidate = resolution.fetch("candidates").find { |row| row.fetch("id") == id }
        actual = candidate.fetch("expected_values")
        actual.all? { |field, value| expected.key?(field) && expected[field] == value }
      end

      def selected(request)
        params = request.params
        declaration = State.kind(params.fetch("kind"), request.registry)
        entry = State.for(request.session).fetch(params.fetch("provider_id"), params.fetch("kind"), request.registry,
                                                  :generation => params.fetch("generation"))
        rows = entry.fetch("rows").select do |row|
          row.fetch("library_id") == params.fetch("library_id") && row.fetch("record_id") == params.fetch("record_id")
        end
        unless rows.length == 1
          raise Error.new("library.row_unavailable", "The selected library record is unavailable or ambiguous.")
        end
        [declaration, entry, rows.first]
      end

      def map(adapter, snapshot)
        mapped = adapter.map.call(DeepCopy.call(snapshot))
        validate!(mapped, adapter.mapped_schema)
        DeepCopy.call(mapped)
      end

      def identity(request, row)
        provider = State.for(request.session).provider(request.params.fetch("provider_id"), request.registry)
        { "provider_kind" => provider.provider_kind, "library_id" => row.fetch("library_id"),
          "record_kind" => request.params.fetch("kind"), "record_id" => row.fetch("record_id") }
      end

      def attribution(request, adapter, entry, row, identity, mapped)
        fingerprint = adapter.fingerprint.call(DeepCopy.call(mapped))
        unless fingerprint.is_a?(String) && /\A[0-9a-f]{64}\z/.match?(fingerprint)
          raise Error.new("library.adapter_invalid", "The kind adapter returned an invalid semantic fingerprint.")
        end
        keys = adapter.mapped_schema.fetch("properties").keys
        snapshot = row.fetch("snapshot").slice(*keys)
        identity.merge("kind" => "library", "fingerprint" => fingerprint,
          "fingerprint_version" => adapter.fingerprint_version,
          "copied_at" => State.for(request.session).copy_time(request.revision, [entry.fetch("generation"), identity]),
          "snapshot" => DeepCopy.call(snapshot))
      end

      def local_id(id, resolution)
        candidates = resolution.fetch("candidates")
        return candidates.first.fetch("id") if id.nil? && candidates.length == 1
        return nil if id.nil? && candidates.empty?
        return id if candidates.any? { |row| row.fetch("id") == id }

        raise Error.new("library.local_choice_required", "Choose one of the reviewed local candidates.")
      end

      def validate!(value, schema)
        return if JsonValue.problems(value).empty? && JsonSchema.validate(value, schema).empty?

        raise Error.new("library.adapter_invalid", "The kind adapter returned invalid mapped values.")
      end
      private_class_method :reviewed_values?, :assign, :selected, :map, :identity, :attribution, :local_id, :validate!
    end
  end
end
