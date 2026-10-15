# frozen_string_literal: true

module PhComposer
  module Spaces
    # Spaces' part of a Zone occurrence becoming independent (`ph_composer.zones.occurrence_independent`;
    # context/CONTRACTS.md, "Compound proposals"). Every Space, Volume and Floor Segment inside the
    # occurrence whose id another occurrence holds takes a new id, and each renamed Volume a new Space
    # Floor, in the Zone's own proposal, so the copy and its Spaces are independent in one Undo step.
    # Numbers and values are kept: the copied Spaces are in a Zone of their own. Payloads are remapped
    # across the copy and to the Zone's new ids. The Zone stamps on the Space Groups are Zones' to rewrite,
    # and Make Zone independent rewrites them. The step binds logically and adds only restorable writes,
    # because the Zone copy watcher's follow-up cannot abort.
    module ZoneCopy
      NAME = "#{FEATURE_ID}.follow_zone_copy"
      TRANSITION = "ph_composer.zones.occurrence_independent"
      REFUSES = %w[copy.rule_missing extension.invalid identity.conflict reference.invalid target.changed
                   target.locked target.shared_definition validation.failed].freeze

      module_function

      def install(feature)
        feature.transition_contributor(NAME, :transition => TRANSITION, :refuses => REFUSES) do |*args|
          contribute(*args)
        end
      end

      def contribute(request, proposal, description)
        zone_path = description.fetch("zone_path")
        allocate = Records::Identity.allocator(request, "transition" => TRANSITION,
                                                        "zone_id" => description.fetch("new_zone_id"))
        parent = { :mapping => description.fetch("mapping"),
                   :references => description.fetch("references").map do |row|
                     Records::ReferenceEntry.new(:kind => row.fetch("kind"), :key => row.fetch("key"),
                                                 :record => row.fetch("record"))
                   end }
        # Records outside the copied Zone only say which ids are held there; one that does not read is
        # not this repair's to refuse.
        scan = Occurrences.scan(request.model, :strict => zone_path)
        plan = IdentityPlan.build(scan, nil, :number => nil, :allocate => allocate,
                                             :catalog => request.registry.catalog, :engine => request.engine,
                                             :scope => zone_path, :parent => parent)
        return [] if plan.rows.empty?

        step = IdentityStep.new(:plan => plan, :scope_path => zone_path)
        proposal.add_step(step, :scopes => [])
        step.planned
      end
    end
  end
end
