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

      def list(request, kind, paged: true)
        ids = request.engine.ids(kind).sort
        ids &= request.params["ids"] if request.params.key?("ids")
        collection = kind == MATERIAL_KIND ? "materials" : "assemblies"
        page, cursor = paged ? Pages.slice(request, "#{FEATURE_ID}.#{collection}.list", ids,
                                         :key => ->(id) { id }) : [ids, nil]
        records, unreadable = read_records(request.engine, kind, page)
        materials = kind == ASSEMBLY_KIND ? read_records(request.engine, MATERIAL_KIND,
                                                         request.engine.ids(MATERIAL_KIND)).first : []
        materials_by_id = materials.to_h { |record| [record.fetch("id"), record] }
        material_findings = materials.to_h { |record| [record.fetch("id"), Validation.material(record)] }
        assemblies = kind == MATERIAL_KIND ? read_records(request.engine, ASSEMBLY_KIND,
                                                           request.engine.ids(ASSEMBLY_KIND)).first : []
        rows = records.map do |record|
          view = request.engine.view(kind, record)
          if kind == MATERIAL_KIND
            material(view, record, assemblies)
          else
            assembly(view, record, materials_by_id, :material_findings => material_findings)
          end
        end
        result = { "records" => rows, "unreadable" => unreadable }
        if kind == MATERIAL_KIND
          result["categories"] = Materials::Schema::CATEGORIES.map do |id, pair|
            { "id" => id, "label" => pair.first, "tone" => pair.last }
          end
        end
        result.merge!("next_cursor" => cursor, "total" => ids.length) if paged
        result
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
