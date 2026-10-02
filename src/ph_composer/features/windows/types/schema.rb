# frozen_string_literal: true

module PhComposer
  module Windows
    # Inclusive bands describe one rectangular, fully covered layout; dimensions may be missing in
    # an incomplete saved type. Geometry and placement depend on these definitions, never vice versa.
    module Types
      SIDES = %w[top right bottom left].freeze
      # A new Type's width and height when the caller supplies none. A client that wants another start,
      # such as the panel's round imperial size, passes `columns_m` and `rows_m`.
      DEFAULT_SIZE_M = [1.0, 1.5].freeze
      ID = { "type" => %w[string null] }.freeze
      SPAN = { "type" => "array", "minItems" => 2, "maxItems" => 2,
               "items" => { "type" => "integer", "minimum" => 0 } }.freeze
      SIDE_SCHEMA = SchemaShapes.object(SIDES.to_h { |side| [side, ID] }).freeze
      OPERATION = SchemaShapes.object({ "type" => { "type" => "string", "enum" => %w[fixed swing slide] },
                                        "directions" => { "type" => "array",
                                                          "items" => { "type" => "string",
                                                                       "enum" => %w[left right up
                                                                                    down] } } }).merge("type" => %w[
                                                                                      object null
                                                                                    ]).freeze
      ELEMENT = SchemaShapes.object({
        "id" => { "type" => "string" }, "name" => { "type" => "string" },
        "kind" => { "type" => "string", "enum" => %w[glazed empty] },
        "row_span" => SPAN, "column_span" => SPAN, "glazing_id" => ID,
        "frames" => SIDE_SCHEMA, "installs" => SIDE_SCHEMA, "operation" => OPERATION
      }).freeze
      BANDS = { "type" => "array", "minItems" => 1, "maxItems" => 40,
                "items" => { "type" => %w[number null], "exclusiveMinimum" => 0, "x-unit" => "m" } }.freeze

      module_function

      def blank(row = 0, column = 0, identity: ->(prefix) { Records::Identity.mint(prefix) })
        { "id" => identity.call("wel"), "name" => "Element", "kind" => "glazed",
          "row_span" => [row, row], "column_span" => [column, column], "glazing_id" => nil,
          "frames" => SIDES.to_h { |side| [side, nil] }, "installs" => SIDES.to_h { |side| [side, nil] },
          "operation" => nil }
      end

      def defaults(values, identity: ->(prefix) { Records::Identity.mint(prefix) })
        width, height = DEFAULT_SIZE_M
        { "rows_m" => [height], "columns_m" => [width], "elements" => [blank(:identity => identity)],
          "product_photos" => [] }.merge(Fields.defaults(values))
      end

      def layout_problems(values)
        found = []
        coverage = {}
        ids = []
        values.fetch("elements").each do |element|
          ids << element.fetch("id")
          found << "Element id is invalid." unless Records::Identity.pattern("wel").match?(element.fetch("id"))
          spans = %w[row_span column_span].map.with_index do |key, axis|
            span = element.fetch(key)
            count = values.fetch(axis.zero? ? "rows_m" : "columns_m").length
            unless span.first <= span.last && span.last < count
              found << "Element spans must stay inside the grid."
              next nil
            end
            span
          end
          if spans.none?(&:nil?)
            (spans[0].first..spans[0].last).each do |row|
              (spans[1].first..spans[1].last).each do |column|
                found << "Elements overlap." if coverage[[row, column]]
                coverage[[row, column]] = true
              end
            end
          end
          operation = element["operation"]
          if operation && operation.fetch("directions").uniq != operation.fetch("directions")
            found << "Operation directions must be unique."
          end
          if operation && operation.fetch("type") == "fixed" && !operation.fetch("directions").empty?
            found << "Fixed elements carry no operation directions."
          end
          if element.fetch("kind") == "empty" && (element["glazing_id"] || operation ||
            (element.fetch("frames").values + element.fetch("installs").values).any?)
            found << "Empty elements cannot carry products or operation."
          end
        end
        found << "Element ids must be unique." unless ids.uniq == ids
        if coverage.length != values.fetch("rows_m").length * values.fetch("columns_m").length
          found << "Every grid cell must be covered."
        end
        found.uniq
      end

      FIELDS = Fields.with_source_snapshot(Fields.common + [
        Fields.field("rows_m", BANDS, :required => true), Fields.field("columns_m", BANDS, :required => true),
        Fields.field("elements", { "type" => "array", "minItems" => 1, "items" => ELEMENT }, :required => true),
        Fields.field("install_depth_m", { "type" => "number", "minimum" => 0, "x-unit" => "m" }),
        Fields.field("product_photos", { "type" => "array", "items" => { "type" => "string" } })
      ])
      SNAPSHOT_SCHEMA = Fields.source_snapshot_schema(FIELDS)
      REFERENCES = [Records::Reference.new(:key => "elements[].glazing_id", :target_kind => GLAZING_KIND,
                                           :cardinality => "one")] +
                   { "frames" => FRAME_KIND, "installs" => PSI_INSTALL_KIND }.flat_map do |field, target|
                     SIDES.map { |side|
                       Records::Reference.new(:key => "elements[].#{field}.#{side}",
                                              :target_kind => target, :cardinality => "one")
                     }
                   end
      KIND = Records::RecordKind.new(:id => TYPE_KIND, :label => "Window Type", :schema_version => 1,
                                     :id_prefix => "wnt", :fields => FIELDS, :references => REFERENCES,
                                     :validate => ->(values) {
                                                    Fields.problems(values) + Fields.source_problems(values["source"], SNAPSHOT_SCHEMA) +
                                                    layout_problems(values)
                                                  })

      def references(record)
        KIND.references.flat_map { |reference| reference.ids(record).map { |id| [reference.target_kind, id] } }.uniq
      end
    end
  end
end
