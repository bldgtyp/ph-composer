# frozen_string_literal: true

module PhComposer
  # The foundation's own read of stored records, registered through the same interface a feature uses.
  # It serves every record kind, so a new kind is readable by every client without adding a query.
  #
  # Pages are bound to the revision they were read at (context/CONTRACTS.md, "Public interface"), and
  # to the session, query and filter (shell/pages.rb): a cursor from anything else is refused.
  module RecordQueries
    FEATURE_ID = "ph_composer.records"
    LIST = "#{FEATURE_ID}.list"

    PARAMS = {
      "type" => "object",
      "additionalProperties" => false,
      "required" => ["kind"],
      "properties" => {
        "kind" => { "type" => "string", "description" => "Record kind id, as listed by discovery." },
        "ids" => { "type" => "array", "items" => { "type" => "string" }, "maxItems" => Pages::MAXIMUM_LIMIT,
                   "description" => "Only these records." },
        "fields" => { "type" => "array", "items" => { "type" => "string" },
                      "description" => "Only these values of each record; all when absent." },
        "limit" => Pages::LIMIT, "cursor" => Pages::CURSOR
      }
    }.freeze

    RESULT = {
      "type" => "object",
      "required" => %w[records next_cursor unreadable units total],
      "properties" => {
        "records" => { "type" => "array", "items" => { "type" => "object" } },
        "next_cursor" => Pages::NEXT_CURSOR,
        "unreadable" => { "type" => "array", "items" => { "type" => "object" } },
        "units" => { "type" => "object", "description" => "The SI unit of each numeric value, by field key." },
        "total" => Pages::TOTAL
      }
    }.freeze

    module_function

    def install(registry)
      feature = registry.feature(FEATURE_ID, :contract_version => Declarations::CONTRACT_VERSION)
      feature.query(LIST, :description => "Stored records of one kind, in id order, a page at a time.",
                          :refuses => %w[query.cursor_expired query.limit_invalid],
                          :params => PARAMS, :result => RESULT,
                          :examples => [{ "kind" => "example.foundation.part", "limit" => 20 }]) do |request|
        list(request)
      end
    end

    def list(request)
      params = request.params
      kind = request.engine.kind(params.fetch("kind"))
      ids = request.engine.ids(kind.id).sort
      ids &= params["ids"] if params.key?("ids")
      page, next_cursor = Pages.slice(request, LIST, ids, :key => ->(id) { id })
      records, unreadable = read_page(request.engine, kind, page, params["fields"])
      { "records" => records, "unreadable" => unreadable, "next_cursor" => next_cursor, "units" => units(kind),
        "total" => ids.length }
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
  end
end
