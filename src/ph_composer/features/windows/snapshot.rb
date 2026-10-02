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

      def list(request, collection, paged: true)
        kind = Operations.kind(collection)
        ids = request.engine.ids(kind.id).sort
        ids &= request.params["ids"] if request.params.key?("ids")
        page, cursor = paged ? Pages.slice(request, "#{FEATURE_ID}.#{collection}.list", ids,
          :key => ->(id) { id }) : [ids, nil]
        records, unreadable = read(request.engine, kind, page)
        settings = Settings.read(request.model)
        types = collection == "types" ? records : read(request.engine, Types::KIND, request.engine.ids(TYPE_KIND)).first
        products = Products::KINDS.to_h do |name, definition|
          product_rows = collection == name ? records : read(request.engine, definition,
            request.engine.ids(definition.id)).first
          [name == "psi_install_types" ? "installs" : name, product_rows.to_h { |row| [row.fetch("id"), row] }]
        end
        uses = Graph.uses(types, settings.fetch("default_psi_install_id")) unless collection == "types"
        views = records.map do |record|
          view = request.engine.view(kind.id, record)
          if collection == "types"
            type(view, record, products, settings)
          else
            product(view, record, kind, uses, settings)
          end
        end
        result = { "records" => views, "unreadable" => unreadable }
        result.merge!("next_cursor" => cursor, "total" => ids.length) if paged
        result
      end

      def type(view, record, products, settings)
        thermal = Thermal.calculate(record, products, settings.fetch("default_psi_install_id"))
        findings = product_findings(record, products)
        findings.concat(thermal.fetch("findings"))
        thermal.fetch("elements").each do |element|
          findings.concat(element.fetch("findings").map { |finding| finding.merge("element_id" => element.fetch("id")) })
        end
        default_id = settings.fetch("default_psi_install_id")
        if default_id && !products.fetch("installs").key?(default_id)
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

      def product_findings(record, products)
        record.fetch("elements").flat_map do |element|
          slots = [["glazings", "glazing", element["glazing_id"]]] +
            %w[frames installs].flat_map { |kind| element.fetch(kind).map { |side, id| [kind, side, id] } }
          slots.filter_map do |kind, side, id|
            next unless id && !products.fetch(kind).key?(id)
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
