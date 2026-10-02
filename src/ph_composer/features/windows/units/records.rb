# frozen_string_literal: true

require_relative "anchors"

module PhComposer
  module Windows
    # Instance records are entity targets, not catalog definitions. A unit keeps its authored
    # identity and anchor even when SketchUp changes its host or occurrence path.
    module Units
      REFERENCE_KIND = "#{FEATURE_ID}.unit"
      STORE = Records::EntityStore.new("ph_composer.window_unit")
      DEFINITION_STORE = Records::EntityStore.new("ph_composer.window_definition")
      PANE_STORE = Records::EntityStore.new("ph_composer.window_pane")
      RECORD_KIND = Records::RecordKind.new(:id => REFERENCE_KIND, :label => "Window unit",
                                            :schema_version => 1, :id_prefix => "wun", :fields => [
                                              Fields.field("window_type_id",
                                                           { "type" => "string" }, :required => true),
                                              Fields.field("anchor",
                                                           { "type" => "string", "enum" => Anchors::ALL }, :required => true)
                                            ], :references => [Records::Reference.new(:key => "window_type_id", :target_kind => TYPE_KIND,
                                                                                      :cardinality => "one")])

      module_function

      def validate!(record)
        found = RECORD_KIND.problems(record)
        return record if found.empty?

        raise CodedError.new("validation.failed", "The Window unit record is invalid.", "findings" => found)
      end

      def read(entity)
        record = STORE.read(entity)
        return nil if record.nil? && entity.get_attribute(STORE.dictionary, STORE.key).nil?

        validate!(record)
      end

      def write(entity, record)
        unless entity.is_a?(Sketchup::ComponentInstance)
          raise CodedError.new("target.wrong_kind", "Window units are stored on ComponentInstances.")
        end

        STORE.write(entity, validate!(record))
      end
    end
  end
end
