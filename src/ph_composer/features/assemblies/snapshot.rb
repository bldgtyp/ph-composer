# frozen_string_literal: true

module PhComposer
  module Assemblies
    # Detached read projections. Stored values remain unchanged; display defaults belong to the
    # display block, so expected_values can always be copied from values without inventing storage.
    module Snapshot
      module_function

      def read_records(engine, kind, ids)
        records = []
        unreadable = []
        ids.each do |id|
          records << engine.find(kind, id)
        rescue CodedError => error
          raise unless error.code == "record.unreadable"

          unreadable << { "id" => id, "code" => error.code, "message" => error.message }
        end
        [records, unreadable]
      end

      # The page of `kind`'s ids a list or all query reads, its cursor and the total.
      def page(request, kind, query, paged)
        ids = request.engine.ids(kind).sort
        ids &= request.params["ids"] if request.params.key?("ids")
        page, cursor = paged ? Pages.slice(request, query, ids, :key => ->(id) { id }) : [ids, nil]
        [page, cursor, ids.length]
      end

      def result(rows, unreadable, cursor, total, paged, extra = {})
        result = { "records" => rows, "unreadable" => unreadable }.merge(extra)
        result.merge!("next_cursor" => cursor, "total" => total) if paged
        result
      end

      def materials(request, paged: true)
        ids, cursor, total = page(request, MATERIAL_KIND, "#{FEATURE_ID}.materials.list", paged)
        records, unreadable = read_records(request.engine, MATERIAL_KIND, ids)
        assemblies = read_records(request.engine, ASSEMBLY_KIND, request.engine.ids(ASSEMBLY_KIND)).first
        rows = records.map { |record| material(request.engine.view(MATERIAL_KIND, record), record, assemblies) }
        result(rows, unreadable, cursor, total, paged, "categories" => categories)
      end

      def assemblies(request, paged: true)
        ids, cursor, total = page(request, ASSEMBLY_KIND, "#{FEATURE_ID}.assemblies.list", paged)
        records, unreadable = read_records(request.engine, ASSEMBLY_KIND, ids)
        materials = read_records(request.engine, MATERIAL_KIND, request.engine.ids(MATERIAL_KIND)).first
        materials_by_id = materials.to_h { |record| [record.fetch("id"), record] }
        material_findings = materials.to_h { |record| [record.fetch("id"), Validation.material(record)] }
        rows = records.map do |record|
          assembly(request.engine.view(ASSEMBLY_KIND, record), record, materials_by_id,
                   :material_findings => material_findings)
        end
        result(rows, unreadable, cursor, total, paged)
      end

      def categories
        Materials::Schema::CATEGORIES.map { |id, pair| { "id" => id, "label" => pair.first, "tone" => pair.last } }
      end

      def material(view, record, assemblies)
        uses = assemblies.select do |assembly|
          Assembly::Schema::MATERIAL_REFERENCE.ids(assembly).include?(record.fetch("id"))
        end.map { |assembly| { "assembly_id" => assembly.fetch("id"), "name" => assembly.fetch("name") } }
        view.merge("findings" => Validation.material(record), "uses" => uses, "use_count" => uses.length)
      end

      def assembly(view, record, materials, material_findings: nil)
        findings = Validation.assembly(record, materials, :material_findings => material_findings)
        thermal = Thermal.preview(record, materials)
        thermal["message_parts"] = MessageParts.plain(thermal.fetch("warnings"))
        layers = record.fetch("layers")
        total = layers.reject { |layer| Materials::Schema.membrane_layer?(layer, materials) }
                      .sum { |layer| layer.fetch("thickness_mm") }
        blockers = Validation.export_blockers(record, materials, findings)
        view.merge("findings" => findings, "export_ready" => blockers.empty?, "export_blockers" => blockers,
                   "display" => {
                     "color" => record.fetch("color", Assembly::Schema.color(record.fetch("id"))),
                     "layer_count" => layers.length, "total_thickness_mm" => total,
                     "thermal" => thermal, "complete" => Validation.complete?(findings)
                   })
      end
    end
  end
end
