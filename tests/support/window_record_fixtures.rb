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

  def thermal_proof
    input = JSON.parse(File.read(File.join(__dir__, "../fixtures/windows/thermal-proof.json")))
    record = { "rows_m" => input.fetch("rows_m"), "columns_m" => input.fetch("columns_m"),
               "elements" => input.fetch("cells").each_with_index.map do |cell, i|
                 cell.merge("row_span" => [i / 2, i / 2], "column_span" => [i % 2, i % 2],
                   "operation" => { "type" => "fixed", "directions" => [] })
               end }
    [record, input]
  end
end
