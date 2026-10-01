# frozen_string_literal: true

module PhComposer
  module Operations
    # One explicit Entities collection and a canonical snapshot used only to verify a host abort.
    # Paths contain Group persistent ids from the Model root. Component definitions are refused for
    # mutations because their storage is shared by every instance.
    class EntityScope
      attr_reader :path

      def initialize(path)
        @path = Array(path).map { |id| Integer(id) }.freeze
      end

      def capture(model)
        CanonicalJson.digest(fingerprint(resolve(model)))
      end

      def unchanged?(model, before)
        capture(model) == before
      rescue StandardError
        false
      end

      def resolve(model)
        path.reduce(model.entities) do |entities, persistent_id|
          entity = find(entities, persistent_id)
          unless entity.is_a?(Sketchup::Group)
            raise CodedError.new("target.shared_definition", "That edit path is not a unique Group occurrence.")
          end
          entity.entities
        end
      end

      def find(entities, persistent_id)
        matches = entities.to_a.select { |entity| entity.persistent_id == persistent_id }
        unless matches.length == 1
          raise CodedError.new("target.not_found", "Entity #{persistent_id} no longer resolves uniquely.")
        end

        matches.first
      end

      private

      def fingerprint(entities)
        entities.to_a.map { |entity| fingerprint_entity(entity) }.sort_by { |row| row.fetch("persistent_id") }
      end

      def fingerprint_entity(entity)
        value = {
          "kind" => entity.class.name,
          "persistent_id" => entity.persistent_id,
          "dictionaries" => dictionaries(entity)
        }
        value["name"] = entity.name.to_s if entity.respond_to?(:name)
        value["transformation"] = entity.transformation.to_a if entity.respond_to?(:transformation)
        if entity.is_a?(Sketchup::Face)
          value["loops"] = entity.loops.map do |loop|
            loop.vertices.map { |vertex| point(vertex.position) }
          end
        elsif entity.is_a?(Sketchup::Edge)
          value["vertices"] = [point(entity.start.position), point(entity.end.position)]
        elsif entity.respond_to?(:entities)
          value["entities"] = fingerprint(entity.entities)
        elsif entity.respond_to?(:definition)
          value["definition_guid"] = entity.definition.guid.to_s
          value["entities"] = fingerprint(entity.definition.entities)
        end
        value
      end

      def dictionaries(entity)
        collection = entity.attribute_dictionaries
        return {} unless collection

        collection.to_a.select { |dictionary| dictionary.name.start_with?("ph_composer.") }
          .sort_by(&:name).to_h do |dictionary|
            values = {}
            dictionary.each { |key, value| values[key.to_s] = value }
            [dictionary.name, values]
          end
      end

      def point(value)
        [value.x.to_f.round(COORDINATE_DECIMALS), value.y.to_f.round(COORDINATE_DECIMALS),
         value.z.to_f.round(COORDINATE_DECIMALS)]
      end
    end
  end
end
