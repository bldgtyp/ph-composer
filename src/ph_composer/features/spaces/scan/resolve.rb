# frozen_string_literal: true

module PhComposer
  module Spaces
    # Strict resolution of an explicit Space, Volume or Floor Segment reference. Paths locate
    # candidates; the record id proves identity. Nothing searches by name or geometry to repair a
    # stale reference.
    module Resolve
      # Per kind: the reference's id key, its label and the occurrences a scan holds for it.
      TARGETS = {
        SPACE_KIND => ["space_id", "Space", ->(scan) { scan.spaces }],
        VOLUME_KIND => ["volume_id", "Volume", ->(scan) { scan.volumes + scan.orphan_volumes }],
        FLOOR_SEGMENT_KIND => ["floor_segment_id", "Floor Segment",
                               ->(scan) { scan.segments + scan.misplaced_segments }]
      }.freeze

      module_function

      # The reference's kind, read from which id key it carries.
      def kind_of(reference)
        kinds = TARGETS.select { |_kind, (key, _label, _list)| reference.key?(key) }.keys
        return kinds.first if kinds.length == 1

        raise CodedError.new("params.invalid", "A reference names one Space, Volume or Floor Segment id.")
      end

      # A write refuses a copied identity, shared storage and a lock, each with nothing written.
      def occurrence(scan, reference, mutable:)
        kind = kind_of(reference)
        key, label, list = TARGETS.fetch(kind)
        path = integer_path(reference.fetch("entity_path"))
        candidates = list.call(scan)
        found = candidates.find { |occurrence| occurrence.path == path }
        raise CodedError.new("target.not_found", "That #{label} occurrence no longer exists.") unless found
        unless found.record.fetch("id") == reference.fetch(key)
          raise CodedError.new("target.changed", "The #{label} identity has changed.")
        end

        writable!(found, candidates, label) if mutable
        found
      end

      def writable!(found, candidates, label)
        if candidates.count { |occurrence| occurrence.record.fetch("id") == found.record.fetch("id") } > 1
          raise CodedError.new("target.ambiguous",
                               "That #{label} shares its identity with a copy. Nothing was written.")
        end
        if found.shared
          raise CodedError.new("target.shared_definition",
                               "That #{label} is inside shared component storage. Nothing was written.")
        end
        return unless found.locked

        raise CodedError.new("target.locked", "That #{label} or a Group above it is locked. Nothing was written.")
      end

      def integer_path(value)
        Array(value).map { |id| Integer(id) }
      rescue ArgumentError, TypeError
        raise CodedError.new("params.invalid", "Occurrence paths contain only persistent-id integers.")
      end
    end
  end
end
