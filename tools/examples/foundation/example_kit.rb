# frozen_string_literal: true

# A second development-only feature, an outside consumer of the example's proposal participant. Its one
# action adds a matched pair of parts in one Undo step by calling `example.foundation.add_part` twice:
# it requires the example feature, names the participant in `participants:` and reaches it only through
# `request.participate`, never the example's store or handler. Loaded by load.rb after the example.
module ExampleKit
  ID = "example.kit"
  ADD_PART = "#{ExampleFoundation::ID}.add_part"

  module_function

  def install(registry)
    feature = registry.feature(ID, :contract_version => 1, :requires => [ExampleFoundation::ID])
    feature.action(
      "#{ID}.add_pair",
      :description => "Add a left and a right part of one length to a definition, in one Undo step.",
      :params => { "type" => "object", "required" => %w[definition_id length_mm], "additionalProperties" => false,
                   "properties" => { "definition_id" => { "type" => "string" },
                                     "length_mm" => { "type" => "number", "exclusiveMinimum" => 0,
                                                      "x-unit" => "mm" } } },
      :result => { "type" => "object", "properties" => { "part_ids" => { "type" => "array" } } },
      :refuses => [], :participants => [ADD_PART], :undo_name => "Add Example Pair",
      :side_effects => "Creates two example parts.",
      :examples => [{ "definition_id" => "exd_Ab12Cd34Ef56", "length_mm" => 2100 }]
    ) do |request, _proposal|
      ids = %w[Left Right].map do |side|
        request.participate(ADD_PART, "definition_id" => request.params.fetch("definition_id"),
                                      "label" => "#{side} jamb", "length_mm" => request.params.fetch("length_mm"))
               .fetch("part_id")
      end
      { "part_ids" => ids }
    end
  end
end
