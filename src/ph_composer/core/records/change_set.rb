# frozen_string_literal: true

module PhComposer
  module Records
    # The complete set of record writes one operation proposes. Handlers build it without writing;
    # the dispatcher validates it whole, then the engine applies it inside one native operation.
    # Each write keeps the record as it was, so an abort can be verified against it. A proposal that
    # raises marks the set refused, and the dispatcher never applies a refused set.
    class ChangeSet
      Write = Struct.new(:kind, :id, :before, :after, keyword_init: true) do
        # The write as a proposal's descriptor and a contribution snapshot both record it.
        def descriptor
          { "kind" => kind, "id" => id, "before" => before, "after" => after }
        end

        def change
          return "created" if before.nil?
          return "deleted" if after.nil?

          "updated"
        end
      end

      attr_reader :refusal

      def initialize
        @writes = []
        @refusal = nil
      end

      # The staged writes, in order, as a frozen list of frozen writes: the only way to add or change
      # one is `put`, `restage` and `delete`, which the write guard sees.
      def writes
        @writes.dup.freeze
      end

      # Marks the set as refused. The engine calls this when a proposal raises, so a handler that
      # rescues the refusal cannot commit what was staged before it.
      def refuse(error)
        @refusal ||= error
      end

      # While the block runs, every write must be to one of `kinds`; any other refuses the whole set
      # with `code`. The foundation confines a contributor that shares another's proposal this way
      # (a proposal participant, a library callback), whether it writes through an engine or calls
      # `put` itself. Guards nest; the innermost decides, so a contributor may delegate to a narrower
      # or different owner for the length of that owner's call.
      def guarded(kinds, code)
        (@guards ||= []).push([kinds, code])
        yield
      ensure
        @guards.pop
      end

      # Records the write unless it would change nothing, so a no-change edit opens no operation.
      def put(kind, before:, after:)
        raise ArgumentError, "a record change needs a before or after value" if before.nil? && after.nil?

        guard!(kind)

        id = (after || before).fetch("id")
        raise ArgumentError, "#{kind} #{id} is already in this change set." if find(kind, id)
        return if before == after

        # The admitted write keeps its own frozen values, so nothing the caller retains can change it.
        @writes << Write.new(:kind => DeepCopy.frozen(kind), :id => DeepCopy.frozen(id),
                             :before => DeepCopy.frozen(before), :after => DeepCopy.frozen(after)).freeze
      end

      # Replaces what an already staged write leaves behind, keeping its `before`. The owner's second
      # pass over a record it just staged (a create completed with remapped extension data) uses this
      # rather than editing the staged record, which is frozen; the write guard sees it like a `put`.
      def restage(kind, id, after:)
        guard!(kind)
        index = @writes.index { |write| write.kind == kind && write.id == id }
        raise ArgumentError, "#{kind} #{id} is not in this change set." unless index

        @writes[index] = Write.new(:kind => @writes[index].kind, :id => @writes[index].id,
                                   :before => @writes[index].before, :after => DeepCopy.frozen(after)).freeze
      end

      def delete(kind, before:)
        put(kind, :before => before, :after => nil)
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

      private

      def guard!(kind)
        kinds, code = @guards&.last
        return if kinds.nil? || kinds.include?(kind)

        error = CodedError.new(code, "This contribution cannot stage a #{kind} write.")
        refuse(error)
        raise error
      end
    end
  end
end
