# frozen_string_literal: true

module PhComposer
  module ColourBy
    # A viewport tool's hold on the Colour-by mode while it runs, so the user sees what they are painting.
    # What a tool turns on is not what the user chose: it is never remembered, and when the tool ends the
    # mode that was on before it took over comes back (or none). A mode the user picked from the Colour by
    # menu while the tool ran is their choice, and the tool leaves it.
    class Lease
      def initialize(session)
        @session = session
        @before = nil
        @taken = nil
        @switches = nil
      end

      def held?
        !@taken.nil?
      end

      # Turns `mode` on for the tool. The first take of a run records what was on before it, and so does a
      # take after the user picked a mode meanwhile: that mode is the one to come back.
      def take(mode)
        return false unless ColourBy.registered?(mode)

        service = ColourBy.for(@session)
        @before = service.mode_name unless held? && service.switches == @switches
        @taken = mode
        service.activate(mode, :remember => false) unless service.mode_name == mode
        @switches = service.switches
        true
      end

      # Puts back what was on before the first take, unless the mode has switched since the tool last took it.
      def release
        taken = @taken
        before = @before
        switches = @switches
        forget
        return unless taken

        service = ColourBy.for(@session)
        return if service.switches != switches || before == taken

        if before && ColourBy.registered?(before)
          service.activate(before, :remember => false)
        else
          service.deactivate
        end
      end

      # Drops the hold without touching the service, for a Model that is already gone.
      def forget
        @before = nil
        @taken = nil
        @switches = nil
      end
    end
  end
end
