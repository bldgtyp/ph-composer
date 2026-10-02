# frozen_string_literal: true

module PhComposer
  module Export
    # A contributor refuses to export the Model, or the Model holds data export cannot safely leave
    # out. The message says what to do; nothing is written.
    class Blocked < CodedError; end

    # How an export contributor reads records (context/CONTRACTS.md, "Records and extension data").
    # Only a kind's declared values and the extension fields the contributor names leave the Model:
    #
    # - `user_data` never does; a record that has some gets a finding saying it was left out.
    # - An extension envelope the contributor names must be understood, and only the named payload
    #   fields go out.
    # - Any other envelope is left out when it declares itself `local_only`, and blocks the export when
    #   it is `required` or its relevance is unknown: nothing guesses from a payload's text.
    class RecordReader
      Finding = Struct.new(:code, :section, :object_id, :message, keyword_init: true) do
        def to_h
          { "code" => code, "section" => section, "object_id" => object_id, "message" => message }
        end
      end

      attr_reader :findings

      def initialize(engine, catalog)
        @engine = engine
        @catalog = catalog
        @findings = []
        @section = nil
      end

      # Runs the block as the reader for `section`, so findings name the section they arose in.
      def within(section)
        previous = @section
        @section = section
        yield
      ensure
        @section = previous
      end

      # Every record of `kind_id`, in id order, as `{"id" => id, <values>..., "extensions" => {...}}`.
      # `extensions` maps a namespace to the payload fields to include.
      def records(kind_id, extensions: {})
        @engine.ids(kind_id).sort.map { |id| record(kind_id, @engine.find(kind_id, id), extensions) }
      end

      # Entity-owned feature records use the same metadata boundary. `fields` is an explicit
      # contributor allowlist; an omitted core field never leaves under an opaque value slot.
      def entity_record(stored, fields:)
        id = stored.fetch("id")
        omit_metadata(id) unless stored.fetch("user_data", {}).empty?
        stored.fetch("extension_data", {}).each { |namespace, envelope| leave_out(id, namespace, envelope) }
        { "id" => id }.merge(DeepCopy.call(stored.slice(*fields)))
      end

      private

      def record(kind_id, stored, extensions)
        id = stored.fetch("id")
        omit_metadata(id) unless stored.fetch("user_data", {}).empty?
        exported = stored.fetch("extension_data", {}).each_with_object({}) do |(namespace, envelope), out|
          fields = extensions[namespace]
          if fields
            out[namespace] = declared_payload(id, namespace, envelope, fields)
          else
            leave_out(id, namespace, envelope)
          end
        end
        values = DeepCopy.call(@engine.kind(kind_id).values(stored))
        { "id" => id }.merge(values).merge(exported.empty? ? {} : { "extensions" => exported })
      end

      def declared_payload(id, namespace, envelope, fields)
        status = Records::Extension.status(envelope, @catalog.extension(namespace))
        unless status == "understood"
          code = { "unavailable" => "extension.unavailable", "invalid" => "extension.invalid" }
                 .fetch(status, "extension.schema_unsupported")
          block(code,
                "#{namespace} data on #{id} is #{status}, so it cannot be exported. Nothing was written.")
        end
        DeepCopy.call(envelope.fetch("payload").slice(*fields))
      end

      def leave_out(id, namespace, envelope)
        relevance = Records::Extension.readable?(envelope) ? envelope.fetch("export_relevance", "unknown") : "unknown"
        case relevance
        when "local_only"
          note("export.metadata_omitted", id, "#{namespace} data is local to this Model and was not exported.")
        when "required"
          block("extension.unavailable",
                "#{id} holds #{namespace} data that export needs, and nothing installed exports it. " \
                "Nothing was written.")
        else
          block("export.relevance_unknown",
                "#{id} holds #{namespace} data whose effect on the export is unknown. Nothing was written.")
        end
      end

      def omit_metadata(id)
        note("export.metadata_omitted", id, "User data is local to this Model and was not exported.")
      end

      def note(code, id, message)
        @findings << Finding.new(:code => code, :section => @section, :object_id => id, :message => message)
      end

      def block(code, message)
        raise Blocked.new(code, message, "section" => @section)
      end
    end
  end
end
