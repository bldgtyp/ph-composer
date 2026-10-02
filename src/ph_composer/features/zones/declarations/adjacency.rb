# frozen_string_literal: true

module PhComposer
  module Zones
    # Solve adjacencies, retire one pair, and the retirement participant Classify composes into its
    # own step. The handlers are Zones module functions (adjacency/operations.rb).
    module AdjacencyRegistration
      # The resolved mutation set, whatever produced it: the selected Zones, or every Zone when the
      # caller is the export preflight. One Zone is allowed; it simply pairs with nothing.
      SOLVE_PARAMS = Shapes.object({
        "zones" => { "type" => "array", "items" => ZONE_REFERENCE, "minItems" => 1,
                     "description" => "The Zone occurrences whose shared Faces to pair; Faces shared with a Zone " \
                                      "outside the scope are left alone." }
      }).freeze
      SOLVE_RESULT = Shapes.object({
        "pair_ids" => Shapes.list(Shapes::ID, :description => "Every Surface pair current after the Solve."),
        "reported" => Shapes::COUNT.merge("description" => "Findings reported instead of paired, as outcome findings.")
      }).freeze
      RETIRE_PARAMS = Shapes.object({
        "face" => Faces::FACE_REFERENCE.merge("description" => "Either Face of the Surface pair to retire.")
      }).freeze
      RETIRE_RESULT = Shapes.object({
        "pair_id" => { "type" => %w[string null], "description" => "The pair retired." }
      }).freeze
      EXAMPLE_ZONES = [{ "zone_id" => "zon_Ab12Cd34Ef56", "zone_path" => [1201] },
                       { "zone_id" => "zon_Gh78Ij90Kl12", "zone_path" => [1301] }].freeze
      EXAMPLE_FACE = { "zone_id" => "zon_Ab12Cd34Ef56", "zone_path" => [1201], "entity_path" => [1202],
                       "entity_id" => "fac_Mn34Op56Qr78" }.freeze

      module_function

      def install(feature)
        feature.action("#{FEATURE_ID}.solve_adjacency",
                       :description => "Reconcile and pair shared Faces within an explicit Zone scope.",
                       :params => SOLVE_PARAMS, :result => SOLVE_RESULT, :undo_name => "Solve Zone Adjacency",
                       :examples => [{ "zones" => EXAMPLE_ZONES }],
                       :side_effects => "Retires old Surface pairs and writes current endpoints.") do |request, proposal|
          Zones.solve_adjacency(request, proposal, :zones => request.params.fetch("zones"))
        end
        feature.action("#{FEATURE_ID}.retire_adjacency", :description => "Retire one reciprocal Surface pair.",
                                                         :params => RETIRE_PARAMS, :result => RETIRE_RESULT, :undo_name => "Retire Zone Adjacency",
                                                         :examples => [{ "face" => EXAMPLE_FACE }],
                                                         :side_effects => "Removes both endpoints and leaves their boundary condition unassigned.") do |
                         request, proposal|
          Zones.retire_adjacency(request, proposal, :face => request.params.fetch("face"))
        end
        feature.proposal_participant("#{FEATURE_ID}.retire_pairs") do |request, targets, index = nil|
          Zones.retire_pairs(request, targets, index)
        end
      end
    end
  end
end
