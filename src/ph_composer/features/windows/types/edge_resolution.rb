# frozen_string_literal: true

module PhComposer
  module Windows
    # Which Psi-Install Type an element edge takes. A shared edge takes none and contributes zero; a
    # partly shared edge has no proved mapping; any other edge takes its own assignment, and without
    # one the model default.
    module EdgeResolution
      Resolution = Struct.new(:source, :assignment_id, :effective_id, keyword_init: true)

      module_function

      # `source` is `:shared`, `:partial`, `:assigned` or `:default`.
      def resolve(cell, side, classification, default_id)
        assignment_id = cell.fetch("installs").fetch(side)
        source = if classification == :shared then :shared
                elsif classification == :partial then :partial
                elsif assignment_id then :assigned
                else :default
                 end
        effective_id = if source == :default then default_id
                elsif source == :assigned then assignment_id
                       end
        Resolution.new(:source => source, :assignment_id => assignment_id, :effective_id => effective_id)
      end
    end
  end
end
