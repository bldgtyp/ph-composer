# frozen_string_literal: true

module PhComposer
  module Zones
    # Solve adjacencies, retire one pair, and the retirement participant Classify composes into its
    # own step. The handlers are Zones module functions (adjacency/operations.rb).
    module AdjacencyRegistration
      # The resolved mutation set, whatever produced it: the selected Zones, or every Zone when the
      # caller is the export preflight. One Zone is allowed; it simply pairs with nothing.
      SOLVE_PARAMS = {
        "type" => "object", "additionalProperties" => false, "required" => ["zones"],
        "properties" => { "zones" => { "type" => "array", "items" => ZONE_REFERENCE, "minItems" => 1 } }
      }.freeze
      RETIRE_PARAMS = {
        "type" => "object", "additionalProperties" => false, "required" => ["face"],
        "properties" => { "face" => { "type" => "object" } }
      }.freeze

      module_function

      def install(feature)
        feature.action("#{FEATURE_ID}.solve_adjacency",
                       :description => "Reconcile and pair shared Faces within an explicit Zone scope.",
                       :params => SOLVE_PARAMS, :result => OBJECT, :undo_name => "Solve Zone Adjacency",
                       :side_effects => "Retires old Surface pairs and writes current endpoints.") do |
                         request, proposal|
          Zones.solve_adjacency(request, proposal)
        end
        feature.action("#{FEATURE_ID}.retire_adjacency", :description => "Retire one reciprocal Surface pair.",
                       :params => RETIRE_PARAMS, :result => OBJECT, :undo_name => "Retire Zone Adjacency",
                       :side_effects => "Removes both endpoints and leaves their boundary condition unassigned.") do |
                         request, proposal|
          Zones.retire_adjacency(request, proposal)
        end
        feature.proposal_participant("#{FEATURE_ID}.retire_pairs") do |request, targets, index = nil|
          Zones.retire_pairs(request, targets, index)
        end
      end
    end
  end
end
