# frozen_string_literal: true

module PhComposer
  module Assemblies
    # Reads every Assemblies definition kind shares. Feature handlers read the explicit record target
    # and stage through the public record engine; the dispatcher validates and applies the entire
    # proposal in one native transaction.
    module Catalog
      module_function

      # Preview and invoke rebuild the same nested identities at the same revision. The allocator
      # is proposal-local and deterministic; it retains no state across Models or requests. `inputs`
      # are the operation's arguments, so two different edits at one revision derive different ids.
      def identity_allocator(request, inputs)
        sequence = 0
        lambda do |prefix|
          sequence += 1
          Records::Identity.derived(prefix, "session" => request.session.id, "revision" => request.revision,
                                    "params" => inputs, "position" => sequence)
        end
      end

      def records(request, kind)
        request.engine.ids(kind).map { |id| request.engine.find(kind, id) }
      end

      def materials(request)
        records(request, MATERIAL_KIND).to_h { |row| [row.fetch("id"), row] }
      end

      def changed_values(kind, before, after)
        values = kind.values(after)
        (kind.values(before).keys | values.keys).each_with_object({}) do |key, changed|
          changed[key] = values[key] if before[key] != values[key] || before.key?(key) != values.key?(key)
        end
      end
    end
  end
end
