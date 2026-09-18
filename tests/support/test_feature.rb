# frozen_string_literal: true

require_relative "record_fixtures"

# A feature built only from the public registration calls, for the dispatch and API tests. It is the
# offline counterpart of the development example under tools/examples/foundation/.
module TestFeature
  ID = "test.fixture"
  R = PhComposer::Records
  OBJECT = { "type" => "object" }.freeze

  EDIT = {
    "type" => "object", "required" => ["id"], "additionalProperties" => false,
    "properties" => {
      "id" => { "type" => "string" },
      "values" => { "type" => "object" },
      "user_data" => { "type" => "object" },
      "expected_values" => { "type" => "object" },
      "extension_payloads" => { "type" => "object" }
    }
  }.freeze
  EDITS = { "type" => "array", "items" => EDIT, "minItems" => 1 }.freeze

  module_function

  def install(registry)
    feature = registry.feature(ID, :contract_version => 1)
    feature.record_kind(RecordFixtures::DEFINITION)
    feature.record_kind(RecordFixtures::PART)
    feature.extension(RecordFixtures::REVIEW)
    feature.snapshot_section("#{ID}.parts", :query => "ph_composer.records.list", :params => { "kind" => "#{ID}.part" })
    declare_reads(feature)
    declare_writes(feature)
    declare_record_operations(feature)
  end

  def declare_reads(feature)
    feature.query("#{ID}.total_length", :description => "Total part length.", :params => { "type" => "object" },
                                        :result => OBJECT) do |request|
      engine = request.engine
      lengths = engine.ids("#{ID}.part").map { |id| engine.find("#{ID}.part", id).fetch("length_mm") }
      { "total_length_mm" => lengths.sum }
    end
  end

  def declare_writes(feature)
    feature.action("#{ID}.create", :description => "Create a definition and parts that name it.",
                                   :params => { "type" => "object", "required" => ["parts"],
                                                "properties" => { "parts" => { "type" => "array" } } },
                                   :result => OBJECT, :undo_name => "Create Test Parts",
                                   :side_effects => "Creates records.") do |request, changes|
      definition = request.engine.propose_create("#{ID}.definition", changes, :values => { "label" => "Frame" })
      ids = request.params.fetch("parts").map do |values|
        request.engine.propose_create("#{ID}.part", changes, :values => values.merge("definition_id" => definition))
      end
      { "definition_id" => definition, "part_ids" => ids }
    end

    feature.action("#{ID}.update_parts", :description => "Edit parts, all or none.",
                                         :params => { "type" => "object", "required" => ["edits"],
                                                      "properties" => { "edits" => EDITS } },
                                         :result => OBJECT, :undo_name => "Edit Test Parts",
                                         :side_effects => "Changes part values and metadata.") do |request, changes|
      request.params.fetch("edits").each do |edit|
        request.engine.propose_update(
          "#{ID}.part", edit.fetch("id"), changes,
          :values => edit.fetch("values", {}), :user_data => edit["user_data"],
          :expected_values => edit.fetch("expected_values", {}),
          :extension_payloads => edit.fetch("extension_payloads", {})
        )
      end
      { "updated" => changes.affected.length }
    end
  end

  def declare_record_operations(feature)
    feature.action("#{ID}.duplicate_parts", :description => "Duplicate parts as one collection.",
                                            :params => { "type" => "object", "required" => ["ids"],
                                                         "properties" => { "ids" => { "type" => "array" } } },
                                            :result => OBJECT, :undo_name => "Duplicate Test Parts",
                                            :side_effects => "Creates records.") do |request, changes|
      { "mapping" => request.engine.propose_duplicate("#{ID}.part", request.params.fetch("ids"), changes) }
    end

    feature.action("#{ID}.migrate_review", :description => "Raise review data to the installed version.",
                                           :params => { "type" => "object", "required" => ["ids"],
                                                        "properties" => { "ids" => { "type" => "array" } } },
                                           :result => OBJECT, :undo_name => "Migrate Test Review",
                                           :side_effects => "Rewrites extension data.") do |request, changes|
      ids = request.params.fetch("ids")
      { "results" => request.engine.propose_migration("#{ID}.part", ids, "#{ID}.review", changes) }
    end

    # Calls the API again while its own request is still running, as a re-entrant client would.
    feature.action("#{ID}.reenter", :description => "Re-enter the dispatcher.", :params => { "type" => "object" },
                                    :result => OBJECT, :undo_name => "Re-enter",
                                    :side_effects => "None.") do |_request, _changes|
      { "inner" => PhComposer::API.invoke(**TestFeature.reentry) }
    end
  end

  class << self
    attr_accessor :reentry
  end
end
