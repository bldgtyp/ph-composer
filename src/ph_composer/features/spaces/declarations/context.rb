# frozen_string_literal: true

module PhComposer
  module Spaces
    # The edit-context commands, Restore position and the reconciler's subscriptions.
    module ContextRegistration
      PATH_RESULT = Shapes.object({ "path" => Shapes::ZONE_PATH.merge("description" => "The edit path afterwards.") })
      TARGET = %w[record.unreadable target.ambiguous target.changed target.locked target.not_found
                  target.shared_definition validation.failed].freeze
      SPACE_PARAM = SPACE_REFERENCE.merge("description" => "The Space, as list returns it.").freeze
      VOLUME_PARAM = VOLUME_REFERENCE.merge("description" => "The Volume, as list returns it.").freeze
      ANY_PARAM = Shapes.object({ "space_id" => Shapes::TEXT, "volume_id" => Shapes::TEXT,
                                  "floor_segment_id" => Shapes::TEXT, "entity_path" => PATH },
                                :optional => %w[space_id volume_id floor_segment_id],
                                :description => "A Space, Volume or Floor Segment, as list returns it.")
      EXAMPLE_SPACE = { "space_id" => "spc_Ab12Cd34Ef56", "entity_path" => [1201, 1300] }.freeze
      EXAMPLE_VOLUME = { "volume_id" => "vol_Ab12Cd34Ef56", "entity_path" => [1201, 1300, 1310] }.freeze

      module_function

      def install(feature)
        declare_views(feature)
        feature.action("#{FEATURE_ID}.volumes.restore_position",
                       :description => "Put a moved Volume back where it was last left, and protect it.",
                       :refuses => TARGET + %w[space.position_unknown space.volume_open],
                       :params => Shapes.object({ "volume" => VOLUME_PARAM }),
                       :result => Shapes.object({ "volume_id" => Shapes::TEXT,
                                                  "moved" => { "type" => "boolean",
                                                               "description" => "Whether it had moved." } }),
                       :undo_name => "Restore Volume Position", :side_effects => "Moves and locks the Volume Group.",
                       :examples => [{ "volume" => EXAMPLE_VOLUME }]) do |request, proposal|
          Authoring.restore_position(request, proposal, :volume => request.params.fetch("volume"))
        end
        subscribe(feature)
      end

      def declare_views(feature)
        feature.view_command("#{FEATURE_ID}.context.open",
                             :description => "Open a Space as the edit context; an open Volume is protected first.",
                             :refuses => TARGET, :params => Shapes.object({ "space" => SPACE_PARAM }),
                             :result => PATH_RESULT, :examples => [{ "space" => EXAMPLE_SPACE }]) do |request|
          Navigation.open(request, :space => request.params.fetch("space"))
        end
        feature.view_command("#{FEATURE_ID}.context.enter_volume",
                             :description => "Open a Volume for editing: the open Volume is protected, this one is " \
                                             "unlocked in its own Undo step (Enter Volume) and the path opens on it.",
                             :refuses => TARGET, :params => Shapes.object({ "volume" => VOLUME_PARAM }),
                             :result => PATH_RESULT, :examples => [{ "volume" => EXAMPLE_VOLUME }]) do |request|
          Navigation.enter_volume(request, :volume => request.params.fetch("volume"))
        end
        feature.view_command("#{FEATURE_ID}.context.close",
                             :description => "Leave the innermost open Space or Volume for its parent, protecting a " \
                                             "Volume being left.",
                             :refuses => [], :params => Shapes::NONE, :result => PATH_RESULT,
                             :examples => [{}]) { |request| Navigation.close(request) }
        feature.view_command("#{FEATURE_ID}.locate",
                             :description => "Select and frame one Space, Volume or Floor Segment; a Floor Segment " \
                                             "opens its Volume.",
                             :refuses => TARGET, :params => Shapes.object({ "reference" => ANY_PARAM }),
                             :result => PATH_RESULT, :examples => [{ "reference" => EXAMPLE_SPACE }]) do |request|
          Navigation.locate(request, :reference => request.params.fetch("reference"))
        end
      end

      # The reconciler hears every event that can move the path or the Volume on it.
      def subscribe(feature)
        %i[session_created transaction_committed transaction_undone transaction_redone
           active_path_changed].each do |kind|
          feature.on_host_event(kind) { |session| Reconciler.for(session).observed }
        end
        feature.on_host_event(:pre_save) { |session| Reconciler.for(session).pre_save }
        feature.on_host_event(:post_save) { |session| Reconciler.for(session).post_save }
        EditContext.boundary(:spaces) { |model, from, to| Protection.leaving(model, from, to) }
      end
    end
  end
end
