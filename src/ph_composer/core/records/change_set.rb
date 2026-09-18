# frozen_string_literal: true

module PhComposer
  module Records
    # The complete set of record writes one operation proposes. Handlers build it without writing;
    # the dispatcher validates it whole, then the engine applies it inside one native operation.
    # Each write keeps the record as it was, so an abort can be verified against it. A proposal that
    # raises marks the set refused, and the dispatcher never applies a refused set.
    class ChangeSet
      Write = Struct.new(:kind, :id, :before, :after, keyword_init: true) do
        def change
          before.nil? ? "created" : "updated"
        end
      end

      attr_reader :writes, :refusal

      def initialize
        @writes = []
        @refusal = nil
      end

      # Marks the set as refused. The engine calls this when a proposal raises, so a handler that
      # rescues the refusal cannot commit what was staged before it.
      def refuse(error)
        @refusal ||= error
      end

      # Records the write unless it would change nothing, so a no-change edit opens no operation.
      def put(kind, before:, after:)
        id = after.fetch("id")
        raise ArgumentError, "#{kind} #{id} is already in this change set." if find(kind, id)
        return if before == after

        @writes << Write.new(:kind => kind, :id => id, :before => before, :after => after)
      end

      def find(kind, id)
        @writes.find { |write| write.kind == kind && write.id == id }
      end

      def empty?
        @writes.empty?
      end

      # What a caller reads back: every record the operation created or changed.
      def affected
        @writes.map { |write| { "kind" => write.kind, "id" => write.id, "change" => write.change } }
      end
    end
  end
end
