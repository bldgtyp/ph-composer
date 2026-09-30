# frozen_string_literal: true

module PhComposer
  # Bounded pages for every paged read (context/AGENT_INTERFACE.md, focused reads). A read sorts its
  # rows by a stable key, and a cursor carries the last key it returned together with what it was
  # read against: the Model session, the query, a digest of the filter and the revision. A cursor
  # reused after any of those changed is refused rather than mixing two states or two questions.
  module Pages
    DEFAULT_LIMIT = 100
    MAXIMUM_LIMIT = 500
    LIMIT = { "type" => "number",
              "description" => "Page size, 1 to #{MAXIMUM_LIMIT}; #{DEFAULT_LIMIT} when absent." }.freeze
    CURSOR = { "type" => "string",
               "description" => "next_cursor from the previous page of the same query and filter." }.freeze
    NEXT_CURSOR = { "type" => %w[string null],
                    "description" => "Pass back as cursor for the next page; null on the last page." }.freeze
    TOTAL = { "type" => "integer", "minimum" => 0,
              "description" => "Rows matching the filter, on every page." }.freeze
    PAGE_KEYS = %w[limit cursor].freeze

    module_function

    # [page, next_cursor] of `rows`, which are sorted by `key`.
    def slice(request, query, rows, key:)
      limit = limit(request.params)
      after = position(request, query)
      remaining = after.nil? ? rows : rows.select { |row| (key.call(row) <=> after).positive? }
      page = remaining.first(limit)
      [page, remaining.length > limit ? token(request, query, key.call(page.last)) : nil]
    end

    def limit(params)
      limit = params.fetch("limit", DEFAULT_LIMIT)
      return limit if limit.is_a?(Integer) && limit.between?(1, MAXIMUM_LIMIT)

      raise CodedError.new("query.limit_invalid", "The page limit must be a whole number from 1 to #{MAXIMUM_LIMIT}.")
    end

    def token(request, query, after)
      [JSON.generate(binding_of(request, query).merge("after" => after))].pack("m0")
    end

    def position(request, query)
      cursor = request.params["cursor"]
      return nil if cursor.nil?

      decoded = JSON.parse(cursor.unpack1("m0"))
      raise ArgumentError, "not a cursor" unless decoded.is_a?(Hash) && decoded.key?("after") &&
                                                 [String, Array].include?(decoded["after"].class)

      expected = binding_of(request, query)
      asked = decoded.reject { |key, _value| %w[after revision].include?(key) }
      if asked != expected.reject { |key, _value| key == "revision" }
        raise CodedError.new("params.invalid", "That cursor belongs to another query, filter or Model.")
      end
      unless decoded["revision"] == expected["revision"]
        raise CodedError.new("query.cursor_expired", "The Model changed since this page was read; start again " \
                                                     "from the first page.")
      end

      decoded.fetch("after")
    rescue JSON::ParserError, ArgumentError
      raise CodedError.new("params.invalid", "That cursor is not one this query issued.")
    end

    def binding_of(request, query)
      { "session" => request.session.id, "query" => query, "revision" => request.revision,
        "filter" => CanonicalJson.digest(request.params.reject { |key, _value| PAGE_KEYS.include?(key) }) }
    end
    private_class_method :binding_of
  end
end
