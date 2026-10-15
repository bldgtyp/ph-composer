# frozen_string_literal: true

module PhComposer
  module Spaces
    # Move Space to Zone, planned. The Space Group is placed again in the target Zone's entities with the
    # transform that holds its world position, and the original is erased; the Volumes, Faces and records
    # inside are the same entities (context/SKETCHUP_HOST_BEHAVIOR.md, "Re-placing a Group's definition"),
    # so ids, numbers, values, `user_data` and each Volume's `home_transform`, which is relative to its
    # Space, are unchanged by construction. Pure.
    module MovePlan
      module_function

      # Transforms read through an open edit context are not the stored ones
      # (context/SKETCHUP_HOST_BEHAVIOR.md, "Observers and edit contexts"), so a move needs the root.
      def refuse!(space:, current_zone_path:, target_zone_path:, open_path:)
        unless open_path.empty?
          raise CodedError.new("space.context_open", "Close the edit context before moving a Space. Nothing was " \
                                                     "written.")
        end
        if current_zone_path == target_zone_path
          raise CodedError.new("space.same_zone", "The Space is already in that Zone. Nothing was written.")
        end
        return unless target_zone_path[0, space.path.length] == space.path

        raise CodedError.new("params.invalid", "A Space cannot move into a Zone inside itself.")
      end

      # The Space Group's transform inside the target Zone: its world transform seen from the Zone's
      # contents. `zone_world` maps the Zone's contents to world.
      def transform(space_world, zone_world)
        (zone_world.inverse * space_world).to_a
      end
    end
  end
end
