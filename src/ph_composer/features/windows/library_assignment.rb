# frozen_string_literal: true

module PhComposer
  module Windows
    # Adapter assignments reuse the owning actions on the shared copy proposal. Targets carry
    # authored guards; changing a single side never replaces another element's assignments.
    module LibraryAssignment
      module_function

      def target_schema(collection)
        target = { "id" => Shapes::ID, "element_id" => Shapes::ID,
                   "expected_values" => Types::KIND.descriptor.patch_schema }
        target["side"] = { "type" => "string", "enum" => Types::SIDES } unless collection == "glazings"
        return Shapes.object(target) unless collection == "psi_install_types"

        target.merge!("mode" => { "type" => "string", "enum" => %w[perimeter model_default] },
          "expected_settings" => Settings::VALUES)
        Shapes.object(target, :optional => %w[id element_id expected_values side])
      end

      def callback(collection, registry)
        actions = registry.declared_actions.select { |action| action.owner == FEATURE_ID }.to_h do |action|
          [action.name.delete_prefix("#{FEATURE_ID}."), action]
        end
        result = Shapes.object({ "assigned" => { "type" => "boolean" } })
        Declarations::LibraryCallback.new(
          :params => Shapes.object({ "target" => target_schema(collection), "local_id" => Shapes::ID }),
          :result => result, :handler => lambda do |request, proposal|
            target = request.params.fetch("target")
            id = request.params.fetch("local_id")
            if collection == "psi_install_types"
              assign_psi(request, proposal, target, id, actions)
            else
              element = target.slice("id", "element_id", "expected_values")
              if collection == "frames"
                run(actions.fetch("types.grid.set_element_frame"), request, proposal,
                  element.merge("side" => target.fetch("side"), "frame_id" => id))
              else
                run(actions.fetch("types.grid.set_element_glazing"), request, proposal,
                  element.merge("glazing_id" => id))
              end
            end
            { "assigned" => true }
          end
        )
      end

      def assign_psi(request, proposal, target, id, actions)
        if target.fetch("mode") == "model_default"
          unless target.keys.sort == %w[expected_settings mode]
            raise CodedError.new("params.invalid", "A Model default target cannot contain element fields.")
          end
          values = Settings.read(request.model).merge("default_psi_install_id" => id)
          run(actions.fetch("settings.update"), request, proposal,
            "values" => values, "expected_values" => target.fetch("expected_settings"))
          return
        end
        unless target.keys.sort == %w[element_id expected_settings expected_values id mode side]
          raise CodedError.new("params.invalid", "A perimeter target needs a guarded element and side.")
        end
        record = request.engine.find(TYPE_KIND, target.fetch("id"))
        after = Installs.paint(record, target.fetch("element_id"), target.fetch("side"), id)
        element = after.fetch("elements").find { |cell| cell.fetch("id") == target.fetch("element_id") }
        edge = { "element_id" => element.fetch("id"), "sides" => element.fetch("installs") }
        run(actions.fetch("types.installs.save"), request, proposal,
          "types" => [{ "id" => target.fetch("id"), "expected_values" => target.fetch("expected_values"),
                        "installs" => [edge] }],
          "psi_install_types" => { "create" => [], "update" => [] },
          "expected_settings" => target.fetch("expected_settings"))
      end

      def run(action, request, proposal, params)
        nested = request.dup
        nested.params = DeepCopy.call(params)
        action.handler.call(nested, proposal)
      end
    end
  end
end
