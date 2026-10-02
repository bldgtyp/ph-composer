# frozen_string_literal: true

module PhComposer
  # One Model-owned settings dictionary. Features declare the schema and domain checks; this
  # service reads without repair and stages one guarded write in the caller's native operation.
  class ModelSettings
    attr_reader :store, :defaults, :schema, :label, :step_name, :affected

    def initialize(dictionary:, defaults:, schema:, label:, step_name:, affected:, &problems)
      @store = Records::EntityStore.new(dictionary)
      @defaults = deep_freeze(DeepCopy.call(defaults))
      @schema = deep_freeze(DeepCopy.call(schema))
      @label = label.dup.freeze
      @step_name = step_name.dup.freeze
      @affected = deep_freeze(DeepCopy.call(affected))
      @problems = problems
      validate!(@defaults)
    end

    def read(model)
      validate!(store.read(model) || DeepCopy.call(defaults))
    end

    def validate!(values)
      problems = JsonSchema.validate(values, schema)
      problems.concat(Array(@problems&.call(values))) if problems.empty?
      unless problems.empty?
        raise CodedError.new("validation.failed",
                             "#{label} settings are invalid: #{problems.first}. Nothing was written.")
      end
      values
    end

    def propose(model, proposal, values:, expected_values:)
      before = read(model)
      unless before == expected_values
        raise CodedError.new("target.changed", "#{label} settings changed since they were read. Nothing was written.")
      end
      after = validate!(values)
      proposal.add_step(step(before, after), :scopes => [scope]) unless before == after
      after
    rescue StandardError => error
      proposal.refuse(error)
      raise
    end

    def scope
      Scope.new(self)
    end

    def step(before, after)
      Step.new(self, before, after)
    end

    private

    def deep_freeze(value)
      case value
      when Hash then value.each_value { |item| deep_freeze(item) }
      when Array then value.each { |item| deep_freeze(item) }
      end
      value.freeze
    end

    # Defaults are a read projection, never the stored pre-image: absent data must remain absent
    # when the host aborts or undoes a write, rather than becoming an authored defaults dictionary.
    class Scope
      def initialize(settings)
        @settings = settings
      end

      def path
        [@settings.store.dictionary]
      end

      def capture(model)
        CanonicalJson.digest(@settings.store.read(model))
      end

      def unchanged?(model, before)
        capture(model) == before
      rescue StandardError
        false
      end
    end

    class Step
      def initialize(settings, before, after)
        @settings = settings
        @before = DeepCopy.call(before)
        @after = DeepCopy.call(after)
      end

      def descriptor
        { "name" => @settings.step_name, "before" => @before, "after" => @after }
      end

      def affected
        DeepCopy.call(@settings.affected)
      end

      def apply(model, _slots)
        unless @settings.read(model) == @before
          raise CodedError.new("target.changed",
                               "#{@settings.label} settings changed after preview. Nothing was written.")
        end
        @settings.store.write(model, @after)
      end
    end
  end
end
