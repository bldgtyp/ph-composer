# frozen_string_literal: true

module PhComposer
  # The foundation's own read of stored records, registered through the same interface a feature uses.
  # It serves every record kind, so a new kind is readable by every client without adding a query.
  #
  # Pages are bound to the revision they were read at (CONTRACTS.md C2): a cursor from an older
  # revision is refused rather than silently mixing two states of the Model.
  module RecordQueries
    FEATURE_ID = "ph_composer.records"
    LIST = "#{FEATURE_ID}.list"
    DEFAULT_LIMIT = 100
    MAXIMUM_LIMIT = 500

    PARAMS = {
      "type" => "object",
      "additionalProperties" => false,
      "required" => ["kind"],
      "properties" => {
        "kind" => { "type" => "string", "description" => "Record kind id, as listed by discovery." },
        "ids" => { "type" => "array", "items" => { "type" => "string" }, "maxItems" => MAXIMUM_LIMIT,
                   "description" => "Only these records." },
        "fields" => { "type" => "array", "items" => { "type" => "string" },
                      "description" => "Only these values of each record; all when absent." },
        "limit" => { "type" => "number", "description" => "Page size, 1 to #{MAXIMUM_LIMIT}; #{DEFAULT_LIMIT} " \
                                                          "when absent." },
        "cursor" => { "type" => "string", "description" => "next_cursor from the previous page." }
      }
    }.freeze

    RESULT = {
      "type" => "object",
      "required" => %w[records next_cursor unreadable units total],
      "properties" => {
        "records" => { "type" => "array", "items" => { "type" => "object" } },
        "next_cursor" => { "type" => %w[string null] },
        "unreadable" => { "type" => "array", "items" => { "type" => "object" } },
        "units" => { "type" => "object", "description" => "The SI unit of each numeric value, by field key." },
        "total" => { "type" => "integer", "description" => "Records matching the filter, on every page." }
      }
    }.freeze

    module_function

    def install(registry)
      feature = registry.feature(FEATURE_ID, :contract_version => Declarations::CONTRACT_VERSION)
      feature.query(LIST, :description => "Stored records of one kind, in id order, a page at a time.",
                          :params => PARAMS, :result => RESULT,
                          :examples => [{ "kind" => "example.foundation.part", "limit" => 20 }]) do |request|
        list(request)
      end
    end

    def list(request)
      params = request.params
      limit = page_limit(params)
      kind = request.engine.kind(params.fetch("kind"))
      ids = request.engine.ids(kind.id)
      ids &= params["ids"] if params.key?("ids")
      after = cursor_position(params["cursor"], request.revision)
      remaining = after ? ids.select { |id| id > after } : ids
      page = remaining.first(limit)
      records, unreadable = read_page(request.engine, kind, page, params["fields"])
      {
        "records" => records, "unreadable" => unreadable,
        "next_cursor" => remaining.length > limit ? cursor(request.revision, page.last) : nil,
        "units" => units(kind), "total" => ids.length
      }
    end

    def page_limit(params)
      limit = params.fetch("limit", DEFAULT_LIMIT)
      return limit if limit.is_a?(Integer) && limit.between?(1, MAXIMUM_LIMIT)

      raise CodedError.new("query.limit_invalid", "The page limit must be a whole number from 1 to #{MAXIMUM_LIMIT}.")
    end

    def read_page(engine, kind, ids, fields)
      unknown = Array(fields) - kind.fields.map(&:key)
      raise CodedError.new("params.invalid", "#{kind.label} has no field #{unknown.first}.") unless unknown.empty?

      records = []
      unreadable = []
      ids.each do |id|
        view = engine.view(kind.id, engine.find(kind.id, id))
        view["values"] = view["values"].select { |key, _value| fields.include?(key) } if fields
        records << view
      rescue CodedError => error
        unreadable << { "id" => id, "code" => error.code, "message" => error.message }
      end
      [records, unreadable]
    end

    def units(kind)
      kind.fields.each_with_object({}) do |field, units|
        unit = field.schema["x-unit"]
        units[field.key] = unit if unit
      end
    end

    def cursor(revision, after)
      [JSON.generate("revision" => revision, "after" => after)].pack("m0")
    end

    def cursor_position(cursor, revision)
      return nil if cursor.nil?

      decoded = JSON.parse(cursor.unpack1("m0"))
      # Record ids are strings; a cursor this query issued always names one.
      raise ArgumentError, "not a cursor" unless decoded.is_a?(Hash) && decoded["after"].is_a?(String)
      unless decoded["revision"] == revision
        raise CodedError.new("query.cursor_expired", "The Model changed since this page was read; start again " \
                                                     "from the first page.")
      end

      decoded.fetch("after")
    rescue JSON::ParserError, ArgumentError
      raise CodedError.new("params.invalid", "That cursor is not one this query issued.")
    end
  end
end
