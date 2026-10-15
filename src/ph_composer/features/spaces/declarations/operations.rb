# frozen_string_literal: true

module PhComposer
  module Spaces
    # The operations' public contract: Create Space and its preview, Volume and Floor Segment edits,
    # update, batch, delete and metadata. The handlers are Authoring module functions.
    module OperationRegistration
      ZONE = Shapes.object({ "zone_id" => Shapes::TEXT, "zone_path" => Shapes::ZONE_PATH },
                           :description => "The Zone occurrence, as ph_composer.zones.list returns it.")
      FACE = Shapes.object({ "zone_id" => Shapes::TEXT, "zone_path" => Shapes::ZONE_PATH,
                             "entity_path" => Shapes::ZONE_PATH, "entity_id" => { "type" => %w[string null] } },
                           :description => "A Zone Face, as ph_composer.zones.faces.list returns it.")
      FACES = Shapes.list(FACE).merge("minItems" => 1, "maxItems" => Pages::MAXIMUM_LIMIT,
                                      "description" => "Loose Faces of the Zone, as its Face list returns them.")
      PATHS = Shapes.list(PATH).merge("minItems" => 1, "maxItems" => Pages::MAXIMUM_LIMIT,
                                      "description" => "Root-to-Face persistent-id paths.")
      # Any one of the three references: the id key it carries says which.
      REFERENCE = Shapes.object({ "space_id" => Shapes::TEXT, "volume_id" => Shapes::TEXT,
                                  "floor_segment_id" => Shapes::TEXT, "entity_path" => PATH },
                                :optional => %w[space_id volume_id floor_segment_id],
                                :description => "A Space, Volume or Floor Segment reference, as list returns it.")
      FACTOR = Schema.factor("The weighting factor to write, 0 to 1; 1 counts the whole area.")
      EDIT = Shapes.object({
        "reference" => REFERENCE,
        "values" => { "type" => "object",
                      "description" => "The values to change. A Space takes name, number, " \
                                       "default_height_m and the three airflows; a Volume " \
                                       "display_name and avg_ceiling_height_m; a Floor " \
                                       "Segment display_name, weighting_factor and " \
                                       "net_area_factor. null removes an optional value." },
        "expected_values" => { "type" => "object",
                               "description" => "Each named value as last read; a key absent " \
                                                "here expects the value absent." }
      })
      IDS = Shapes.object({ "ids" => Shapes.list(Shapes::TEXT) })
      LEFT_OUT = Shapes.object({ "reference" => FACE, "reason" => Shapes::TEXT, "message" => Shapes::TEXT })
      PREVIEW = Shapes.object({ "accepted" => Shapes.list(FACE), "left_out" => Shapes.list(LEFT_OUT) })
      CREATED = Shapes.object({ "space_id" => Shapes::TEXT, "volume_id" => Shapes::TEXT,
                                "floor_segment_ids" => Shapes.list(Shapes::TEXT) })
      TARGET = %w[record.unreadable target.ambiguous target.changed target.locked target.not_found
                  target.shared_definition validation.failed].freeze
      ZONE_TARGET = %w[record.unreadable target.ambiguous target.changed target.locked target.not_found
                       target.shared_definition target.wrong_hierarchy target.wrong_kind validation.failed].freeze
      EXAMPLE_ZONE = { "zone_id" => "zon_Ab12Cd34Ef56", "zone_path" => [1201] }.freeze
      EXAMPLE_FACE = EXAMPLE_ZONE.merge("entity_path" => [1202], "entity_id" => nil).freeze
      EXAMPLE_SPACE = { "space_id" => "spc_Ab12Cd34Ef56", "entity_path" => [1201, 1300] }.freeze
      EXAMPLE_VOLUME = { "volume_id" => "vol_Ab12Cd34Ef56", "entity_path" => [1201, 1300, 1310] }.freeze

      CREATE_PARAMS = Shapes.object({ "zone" => ZONE, "faces" => FACES })
      DEFAULT_FACTOR = 1.0
      # Each action as [name, declaration, handler]; a handler takes the request, the proposal and the params.
      ACTIONS = [
        ["create", {
          :description => "Group explicit loose Faces of an open Zone into one new Space with one Volume, each " \
                          "Face a Floor Segment. The Zone's edit context must be open.",
          :refuses => (ZONE_TARGET + %w[space.context_required space.nothing_to_create]).uniq,
          :params => Shapes.object(CREATE_PARAMS.fetch("properties").merge(
            "name" => Shapes::TEXT.merge("description" => "The new Space's name; empty when absent."),
            "number" => Shapes::TEXT.merge("description" => "The new Space's number; the " \
                                                            "next free one in the Zone " \
                                                            "when absent."),
            "weighting_factor" => FACTOR
          ), :optional => %w[name number weighting_factor]),
          :result => CREATED, :undo_name => "Create Space", :participants => [Authoring::STAMP],
          :side_effects => "Groups the Faces and writes the Space, Volume, Floor Segment and Zone stamp.",
          :examples => [{ "zone" => EXAMPLE_ZONE, "faces" => [EXAMPLE_FACE], "name" => "Living" }]
        }, lambda { |request, proposal, params|
          Authoring.create(request, proposal, :zone => params.fetch("zone"), :faces => params.fetch("faces"),
                                              :name => params["name"], :number => params["number"],
                                              :weighting_factor => params.fetch("weighting_factor", DEFAULT_FACTOR))
        }],
        ["volumes.create", {
          :description => "Group explicit loose Faces at an open Space's root into its next Volume.",
          :refuses => (TARGET + %w[space.context_required target.wrong_hierarchy target.wrong_kind]).uniq,
          :params => Shapes.object({ "space" => REFERENCE, "faces" => PATHS, "weighting_factor" => FACTOR },
                                   :optional => ["weighting_factor"]),
          :result => Shapes.object({ "volume_id" => Shapes::TEXT, "floor_segment_ids" => Shapes.list(Shapes::TEXT) }),
          :undo_name => "Add Volume", :side_effects => "Groups the Faces and writes their records.",
          :examples => [{ "space" => EXAMPLE_SPACE, "faces" => [[1201, 1300, 1320]] }]
        }, lambda { |request, proposal, params|
          Authoring.create_volume(request, proposal, :space => params.fetch("space"), :faces => params.fetch("faces"),
                                                     :weighting_factor => params.fetch("weighting_factor",
                                                                                       DEFAULT_FACTOR))
        }],
        ["update", {
          :description => "Change one Space, Volume or Floor Segment's values, guarded by the values last read.",
          :refuses => TARGET, :params => EDIT, :result => IDS, :undo_name => "Edit Space",
          :side_effects => "Rewrites the record; a height edit also records the Model's last height.",
          :examples => [{ "reference" => EXAMPLE_SPACE, "values" => { "v_sup_m3h" => 60.0 }, "expected_values" => {} }]
        }, lambda { |request, proposal, params|
          Authoring.update(request, proposal, :reference => params.fetch("reference"),
                                              :values => params.fetch("values"),
                                              :expected_values => params.fetch("expected_values"))
        }],
        ["batch_update", {
          :description => "Change many Spaces, Volumes and Floor Segments in one all-or-nothing step.",
          :refuses => TARGET,
          :params => Shapes.object({ "edits" => Shapes.list(EDIT).merge("minItems" => 1,
                                                                        "maxItems" => Pages::MAXIMUM_LIMIT,
                                                                        "description" => "The edits, all or none.") }),
          :result => IDS, :undo_name => "Edit Spaces", :side_effects => "Rewrites every named record in one Undo step.",
          :examples => [{ "edits" => [{ "reference" => EXAMPLE_VOLUME, "values" => { "avg_ceiling_height_m" => 2.7 },
                                        "expected_values" => { "avg_ceiling_height_m" => 2.5 } }] }]
        }, ->(request, proposal, params) {
             Authoring.batch_update(request, proposal, :edits => params.fetch("edits"))
           }],
        ["volumes.remove", {
          :description => "Remove one Volume's structure: its Floor Segment records go and its Faces stay loose in " \
                          "the Space.",
          :refuses => TARGET, :params => Shapes.object({ "volume" => REFERENCE }),
          :result => Shapes.object({ "volume_id" => Shapes::TEXT }), :undo_name => "Remove Volume",
          :side_effects => "Explodes the Volume Group and removes its records.",
          :examples => [{ "volume" => EXAMPLE_VOLUME }]
        }, lambda { |request, proposal, params|
          Authoring.remove_volume(request, proposal, :volume => params.fetch("volume"))
        }],
        ["delete", {
          :description => "Erase one Space and everything in it.", :refuses => TARGET,
          :params => Shapes.object({ "space" => REFERENCE }), :result => Shapes.object({ "space_id" => Shapes::TEXT }),
          :undo_name => "Delete Space", :side_effects => "Erases the Space Group.",
          :examples => [{ "space" => EXAMPLE_SPACE }]
        }, ->(request, proposal, params) { Authoring.delete(request, proposal, :space => params.fetch("space")) }],
        ["update_metadata", {
          :description => "Replace the user_data and installed extension payloads of explicit Spaces, Volumes and " \
                          "Floor Segments, guarded by the metadata last read.",
          :refuses => (TARGET + %w[extension.invalid extension.migration_required extension.schema_unsupported
                                   extension.unavailable reference.invalid]).uniq,
          :params => Shapes.metadata_updates(REFERENCE, Pages::MAXIMUM_LIMIT),
          :result => Shapes.metadata_result(REFERENCE), :undo_name => "Edit Space Metadata",
          :side_effects => "Rewrites only the named records' metadata.",
          :examples => [{ "updates" => [{ "reference" => EXAMPLE_SPACE,
                                          "user_data" => { "example" => { "note" => "kept" } },
                                          "expected_metadata" => { "user_data" => {}, "extension_data" => {} } }] }]
        }, lambda { |request, proposal, params|
          Authoring.update_metadata(request, proposal, :updates => params.fetch("updates"))
        }],
        ["floors.mark", {
          :description => "Mark explicit Faces directly inside Volumes as Floor Segments with one weighting factor; " \
                          "a marked Face takes the factor.",
          :refuses => (TARGET + %w[target.wrong_hierarchy target.wrong_kind]).uniq,
          :params => Shapes.object({ "faces" => PATHS, "weighting_factor" => FACTOR }),
          :result => Shapes.object({ "floor_segment_ids" => Shapes.list(Shapes::TEXT) }),
          :undo_name => "Mark Floor", :side_effects => "Writes Floor Segment records on the Faces.",
          :examples => [{ "faces" => [[1201, 1300, 1310, 1311]], "weighting_factor" => 1.0 }]
        }, lambda { |request, proposal, params|
          Authoring.mark_floors(request, proposal, :faces => params.fetch("faces"),
                                                   :weighting_factor => params.fetch("weighting_factor"))
        }],
        ["floors.unmark", {
          :description => "Remove explicit Floor Segment records; the Faces stay.", :refuses => TARGET,
          :params => Shapes.object({ "floor_segments" => Shapes.list(REFERENCE).merge(
            "minItems" => 1, "description" => "The Floor Segments whose records go."
          ) }),
          :result => Shapes.object({ "floor_segment_ids" => Shapes.list(Shapes::TEXT) }),
          :undo_name => "Unmark Floor", :side_effects => "Removes Floor Segment records.",
          :examples => [{ "floor_segments" => [{ "floor_segment_id" => "fsg_Ab12Cd34Ef56",
                                                 "entity_path" => [1201, 1300, 1310, 1311] }] }]
        }, lambda { |request, proposal, params|
          Authoring.unmark_floors(request, proposal, :floor_segments => params.fetch("floor_segments"))
        }]
      ].freeze

      module_function

      def install(feature)
        feature.query("#{FEATURE_ID}.create_preview",
                      :description => "Which explicit Faces Create Space would take into a new Space, and why it " \
                                      "leaves each other one out. Writes nothing.",
                      :refuses => ZONE_TARGET, :params => CREATE_PARAMS, :result => PREVIEW,
                      :examples => [{ "zone" => EXAMPLE_ZONE, "faces" => [EXAMPLE_FACE] }]) do |request|
          Authoring.create_preview(request, :zone => request.params.fetch("zone"),
                                            :faces => request.params.fetch("faces"))
        end
        ACTIONS.each do |name, declaration, handler|
          feature.action("#{FEATURE_ID}.#{name}", **declaration) do |request, proposal|
            handler.call(request, proposal, request.params)
          end
        end
      end
    end
  end
end
