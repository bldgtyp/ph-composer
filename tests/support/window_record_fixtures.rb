# frozen_string_literal: true

require_relative "../../src/ph_composer/features/windows/install"

module WindowRecordFixtures
  W = PhComposer::Windows

  def window_values(overrides = {})
    W::Types.defaults({ "name" => "Test type" }.merge(overrides), :identity => window_allocator)
  end

  def window_allocator
    @window_id_position ||= 0
    lambda do |prefix|
      @window_id_position += 1
      "#{prefix}_#{@window_id_position.to_s.rjust(12, '0')}"
    end
  end

  def window_record(overrides = {})
    window_values(overrides).merge("id" => "wnt_AAAAAAAAAAAA", "schema_version" => 1)
  end

  # A writable host on `face` in `group`, which becomes a synthetic Zone the first time, located through
  # the Zones Face target's resolver as the Units actions locate one. `values` stand in for the
  # `host_context` row, so a step can be shown a Surface host without classifying the Face.
  def zone_host(face, group, values = {})
    zone_id = "zon_#{group.persistent_id.to_s.rjust(12, '0')}"
    unless PhComposer::Zones::ZONE_STORE.read(group)
      PhComposer::Zones::ZONE_STORE.write(group, "id" => zone_id, "schema_version" => 1, "name" => "Zone",
        "building_segment" => "Building", "level" => nil, "ground_depth_mm" => 0.0, "user_data" => {},
        "extension_data" => {})
    end
    reference = { "zone_id" => zone_id, "zone_path" => [group.persistent_id], "entity_path" => [face.persistent_id],
                  "entity_id" => nil }
    locator = PhComposer::Zones::Faces::Registration::TARGET.method(:locate)
    located = locator.call(Sketchup.active_model, reference, :mutable => true)
    W::Placement::Host.new(:entity => located.entity, :entities => located.entities,
      :parent_path => located.parent_path, :transform => located.transform, :reference => reference,
      :values => values, :zone_state => "found", :locator => locator,
      :geometry => PhComposer::FaceGeometry.capture(located.entity, located.transform))
  end

  def thermal_proof
    input = JSON.parse(File.read(File.join(__dir__, "../fixtures/windows/thermal-proof.json")))
    input["psi_install_types"] = input.delete("installs")
    record = { "rows_m" => input.fetch("rows_m"), "columns_m" => input.fetch("columns_m"),
               "elements" => input.fetch("cells").each_with_index.map do |cell, i|
                 cell.merge("row_span" => [i / 2, i / 2], "column_span" => [i % 2, i % 2],
                   "operation" => { "type" => "fixed", "directions" => [] })
               end }
    [record, input]
  end
end
