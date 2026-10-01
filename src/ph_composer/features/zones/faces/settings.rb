# frozen_string_literal: true

module PhComposer
  module Zones
    module Faces
      # Authoring choices belong to this SKP, unlike the shell's user-wide display preferences.
      module Settings
        STORE = Records::EntityStore.new("ph_composer.zones_settings")
        DEFAULTS = { "suggest_on_make" => true, "roof_angle_deg" => 60.0, "floor_angle_deg" => 130.0 }.freeze
        VALUES = {
          "type" => "object", "additionalProperties" => false, "required" => DEFAULTS.keys,
          "properties" => {
            "suggest_on_make" => { "type" => "boolean" },
            "roof_angle_deg" => { "type" => "number", "minimum" => 0, "maximum" => 180 },
            "floor_angle_deg" => { "type" => "number", "minimum" => 0, "maximum" => 180 }
          }
        }.freeze

        module_function

        def read(model)
          validate!(STORE.read(model) || DEFAULTS.dup)
        end

        def validate!(values)
          problems = JsonSchema.validate(values, VALUES)
          if problems.empty? && values.fetch("roof_angle_deg") >= values.fetch("floor_angle_deg")
            problems << "The roof angle must be less than the floor angle."
          end
          unless problems.empty?
            raise CodedError.new("validation.failed",
                                 "Zone settings are invalid: #{problems.first}. Nothing was written.")
          end
          values
        end

        def install(feature)
          feature.query("#{FEATURE_ID}.settings.get", :description => "This Model's classification settings.",
                        :params => Shapes::NONE, :result => VALUES, :examples => [{}]) do |request|
            read(request.model)
          end
          feature.snapshot_section("#{FEATURE_ID}.settings", :query => "#{FEATURE_ID}.settings.get")
          feature.action("#{FEATURE_ID}.settings.update", :description => "Set this Model's classification settings.",
                         :params => Shapes.object({ "values" => VALUES, "expected_values" => VALUES }),
                         :result => VALUES, :undo_name => "Change Zone Settings",
                         :examples => [{ "values" => DEFAULTS, "expected_values" => DEFAULTS }],
                         :side_effects => "Stores classification settings in this SKP in one Undo step.") do |
                           request, proposal|
            before = read(request.model)
            unless before == request.params.fetch("expected_values")
              raise CodedError.new("target.changed", "Zone settings changed since they were read. Nothing was written.")
            end
            after = validate!(request.params.fetch("values"))
            proposal.add_step(Step.new(before, after), :scopes => [Scope.new]) unless before == after
            after
          end
        end

        # Only this model dictionary participates in rollback proof; geometry is untouched.
        class Scope
          def path
            ["ph_composer.zones_settings"]
          end

          def capture(model)
            CanonicalJson.digest(STORE.read(model))
          end

          def unchanged?(model, before)
            capture(model) == before
          rescue StandardError
            false
          end
        end

        class Step
          def initialize(before, after)
            @before = DeepCopy.call(before)
            @after = DeepCopy.call(after)
          end

          def descriptor
            { "name" => "update_zone_settings", "before" => @before, "after" => @after }
          end

          def affected
            [{ "kind" => "zone_settings", "id" => FEATURE_ID, "change" => "updated" }]
          end

          def apply(model, _slots)
            unless Settings.read(model) == @before
              raise CodedError.new("target.changed", "Zone settings changed after preview. Nothing was written.")
            end
            STORE.write(model, @after)
          end
        end
      end
    end
  end
end
