# frozen_string_literal: true

module PhComposer
  module Library
    # The same library resolution and owner callbacks can join another feature's proposal.
    # No nested dispatch or native transaction is started by a participant.
    module CopyParticipant
      module_function

      def call(request, proposal, params)
        unless proposal && proposal.equal?(request.proposal)
          raise CodedError.new("operation.proposal_required", "Library copy needs the caller's active proposal.")
        end

        feature = request.registry.features.fetch(request.owner)
        unless request.owner == FEATURE_ID || feature.requires.include?(FEATURE_ID)
          raise CodedError.new("operation.dependency_missing", "The caller must require the library feature.")
        end
        unless params.is_a?(Hash) && JsonValue.problems(params).empty? &&
               JsonSchema.validate(params, Library.copy_params).empty?
          raise CodedError.new("params.invalid", "Library copy params do not match their schema.")
        end

        value = Coordinator.copy(request.with(:params => params), proposal)
        unless JsonValue.problems(value).empty? && JsonSchema.validate(value, Schemas.copy_result).empty?
          raise InternalError, "Library copy returned a result outside its schema."
        end

        DeepCopy.call(value)
      rescue StandardError => error
        request.proposal&.refuse(error)
        raise
      end
    end
  end
end
