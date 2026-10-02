# frozen_string_literal: true

module PhComposer
  module Windows
    # One detached inventory projection, with authored storage kept distinct from effective defaults.
    module Snapshot
      module_function

      def read(engine, kind, ids)
        rows = []
        unreadable = []
        ids.each do |id|
          rows << engine.find(kind.id, id)
        rescue CodedError => error
          raise unless error.code == "record.unreadable"
          unreadable << { "id" => id, "code" => error.code, "message" => error.message }
        end
        [rows, unreadable]
      end

      # The page of `kind`'s ids a list or all query reads, its cursor and the total.
      def page(request, kind, query, paged)
        ids = request.engine.ids(kind.id).sort
        ids &= request.params["ids"] if request.params.key?("ids")
        page, cursor = paged ? Pages.slice(request, query, ids, :key => ->(id) { id }) : [ids, nil]
        [page, cursor, ids.length]
      end

      def result(views, unreadable, cursor, total, paged)
        result = { "records" => views, "unreadable" => unreadable }
        result.merge!("next_cursor" => cursor, "total" => total) if paged
        result
      end

      # Every product by collection, then id: what a Type's thermal values and findings read.
      def products_by_collection(request)
        Products::KINDS.to_h do |collection, kind|
          rows = read(request.engine, kind, request.engine.ids(kind.id)).first
          [collection, rows.to_h { |row| [row.fetch("id"), row] }]
        end
      end

      def types(request, paged: true)
        ids, cursor, total = page(request, Types::KIND, "#{FEATURE_ID}.types.list", paged)
        records, unreadable = read(request.engine, Types::KIND, ids)
        settings = Settings.read(request.model)
        products = products_by_collection(request)
        views = records.map { |record| type(request.engine.view(TYPE_KIND, record), record, products, settings) }
        result(views, unreadable, cursor, total, paged)
      end

      def products(request, collection, paged: true)
        kind = Products::KINDS.fetch(collection)
        ids, cursor, total = page(request, kind, "#{FEATURE_ID}.#{collection}.list", paged)
        records, unreadable = read(request.engine, kind, ids)
        settings = Settings.read(request.model)
        types = read(request.engine, Types::KIND, request.engine.ids(TYPE_KIND)).first
        uses = Graph.uses(types, settings.fetch("default_psi_install_id"))
        views = records.map { |record| product(request.engine.view(kind.id, record), record, kind, uses, settings) }
        result(views, unreadable, cursor, total, paged)
      end

      def type(view, record, products, settings)
        thermal = Thermal.calculate(record, products, settings.fetch("default_psi_install_id"))
        findings = product_findings(record, products)
        findings.concat(thermal.fetch("findings"))
        thermal.fetch("elements").each do |element|
          element_id = element.fetch("id")
          findings.concat(element.fetch("findings").map { |finding| finding.merge("element_id" => element_id) })
        end
        default_id = settings.fetch("default_psi_install_id")
        if default_id && !products.fetch("psi_install_types").key?(default_id)
          findings << { "code" => "window_type.default_install_dangling",
                "message" => "The Model default Psi-Install Type is missing." }
        end
        view.merge("findings" => findings, "display" => {
          "thermal" => thermal, "width_m" => dimensions(record.fetch("columns_m")),
                "height_m" => dimensions(record.fetch("rows_m")),
                "install_depth_m" => record.fetch("install_depth_m", settings.fetch("default_install_depth_m")),
                "complete" => thermal.fetch("complete")
        })
      end

      def dimensions(bands)
        bands.any?(&:nil?) ? nil : bands.sum
      end

      # Each slot an element assigns: the product collection it names, the side, and the product id.
      def product_slots(element)
        [["glazings", "glazing", element["glazing_id"]]] +
          element.fetch("frames").map { |side, id| ["frames", side, id] } +
          element.fetch("installs").map { |side, id| ["psi_install_types", side, id] }
      end

      def product_findings(record, products)
        record.fetch("elements").flat_map do |element|
          product_slots(element).filter_map do |collection, side, id|
            next unless id && !products.fetch(collection).key?(id)
            { "code" => "window_type.product_dangling", "message" => "#{side}: the assigned product is missing.",
              "element_id" => element.fetch("id"), "side" => side, "product_id" => id }
          end
        end
      end

      def product(view, record, kind, uses, settings)
        rows = DeepCopy.call(uses[[kind.id, record.fetch("id")]])
        if kind.id == PSI_INSTALL_KIND && settings.fetch("default_psi_install_id") == record.fetch("id")
          rows << { "kind" => "model_default", "name" => "Model default" }
        end
        view.merge("findings" => [], "uses" => rows, "use_count" => rows.length,
          "element_use_count" => rows.filter_map { |row|
 [row["type_id"], row["element_id"]] if row["element_id"] }.uniq.length)
      end
    end
  end
end
