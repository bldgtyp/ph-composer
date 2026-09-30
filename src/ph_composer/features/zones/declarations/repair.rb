# frozen_string_literal: true

module PhComposer
  module Zones
    # Identity and membership repairs: a copied Zone, a natively split Face, an exploded Zone. The
    # handlers are Zones module functions (zone/operations.rb).
    module RepairRegistration
      # The copy is named by path, not by id: its id is the ambiguous thing being repaired.
      REPAIR_PARAMS = {
        "type" => "object", "additionalProperties" => false, "required" => ["zone_path"],
        "properties" => { "zone_path" => PATH }
      }.freeze
      SPLIT_REPAIR_PARAMS = {
        "type" => "object", "additionalProperties" => false, "required" => %w[zone face_id zones],
        "properties" => {
          "zone" => ZONE_REFERENCE, "face_id" => { "type" => "string" },
          "zones" => { "type" => "array", "items" => ZONE_REFERENCE, "minItems" => 1 },
          "retaining_entity_path" => PATH
        }
      }.freeze
      RESTORE_PARAMS = {
        "type" => "object", "additionalProperties" => false, "required" => %w[parent_path zone_id],
        "properties" => { "parent_path" => PATH, "zone_id" => { "type" => "string" } }
      }.freeze

      module_function

      def install(feature)
        SplitIdentityMenu.install(feature)
        feature.action("#{FEATURE_ID}.repair_split_face",
                       :description => "Repair copied Face identities after a native split.",
                       :params => SPLIT_REPAIR_PARAMS, :result => OBJECT,
                       :undo_name => "Repair Split Face Identity",
                       :side_effects => "Reidentifies split pieces and retires invalid Surface links.") do |
                         request, proposal|
          Zones.repair_split_face(request, proposal)
        end
        feature.action("#{FEATURE_ID}.repair_identity",
                       :description => "Give one copied Zone occurrence an identity of its own.",
                       :params => REPAIR_PARAMS, :result => OBJECT, :undo_name => "Repair Zone Identity",
                       :side_effects => "Reidentifies the named occurrence and its Faces; the original is " \
                                        "left untouched.") do |request, proposal|
          Zones.repair_identity(request, proposal)
        end
        feature.action("#{FEATURE_ID}.restore",
                       :description => "Regroup the stamped members of an exploded Zone, recovering only their stamp.",
                       :params => RESTORE_PARAMS, :result => OBJECT, :undo_name => "Restore Zone",
                       :side_effects => "Groups stamped Faces in one parent context and writes a Zone record.") do |
                         request, proposal|
          Zones.restore(request, proposal)
        end
      end
    end
  end
end
