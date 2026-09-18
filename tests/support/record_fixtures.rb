# frozen_string_literal: true

# A synthetic record catalog for the engine and dispatch tests: a shared definition kind, a part kind
# that names one definition and any number of neighbouring parts, and one versioned extension. None
# of it is a building record; it exists to exercise identity, references and extension data.
module RecordFixtures
  R = PhComposer::Records

  DEFINITION = R::RecordKind.new(
    :id => "test.fixture.definition", :label => "Test definition", :schema_version => 1, :id_prefix => "tdf",
    :fields => [R::Field.new(:key => "label", :schema => { "type" => "string", "minLength" => 1 }, :required => true)]
  )

  # A store that can be told to raise on a later write, to prove that a failure part-way through an
  # operation rolls every earlier write back.
  class FailingStore < R::DictionaryStore
    class << self
      attr_accessor :writes_before_failure
    end

    def write(model, record)
      countdown = self.class.writes_before_failure
      if countdown
        raise IOError, "injected write failure" if countdown.zero?

        self.class.writes_before_failure = countdown - 1
      end
      super
    end
  end

  PART = R::RecordKind.new(
    :id => "test.fixture.part", :label => "Test part", :schema_version => 1, :id_prefix => "tpt",
    :store => FailingStore.new("test.fixture.part"),
    :fields => [
      R::Field.new(:key => "label", :schema => { "type" => "string", "minLength" => 1 }, :required => true),
      R::Field.new(
        :key => "length_mm", :schema => { "type" => "number", "exclusiveMinimum" => 0, "x-unit" => "mm" },
        :required => true
      ),
      R::Reference.new(:key => "definition_id", :target_kind => "test.fixture.definition", :cardinality => "one",
                       :required => true),
      R::Reference.new(:key => "neighbour_ids", :target_kind => "test.fixture.part", :cardinality => "many",
                       :required => false)
    ]
  )

  # Version 1 stored `{"status": ...}`; version 2 renamed it and added a reference to another part.
  REVIEW = R::Extension.new(
    :namespace => "test.fixture.review", :schema_version => 2, :export_relevance => "required",
    :references => [{ "path" => "$.checked_against", "target_kind" => "test.fixture.part", "cardinality" => "one" }],
    :migrations => { 1 => ->(payload) { { "review_status" => payload.fetch("status") } } },
    :validate => lambda do |payload|
      %w[draft checked].include?(payload["review_status"]) ? [] : ["review_status must be draft or checked"]
    end
  )

  def record_catalog(extensions: [REVIEW])
    R::Catalog.new(:kinds => [DEFINITION, PART], :extensions => extensions)
  end

  # Writes records straight to the store, as a saved Model or an older extension would have left them.
  def store_record(model, kind, record)
    kind.store.write(model, record)
    record
  end

  def stored_text(model, kind, id)
    model.attribute_dictionary(kind.store.dictionary)[id]
  end
end
