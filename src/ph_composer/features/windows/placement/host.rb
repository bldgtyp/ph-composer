# frozen_string_literal: true

module PhComposer
  module Windows
    module Placement
      # A Face that hosts, or may host, a Window unit. `locator` is set on a writable host only: the
      # Zones Face target's resolver, which a placing step calls again at apply to find the live Face.
      Host = Struct.new(:entity, :entities, :parent_path, :transform, :reference, :values, :geometry,
                        :zone_state, :locator, keyword_init: true)

      # Face semantics come from Zones' public contract: `host_context` for a Face's reference and values,
      # `zones.all` for Zone state, and the Face reference target's `locate` for a writable host's live
      # Face, with Zones' own refusals. Windows walks no Zone path and reads no Zone dictionary.
      module Hosts
        FACE_KIND = "ph_composer.zones.faces.face"
        CONTEXT = "ph_composer.zones.faces.host_context"
        ZONES = "ph_composer.zones.all"
        # The Face types a Window may be placed in.
        SUPPORTED_FACE_TYPES = %w[Wall RoofCeiling].freeze

        module_function

        # The `host_context` rows for root-to-Face native paths, keyed by path, in reads of at most the
        # query's page limit each.
        def context(request, paths)
          paths.uniq.each_slice(Pages::MAXIMUM_LIMIT).each_with_object({}) do |slice, rows|
            request.query(CONTEXT, "paths" => slice).fetch("faces").each { |row| rows[row.fetch("path")] = row }
          end
        end

        # Each Zone occurrence's state from a `zones.all` read, keyed by Zone reference.
        def zone_states(zone_rows)
          zone_rows.to_h { |zone| [zone.fetch("reference"), zone.fetch("state")] }
        end

        # The state of the Zone a `host_context` row's Face is in; nil when no Zone read names it.
        def zone_state(states, row)
          states[row.fetch("reference").slice("zone_id", "zone_path")]
        end

        # A host a Window may be written to, named by an explicit Face reference. Locating it for
        # mutation refuses an ambiguous, shared or nested Zone, so its Zone state is `found`. A caller
        # that already read the Face's `host_context` row passes it.
        def writable(request, reference, row: nil)
          locator = request.locator(FACE_KIND)
          located = locator.call(request.model, reference, :mutable => true)
          row ||= context(request, [located.parent_path + [located.entity.persistent_id]]).values.first
          unless row && row.fetch("reference") == reference
            raise CodedError.new("target.changed", "The host Face reference no longer matches the Zone read.")
          end
          placeable!(row, "found")

          Host.new(:entity => located.entity, :entities => located.entities, :parent_path => located.parent_path,
            :transform => located.transform, :reference => DeepCopy.call(reference),
            :values => DeepCopy.call(row.fetch("values")), :zone_state => "found",
            :geometry => FaceGeometry.capture(located.entity, located.transform), :locator => locator)
        end

        # What Windows itself refuses in a host: a Zone that is not uniquely found, and a Surface Face.
        def placeable!(row, zone_state)
          unless zone_state == "found"
            raise CodedError.new("target.not_found", "Choose a Face in one writable, unambiguous Zone.")
          end
          return unless row.fetch("values")["boundary_condition"] == "Surface"

          raise CodedError.new("window.surface_host", "A paired Surface Face cannot host a Window unit.")
        end

        # The Window conditions a host Face's Zones values raise, as codes: the same codes for the same
        # Face in a Unit read and in the export preflight. `zoned` is whether the Face has an owning Zone.
        # A Face with no record has no Face type or boundary, so it raises both of those conditions.
        def conditions(values, zoned:)
          face_type = values["face_type"]
          boundary = values["boundary_condition"]
          codes = []
          codes << "window.host_unclassified" unless face_type && zoned
          codes << "window.host_type_unsupported" if face_type && !SUPPORTED_FACE_TYPES.include?(face_type)
          if boundary == "Surface"
            codes << "window.surface_host"
          elsif boundary != "Outdoors"
            codes << "window.host_boundary_unsupported"
          end
          codes
        end

        # A read-only host on a Face the caller already holds: a Unit's glue, in the Unit's own parent, or
        # a pick. It does not locate, so a Unit in an ambiguous Zone stays a finding rather than a refusal.
        def read(face, parent_path, transform, row, zone_state)
          Host.new(:entity => face, :parent_path => parent_path.dup, :transform => transform,
            :reference => DeepCopy.call(row.fetch("reference")), :values => DeepCopy.call(row.fetch("values")),
            :zone_state => zone_state, :geometry => FaceGeometry.capture(face, transform))
        end
      end
    end
  end
end
